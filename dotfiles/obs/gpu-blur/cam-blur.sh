#!/usr/bin/env bash
# Launcher: exposes the pip CUDA 11 libs and hides the system CUDA 13
# (no Pascal kernels) before starting the daemon.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="$HOME/.local/share/cam-blur/venv311"

export LD_LIBRARY_PATH="$(ls -d "$VENV"/lib/python*/site-packages/nvidia/*/lib 2>/dev/null | tr '\n' ':')${LD_LIBRARY_PATH:-}"
unset CUDA_PATH

exec "$VENV/bin/python" "$DIR/cam-blur.py" "$@"
