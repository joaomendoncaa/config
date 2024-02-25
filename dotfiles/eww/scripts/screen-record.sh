#!/bin/bash

# Use slurp to select an area and grim to get the geometry
GEOMETRY=$(slurp)
if [ -z "$GEOMETRY" ]; then
  echo "No area selected."
  exit 1
fi

# Use ffmpeg to record the selected area
ffmpeg -f pipewire -i "default" -vf "crop=${GEOMETRY}" -y ~/Videos/record_$(date +%Y%m%d_%H%M%S).mp4

