# Use multi-stage build to combine both services
FROM bluenviron/mediamtx:latest AS rtsp-server

# Create final image
FROM alpine:latest

# Install required packages
RUN apk upgrade --no-cache && apk add --no-cache \
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

# Health check: probe the RTSP port, which is the service this image exists to
# provide. The HLS port (8888) answers 404 on `/` — MediaMTX only serves a path
# per stream — so `curl -f` against it marked every container unhealthy even
# while RTSP was serving correctly. Matches the check the compose files use.
HEALTHCHECK --interval=10s --timeout=5s --retries=3 --start-period=10s \
    CMD nc -z localhost 8554 || exit 1

# Start both services
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"] 