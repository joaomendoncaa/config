#!/usr/bin/env bash
set -o pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
IMAGE_DIR="$STATE_DIR/clipboard-images"
mkdir -p "$IMAGE_DIR"

types=$(wl-paste --list-types 2>/dev/null || true)
[ -z "$types" ] && exit 0

MAX_SIZE=$((50 * 1024 * 1024))

save_blob() {
  local mime="$1" ext="$2" type="$3" srcpath="${4:-}"
  local tmp hash file
  if [ -n "$srcpath" ]; then
    hash=$(sha256sum "$srcpath" | awk '{print $1}')
    file="$IMAGE_DIR/$hash.$ext"
    if [ ! -e "$file" ]; then
      cp "$srcpath" "$file"
    fi
  else
    tmp=$(mktemp --tmpdir="$IMAGE_DIR" clipboard.XXXXXX) || return 1
    wl-paste --type "$mime" > "$tmp" 2>/dev/null
    if [ ! -s "$tmp" ]; then rm -f "$tmp"; return 1; fi
    hash=$(sha256sum "$tmp" | awk '{print $1}')
    file="$IMAGE_DIR/$hash.$ext"
    if [ -e "$file" ]; then rm -f "$tmp"
    else mv "$tmp" "$file"; fi
  fi
  if [ "$type" = "video" ]; then
    local thumb="$IMAGE_DIR/${hash}_thumb.jpg"
    if [ ! -e "$thumb" ]; then
      ffmpeg -y -i "$file" -vframes 1 -f image2 "$thumb" 2>/dev/null &
      wait $!
    fi
    if [ -s "$thumb" ]; then
      jq -cn --arg type "$type" --arg mime "$mime" --arg path "$file" \
        --arg thumb "$thumb" --arg at "$(date +'%A %H:%M')" \
        '{type:$type, mime:$mime, path:$path, thumbnail:$thumb, capturedAt:$at}'
    else
      rm -f "$thumb"
      jq -cn --arg type "$type" --arg mime "$mime" --arg path "$file" \
        --arg at "$(date +'%A %H:%M')" \
        '{type:$type, mime:$mime, path:$path, capturedAt:$at}'
    fi
  else
    jq -cn --arg type "$type" --arg mime "$mime" --arg path "$file" \
      --arg at "$(date +'%A %H:%M')" \
      '{type:$type, mime:$mime, path:$path, capturedAt:$at}'
  fi
  return 0
}

handle_uri_list() {
  local uris
  uris=$(wl-paste --type text/uri-list --no-newline 2>/dev/null || true)
  [ -z "$uris" ] && return 1
  local uri
  while IFS= read -r uri; do
    uri="${uri%%[$'\r\n']*}"
    [ -z "$uri" ] && continue
    local path
    path=$(echo "$uri" | sed 's|^file://||; s|%20| |g; s|%23|#|g; s|http.*||')
    [ -z "$path" ] && continue
    [ ! -f "$path" ] && continue
    local size
    size=$(stat -c%s "$path" 2>/dev/null || echo 0)
    [ "$size" -gt "$MAX_SIZE" ] && continue
    local mime
    mime=$(file --mime-type -b "$path" 2>/dev/null || echo "")
    case "$mime" in
      image/png)  save_blob "" "png" "image" "$path" && return 0 ;;
      image/jpeg) save_blob "" "jpg" "image" "$path" && return 0 ;;
      image/webp) save_blob "" "webp" "image" "$path" && return 0 ;;
      image/gif)  save_blob "" "gif" "image" "$path" && return 0 ;;
      image/bmp)  save_blob "" "bmp" "image" "$path" && return 0 ;;
      image/tiff) save_blob "" "tiff" "image" "$path" && return 0 ;;
      video/mp4|video/webm|video/x-matroska|video/ogg|video/quicktime|video/x-msvideo|video/mpeg)
                  local vext="${mime#video/}"
                  case "$vext" in
                    x-matroska) vext="mkv" ;;
                    quicktime)  vext="mov" ;;
                    x-msvideo)  vext="avi" ;;
                  esac
                  save_blob "" "$vext" "video" "$path" && return 0 ;;
    esac
  done <<< "$uris"
  return 1
}

for pair in "image/png:png" "image/jpeg:jpg" "image/webp:webp" "image/gif:gif" "image/bmp:bmp" "image/tiff:tiff"; do
  mime="${pair%%:*}"
  ext="${pair##*:}"
  if echo "$types" | grep -qx "$mime"; then
    save_blob "$mime" "$ext" "image" && exit 0
  fi
done

for pair in "video/mp4:mp4" "video/webm:webm" "video/x-matroska:mkv" "video/ogg:ogv" "video/quicktime:mov" "video/x-msvideo:avi" "video/mpeg:mpeg"; do
  mime="${pair%%:*}"
  ext="${pair##*:}"
  if echo "$types" | grep -qx "$mime"; then
    save_blob "$mime" "$ext" "video" && exit 0
  fi
done

if echo "$types" | grep -qx 'text/uri-list'; then
  handle_uri_list && exit 0
fi

if echo "$types" | grep -q '^text/' || echo "$types" | grep -qx 'UTF8_STRING\|STRING'; then
  wl-paste --type text --no-newline 2>/dev/null | jq -cRs 'select(length > 0) | {type:"text", text:.}'
  exit 0
fi
