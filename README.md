# RTSP Video Streamer

This project provides a Docker-based setup for streaming videos via RTSP protocol. It supports both single and multiple video inputs, with the ability to loop single videos.

It is published as a multi-architecture image (`linux/amd64`, `linux/arm64`) on Docker Hub, so you can run it without building anything:

```bash
docker run --rm -p 8554:8554 -p 8888:8888 \
  -v "$PWD/videos:/data/videos:ro" \
  plainsightai/rtsp-streamer:latest
```

Each released tag carries a signed SPDX SBOM attestation (keyless cosign, recorded in the public Rekor transparency log), which you can verify with `cosign verify-attestation`.

## Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- Make (for build automation)
- FFmpeg (for testing the streams)

## Building

The project includes a Makefile for automating the build process:

```bash
# Show available commands
make help

# Build the image
make build

# Build without cache (useful for CI)
make build-no-cache

# Run the container
make run

# Run in detached mode
make run-detached

# Stop the containers
make stop

# Clean up
make clean

# Run tests
make test
```

## CI/CD

The project includes GitHub Actions workflows for continuous integration and deployment:

- **CI Workflow**:
  - On every push and pull request, builds the image for `linux/amd64` and `linux/arm64` without
    pushing, so a broken Dockerfile is caught before a release is cut
  - On a `v*.*.*` tag (or a manual dispatch), builds and pushes
    `plainsightai/rtsp-streamer:<VERSION>` and `:latest`, then attaches a signed SPDX SBOM
    attestation to the pushed manifest list

- **Release Workflow**: Manages version releases
  - Supports major, minor, and patch version updates
  - Bumps the `VERSION` file, tags, and creates the GitHub release
  - The tag it pushes is what triggers the publish job above

To create a new release:
1. Go to the Actions tab in GitHub
2. Select "Release" workflow
3. Click "Run workflow"
4. Choose the release type (major/minor/patch)

## Configuration

The setup can be configured through environment variables in the `.env` file:

```env
# RTSP Server Configuration
RTSP_PORT=8554
RTSP_TRANSPORT=tcp
WEB_INTERFACE_PORT=8888

# Video Configuration
VIDEO_SOURCE=/data/videos
VIDEO_LOOP=false
VIDEO_STREAM_NAME=mystream

# Resource Limits
FFMPEG_CPU_LIMIT=1000m
FFMPEG_MEMORY_LIMIT=1Gi
FFMPEG_CPU_REQUEST=500m
FFMPEG_MEMORY_REQUEST=512Mi
RTSP_CPU_LIMIT=500m
RTSP_MEMORY_LIMIT=512Mi
RTSP_CPU_REQUEST=200m
RTSP_MEMORY_REQUEST=256Mi
```

## Usage

1. Create a directory for your videos and place your video files there:
   ```bash
   mkdir -p videos
   cp your_video.mp4 videos/
   ```

2. Start the streaming containers:
   ```bash
   docker-compose up
   ```

3. The RTSP streams will be available at:
   - For single video: `rtsp://localhost:${RTSP_PORT}/${VIDEO_STREAM_NAME}`
   - For multiple videos: `rtsp://localhost:${RTSP_PORT}/stream0`, `rtsp://localhost:${RTSP_PORT}/stream1`, etc.

4. Access the web interface:
   - Open your browser and navigate to `http://localhost:${WEB_INTERFACE_PORT}`
   - The web interface provides monitoring and management of your RTSP streams

## Testing the Streams

You can test the streams using FFmpeg or any RTSP-capable video player:

```bash
ffplay rtsp://localhost:${RTSP_PORT}/${VIDEO_STREAM_NAME}
```

## Notes

- The videos should be mounted at the path specified in `VIDEO_SOURCE` (default: `/data/videos`)
- Supported video formats: MP4, AVI, MKV
- The RTSP server (MediaMTX) runs on the port specified in `RTSP_PORT`
- The web interface is available on the port specified in `WEB_INTERFACE_PORT`
- TCP transport is used for better reliability
- Multiple video streams run in parallel
- Single video streams can be looped by setting `VIDEO_LOOP=true` in the `.env` file
- Resource limits can be adjusted in the `.env` file

## Reference Configuration

The project includes a reference Docker Compose configuration (`docker-compose.reference.yml`) that shows the original two-service setup using separate containers for the RTSP server and FFmpeg streamer. This can be useful for understanding the architecture or if you need to run the services separately.

To use the reference configuration:
```bash
docker-compose -f docker-compose.reference.yml up
```

## How it works

```shell
[FFmpeg Container] ---> [MediaMTX Container] ---> [RTSP Clients]
(streams video)         (manages streams)         (viewers)
```

## Credits

The bundled clip in `sample-videos/` is "Seattle, Washinghton" by the Pexels contributor credited as
"K", used under the Pexels license, which permits free use without requiring attribution:
https://www.pexels.com/video/seattle-washinghton-2257258/

The RTSP server itself is [MediaMTX](https://github.com/bluenviron/mediamtx) (MIT), pulled in by the
Dockerfile; this project supplies the packaging, the streaming entrypoint and the configuration
around it.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
```