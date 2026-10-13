# Use multi-stage build to combine both services
FROM bluenviron/mediamtx:latest AS rtsp-server

# Create final image
FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    netcat-openbsd \
    bash \
    ffmpeg \
    curl

# Copy binaries and configurations from both services
COPY --from=rtsp-server /mediamtx /usr/local/bin/

# Create necessary directories
RUN mkdir -p /data/videos /usr/local/share/sample-videos /etc/mediamtx

# Copy our streaming script
COPY stream.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/stream.sh

# Copy sample video
COPY sample-videos/sample-video.mp4 /usr/local/share/sample-videos/

# Copy MediaMTX configuration
COPY mediamtx.yml /etc/mediamtx/mediamtx.yml

# Set environment variables
ENV MTX_RTSPTRANSPORTS=tcp
ENV VIDEO_LOOP=false
ENV VIDEO_STREAM_NAME=stream0

# Expose ports
EXPOSE 8554 8888

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=3 --start-period=10s \
    CMD curl -f http://localhost:8888/ || exit 1

# Start both services
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"] 