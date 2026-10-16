#!/usr/bin/env python3
"""Model bake-off: same raw frames, same composite, per-model matte + speed.

Usage: shootout.py --frames DIR (dumps comp_<model>_<i>.jpg + stats)
       shootout.py --capture N --frames DIR (grab N raw frames first)
"""
import argparse
import glob
import os
import sys
import time

import cv2
import numpy as np

# Pascal-era CUDA libs must be preloaded by absolute path (dlopen ignores
# in-process LD_LIBRARY_PATH) and system CUDA_PATH (v13, no Pascal kernels).
import ctypes
import glob as _glob

_NV = os.path.expanduser("~/.local/share/cam-blur/venv311/lib/python3.11/site-packages/nvidia")
for _soname in ("libcublasLt.so.11", "libcudnn.so.8", "libcufft.so.10", "libcurand.so.10"):
    for _p in _glob.glob(f"{_NV}/*/lib/{_soname}"):
        try:
            ctypes.CDLL(_p, mode=ctypes.RTLD_GLOBAL)
        except OSError:
            pass
os.environ.pop("CUDA_PATH", None)

IM_MEAN = np.array([0.485, 0.456, 0.406], np.float32)[None, :, None, None]
IM_STD = np.array([0.229, 0.224, 0.225], np.float32)[None, :, None, None]
BUNDLED = "/usr/share/obs/obs-plugins/obs-backgroundremoval/models"
LOCAL = os.path.expanduser("~/.local/share/cam-blur/models")


def sess(path, cuda=True):
    import onnxruntime as ort

    prov = ["CUDAExecutionProvider", "CPUExecutionProvider"] if cuda else ["CPUExecutionProvider"]
    return ort.InferenceSession(path, providers=prov)


def rgb_norm(bgr, size):
    small = cv2.resize(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB), (size, size), interpolation=cv2.INTER_AREA)
    x = small.transpose(2, 0, 1)[None].astype(np.float32) / 255.0
    return (x - IM_MEAN) / IM_STD


def rgb_plain(bgr, size, nchw=True):
    small = cv2.resize(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB), (size, size), interpolation=cv2.INTER_AREA)
    x = small.transpose(2, 0, 1)[None].astype(np.float32) / 255.0 if nchw else small[None].astype(np.float32) / 255.0
    return x


def softmax(x, axis):
    e = np.exp(x - x.max(axis=axis, keepdims=True))
    return e / e.sum(axis=axis, keepdims=True)


def sigmoid(x):
    return 1 / (1 + np.exp(-x))


def run_modnet(s, f, size):
    return s.run(None, {"input": rgb_norm(f, size)})[0][0, 0]


