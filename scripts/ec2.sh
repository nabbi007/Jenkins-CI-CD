#!/usr/bin/env bash
set -euo pipefail

# Provisions an Amazon Linux 2 t3.micro instance for Jenkins deployment target use.
# Requires: aws cli configured.

REGION="${REGION:-eu-west-1}"
INSTANCE_NAME="${INSTANCE_NAME:-jenkins-cicd-t3micro}"
KEY_NAME="${KEY_NAME:-jenkins}"
KEY_PATH="${KEY_PATH:-/tmp/${KEY_NAME}.pem}"
VPC_ID="${VPC_ID:-}"
SUBNET_ID="${SUBNET_ID:-}"
SSH_CIDR="${SSH_CIDR:-0.0.0.0/0}"
HTTP_CIDR="${HTTP_CIDR:-0.0.0.0/0}"
PROFILE_ARG=()

if [[ -n "${AWS_PROFILE:-}" ]]; then
  PROFILE_ARG+=(--profile "${AWS_PROFILE}")
fi

if aws "${PROFILE_ARG[@]}" ec2 describe-key-pairs \
  --region "${REGION}" \
  --key-names "${KEY_NAME}" >/dev/null 2>&1; then
  echo "Using existing key pair: ${KEY_NAME}"
  if [[ ! -f "${KEY_PATH}" ]]; then
    echo "Private key file not found at ${KEY_PATH}."
    echo "Set KEY_PATH to your existing .pem file location."
    echo "Example: KEY_PATH=$HOME/.ssh/${KEY_NAME}.pem ./ec2.sh"
    exit 1
  fi
  chmod 400 "${KEY_PATH}" >/dev/null 2>&1 || true
else
  echo "Key pair ${KEY_NAME} not found in ${REGION}. Creating it..."
  mkdir -p "$(dirname "${KEY_PATH}")"
  aws "${PROFILE_ARG[@]}" ec2 create-key-pair \
    --region "${REGION}" \
    --key-name "${KEY_NAME}" \
    --query 'KeyMaterial' \
    --output text > "${KEY_PATH}"
  chmod 400 "${KEY_PATH}"
  echo "Private key written to: ${KEY_PATH}"
fi

if [[ -z "${VPC_ID}" ]]; then
  echo "VPC_ID not provided. Resolving default VPC in ${REGION}..."
  VPC_ID="$(aws "${PROFILE_ARG[@]}" ec2 describe-vpcs \
    --region "${REGION}" \
    --filters Name=isDefault,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)"

  if [[ "${VPC_ID}" == "None" || -z "${VPC_ID}" ]]; then
    echo "No default VPC found in ${REGION}. Provide VPC_ID explicitly."
    exit 1
  fi
fi

if [[ -z "${SUBNET_ID}" ]]; then
  echo "SUBNET_ID not provided. Resolving default subnet in ${REGION}..."
  SUBNET_ID="$(aws "${PROFILE_ARG[@]}" ec2 describe-subnets \
    --region "${REGION}" \
    --filters Name=vpc-id,Values="${VPC_ID}" Name=default-for-az,Values=true \
    --query 'Subnets[0].SubnetId' \
    --output text)"

  if [[ "${SUBNET_ID}" == "None" || -z "${SUBNET_ID}" ]]; then
    echo "No default subnet found in VPC ${VPC_ID}. Provide SUBNET_ID explicitly."
    exit 1
  fi
fi

echo "Resolving latest Amazon Linux 2 AMI in ${REGION}..."
AMI_ID="$(aws "${PROFILE_ARG[@]}" ssm get-parameter \
  --region "${REGION}" \
  --name /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
  --query 'Parameter.Value' \
  --output text)"

SG_NAME="${INSTANCE_NAME}-sg"

echo "Ensuring security group ${SG_NAME} exists..."
EXISTING_SG_ID="$(aws "${PROFILE_ARG[@]}" ec2 describe-security-groups \
  --region "${REGION}" \
  --filters "Name=group-name,Values=${SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)"

if [[ "${EXISTING_SG_ID}" == "None" || -z "${EXISTING_SG_ID}" ]]; then
  SG_ID="$(aws "${PROFILE_ARG[@]}" ec2 create-security-group \
    --region "${REGION}" \
    --group-name "${SG_NAME}" \
    --description "Security group for ${INSTANCE_NAME}" \
    --vpc-id "${VPC_ID}" \
    --query 'GroupId' \
    --output text)"

  aws "${PROFILE_ARG[@]}" ec2 authorize-security-group-ingress \
    --region "${REGION}" \
    --group-id "${SG_ID}" \
    --ip-permissions "[
      {\"IpProtocol\":\"tcp\",\"FromPort\":22,\"ToPort\":22,\"IpRanges\":[{\"CidrIp\":\"${SSH_CIDR}\"}]},
      {\"IpProtocol\":\"tcp\",\"FromPort\":80,\"ToPort\":80,\"IpRanges\":[{\"CidrIp\":\"${HTTP_CIDR}\"}]}
    ]" >/dev/null
else
  SG_ID="${EXISTING_SG_ID}"
fi

echo "Launching ${INSTANCE_NAME} (t3.micro)..."
INSTANCE_ID="$(aws "${PROFILE_ARG[@]}" ec2 run-instances \
  --region "${REGION}" \
  --image-id "${AMI_ID}" \
  --instance-type t3.micro \
  --key-name "${KEY_NAME}" \
  --security-group-ids "${SG_ID}" \
  --subnet-id "${SUBNET_ID}" \
  --associate-public-ip-address \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" \
  --user-data '#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
' \
  --query 'Instances[0].InstanceId' \
  --output text)"

echo "Waiting for instance to enter running state..."
aws "${PROFILE_ARG[@]}" ec2 wait instance-running --region "${REGION}" --instance-ids "${INSTANCE_ID}"

echo "Waiting for instance status checks..."
aws "${PROFILE_ARG[@]}" ec2 wait instance-status-ok --region "${REGION}" --instance-ids "${INSTANCE_ID}"

PUBLIC_DNS="$(aws "${PROFILE_ARG[@]}" ec2 describe-instances \
  --region "${REGION}" \
  --instance-ids "${INSTANCE_ID}" \
  --query 'Reservations[0].Instances[0].PublicDnsName' \
  --output text)"

PUBLIC_IP="$(aws "${PROFILE_ARG[@]}" ec2 describe-instances \
  --region "${REGION}" \
  --instance-ids "${INSTANCE_ID}" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)"

echo
echo "Provisioned successfully:"
echo "  Instance ID: ${INSTANCE_ID}"
echo "  Public DNS : ${PUBLIC_DNS}"
echo "  Public IP  : ${PUBLIC_IP}"
echo "  SecurityGrp: ${SG_ID}"
echo "  VPC ID     : ${VPC_ID}"
echo "  Subnet ID  : ${SUBNET_ID}"
echo
echo "Use these Jenkins build parameters:"
echo "  EC2_HOST=${PUBLIC_DNS}"
echo "  EC2_USER=ec2-user"
echo "  REGISTRY_REPO=nabbi007/jenkins-ci-cd-demo"
echo "  HOST_PORT=80"
echo "  HEALTH_PATH=/health"
echo
echo "Important: Set Jenkins SSH credential 'ec2_ssh' using private key file: ${KEY_PATH}"
