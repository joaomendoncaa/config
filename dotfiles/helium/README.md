# Helium runbook (2026-10-09)

## Camera: `grabFrame NotReadableError`, 0fps, app stuck in USB power-cycle loop

- Hardware is fine — verify with the tab closed: `timeout 15 ffmpeg -y -f v4l2
  -input_format mjpeg -video_size 1280x720 -i /dev/video0 -frames:v 3 /tmp/camtest-%d.jpg`
- Cause was stale GPU/media caches in the Helium profile after the 0.17 → 0.18
  (Chromium 154) update. Fresh profile worked, main profile didn't.
- Fix (quit Helium first; bookmarks/history/logins untouched):
  ```bash
  pkill -f helium; sleep 2
  rm -rf ~/.config/net.imput.helium/Default/GPUCache ~/.config/net.imput.helium/GPUPersistentCache ~/.config/net.imput.helium/ShaderCache ~/.config/net.imput.helium/GrShaderCache ~/.config/net.imput.helium/GraphiteDawnCache
  ```
- Ruled out along the way: Krom Kam firmware hang (ffmpeg grabs fine),
  wrong v4l2 format (MJPG 1280x720@30 negotiates correctly), dead BlurredCam
  loopback `/dev/video10` (uninvolved — remove its autoload only if blur is abandoned),
  `--disable-accelerated-video-decode` (removing it didn't help).

## Menus: blurred halo around all browser popups/menus

- Cause: `--ozone-platform=x11` put Helium on XWayland; Hyprland blurs every
  menu window's transparent padding. Native Wayland menus are subsurfaces, no blur.
- Fix: line removed from `helium-browser-flags.conf` (kept commented with rollback note).
- Rollback if NVIDIA Xid-32 hangs return: uncomment `--ozone-platform=x11`
  and instead add a Hyprland `noblur` rule for the menu windows.
