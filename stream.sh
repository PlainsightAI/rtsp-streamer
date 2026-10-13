#!/bin/bash

# Function to stream a video
stream_video() {
    local video=$1
    local loop=$2
    local stream_name=$3
    
    # Always use loop mode for continuous streaming
    ffmpeg -re -stream_loop -1 -i "$video" -c copy -f rtsp -rtsp_transport tcp "rtsp://localhost:8554/$stream_name"
}

# Check if videos directory is mounted and contains videos
if [ -d "/data/videos" ] && [ "$(ls -A /data/videos/*.mp4 2>/dev/null || ls -A /data/videos/*.avi 2>/dev/null || ls -A /data/videos/*.mkv 2>/dev/null)" ]; then
    # Use videos from mounted volume
    echo "Using videos from mounted directory..."
    VIDEOS=($(ls /data/videos/*.mp4 2>/dev/null || ls /data/videos/*.avi 2>/dev/null || ls /data/videos/*.mkv 2>/dev/null))
else
    # Use baked-in sample video
    echo "Using baked-in sample video..."
    VIDEOS=("/usr/local/share/sample-videos/sample-video.mp4")
fi

if [ ${#VIDEOS[@]} -eq 1 ]; then
    # Single video case
    stream_video "${VIDEOS[0]}" "$VIDEO_LOOP" "${VIDEO_STREAM_NAME:-stream0}"
else
    # Multiple videos case
    for i in "${!VIDEOS[@]}"; do
        stream_video "${VIDEOS[$i]}" "false" "stream$i" &
    done
    wait
fi 