def run_rvm(s, f):
    small = cv2.resize(f, (640, 360))
    src = cv2.cvtColor(small, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
    src = np.transpose(src, (2, 0, 1))[None]
    shapes = {}
    for i in s.get_inputs():
        shapes[i.name] = [d if isinstance(d, int) else 1 for d in i.shape]
    feeds = {"src": src, "downsample_ratio": np.array([0.25], np.float32)}
    for n in ("r1i", "r2i", "r3i", "r4i"):
        feeds[n] = np.zeros(shapes[n], np.float32)
    outs = None
    for _ in range(5):  # settle recurrent state on stills
        outs = s.run(None, feeds)
        feeds.update({n: np.asarray(o, np.float32) for n, o in zip(("r1i", "r2i", "r3i", "r4i"), outs[2:])})
    return outs[1][0, 0]


def run_selfie_seg(s, f):
    o = s.run(None, {"input_1:0": rgb_plain(f, 256, False)})[0][0, :, :, 0]
    return sigmoid(o) if o.max() > 1 or o.min() < 0 else np.clip(o, 0, 1)


def run_selfie_multi(s, f):
    o = s.run(None, {"input_29": rgb_plain(f, 256, False)})[0][0]
    return 1 - softmax(o, axis=-1)[:, :, 0]


def run_pphumanseg(s, f):
    o = s.run(None, {"x": rgb_norm(f, 192)})[0][0]
    o = np.transpose(o, (2, 0, 1)) if o.shape[2] == 2 else o
    return softmax(o, axis=0)[1]


def run_u2net(s, f):
    o = s.run(None, {"input.1": rgb_norm(f, 320)})[0][:, 0, :, :]
    ma, mi = o.max(), o.min()
    return np.squeeze((o - mi) / max(ma - mi, 1e-6))


CONTESTANTS = [
    ("modnet384", f"{LOCAL}/modnet.onnx", lambda s, f: run_modnet(s, f, 384)),
    ("modnet512", f"{LOCAL}/modnet.onnx", lambda s, f: run_modnet(s, f, 512)),
    ("rvm", f"{LOCAL}/rvm_resnet50_fp32.onnx", run_rvm),
    ("selfie_seg", f"{BUNDLED}/selfie_segmentation.with_runtime_opt.ort", run_selfie_seg),
    ("selfie_multi", f"{BUNDLED}/selfie_multiclass_256x256.with_runtime_opt.ort", run_selfie_multi),
    ("pphumanseg", f"{BUNDLED}/pphumanseg_fp32.with_runtime_opt.ort", run_pphumanseg),
    ("u2net_hs", f"{LOCAL}/u2net_human_seg.onnx", run_u2net),
]


def composite(frame, alpha):
    H, W, _ = frame.shape
    af = cv2.resize(alpha, (W, H))[..., None]
    tiny = cv2.resize(frame, (W // 4, H // 4))
    bg = cv2.resize(cv2.GaussianBlur(tiny, (21, 21), 0), (W, H))
    return (frame.astype(np.float32) * af + bg.astype(np.float32) * (1 - af)).astype(np.uint8)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--frames", required=True)
    ap.add_argument("--capture", type=int, default=0)
    ap.add_argument("--cam-name", default="Krom Kam")
    ap.add_argument("--only", default="", help="comma list to run subset")
    args = ap.parse_args()
    os.makedirs(args.frames, exist_ok=True)

    if args.capture:
        import fcntl
        import struct

        dev = "/dev/video0"
        for d in sorted(glob.glob("/dev/video*")):
            try:
                with open(d, "rb") as f:
                    buf = fcntl.ioctl(f.fileno(), 0x80685600, bytes(104))
                card = struct.unpack("16s32s32s6I", buf)[1].split(b"\0")[0].decode()
                if args.cam_name.lower() in card.lower() and "loopback" not in card.lower() and "BlurredCam" not in card:
                    dev = d
                    break
            except OSError:
                continue
        cap = cv2.VideoCapture(dev, cv2.CAP_V4L2)
        cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*"MJPG"))
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        for i in range(args.capture):
            for _ in range(60):
                cap.read()
            ok, fr = cap.read()
            if ok:
                cv2.imwrite(f"{args.frames}/raw_{i}.jpg", fr)
                print(f"captured raw_{i}.jpg", flush=True)
        cap.release()

    paths = sorted(glob.glob(f"{args.frames}/raw_*.jpg"))
    frames = [cv2.imread(p) for p in paths]
    only = set(args.only.split(",")) if args.only else None
    for name, path, fn in CONTESTANTS:
        if only and name not in only:
            continue
        if not os.path.exists(path):
            print(f"{name}: missing {path}")
            continue
        s = sess(path)
        ep = s.get_providers()[0]
        ts, ms = [], []
        for i, fr in enumerate(frames):
            t = time.time()
            for _ in range(3):
                a = fn(s, fr)
            ms.append((time.time() - t) / 3 * 1000)
            a = np.clip(a, 0, 1).astype(np.float32)
            cv2.imwrite(f"{args.frames}/comp_{name}_{i}.jpg", composite(fr, a))
            ts.append(float((a > 0.5).mean()))
        print(f"{name} [{ep}]: fg={np.mean(ts):.3f} infer={np.mean(ms):.0f}ms", flush=True)


if __name__ == "__main__":
    main()
