#!/usr/bin/env python3
"""Webcam background blur on NVIDIA GPU: matting -> v4l2 loopback.

OBS uses the loopback as a plain webcam (no plugin filter).
Idle contract: no readers on the loopback -> camera released, model unloaded
(0 CPU, 0 GPU, small RSS). Service stopped -> literally zero.
"""
import argparse
import fcntl
import gc
import glob
import math
import os
import struct
import sys
import time

import cv2
import numpy as np

VIDIOC_QUERYCAP = 0x80685600

# RVM recurrent geometry (from model source: GRU channels + /8../64 strides)
RVM_REC = (("r1i", 8, 16), ("r2i", 16, 32), ("r3i", 32, 64), ("r4i", 64, 128))


def find_cam(want, fallback):
    """Resolve the real camera by card name; numbers shift across replugs."""
    for dev in sorted(glob.glob("/dev/video*")):
        try:
            with open(dev, "rb") as f:
                buf = fcntl.ioctl(f.fileno(), VIDIOC_QUERYCAP, bytes(104))
            card = struct.unpack("16s32s32s6I", buf)[1].split(b"\0")[0].decode()
            if want.lower() in card.lower():
                return dev
        except OSError:
            continue
    return fallback


def has_readers(dev):
    """True if any other process holds the loopback open."""
    me = str(os.getpid())
    base = os.path.basename(dev)
    for pid in filter(str.isdigit, os.listdir("/proc")):
        if pid == me:
            continue
        try:
            fds = os.listdir(f"/proc/{pid}/fd")
        except OSError:
            continue
        for fd in fds:
            try:
                if os.path.basename(os.readlink(f"/proc/{pid}/fd/{fd}")) == base:
                    return True
            except OSError:
                continue
    return False


def rec_zeros(w, h):
    return [np.zeros((1, ch, math.ceil(h / sc), math.ceil(w / sc)), np.float32) for _, sc, ch in RVM_REC]


def _warmup(sess):
    names = [i.name for i in sess.get_inputs()]
    if "downsample_ratio" in names:
        feeds = {"src": np.zeros((1, 3, 540, 960), np.float32), "downsample_ratio": np.array([0.25], np.float32)}
        for (n, _, _), z in zip(RVM_REC, rec_zeros(960, 540)):
            feeds[n] = z
    else:
        feeds = {}
        for i in sess.get_inputs():
            dims = [(d if isinstance(d, int) else (160 if idx >= 2 else 1)) for idx, d in enumerate(i.shape)]
            feeds[i.name] = np.zeros(dims, np.float32)
    sess.run(None, feeds)


