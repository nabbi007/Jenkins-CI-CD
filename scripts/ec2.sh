#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TF_DIR="${TF_DIR:-${REPO_ROOT}/infra/terraform}"
ENV_OUT_PATH="${ENV_OUT_PATH:-/tmp/jenkins-ec2.env}"
ACTION="${1:-apply}"

log() {
  printf '[ec2-tf] %s\n' "$*"
}

fatal() {
  printf '[ec2-tf] ERROR: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fatal "Missing required command: $1"
}

tf_out() {
  terraform -chdir="${TF_DIR}" output -raw "$1"
}

build_tf_var_args() {
  TF_VAR_ARGS=()

  add_var() {
    local tf_name="$1"
    local env_name="$2"
    local val="${!env_name:-}"
    if [[ -n "${val}" ]]; then
      TF_VAR_ARGS+=("-var" "${tf_name}=${val}")
    fi
  }

  add_var "region" "REGION"
  add_var "instance_name" "INSTANCE_NAME"
  add_var "instance_type" "INSTANCE_TYPE"
  add_var "key_name" "KEY_NAME"
  add_var "ssh_cidr" "SSH_CIDR"
  add_var "http_cidr" "HTTP_CIDR"
  add_var "ecr_repository" "ECR_REPOSITORY"
  add_var "host_port" "HOST_PORT"
  add_var "health_path" "HEALTH_PATH"
}

write_env_file() {
  local ec2_instance_id ec2_host ec2_public_ip ec2_user
  local aws_region aws_account_id ecr_registry ecr_repository
  local registry_repo host_port health_path ssh_key_path

  ec2_instance_id="$(tf_out ec2_instance_id)"
  ec2_host="$(tf_out ec2_host)"
  ec2_public_ip="$(tf_out ec2_public_ip)"
  ec2_user="$(tf_out ec2_user)"
  aws_region="$(tf_out aws_region)"
  aws_account_id="$(tf_out aws_account_id)"
  ecr_registry="$(tf_out ecr_registry)"
  ecr_repository="$(tf_out ecr_repository)"
  registry_repo="$(tf_out registry_repo)"
  host_port="$(tf_out host_port)"
  health_path="$(tf_out health_path)"
  ssh_key_path="$(tf_out ssh_key_path)"

  cat > "${ENV_OUT_PATH}" <<EOT
EC2_INSTANCE_ID=${ec2_instance_id}
EC2_HOST=${ec2_host}
EC2_PUBLIC_IP=${ec2_public_ip}
EC2_USER=${ec2_user}
AWS_REGION=${aws_region}
AWS_ACCOUNT_ID=${aws_account_id}
ECR_REGISTRY=${ecr_registry}
ECR_REPOSITORY=${ecr_repository}
REGISTRY_REPO=${registry_repo}
HOST_PORT=${host_port}
HEALTH_PATH=${health_path}
SSH_KEY_PATH=${ssh_key_path}
EOT

  chmod 600 "${ENV_OUT_PATH}" >/dev/null 2>&1 || true

  cat <<EOT

Provisioned/Reused successfully via Terraform:
  Instance ID: ${ec2_instance_id}
  Public DNS : ${ec2_host}
  Public IP  : ${ec2_public_ip}
  Region     : ${aws_region}
  ECR Repo   : ${registry_repo}

Saved deploy env file:
  ${ENV_OUT_PATH}

Next commands:
  source ${ENV_OUT_PATH}
  aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"
  docker build -t "$REGISTRY_REPO:latest" .
  docker push "$REGISTRY_REPO:latest"
  ./scripts/deploy-ec2.sh
EOT
}

main() {
  require_cmd terraform
  require_cmd aws

  [[ -d "${TF_DIR}" ]] || fatal "Terraform directory not found: ${TF_DIR}"

  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    fatal "AWS credentials not found. Run 'aws login' or 'aws configure' and retry."
  fi

  build_tf_var_args

  export TF_IN_AUTOMATION=1

  log "Initializing Terraform in ${TF_DIR}"
  terraform -chdir="${TF_DIR}" init -input=false >/dev/null

  case "${ACTION}" in
    apply)
      log "Applying Terraform (stateful: existing resources are reused)"
      terraform -chdir="${TF_DIR}" apply -auto-approve -input=false "${TF_VAR_ARGS[@]}"
      write_env_file
      ;;
    plan)
      log "Planning Terraform changes"
      terraform -chdir="${TF_DIR}" plan -input=false "${TF_VAR_ARGS[@]}"
      ;;
    destroy)
      log "Destroying Terraform-managed infrastructure"
      terraform -chdir="${TF_DIR}" destroy -auto-approve -input=false "${TF_VAR_ARGS[@]}"
      rm -f "${ENV_OUT_PATH}"
      log "Destroyed. Removed ${ENV_OUT_PATH}"
      ;;
    *)
      fatal "Unsupported action '${ACTION}'. Use apply | plan | destroy"
      ;;
  esac
}

main "$@"
