#!/bin/bash

# Start MediaMTX in the background
mediamtx &

# Wait for MediaMTX to be ready
until nc -z localhost 8554; do
    echo "Waiting for RTSP server to be ready..."
    sleep 2
done

echo "RTSP server is ready, starting ffmpeg stream"

# Start the streaming script
exec /usr/local/bin/stream.sh 