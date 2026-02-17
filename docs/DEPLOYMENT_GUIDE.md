# Deployment Guide

## Prerequisites

- Jenkins server running
- Docker installed on Jenkins and EC2
- AWS credentials configured
- GitHub repository access
- Terraform installed (optional, for manual provisioning)

---

## Deployment Methods

### Method 1: Automatic (Jenkins Pipeline)

1. **Create Pipeline Job**
   - New Item → Pipeline
   - Name: app-pipeline
   - Pipeline → GitHub repo URL

2. **Configure Credentials**
   - Credentials → System → Global credentials
   - Add aws_creds (username/password)
   - Add aws_session_token (secret text)

3. **Trigger Deployment**
   - Push to main branch
   - Jenkins automatically triggers pipeline
   - Watch console output
   - App deployed when pipeline succeeds

### Method 2: Manual (Scripts)

```bash
./scripts/deploy-ec2.sh \
  --image 049618907165.dkr.ecr.eu-west-1.amazonaws.com/jenkins-ci-cd-demo:latest \
  --host 54.74.21.91 \
  --user ec2-user \
  --key ./jenkins.pem
```

---

## Verification Steps

### Health Check

```bash
curl http://54.74.21.91:80/health
```

Expected response:
```json
{
  "status": "ok",
  "uptimeSeconds": 120,
  "timestamp": "2026-02-17T11:30:00Z",
  "deploymentRecords": 1
}
```

### Metrics Check

```bash
curl http://54.74.21.91:80/metrics
```

### Web UI Access

Open browser: http://54.74.21.91:80

Expected: Deployment dashboard loads with styling

---

## Rollback Procedure

1. **SSH to EC2:**
   ```bash
   ssh -i jenkins.pem ec2-user@54.74.21.91
   ```

2. **Stop Current Container:**
   ```bash
   docker stop jenkins-ci-cd-app
   ```

3. **Restart Previous Tag:**
   ```bash
   docker run -d --name jenkins-ci-cd-app \
     -p 80:3000 \
     049618907165.dkr.ecr.eu-west-1.amazonaws.com/jenkins-ci-cd-demo:previous-tag
   ```

4. **Verify:**
   ```bash
   curl http://localhost:3000/health
   ```

---

## Production Checklist

- [ ] All tests passing (100%)
- [ ] Code reviewed
- [ ] Dockerfile tested locally
- [ ] ECR credentials configured
- [ ] EC2 security group allows port 80
- [ ] Health check endpoint working
- [ ] UI loads without errors
- [ ] Database backups (if applicable)
- [ ] Monitoring alerts configured
- [ ] Rollback plan documented

