# Media Center

On-demand Jellyfin stack. Nothing autostarts.

```bash
media-center start     # everything
media-center stop      # everything, one shot
media-center open      # start if needed, open Seerr as an app window
media-center status
media-center logs
```

Desktop entry: "Media Center" (click = start + open Seerr, right-click = Stop / Jellyfin / qBittorrent).

## Layout

```
MEDIA_DIR (default ~/Media)
├── movies/       Radarr imports here
├── shows/        Sonarr imports here
└── downloads/    qBittorrent + in-progress
```

`MEDIA_DIR` lives in `.env` (gitignored). Change it, then `media-center stop && media-center start`.

## Ports

| App | URL |
|---|---|
| Seerr (front door) | http://IP:5055 |
| Jellyfin | http://IP:8096 |
| Prowlarr | http://IP:9696 |
| qBittorrent | http://IP:8080 |
| Radarr / Sonarr | 7878 / 8989 (setup only) |

## Status

Preconfigured: Jellyfin libraries (`/media/movies`, `/media/shows`), Seerr + its Radarr/Sonarr
connections (1080p profile), Prowlarr → Radarr/Sonarr sync, Byparr behind the `cf` tag.

Only manual step: **Prowlarr → Indexers → add your sites.** Any indexer behind Cloudflare
needs the **`cf`** tag on the indexer. No indexers = no search results.

## Disk / IO

qBittorrent is capped at **15 MB/s writes** on the root device and given a low IO weight, so a
download can't freeze the desktop. Tune it in `docker-compose.yml` under `blkio_config`.

One-time, needs sudo: `media-center tune` — lowers the kernel dirty-page limits
(`vm.dirty_bytes=1G`, `vm.dirty_background_bytes=256M`). The defaults (20%/10% of 31 GB) let
gigabytes of writes pile up before flushing, which is what made the whole system stall.

Media folders are marked `chattr +C` (no btrfs CoW/compression on video).

## Flow

Seerr search → Request → Radarr/Sonarr grab from Prowlarr → qBittorrent → import → "Watch on Jellyfin" → delete from Jellyfin (media deletion enabled per user/library).

qBittorrent is the only writer to `downloads/`; Jellyfin mounts `/media` read-only. A fixed qBittorrent password is set at setup — if you change it, update it in Radarr and Sonarr too.

Skipped: Bazarr (subtitles), Tdarr (transcoding), VPN container. Add when needed.
