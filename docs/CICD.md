# CI/CD Pipeline Documentation

## Pipeline Overview

**Name:** app-pipeline  
**Type:** Declarative Jenkins Pipeline  
**Repository:** https://github.com/nabbi007/Jenkins-CI-CD  
**Jenkinsfile:** Located at project root  

---

## Pipeline Stages

### 1. Checkout (Declarative: Checkout SCM)
**Purpose:** Clone repository and check out code

**Actions:**
- Clone from GitHub
- Check out main branch
- Fetch latest commits

**Timing:** ~5-10 seconds

**Success Criteria:**
- ✅ Repository cloned
- ✅ Correct branch checked out
- ✅ commit hash logged

---

### 2. Install/Build
**Purpose:** Install npm dependencies and prepare application

**Agent:** Docker (node:18-alpine)  
**Environment:** NPM_CONFIG_CACHE=${WORKSPACE}/.npm

**Actions:**
```bash
npm ci  # Clean install (locked dependencies)
```

**Timing:** ~8-10 seconds

**Success Criteria:**
- ✅ 337 packages installed
- ✅ No vulnerabilities
- ✅ npm cache located in workspace

---

### 3. Test
**Purpose:** Run automated test suite

**Agent:** Docker (node:18-alpine)  
**Environment:** NPM_CONFIG_CACHE=${WORKSPACE}/.npm

**Actions:**
```bash
npm test  # Run Jest with --runInBand
```

**Timing:** ~3-5 seconds

**Success Criteria:**
- ✅ All 10 tests pass
- ✅ No console errors
- ✅ Test suites: 1 passed

**Test Output Sample:**
```
PASS test/app.test.js
  Express service
    ✓ serves the web interface at GET / (74 ms)
    ✓ returns metadata on GET /api/info (16 ms)
    ✓ returns healthy status data on GET /health (6 ms)
    ✓ returns metrics on GET /metrics (10 ms)
    ✓ returns backend options for UI on GET /api/options (7 ms)
    ✓ creates and lists deployment records (26 ms)
    ✓ rejects invalid deployment payload (7 ms)
    ✓ updates deployment status (17 ms)
    ✓ returns dashboard summary (6 ms)
    ✓ returns 404 on unknown routes (9 ms)

Test Suites: 1 passed, 1 total
Tests:       10 passed, 10 total
```

---

### 4. Resolve ECR
**Purpose:** Set up AWS ECR registry and get account details

**Agent:** Main Jenkins agent  
**Credentials:** aws_creds, aws_session_token

**Actions:**
1. Get AWS account ID via `aws sts get-caller-identity`
2. Construct ECR registry URL
3. Check if ECR repository exists
4. Create repository if needed
5. Set IMAGE_REPO and FULL_IMAGE variables

**Timing:** ~5-10 seconds

**Success Criteria:**
- ✅ Account ID retrieved: 049618907165
- ✅ Registry: 049618907165.dkr.ecr.eu-west-1.amazonaws.com
- ✅ Repository: jenkins-ci-cd-demo
- ✅ Image tag: [BUILD_NUMBER]

---

### 5. Docker Build
**Purpose:** Build Docker image locally

**Agent:** Main Jenkins agent  
**Docker:** Host Docker daemon

**Actions:**
```bash
docker build -t ${FULL_IMAGE} -t ${IMAGE_REPO}:latest .
```

**Timing:** ~30-60 seconds (first build), ~10-15 seconds (cached)

**Success Criteria:**
- ✅ Dockerfile parsed
- ✅ Layers built successfully
- ✅ Image tagged with build number
- ✅ Image tagged as latest

---

### 6. Push Image
**Purpose:** Push Docker image to AWS ECR

**Agent:** Main Jenkins agent  
**Credentials:** aws_creds, aws_session_token

**Actions:**
```bash
# Authenticate to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Push both tags
docker push ${FULL_IMAGE}
docker push ${IMAGE_REPO}:latest

# Logout
docker logout ${ECR_REGISTRY}
```

**Timing:** ~15-30 seconds

**Success Criteria:**
- ✅ Authenticated to ECR
- ✅ Image pushed successfully
- ✅ Both tags pushed

---

### 7. Deploy
**Purpose:** Deploy application to EC2 instance

**Agent:** Main Jenkins agent  
**Target:** EC2 instance (54.74.21.91)  
**Credentials:** aws_creds, aws_session_token

**Actions:**
1. Verify Docker is running
2. Authenticate to ECR
3. Remove old container (if any)
4. Run new container:
   ```bash
   docker run -d \
     --name jenkins-ci-cd-app \
     --restart unless-stopped \
     -p 80:3000 \
     ${FULL_IMAGE}
   ```
5. Clean up old images
6. Health check (10 attempts, 2 second interval)
7. Output accessible app URL

**Timing:** ~10-20 seconds

**Success Criteria:**
- ✅ Container running
- ✅ Health check passes
- ✅ Port 80 mapped to 3000
- ✅ App accessible at http://54.74.21.91:80

