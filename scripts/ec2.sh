#!/usr/bin/env bash
set -euo pipefail

# One-command EC2 provisioning/reuse for Jenkins deploy target.
# Default behavior:
# - Region: eu-west-1
# - Key name: jenkins
# - Instance type: t3.micro
# - Reuses an existing instance with tag Name=jenkins-cicd-t3micro when present.

REGION="${REGION:-eu-west-1}"
INSTANCE_NAME="${INSTANCE_NAME:-jenkins-cicd-t3micro}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
KEY_NAME="${KEY_NAME:-jenkins}"
KEY_PATH="${KEY_PATH:-/tmp/${KEY_NAME}.pem}"
REGISTRY_REPO="${REGISTRY_REPO:-${DOCKERHUB_USERNAME:-nabbi007}/jenkins-ci-cd-demo}"
VPC_ID="${VPC_ID:-}"
SUBNET_ID="${SUBNET_ID:-}"
SSH_CIDR="${SSH_CIDR:-0.0.0.0/0}"
HTTP_CIDR="${HTTP_CIDR:-0.0.0.0/0}"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-10}"
WAIT_RUNNING_TIMEOUT_SECONDS="${WAIT_RUNNING_TIMEOUT_SECONDS:-300}"
WAIT_STATUS_TIMEOUT_SECONDS="${WAIT_STATUS_TIMEOUT_SECONDS:-600}"
SKIP_STATUS_WAIT="${SKIP_STATUS_WAIT:-false}"
STRICT_STATUS_WAIT="${STRICT_STATUS_WAIT:-false}"
PROFILE_ARG=()

if [[ -n "${AWS_PROFILE:-}" ]]; then
  PROFILE_ARG+=(--profile "${AWS_PROFILE}")
fi

log() {
  printf '[ec2] %s\n' "$*"
}

fatal() {
  printf '[ec2] ERROR: %s\n' "$*" >&2
  exit 1
}

aws_ec2() {
  aws "${PROFILE_ARG[@]}" ec2 --region "${REGION}" "$@"
}

validate_aws_auth() {
  if ! aws "${PROFILE_ARG[@]}" sts get-caller-identity >/dev/null 2>&1; then
    fatal "AWS credentials not found. Run 'aws login' or 'aws configure' and retry."
  fi
}

ensure_key_pair() {
  if aws_ec2 describe-key-pairs --key-names "${KEY_NAME}" >/dev/null 2>&1; then
    log "Using existing key pair: ${KEY_NAME}"
    if [[ ! -f "${KEY_PATH}" ]]; then
      fatal "Private key not found at ${KEY_PATH}. Set KEY_PATH to your .pem path."
    fi
    chmod 400 "${KEY_PATH}" >/dev/null 2>&1 || true
    return
  fi

  log "Creating key pair: ${KEY_NAME}"
  mkdir -p "$(dirname "${KEY_PATH}")"
  aws_ec2 create-key-pair \
    --key-name "${KEY_NAME}" \
    --query 'KeyMaterial' \
    --output text > "${KEY_PATH}"
  chmod 400 "${KEY_PATH}"
  log "Private key written to: ${KEY_PATH}"
}

resolve_network_defaults() {
  if [[ -z "${VPC_ID}" ]]; then
    log "Resolving default VPC in ${REGION}..."
    VPC_ID="$(aws_ec2 describe-vpcs \
      --filters Name=isDefault,Values=true \
      --query 'Vpcs[0].VpcId' \
      --output text)"
    [[ "${VPC_ID}" != "None" && -n "${VPC_ID}" ]] || fatal "No default VPC in ${REGION}. Set VPC_ID."
  fi

  if [[ -z "${SUBNET_ID}" ]]; then
    log "Resolving default subnet in VPC ${VPC_ID}..."
    SUBNET_ID="$(aws_ec2 describe-subnets \
      --filters Name=vpc-id,Values="${VPC_ID}" Name=default-for-az,Values=true \
      --query 'Subnets[0].SubnetId' \
      --output text)"
    [[ "${SUBNET_ID}" != "None" && -n "${SUBNET_ID}" ]] || fatal "No default subnet in VPC ${VPC_ID}. Set SUBNET_ID."
  fi
}

