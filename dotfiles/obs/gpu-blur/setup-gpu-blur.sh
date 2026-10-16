#!/usr/bin/env bash
# One-time setup for the GPU background-blur virtual camera.
# Run steps 1-2 yourself (need sudo); the rest is automatic.
set -euo pipefail

VENV="$HOME/.local/share/cam-blur/venv311"
MODEL_DIR="$HOME/.local/share/cam-blur/models"
MODEL_URL="https://github.com/PeterL1n/RobustVideoMatting/releases/download/v1.0.0/rvm_resnet50_fp32.onnx"

echo "1. Install kernel module + tools (needs sudo):"
echo "   sudo pacman -S --needed v4l2loopback-dkms v4l2loopback-utils"
echo "   echo 'v4l2loopback' | sudo tee /etc/modules-load.d/v4l2loopback.conf"
echo "   echo 'options v4l2loopback devices=1 video_nr=10 card_label=BlurredCam exclusive_caps=1' | sudo tee /etc/modprobe.d/v4l2loopback.conf"
echo "   sudo modprobe v4l2loopback devices=1 video_nr=10 card_label=BlurredCam exclusive_caps=1"

mise install python@3.11
"$HOME/.local/share/mise/installs/python/3.11.17/bin/python" -m venv "$VENV"
"$VENV/bin/pip" install -r "$(dirname "$0")/requirements.txt"

mkdir -p "$MODEL_DIR"
[[ -f "$MODEL_DIR/rvm_resnet50_fp32.onnx" ]] || curl -sSL -o "$MODEL_DIR/rvm_resnet50_fp32.onnx" "$MODEL_URL"

echo "2. OBS: remove the 'Background Removal' filter from your webcam,"
echo "   add source V4L2 '/dev/video10 (BlurredCam)', no filter needed."
echo "3. Enable autostart: systemctl --user enable --now cam-blur.service"
