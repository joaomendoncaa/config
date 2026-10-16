# OBS reliable background blur

No custom C++ plugin. That would duplicate upstream `obs-backgroundremoval`
(4.6k stars, ONNX) and look worse per watt.

What this owns instead:

- `scripts/reliable-blur.lua` — OBS script (Tools → Scripts) that forces one
  tuned `background_removal` filter onto the webcam and recreates it if it
  goes missing. That is the "never fail" part.
- Tuned for quality-per-watt on CPU (Arch ships `onnxruntime-cpu` only, so
  the GTX 1060 can't help here without a from-source CUDA build):
  SINet model (sharp static edges, no recurrent state to go stale),
  2 threads (upstream: 2 beats 8), mask every 3rd frame, blur 10,
  image-similarity freeze off, pause when source inactive.

## Enable

1. `mkdir -p ~/.config/obs-studio/scripts && ln -sf <repo>/dotfiles/obs/scripts/reliable-blur.lua ~/.config/obs-studio/scripts/`
   (or re-run `./setup`)
2. OBS → Tools → Scripts → + → pick `reliable-blur.lua`
3. Set webcam source name if yours differs (default `Video Capture Device (V4L2)`)
4. Press "Apply tuned blur now"

## Why your old settings looked bad

- RVM model + mask every 20 frames breaks its temporal state → smeary edges.
- 8 threads contends on CPU; upstream recommends 2.
- `blur_background = 5` is weak; 10 reads as real blur.
- Image-similarity freeze holds a stale mask while you move.
- Filter was saved as `enabled: false`, so sometimes "it doesn't work".

Skipped: from-scratch plugin, CUDA ONNX build. Add when CPU blur measurably falls short.