ensure_security_group() {
  local sg_name="${INSTANCE_NAME}-sg"
  local existing_sg_id
  existing_sg_id="$(aws_ec2 describe-security-groups \
    --filters "Name=group-name,Values=${sg_name}" "Name=vpc-id,Values=${VPC_ID}" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)"

  if [[ "${existing_sg_id}" == "None" || -z "${existing_sg_id}" ]]; then
    SG_ID="$(aws_ec2 create-security-group \
      --group-name "${sg_name}" \
      --description "Security group for ${INSTANCE_NAME}" \
      --vpc-id "${VPC_ID}" \
      --query 'GroupId' \
      --output text)"
    log "Created security group: ${SG_ID}"
  else
    SG_ID="${existing_sg_id}"
    log "Using existing security group: ${SG_ID}"
  fi

  # Keep these idempotent by ignoring duplicate rule errors.
  aws_ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp --port 22 --cidr "${SSH_CIDR}" >/dev/null 2>&1 || true
  aws_ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp --port 80 --cidr "${HTTP_CIDR}" >/dev/null 2>&1 || true
}

find_existing_instance() {
  local instance_and_state
  instance_and_state="$(aws_ec2 describe-instances \
    --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'reverse(sort_by(Reservations[].Instances[], &LaunchTime))[0].[InstanceId,State.Name]' \
    --output text)"

  EXISTING_INSTANCE_ID="$(awk '{print $1}' <<< "${instance_and_state}")"
  EXISTING_INSTANCE_STATE="$(awk '{print $2}' <<< "${instance_and_state}")"

  if [[ "${EXISTING_INSTANCE_ID}" == "None" || -z "${EXISTING_INSTANCE_ID}" ]]; then
    EXISTING_INSTANCE_ID=""
    EXISTING_INSTANCE_STATE=""
  fi
}

wait_for_instance_running() {
  local elapsed=0

  while (( elapsed < WAIT_RUNNING_TIMEOUT_SECONDS )); do
    local state
    state="$(aws_ec2 describe-instances \
      --instance-ids "${INSTANCE_ID}" \
      --query 'Reservations[0].Instances[0].State.Name' \
      --output text)"

    if [[ "${state}" == "running" ]]; then
      log "Instance is running."
      return
    fi

    log "Waiting for running state... current=${state}, elapsed=${elapsed}s"
    sleep "${POLL_INTERVAL_SECONDS}"
    elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
  done

  fatal "Timed out waiting for instance to reach running state."
}

wait_for_status_ok() {
  if [[ "${SKIP_STATUS_WAIT}" == "true" ]]; then
    log "Skipping EC2 status checks (SKIP_STATUS_WAIT=true)."
    return
  fi

  local elapsed=0
  while (( elapsed < WAIT_STATUS_TIMEOUT_SECONDS )); do
    local checks
    checks="$(aws_ec2 describe-instance-status \
      --instance-ids "${INSTANCE_ID}" \
      --query 'InstanceStatuses[0].[SystemStatus.Status,InstanceStatus.Status]' \
      --output text 2>/dev/null || true)"

    local system_status instance_status
    system_status="$(awk '{print $1}' <<< "${checks}")"
    instance_status="$(awk '{print $2}' <<< "${checks}")"

    if [[ "${system_status}" == "ok" && "${instance_status}" == "ok" ]]; then
      log "Instance/system status checks are ok."
      return
    fi

    log "Waiting for status checks... system=${system_status:-n/a}, instance=${instance_status:-n/a}, elapsed=${elapsed}s"
    sleep "${POLL_INTERVAL_SECONDS}"
    elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
  done

  if [[ "${STRICT_STATUS_WAIT}" == "true" ]]; then
    fatal "Timed out waiting for status checks (STRICT_STATUS_WAIT=true)."
  fi

  log "Status checks not fully ok yet. Continuing (STRICT_STATUS_WAIT=false)."
}