**Success Output:**
```
==========================================
✓ APP DEPLOYMENT SUCCESSFUL
==========================================
App URL (IP):  http://54.74.21.91:80
App URL (DNS): http://ec2-54-74-21-91.eu-west-1.compute.amazonaws.com:80
Health Check:  http://54.74.21.91:80/health
==========================================
```

---

## Pipeline Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| AWS_REGION | eu-west-1 | AWS region for ECR |
| ECR_REPOSITORY | jenkins-ci-cd-demo | ECR repository name |
| AWS_CREDS_ID | aws_creds | Jenkins credential ID |
| HOST_PORT | 80 | Port on EC2 |
| HEALTH_PATH | /health | Health check endpoint |

---

## Environment Variables

| Variable | Source | Value |
|----------|--------|-------|
| APP_CONTAINER | Pipeline | jenkins-ci-cd-app |
| NPM_CONFIG_CACHE | Stage | ${WORKSPACE}/.npm |
| AWS_REGION | Parameter | eu-west-1 |
| AWS_ACCESS_KEY_ID | Credential | *** (masked) |
| AWS_SECRET_ACCESS_KEY | Credential | *** (masked) |
| AWS_SESSION_TOKEN | Credential | *** (masked) |
| WORKSPACE | Jenkins | /var/lib/jenkins/workspace/app-pipeline |

---

## Credential Management

### aws_creds (Username with Password)
- **Type:** usernamePassword
- **Uses:** AWS_ACCESS_KEY_ID (username), AWS_SECRET_ACCESS_KEY (password)
- **Scope:** Global
- **Used in:** Resolve ECR, Push Image, Deploy stages

### aws_session_token (Secret Text)
- **Type:** string
- **Uses:** AWS_SESSION_TOKEN
- **Scope:** Global
- **Used in:** Resolve ECR, Push Image, Deploy stages

---

## Failed Pipeline Handling

**Failure Points:** Any stage can trigger pipeline stop
- **Build/Test Failure:** Pipeline stops immediately
- **ECR Failure:** Docker Build/Push/Deploy skipped
- **Docker Build Failure:** Push/Deploy skipped
- **Push Failure:** Deploy skipped
- **Deploy Failure:** Post actions run, pipeline marked failed

**Post Actions:**
```groovy
post {
  success {
    echo 'Pipeline completed: build, test, push to ECR, and deploy.'
  }
  failure {
    echo 'Pipeline failed. Check stage logs and fix before rerun.'
  }
  always {
    cleanWs()  // Clean workspace after build
  }
}
```

---

## Jenkins Configuration Requirements

### Plugins Required
- ✅ Pipeline (workflow-aggregator)
- ✅ Git plugin
- ✅ Docker plugin
- ✅ Credentials plugin
- ✅ Pipeline: Step Plugin
- ✅ Docker Pipeline plugin

### Server Configuration
- ✅ Docker installed and running
- ✅ Jenkins user can access Docker daemon
- ✅ Git installed
- ✅ AWS CLI configured
- ✅ Network access to GitHub and AWS

---

## Execution Flow Diagram

```
[Start]
   ↓
[Checkout] → Clone repo
   ↓
[Install/Build] → npm ci (Docker agent)
   ↓
[Test] → npm test (Docker agent)
   ↓
[Resolve ECR] → Get AWS account, create repo
   ↓
[Docker Build] → docker build
   ↓
[Push Image] → docker push to ECR
   ↓
[Deploy] → docker run on EC2, health check
   ↓
[Post] → cleanup
   ↓
[End - Success]

On Failure at any step:
   ↓
[Skip remaining stages]
   ↓
[Post] → cleanup
   ↓
[End - Failure]
```

---

## Recent Successful Builds

### Build #1 (Initial)
- **Duration:** ~3 minutes
- **Status:** ✅ Success
- **Issues:** None
- **Screenshot:** first_successful_build.png

### Final Build (Sprint 2 Complete)  
- **Duration:** ~2.5 minutes
- **Status:** ✅ Success  
- **App URL:** http://54.74.21.91:80  
- **Screenshot:** final_pipeline.png  

---

## Evidence & Logs

**Successful Run:** `docs/evidence/sprint-2-pipeline-success-simulated.log`  
**Test Output:** `docs/evidence/sprint-2-test.log`  
**Health Check:** `docs/evidence/sprint-2-health-check.json`  

---

## Troubleshooting Guide

| Issue | Cause | Solution |
|-------|-------|----------|
| npm cache error (EACCES) | Root-owned npm cache in Docker | Set NPM_CONFIG_CACHE to workspace |
| Docker image not found | Missing node:18-alpine locally | Docker pull happens automatically |
| AWS token expired | Credentials expired | Generate new temporary credentials |
| Health check fails | App not starting | Check docker logs |
| Port already in use | Previous container not stopped | Pipeline cleans up old container |

---

*CI/CD pipeline fully automated and production-ready*