def build_session(model_path, use_cuda):
    import onnxruntime as ort

    order = [["CUDAExecutionProvider", "CPUExecutionProvider"]] if use_cuda else [["CPUExecutionProvider"]]
    sess = ort.InferenceSession(model_path, providers=order[0])
    if use_cuda and sess.get_providers()[0] != "CUDAExecutionProvider":
        raise RuntimeError("CUDA provider unavailable")
    if use_cuda:
        try:
            _warmup(sess)
        except Exception as e:
            print(f"[cam-blur] GPU warmup failed ({e}); falling back to CPU", flush=True)
            sess = ort.InferenceSession(model_path, providers=["CPUExecutionProvider"])
    print(f"[cam-blur] provider: {sess.get_providers()[0]}", flush=True)
    state_names = [i.name for i in sess.get_inputs() if i.name != "src"]
    state_shapes = {i.name: [d if isinstance(d, int) else 1 for d in i.shape] for i in sess.get_inputs() if i.name != "src" and i.name != "downsample_ratio"}
    return sess, sess.get_providers()[0], state_names, state_shapes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cam", default="/dev/video0", help="fallback path if --cam-name not found")
    ap.add_argument("--cam-name", default="Krom Kam", help="match camera by card name")
    ap.add_argument("--out", default="/dev/video10")
    ap.add_argument("--width", type=int, default=1280)
    ap.add_argument("--height", type=int, default=720)
    ap.add_argument("--infer", type=int, default=960, help="inference width (height auto 16:9)")
    ap.add_argument("--blur", type=int, default=10, help="1..20")
    ap.add_argument("--mode-file", default="", help="file containing 'blur' or 'raw'; default $XDG_RUNTIME_DIR/cam-blur.mode")
    ap.add_argument("--model", required=True)
    ap.add_argument("--no-cuda", action="store_true")
    ap.add_argument("--test-frames", type=int, default=0, help="no loopback: capture N frames, print stats")
    ap.add_argument("--save-sample", default="", help="save one composite jpg here (with --test-frames)")
    args = ap.parse_args()

    in_h = args.infer * 9 // 16
    mode_file = args.mode_file or os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "cam-blur.mode")

    def read_mode():
        try:
            with open(mode_file) as f:
                return f.read().strip()
        except OSError:
            return "raw"  # ponytail: no load unless asked

    def open_cam():
        dev = find_cam(args.cam_name, args.cam)
        c = cv2.VideoCapture(dev, cv2.CAP_V4L2)
        c.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*"MJPG"))
        c.set(cv2.CAP_PROP_FRAME_WIDTH, args.width)
        c.set(cv2.CAP_PROP_FRAME_HEIGHT, args.height)
        c.set(cv2.CAP_PROP_FPS, 30)
        return c, dev

    def run(n_frames=0):
        sess, active, state_names, state_shapes = build_session(args.model, not args.no_cuda)
        rec_names = [n for n, _, _ in RVM_REC]
        rec = rec_zeros(args.infer, in_h)
        prev_alpha = None
        in_names = [i.name for i in sess.get_inputs()]
        if "downsample_ratio" in in_names:
            kind = "rvm"
        elif sess.get_inputs()[0].name == "input":
            kind = "modnet"
        else:
            kind = "selfie"  # channels-last portrait model (selfie_seg/multiclass)
        print(f"[cam-blur] model: {kind}", flush=True)
        ds = np.array([0.25], dtype=np.float32)
        k = args.blur * 2 + 1
        _clahe = cv2.createCLAHE(clipLimit=2.0)

        cap, dev = open_cam()
        if not cap.isOpened():
            return f"cannot open camera ({dev})"

        fake = None
        if not n_frames:
            import pyfakewebcam

            try:
                fake = pyfakewebcam.FakeWebcam(args.out, args.width, args.height)
            except Exception:
                cap.release()
                return f"cannot open {args.out}: load v4l2loopback first"

        fps, n, t0 = 0.0, 0, time.time()
        fg_ratio = 0.0
        mode, prev_mode = "raw", ""
        last_seen = time.time()
        fails = 0
        interval = 1.0 / 30  # ponytail: never spin faster than output needs

        def post(alpha, frame=None):
            nonlocal prev_alpha, fg_ratio
            alpha = np.clip(alpha, 0, 1).astype(np.float32)
            if frame is not None:
                Hh, Ww = frame.shape[:2]
                if alpha.shape != (Hh, Ww):
                    alpha = cv2.resize(alpha, (Ww, Hh))
                # reclaim dropped skin adjacent to the mask (nose/cheek/arms)
                ycrcb = cv2.cvtColor(frame, cv2.COLOR_BGR2YCrCb)
                skin = ((ycrcb[:, :, 1] >= 77) & (ycrcb[:, :, 1] <= 127) & (ycrcb[:, :, 2] >= 133) & (ycrcb[:, :, 2] <= 173)).astype(np.float32)
                near = cv2.dilate((alpha > 0.5).astype(np.uint8), np.ones((21, 21), np.uint8)).astype(np.float32)
                alpha = np.clip(alpha + skin * near * (1 - alpha) * 0.9, 0, 1)
            if prev_alpha is None or prev_alpha.shape != alpha.shape:
                prev_alpha = np.zeros_like(alpha)
            alpha = 0.85 * alpha + 0.15 * prev_alpha
            prev_alpha = alpha.copy()
            alpha = np.clip((alpha - 0.15) / 0.7, 0.0, 1.0)
            fg_ratio = float((alpha > 0.5).mean())
            return alpha

        def comp(frame, alpha):
            alpha_full = cv2.resize(alpha, (args.width, args.height))
            a = ((alpha_full * 255 + 0.5).astype(np.uint8))[..., None].astype(np.uint16)
            tiny = cv2.resize(frame, (args.width // 4, args.height // 4))
            bg = cv2.resize(cv2.GaussianBlur(tiny, (k, k), 0), (args.width, args.height)).astype(np.uint16)
            f = frame.astype(np.uint16)
            return (((f * a + bg * (255 - a) + 127) // 255)).astype(np.uint8)
        while True:
            tick = time.time()
            ok, frame = cap.read()  # BGR full-res
            if not ok:
                fails += 1
                if fails % 25 == 1:
                    print(f"[cam-blur] camera unreadable ({fails} fails); reopening", flush=True)
                    try:
                        cap.release()
                    except Exception:
                        pass
                    time.sleep(1)
                    cap, _ = open_cam()
                else:
                    time.sleep(0.2)
                continue
            fails = 0
            if n % 30 == 0:
                mode = read_mode()
                if mode != prev_mode:
                    print(f"[cam-blur] mode: {mode}", flush=True)
                    rec = rec_zeros(args.infer, in_h)
                    prev_alpha = None
                    prev_mode = mode
                if has_readers(args.out):
                    last_seen = tick
                elif not n_frames and tick - last_seen > 10:
                    print("[cam-blur] no readers; sleeping", flush=True)
                    break
            if mode != "blur":
                out = frame
            elif kind == "selfie":
                small = cv2.resize(frame, (256, 256), interpolation=cv2.INTER_AREA)
                lab = cv2.cvtColor(cv2.cvtColor(small, cv2.COLOR_BGR2RGB), cv2.COLOR_RGB2LAB)
                lab[:, :, 0] = _clahe.apply(lab[:, :, 0])
                rgb = cv2.cvtColor(lab, cv2.COLOR_LAB2RGB)
                x = rgb.astype(np.float32)[None] / 255.0
                o = sess.run(None, {sess.get_inputs()[0].name: x})[0][0]
                e = np.exp(o - o.max(axis=-1, keepdims=True))
                e = e / e.sum(axis=-1, keepdims=True)
                alpha = 1 - e[:, :, 0]
                alpha = post(alpha, frame)
                out = comp(frame, alpha)
            elif kind == "modnet":
                small = cv2.resize(frame, (384, 384), interpolation=cv2.INTER_AREA)
                src = cv2.cvtColor(small, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
                mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)[None, :, None, None]
                std = np.array([0.229, 0.224, 0.225], dtype=np.float32)[None, :, None, None]
                src = (np.transpose(src, (2, 0, 1))[None] - mean) / std

                outs = sess.run(None, {"input": src})
                alpha = post(outs[0][0, 0], frame)
                out = comp(frame, alpha)
            else:
                small = cv2.resize(frame, (args.infer, in_h))
                src = cv2.cvtColor(small, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
                src = np.transpose(src, (2, 0, 1))[None]

                feeds = {"src": src, "downsample_ratio": ds}
                for name, state in zip(rec_names, rec):
                    feeds[name] = state
                outs = sess.run(None, feeds)
                rec = [np.asarray(o, dtype=np.float32) for o in outs[2:]]
                out = comp(frame, post(outs[1][0, 0], frame))

            n += 1
            if n_frames:
                if args.save_sample and n == n_frames // 2:
                    cv2.imwrite(args.save_sample, out)
                if n >= n_frames:
                    break
                continue
            fake.schedule_frame(cv2.cvtColor(out, cv2.COLOR_BGR2RGB))
            if n % 60 == 0:
                fps = 60 / (time.time() - t0)
                t0 = time.time()
                print(f"[cam-blur] {fps:.0f} fps fg={fg_ratio:.2f} mode={mode}", flush=True)
            time.sleep(max(0.0, interval - (time.time() - tick)))

        cap.release()
        del sess
        gc.collect()
        if n_frames:
            dt = time.time() - t0
            print(f"[cam-blur] {n} frames in {dt:.1f}s = {n / dt:.1f} fps fg={fg_ratio:.2f}", flush=True)
        return None

    if args.test_frames:
        err = run(args.test_frames)
        if err:
            sys.exit(f"[cam-blur] {err}")
        return
    while True:
        if not has_readers(args.out):
            time.sleep(2)
            continue
        print("[cam-blur] reader detected; starting", flush=True)
        err = run()
        if err:
            print(f"[cam-blur] {err}; retrying in 5s", flush=True)
            time.sleep(5)


if __name__ == "__main__":
    main()