launch_or_reuse_instance() {
  find_existing_instance

  if [[ -n "${EXISTING_INSTANCE_ID}" ]]; then
    case "${EXISTING_INSTANCE_STATE}" in
      running|pending)
        INSTANCE_ID="${EXISTING_INSTANCE_ID}"
        log "Reusing existing instance ${INSTANCE_ID} (state=${EXISTING_INSTANCE_STATE})."
        ;;
      stopped|stopping)
        INSTANCE_ID="${EXISTING_INSTANCE_ID}"
        log "Starting existing instance ${INSTANCE_ID} (state=${EXISTING_INSTANCE_STATE})."
        aws_ec2 start-instances --instance-ids "${INSTANCE_ID}" >/dev/null
        ;;
      *)
        fatal "Unexpected existing instance state: ${EXISTING_INSTANCE_STATE}"
        ;;
    esac
    return
  fi

  log "Resolving latest Amazon Linux 2 AMI in ${REGION}..."
  AMI_ID="$(aws "${PROFILE_ARG[@]}" ssm get-parameter \
    --region "${REGION}" \
    --name /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
    --query 'Parameter.Value' \
    --output text)"

  log "Launching new ${INSTANCE_TYPE} instance..."
  INSTANCE_ID="$(aws_ec2 run-instances \
    --image-id "${AMI_ID}" \
    --instance-type "${INSTANCE_TYPE}" \
    --key-name "${KEY_NAME}" \
    --security-group-ids "${SG_ID}" \
    --subnet-id "${SUBNET_ID}" \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" \
    --user-data '#!/bin/bash
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
' \
    --query 'Instances[0].InstanceId' \
    --output text)"
}

load_instance_network() {
  PUBLIC_DNS="$(aws_ec2 describe-instances \
    --instance-ids "${INSTANCE_ID}" \
    --query 'Reservations[0].Instances[0].PublicDnsName' \
    --output text)"

  PUBLIC_IP="$(aws_ec2 describe-instances \
    --instance-ids "${INSTANCE_ID}" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)"
}

write_env_output() {
  local env_out="${ENV_OUT_PATH:-/tmp/jenkins-ec2.env}"
  cat > "${env_out}" <<EOF
EC2_INSTANCE_ID=${INSTANCE_ID}
EC2_HOST=${PUBLIC_DNS}
EC2_PUBLIC_IP=${PUBLIC_IP}
EC2_USER=ec2-user
REGISTRY_REPO=${REGISTRY_REPO}
HOST_PORT=80
HEALTH_PATH=/health
SSH_KEY_PATH=${KEY_PATH}
EOF
  log "Saved reusable output vars to: ${env_out}"
}

main() {
  validate_aws_auth
  ensure_key_pair
  resolve_network_defaults
  ensure_security_group
  launch_or_reuse_instance
  wait_for_instance_running
  wait_for_status_ok
  load_instance_network
  write_env_output

  cat <<EOF

Provisioned/Reused successfully:
  Instance ID: ${INSTANCE_ID}
  Public DNS : ${PUBLIC_DNS}
  Public IP  : ${PUBLIC_IP}
  SecurityGrp: ${SG_ID}
  VPC ID     : ${VPC_ID}
  Subnet ID  : ${SUBNET_ID}

Jenkins build parameters:
  EC2_HOST=${PUBLIC_DNS}
  EC2_USER=ec2-user
  REGISTRY_REPO=${REGISTRY_REPO}
  HOST_PORT=80
  HEALTH_PATH=/health

Jenkins SSH credential:
  ec2_ssh private key file -> ${KEY_PATH}

Quick checks:
  ssh -i ${KEY_PATH} ec2-user@${PUBLIC_DNS} "docker --version"
  curl http://${PUBLIC_DNS}/health
EOF
}

main "$@"
