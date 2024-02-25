#!/bin/bash

current_sink_name=$(pactl info | grep "Default Sink" | awk '{print $3}')

find_sink_id() {
    name="$1"
    pactl list sinks short | grep -i "$name" | awk '{print $1}'
}

current_id=$(find_sink_id $current_sink_name)
headphones_id=$(find_sink_id "razer")
speakers_id=$(find_sink_id "logi")

if [ $current_id == $headphones_id ]; then
    echo "headphones"
else
    echo "speakers"
fi
