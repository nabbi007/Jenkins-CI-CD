#!/usr/bin/env bash
set -euo pipefail

: "${EC2_HOST:?EC2_HOST is required}"
: "${EC2_USER:?EC2_USER is required}"
: "${IMAGE_NAME:?IMAGE_NAME is required}"

APP_CONTAINER="${APP_CONTAINER:-jenkins-ci-cd-app}"
HOST_PORT="${HOST_PORT:-80}"
CONTAINER_PORT="3000"
HEALTH_PATH="${HEALTH_PATH:-/health}"

SSH_CMD=(ssh -o StrictHostKeyChecking=no)
if [[ -n "${SSH_KEY_PATH:-}" ]]; then
  : "${SSH_KEY_PATH:?SSH_KEY_PATH is set but empty}"
  [[ -f "${SSH_KEY_PATH}" ]] || { echo "SSH key file not found: ${SSH_KEY_PATH}"; exit 1; }
  chmod 400 "${SSH_KEY_PATH}" >/dev/null 2>&1 || true
  SSH_CMD+=(-i "${SSH_KEY_PATH}")
fi

"${SSH_CMD[@]}" "${EC2_USER}@${EC2_HOST}" <<REMOTE
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

# Remove residual stopped containers and old images after deployment.
docker container prune -f >/dev/null 2>&1 || true
docker image prune -af >/dev/null 2>&1 || true

# Verify new deployment is healthy before returning success.
for attempt in \
  1 2 3 4 5 6 7 8 9 10
  do
    if curl -fsS "http://localhost:${HOST_PORT}${HEALTH_PATH}" >/dev/null; then
      echo "Deployment verified at ${HEALTH_PATH}"
      exit 0
    fi
    sleep 2
  done

echo "Health check failed after deployment"
docker logs --tail 50 ${APP_CONTAINER} || true
exit 1
REMOTE
