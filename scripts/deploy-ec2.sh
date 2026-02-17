#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-/tmp/jenkins-ec2.env}"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck source=/tmp/jenkins-ec2.env
  source "${ENV_FILE}"
  set +a
fi

: "${EC2_HOST:?EC2_HOST is required}"
: "${EC2_USER:?EC2_USER is required}"
if [[ -z "${IMAGE_NAME:-}" && -n "${REGISTRY_REPO:-}" ]]; then
  IMAGE_NAME="${REGISTRY_REPO}:latest"
fi
: "${IMAGE_NAME:?IMAGE_NAME is required (set IMAGE_NAME or REGISTRY_REPO)}"

if [[ -z "${ECR_REGISTRY:-}" && "${IMAGE_NAME}" == *.amazonaws.com/* ]]; then
  ECR_REGISTRY="${IMAGE_NAME%%/*}"
fi

if [[ -z "${AWS_REGION:-}" && -n "${ECR_REGISTRY:-}" ]]; then
  AWS_REGION="$(awk -F'.' '{print $4}' <<< "${ECR_REGISTRY}")"
fi

if [[ -n "${ECR_REGISTRY:-}" && -z "${AWS_REGION:-}" ]]; then
  echo "Unable to derive AWS_REGION for ECR login. Set AWS_REGION explicitly."
  exit 1
fi

APP_CONTAINER="${APP_CONTAINER:-jenkins-ci-cd-app}"
HOST_PORT="${HOST_PORT:-80}"
CONTAINER_PORT="3000"
HEALTH_PATH="${HEALTH_PATH:-/health}"

SSH_CMD=(ssh -T -o StrictHostKeyChecking=no)
if [[ -n "${SSH_KEY_PATH:-}" ]]; then
  : "${SSH_KEY_PATH:?SSH_KEY_PATH is set but empty}"
  [[ -f "${SSH_KEY_PATH}" ]] || {
    echo "SSH key file not found: ${SSH_KEY_PATH}"
    exit 1
  }
  chmod 400 "${SSH_KEY_PATH}" >/dev/null 2>&1 || true
  SSH_CMD+=(-i "${SSH_KEY_PATH}")
fi

"${SSH_CMD[@]}" "${EC2_USER}@${EC2_HOST}" <<REMOTE
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed on target host"
  exit 1
fi

if [[ "${ECR_REGISTRY:-}" == *.amazonaws.com ]]; then
  if ! command -v aws >/dev/null 2>&1; then
    echo "AWS CLI is not installed on target host"
    exit 1
  fi

  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS credentials are unavailable on EC2."
    echo "Attach an IAM role with ECR read permissions (e.g., AmazonEC2ContainerRegistryReadOnly)."
    exit 1
  fi

  aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
fi

if ! docker pull ${IMAGE_NAME}; then
  echo "Failed to pull image: ${IMAGE_NAME}"
  echo "Verify image exists and is accessible in ECR."
  exit 1
fi

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
