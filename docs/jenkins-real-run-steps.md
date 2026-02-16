# Real Jenkins Run Steps (ECR -> EC2)

## 1. Fixed Project Values

- Repo URL: `https://github.com/nabbi007/Jenkins-CI-CD.git`
- Branch: `main`
- Jenkinsfile path: `Jenkinsfile`
- EC2 deploy user: `ec2-user`
- Default AWS region: `eu-west-1`
- Default ECR repository: `jenkins-ci-cd-demo`

## 2. Jenkins Credentials Required

- `aws_creds` (Username/Password)
  - Username: AWS access key id
  - Password: AWS secret access key
- `ec2_ssh` (SSH private key for EC2)
- `git_credentials` (optional)

## 3. Provision EC2 (fastest, Terraform-backed)

```bash
bash scripts/ec2.sh
```

Outputs are saved to `/tmp/jenkins-ec2.env` with:
- `EC2_HOST`
- `AWS_REGION`
- `ECR_REGISTRY`
- `ECR_REPOSITORY`
- `REGISTRY_REPO`

The Terraform module configures EC2 with an IAM instance profile for ECR read access.

Useful variants:

```bash
bash scripts/ec2.sh plan
bash scripts/ec2.sh apply
bash scripts/ec2.sh destroy
```

## 4. Jenkins Job Setup

1. Create Pipeline job (`Pipeline script from SCM`)
2. Repo URL: `https://github.com/nabbi007/Jenkins-CI-CD.git`
3. Branch: `*/main`
4. Script path: `Jenkinsfile`

## 5. Build Parameters

Use:

- `EC2_HOST` = your EC2 public DNS/IP
- `EC2_USER` = `ec2-user`
- `AWS_REGION` = `eu-west-1`
- `ECR_REPOSITORY` = `jenkins-ci-cd-demo`
- `AWS_CREDS_ID` = `aws_creds`
- `HOST_PORT` = `80`
- `HEALTH_PATH` = `/health`

## 6. Expected Stages

1. Checkout
2. Install/Build
3. Test
4. Resolve ECR
5. Docker Build
6. Push Image
7. Deploy

## 7. Verify After Success

```bash
curl -s http://<EC2_PUBLIC_DNS_OR_IP>/
curl -s http://<EC2_PUBLIC_DNS_OR_IP>/health
curl -s http://<EC2_PUBLIC_DNS_OR_IP>/metrics
```

## 8. Common Failures

- Push stage fails with ECR auth errors:
  - check `aws_creds`
  - check IAM permissions for ECR push on Jenkins side
- Deploy stage fails pulling from ECR:
  - check EC2 IAM role/credentials for ECR read
  - check AWS CLI availability on EC2
- Deploy stage fails health check:
  - inspect logs on EC2:

```bash
docker ps -a
docker logs --tail 100 jenkins-ci-cd-app
```
