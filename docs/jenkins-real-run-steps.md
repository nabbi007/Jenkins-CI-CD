# Real Jenkins Run Steps (Using Current Project Values)

This is the exact execution checklist for the current repository and Jenkinsfile values.

## 1. Fixed Values for This Project

- Git repo URL: `https://github.com/nabbi007/Jenkins-CI-CD.git`
- Branch: `main`
- Jenkinsfile path: `Jenkinsfile`
- Docker registry repo: `nabbi007/jenkins-ci-cd-demo`
- App container name (pipeline env): `jenkins-ci-cd-app`
- EC2 SSH user: `ec2-user`
- Host port: `80`
- Health endpoint path: `/health`
- Jenkins credentials IDs:
  - `registry_creds` (Docker registry username/password or token)
  - `ec2_ssh` (SSH private key for EC2)
  - `git_credentials` (optional, only if repo access is private)

## 2. Jenkins Plugins (Must Be Installed)

- Pipeline
- Git
- Credentials Binding
- Docker Pipeline (or Docker plugin)
- SSH Agent

## 3. Create/Verify Jenkins Credentials

In Jenkins: `Manage Jenkins` -> `Credentials` -> global store

1. Add Username/Password credential:
   - ID: `registry_creds`
   - Username: your Docker Hub username
   - Password: Docker Hub password or access token
2. Add SSH Username with private key:
   - ID: `ec2_ssh`
   - Username: `ec2-user`
   - Private key: the `.pem` key for your EC2 instance
3. Optional Git credential:
   - ID: `git_credentials`
   - Needed only if repository access is private

## 4. Prepare EC2 Once

SSH to your EC2 host and run:

```bash
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -aG docker ec2-user
```

Reconnect SSH, then verify:

```bash
docker --version
docker ps
```

Ensure security group inbound rules allow:
- `22/tcp` from Jenkins host IP
- `80/tcp` from the client IP range you will use for verification

### Option A: Provision a New `t3.micro` Automatically (Recommended)

Use the helper script in this repo:

```bash
KEY_NAME=<your-ec2-keypair-name> \
VPC_ID=<your-vpc-id> \
SUBNET_ID=<your-public-subnet-id> \
REGION=us-east-1 \
bash scripts/provision-t3-micro.sh
```

This creates:
- Amazon Linux 2 `t3.micro`
- Security group with `22` and `80` ingress
- Docker preinstalled via user-data

The script prints the exact Jenkins values for `EC2_HOST` and the rest of the deploy parameters.

### Option B: Use an Existing EC2 Instance

If you already have a running host, keep using it and ensure Docker + security rules are configured as above.

## 5. Create Jenkins Pipeline Job

1. `New Item` -> `Pipeline` -> name: `jenkins-ci-cd-real-run`
2. Pipeline definition: `Pipeline script from SCM`
3. SCM: `Git`
4. Repository URL: `https://github.com/nabbi007/Jenkins-CI-CD.git`
5. Branch specifier: `*/main`
6. Script path: `Jenkinsfile`
7. Save

## 6. Build With Parameters (Use These Exact Values)

Run `Build with Parameters` and set:

- `EC2_HOST` = `<YOUR_EC2_PUBLIC_DNS_OR_IP>` (only environment-specific value)
- `EC2_USER` = `ec2-user`
- `REGISTRY_REPO` = `nabbi007/jenkins-ci-cd-demo`
- `HOST_PORT` = `80`
- `HEALTH_PATH` = `/health`

## 7. Expected Stage Sequence

The run must execute in this order:

1. `Checkout`
2. `Install/Build` (`npm ci`)
3. `Test` (`npm test`)
4. `Docker Build` (tags `${REGISTRY_REPO}:${BUILD_NUMBER}` and `:latest`)
5. `Push Image` (uses `registry_creds`)
6. `Deploy` (SSH using `ec2_ssh`, health-checked deployment)

## 8. Verify Deployment

After Jenkins build succeeds, run:

```bash
curl -s http://<YOUR_EC2_PUBLIC_DNS_OR_IP>/ | jq
curl -s http://<YOUR_EC2_PUBLIC_DNS_OR_IP>/health | jq
curl -s http://<YOUR_EC2_PUBLIC_DNS_OR_IP>/metrics | jq
```

Expected:
- `/` includes `service`, `version`, `status`
- `/health` includes `status`, `uptimeSeconds`, `timestamp`
- `/metrics` includes `totalRequests`, `totalErrors`

## 9. Capture Submission Evidence

Save screenshots/logs of:

1. Jenkins stage view with all stages green
2. Console log showing successful `docker push` and `Deploy`
3. Browser or curl output for:
   - `http://<EC2_HOST>/`
   - `http://<EC2_HOST>/health`
4. One intentionally failed run (for failure evidence), e.g. temporary failing test commit

## 10. Quick Failure Fix Map

- `Push Image` fails: recheck `registry_creds` username/token
- `Deploy` fails at SSH: recheck `ec2_ssh`, EC2 host value, security group `22`
- `Deploy` fails health check: inspect container logs on EC2:

```bash
docker ps -a
docker logs --tail 100 jenkins-ci-cd-app
```
