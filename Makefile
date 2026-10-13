# Variables
IMAGE ?= plainsightai/rtsp-streamer
VERSION ?= $(shell cat VERSION)
DOCKER_BUILDKIT ?= 1

COMPOSE_FILE=docker-compose.yml
CONTAINER_EXEC := docker

export IMAGE
export VERSION

# Default target
.PHONY: all
all: build

# Build the Docker image
.PHONY: build
build:
	docker compose -f $(COMPOSE_FILE) build

.PHONY: build-image
build-image:  ## Build docker image
	${CONTAINER_EXEC} build \
		-t ${IMAGE}:${VERSION} \
		.

# Build with no cache (useful for CI)
.PHONY: build-no-cache
build-no-cache:
	docker compose -f $(COMPOSE_FILE) build --no-cache

# Publish the docker image
.PHONY: publish-image
publish-image:  ## Publish docker image
	${CONTAINER_EXEC} push ${IMAGE}:${VERSION}

# Print the fully-qualified image ref(s) pushed on release, one per line
.PHONY: print-image-refs
print-image-refs:  ## Print image ref(s) pushed on release (for SBOM attestation)
	@echo "${IMAGE}:${VERSION}"

# Run the container locally
.PHONY: run
run:
	docker compose -f $(COMPOSE_FILE) up

# Run the container locally
.PHONY: run-prod
run-prod:
	docker compose -f docker-compose.prod.yml up

# Run in detached mode
.PHONY: run-detached
run-detached:
	docker compose -f $(COMPOSE_FILE) up -d

# Stop the containers
.PHONY: stop
stop:
	docker compose -f $(COMPOSE_FILE) down

# Clean up containers and volumes
.PHONY: clean
clean:
	docker compose -f $(COMPOSE_FILE) down -v
	docker system prune -f

# Remove the built image
.PHONY: remove-image
remove-image:
	docker rmi $(IMAGE):$(VERSION)

# Test the build (builds and runs comprehensive tests)
.PHONY: test
test:
	@echo "Starting RTSP Streamer tests..."
	
	@# Start the container
	docker compose -f $(COMPOSE_FILE) up -d
	
	@# Wait for container to be healthy
	@echo "Waiting for container to be healthy..."
	@for i in $$(seq 1 30); do \
		if docker compose -f $(COMPOSE_FILE) ps | grep -q "healthy"; then \
			break; \
		fi; \
		sleep 1; \
	done
	@# Test RTSP port
	@echo "Testing RTSP port (8554)..."
	nc -z localhost 8554 || (echo "RTSP port test failed" && exit 1)
	
	@# Test video source mounting
	@echo "Testing video source mounting..."
	docker compose -f $(COMPOSE_FILE) exec rtsp-streamer ls /data/videos || (echo "Video source mounting test failed" && exit 1)
	
	@# Test container health status
	@echo "Testing container health status..."
	docker compose -f $(COMPOSE_FILE) ps | grep -q "healthy" || (echo "Container health status test failed" && exit 1)
	@echo "All tests passed successfully!"
	
	@# Clean up
	docker compose -f $(COMPOSE_FILE) down

# Show help
.PHONY: help
help:
	@echo "RTSP Streamer Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  build           - Build the Docker image"
	@echo "  build-no-cache  - Build the Docker image without cache (CI)"
	@echo "  run             - Run the containers in foreground"
	@echo "  run-detached    - Run the containers in background"
	@echo "  stop            - Stop the containers"
	@echo "  clean           - Clean up containers, volumes, and unused images"
	@echo "  remove-image    - Remove the built image"
	@echo "  test            - Build and run comprehensive tests"
	@echo "  help            - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE         - Name of the Docker image (default: plainsightai/rtsp-streamer)"
	@echo "  VERSION       - Tag for the Docker image (default: read from the VERSION file)"