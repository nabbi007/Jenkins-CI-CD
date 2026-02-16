#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-jenkins-ci-cd-demo:verify-local}"
CONTAINER_NAME="${CONTAINER_NAME:-verify-local-check}"
HOST_PORT="${HOST_PORT:-3010}"

cd "${REPO_ROOT}"

if [[ ! -f Dockerfile ]]; then
  echo "Dockerfile not found in ${REPO_ROOT}"
  exit 1
fi

npm ci
npm test

docker build -t "${IMAGE_NAME}" .

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run -d --name "${CONTAINER_NAME}" -p "${HOST_PORT}:3000" "${IMAGE_NAME}" >/dev/null

cleanup() {
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  docker rmi "${IMAGE_NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

for attempt in 1 2 3 4 5; do
  if curl -fsS "http://127.0.0.1:${HOST_PORT}/health" > /dev/null; then
    echo "Local verification passed on attempt ${attempt}."
    exit 0
  fi
  sleep 1
done

echo "Local verification failed: /health not reachable."
exit 1
