#!/usr/bin/env bash
set -euo pipefail

: "${EC2_HOST:?EC2_HOST is required}"
: "${EC2_USER:?EC2_USER is required}"
: "${IMAGE_NAME:?IMAGE_NAME is required}"

APP_CONTAINER="${APP_CONTAINER:-jenkins-ci-cd-app}"
HOST_PORT="${HOST_PORT:-80}"
CONTAINER_PORT="3000"

ssh -o StrictHostKeyChecking=no "${EC2_USER}@${EC2_HOST}" <<REMOTE
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed on target host"
  exit 1
fi

docker pull ${IMAGE_NAME}

docker rm -f ${APP_CONTAINER} >/dev/null 2>&1 || true

docker run -d \
  --name ${APP_CONTAINER} \
  --restart unless-stopped \
  -p ${HOST_PORT}:${CONTAINER_PORT} \
  ${IMAGE_NAME}

# Cleanup old dangling images to control disk growth.
docker image prune -af >/dev/null 2>&1 || true
REMOTE
