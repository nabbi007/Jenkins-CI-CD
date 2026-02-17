# Jenkins CI/CD Runbook (ECR + EC2)

## 1. Prerequisites

- Jenkins LTS with Docker and AWS CLI available on the Jenkins agent.
- AWS account with ECR access.
- EC2 (Amazon Linux 2) reachable over SSH.
- Security group allows:
  - SSH `22` from Jenkins host
  - App traffic `80` from client/browser

## 2. Jenkins Plugins

- Pipeline
- Git
- Credentials Binding
- Docker Pipeline (or Docker plugin)
- SSH Agent

## 3. Jenkins Credentials

Create these credentials in Jenkins:

1. `aws_creds` (Username/Password):
   - Username = `AWS_ACCESS_KEY_ID`
   - Password = `AWS_SECRET_ACCESS_KEY`
2. `ec2_ssh` (SSH private key): key used for `ec2-user` login
3. `git_credentials` (optional): only if repo access needs auth

## 4. Provision/Re-use EC2 Quickly (Terraform)

```bash
bash scripts/ec2.sh
```

This script:
- runs Terraform in `infra/terraform`
- creates/updates EC2, SG, key pair, IAM role/profile, and ECR repository
- preserves state so repeated `apply` runs do not recreate resources unnecessarily
- writes env output to `/tmp/jenkins-ec2.env` for deploy scripts

Useful commands:

```bash
bash scripts/ec2.sh plan
bash scripts/ec2.sh apply
bash scripts/ec2.sh destroy
```

Important for ECR pull:
- The Terraform module attaches `AmazonEC2ContainerRegistryReadOnly` to EC2 via instance profile.

## 5. Jenkins Job Setup

1. Create Pipeline job
2. SCM repo: this repository
3. Branch: `main`
4. Script path: `Jenkinsfile`
5. Build parameters:
   - `EC2_HOST`
   - `EC2_USER` = `ec2-user`
   - `AWS_REGION` = `eu-west-1`
   - `ECR_REPOSITORY` = `jenkins-ci-cd-demo`
   - `AWS_CREDS_ID` = `aws_creds`
   - `HOST_PORT` = `80`
   - `HEALTH_PATH` = `/health`

## 6. Pipeline Flow

1. Checkout
2. Install/Build (`npm ci`)
3. Test (`npm test`)
4. Resolve ECR (account/registry/repository)
5. Docker Build
6. Push Image to ECR
7. Deploy to EC2 via SSH (ECR login on host + pull + run + health check)

## 7. Verification

```bash
curl http://<EC2_PUBLIC_DNS_OR_IP>/
curl http://<EC2_PUBLIC_DNS_OR_IP>/health
curl http://<EC2_PUBLIC_DNS_OR_IP>/metrics
```

## 8. Failure Triage

- ECR push fails: verify `aws_creds` and IAM permissions on Jenkins side.
- ECR pull fails on EC2: verify EC2 IAM role/credentials and AWS CLI on host.
- SSH deploy fails: verify `ec2_ssh` key, host value, security group `22`.
