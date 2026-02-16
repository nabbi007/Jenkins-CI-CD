# Jenkins CI/CD Runbook

## 1. Prerequisites

- Jenkins LTS with Docker access on Jenkins agent.
- Docker Hub (or other registry) repository created.
- AWS EC2 (Amazon Linux 2) reachable over SSH.
- Security group allows:
  - SSH `22` from Jenkins host
  - App traffic `80` from your test client

## 2. Jenkins Plugins

Install these plugins:

- Pipeline
- Git
- Credentials Binding
- Docker Pipeline (or Docker plugin)
- SSH Agent

## 3. Jenkins Credentials

Create these credentials in Jenkins:

1. `git_credentials` (optional): Git username/token if private repository is used.
2. `registry_creds`: Username + password/token for Docker registry.
3. `ec2_ssh`: SSH private key credential for EC2 deployment user.

## 4. EC2 Host Preparation

Run once on EC2:

```bash
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -aG docker ec2-user
```

Reconnect SSH after adding the user to docker group.

## 5. Jenkins Job Setup

1. Create a Pipeline job.
2. Point SCM to this repository.
3. Use `Jenkinsfile` from repository.
4. Set parameters at build time:
   - `EC2_HOST` = public DNS/IP
   - `EC2_USER` = `ec2-user`
   - `REGISTRY_REPO` = e.g. `nabbi007/jenkins-ci-cd-demo`
   - `HOST_PORT` = `80`

## 6. Pipeline Stage Behavior

1. Checkout: Pull repository source.
2. Install/Build: `npm ci`
3. Test: `npm test`
4. Docker Build: Build and tag image (`BUILD_NUMBER` and `latest`).
5. Push Image: Authenticate using `registry_creds`, push both tags.
6. Deploy: SSH via `ec2_ssh`, pull image, replace container, prune old images.

## 7. Verification

After a successful run:

1. Confirm Jenkins stage view shows all stages green.
2. Check deployment result:

```bash
curl http://<EC2_PUBLIC_DNS_OR_IP>/
```

3. Expected response JSON includes `service`, `version`, and `status`.

## 8. Failure Triage

- Test failures: check `test/app.test.js` and app route behavior.
- Docker build failures: validate `Dockerfile` and build context.
- Push failures: verify `registry_creds` username/token permissions.
- Deploy failures: verify `ec2_ssh` key, EC2 firewall, Docker service on host.
