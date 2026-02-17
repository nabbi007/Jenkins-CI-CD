# Reviewer Explanation Guide: Jenkins_CI-CD Project

This guide is a complete walkthrough of the repository so you can explain design choices, implementation details, and evidence clearly during review.

## 1. What this project delivers

The project implements a Node.js API and a CI/CD delivery flow with Jenkins, Docker, AWS ECR, and EC2.

Core outcome:
- Build and test an Express service automatically.
- Build a production Docker image.
- Push the image to Amazon ECR.
- Deploy and verify a running container.
- Show Agile artifacts and sprint evidence for traceability.

## 2. Repository map (touches all major areas)

### Application and runtime
- `src/app.js`: Main Express app, API routes, in-memory deployment data model, metrics, structured request logging, and validation logic.
- `src/server.js`: Starts the app on `PORT` (default `3000`).

### Tests
- `test/app.test.js`: Jest test suite for metadata, health, metrics, create/update deployment records, dashboard, invalid payload handling, and 404 behavior.

### Containerization
- `Dockerfile`: Production image (`node:18-alpine`), installs production dependencies, copies `src`, exposes `3000`, starts server.
- `.dockerignore`: Reduces Docker build context size.

### CI/CD automation
- `Jenkinsfile`: Pipeline definition (checkout, install/build, test, ECR resolution, Docker build, push, deploy, post actions).
- `scripts/deploy-ec2.sh`: SSH-based deploy script for EC2 host (pull image, restart container, health-check).
- `scripts/verify-local.sh`: Local release gate (npm test + docker build + smoke-check).
- `scripts/ec2.sh`: Terraform wrapper for provisioning/reusing EC2/ECR resources and writing deploy env file.

### Infrastructure as Code
- `infra/terraform/main.tf`: AWS resources (ECR repo, SG, key pair, IAM role/profile, EC2 with Docker/AWS CLI bootstrap).
- `infra/terraform/variables.tf`: Input variables (region, instance settings, network CIDRs, app port, health path).
- `infra/terraform/outputs.tf`: Deployment outputs (host, region, registry, repository URI, key path, etc.).
- `infra/terraform/versions.tf`: Terraform/provider requirements.
- `infra/terraform/README.md`: Direct Terraform usage and env export guidance.

### Documentation and delivery evidence
- `README.md`: Project summary, endpoints, local run, and infrastructure pointer.
- `runbook.md`: Jenkins setup, credentials, pipeline flow, verification, and failure triage.
- `docs/jenkins-real-run-steps.md`: Practical end-to-end Jenkins run procedure.
- `docs/final-deliverables.md`: Index of all required artifacts.
- `docs/evidence/*`: Logs/JSON snapshots proving tests, pipeline outcomes, and monitoring checks.
- `docs/sprint-0/*`: Product vision, backlog, DoD, sprint planning.
- `docs/sprint-1/*`: Sprint backlog, review, retrospective.
- `docs/sprint-2/*`: Sprint backlog, review, retrospective.

## 3. Application behavior (`src/app.js`)

### Data model
- Tracks deployment records in memory (`deployments` array).
- Starts with a seeded record (`dep-1001`).
- Uses incrementing IDs from `dep-1002` onward.

### Observability
- Global middleware tracks:
- `metrics.totalRequests`
- `metrics.totalErrors`
- Structured JSON request log with `method`, `path`, `statusCode`, and `durationMs`.

### API endpoints
- `GET /`: service metadata and endpoint catalog.
- `GET /health`: health status, uptime, timestamp, current deployment count.
- `GET /metrics`: request/error counters and tracked deployments.
- `GET /api/deployments`: list deployments, optional `environment` and `status` filters.
- `GET /api/deployments/:id`: fetch one deployment or 404.
- `POST /api/deployments`: validates required fields (`serviceName`, `version`, `environment`, `owner`) and creates a pending deployment.
- `PATCH /api/deployments/:id/status`: updates status (`pending`, `running`, `succeeded`, `failed`, `rolled_back`) and completion timestamp rules.
- `GET /api/dashboard`: summary view with counters, status breakdown, and recent deployments.
- Fallback 404 handler for unknown routes.

### Input handling
- Custom JSON body parser (`parseJsonBody`) handles raw payload parsing and rejects invalid JSON with HTTP 400.

## 4. Test coverage (`test/app.test.js`)

The tests validate the key acceptance criteria:
- Service metadata route works.
- Health route returns expected runtime fields.
- Metrics route returns operational counters.
- Deployment creation and listing logic works.
- Invalid payloads return 400 with missing field details.
- Status transitions update deployment state correctly.
- Dashboard route returns summary sections.
- Unknown routes return 404.

The suite resets app state before each test via `app.resetState()` to keep tests deterministic.

## 5. Containerization (`Dockerfile`)

Build strategy:
- Uses minimal Alpine-based Node image.
- Installs only production dependencies (`npm ci --omit=dev`) to keep runtime image lean.
- Copies only `src/` for runtime execution.
- Runs on container port `3000`.

This supports consistent behavior between Jenkins, local Docker runs, and EC2-hosted container deployment.

## 6. Jenkins pipeline (`Jenkinsfile`) stage-by-stage

### Parameters
- `AWS_REGION`
- `ECR_REPOSITORY`
- `AWS_CREDS_ID`
- `HOST_PORT`
- `HEALTH_PATH`

### Environment
- `APP_CONTAINER=jenkins-ci-cd-app`

### Stages
1. `Checkout`: pulls source from SCM.
2. `Install/Build`: runs `npm ci`.
3. `Test`: runs `npm test`.
4. `Resolve ECR`:
- Reads AWS account ID via STS.
- Computes `ECR_REGISTRY`, `IMAGE_REPO`, and versioned tag (`FULL_IMAGE`).
- Creates ECR repository if it does not already exist.
5. `Docker Build`: builds both `${FULL_IMAGE}` and `:latest` tags.
6. `Push Image`: authenticates to ECR, pushes both tags, logs out.
7. `Deploy`: authenticates, replaces running container, prunes images, and blocks on health-check.

### Post actions
- `success`: success message.
- `failure`: failure message.
- `always`: workspace cleanup (`cleanWs()`).

## 7. Deep dive: `scripts/deploy-ec2.sh`

This is the SSH-based remote deploy script (useful for explicit EC2 deployment).

### Local prechecks
1. Enforces strict shell behavior (`set -euo pipefail`).
2. Loads environment file from `ENV_FILE` (default `/tmp/jenkins-ec2.env`) when available.
3. Requires `EC2_HOST`, `EC2_USER`, and image reference (`IMAGE_NAME` or `REGISTRY_REPO`).
4. Derives `ECR_REGISTRY` and `AWS_REGION` from image URI when possible.
5. Configures deploy defaults:
- `APP_CONTAINER=jenkins-ci-cd-app`
- `HOST_PORT=80`
- `CONTAINER_PORT=3000`
- `HEALTH_PATH=/health`
6. Builds SSH command and optionally applies `SSH_KEY_PATH` with permission hardening.

### Remote EC2 actions over SSH
1. Verify Docker exists.
2. If target image is ECR-hosted:
- Verify AWS CLI exists.
- Verify credentials are available on EC2 (`aws sts get-caller-identity`).
- Login to ECR.
3. Pull target image.
4. Remove previous app container.
5. Start replacement container with restart policy and host port mapping.
6. Prune stopped containers and old images.
7. Run up to 10 health-check attempts (`curl http://localhost:${HOST_PORT}${HEALTH_PATH}`).
8. On failure, print recent container logs and exit non-zero.

### Important review note
- `deploy-ec2.sh` exists and is production-ready for SSH-to-EC2 deployment.
- Current `Jenkinsfile` `Deploy` stage deploys directly on the Jenkins agent host (local Docker) and does **not** invoke `scripts/deploy-ec2.sh` in its current form.
- If reviewer expects strict remote-EC2 deployment from Jenkins, this difference should be called out clearly.

## 8. Infrastructure provisioning flow (`scripts/ec2.sh` + Terraform)

### What `scripts/ec2.sh` automates
- Validates required CLI tools (`terraform`, `aws`).
- Verifies AWS credentials availability.
- Runs `terraform init` and requested action (`apply`, `plan`, `destroy`).
- Passes optional environment overrides into Terraform variables.
- After `apply`, exports Terraform outputs to `/tmp/jenkins-ec2.env` with secure file permission.

### What Terraform creates (`infra/terraform/main.tf`)
- ECR repository (image scanning enabled).
- Security group (SSH 22, HTTP 80, Jenkins 8080 ingress; all egress).
- EC2 key pair plus generated local private key file.
- IAM role + instance profile with `AmazonEC2ContainerRegistryReadOnly` for EC2 image pulls.
- Amazon Linux 2 EC2 instance with user data that installs Docker and AWS CLI.

### Critical outputs (`infra/terraform/outputs.tf`)
- EC2 host/IP/user
- AWS account/region
- ECR registry/repository URI
- runtime host port/health path
- SSH key path

These outputs drive both manual deployment and script-driven deployment.

## 9. Local quality gate (`scripts/verify-local.sh`)

`npm run verify:local` executes a reproducible local pre-merge check:
1. `npm ci`
2. `npm test`
3. Docker build
4. Container run
5. Health endpoint smoke test
6. Automatic cleanup via shell trap

This reduces broken pipeline pushes by validating runtime behavior before CI.

## 10. Documentation and evidence traceability

### Operational docs
- `runbook.md`: installation prerequisites, plugin and credentials checklist, job config, flow, troubleshooting.
- `docs/jenkins-real-run-steps.md`: concrete step list for running the pipeline in Jenkins.

### Evidence artifacts
- `docs/evidence/sprint-1-*`: baseline test/build/pipeline evidence.
- `docs/evidence/sprint-2-*`: verification script, pipeline success, health/metrics checks.
- `docs/evidence/README.md`: expected artifact categories.

### Agile traceability
- `docs/sprint-0/*`: vision/backlog/DoD/plan foundation.
- `docs/sprint-1/*` and `docs/sprint-2/*`: execution, outcomes, reviews, retrospectives.
- `docs/final-deliverables.md`: index for assessor navigation.

## 11. End-to-end story you can present to reviewer

1. Product intent: deployable release-tracking API with reliable CI/CD.
2. Engineering controls: tests + Dockerized runtime + health/metrics.
3. Delivery automation: Jenkins builds/tests/images/pushes/deploys and gates success on health checks.
4. Infrastructure repeatability: Terraform-defined EC2/ECR/IAM/SG resources.
5. Operational readiness: runbook and troubleshooting guidance.
6. Process maturity: sprint planning, reviews, retrospectives, and preserved evidence.

## 12. Likely reviewer questions and direct answers

Q: How do you prove deployment health, not just build success?
A: Both pipeline deploy logic and `deploy-ec2.sh` include post-deploy health checks (`/health`) and fail the run if not healthy.

Q: How is infrastructure reproducible?
A: Terraform defines resources declaratively, and `scripts/ec2.sh` wraps init/plan/apply/destroy while exporting outputs for deployment reuse.

Q: What protects against regressions?
A: Jest route tests run in pipeline before image build/push; local `verify:local` mirrors those checks pre-merge.

Q: Is there auditability of delivery work?
A: Yes, sprint docs + evidence logs in `docs/` provide traceable outcomes and artifacts.

## 13. Optional improvement items to mention proactively

- Wire `Jenkinsfile` Deploy stage to call `scripts/deploy-ec2.sh` so CI behavior matches explicit SSH-to-EC2 runbook expectations.
- Add automatic rollback to previous image when post-deploy health checks fail.
- Integrate persistent metrics backend (CloudWatch/Prometheus) for long-term runtime observability.

## 14. Full file inventory checklist (explicit)

Use this when a reviewer asks whether every artifact was covered.

### Root-level files
- `README.md`
- `runbook.md`
- `Jenkinsfile`
- `Dockerfile`
- `package.json`
- `package-lock.json`

### Scripts
- `scripts/ec2.sh`
- `scripts/deploy-ec2.sh`
- `scripts/verify-local.sh`

### Application and tests
- `src/app.js`
- `src/server.js`
- `test/app.test.js`

### Terraform
- `infra/terraform/main.tf`
- `infra/terraform/variables.tf`
- `infra/terraform/outputs.tf`
- `infra/terraform/versions.tf`
- `infra/terraform/README.md`

### Delivery and process docs
- `docs/final-deliverables.md`
- `docs/jenkins-real-run-steps.md`
- `docs/evidence/README.md`

### Evidence artifacts
- `docs/evidence/sprint-1-docker-build.log`
- `docs/evidence/sprint-1-local-smoke.json`
- `docs/evidence/sprint-1-pipeline-failure-simulated.log`
- `docs/evidence/sprint-1-pipeline-success-simulated.log`
- `docs/evidence/sprint-1-test.log`
- `docs/evidence/sprint-2-health-check.json`
- `docs/evidence/sprint-2-metrics-check.json`
- `docs/evidence/sprint-2-pipeline-success-simulated.log`
- `docs/evidence/sprint-2-test.log`
- `docs/evidence/sprint-2-verify-local.log`

### Agile artifacts
- `docs/sprint-0/product-vision.md`
- `docs/sprint-0/backlog.md`
- `docs/sprint-0/definition-of-done.md`
- `docs/sprint-0/sprint-1-plan.md`
- `docs/sprint-1/sprint-backlog.md`
- `docs/sprint-1/review.md`
- `docs/sprint-1/retrospective.md`
- `docs/sprint-2/sprint-backlog.md`
- `docs/sprint-2/review.md`
- `docs/sprint-2/retrospective.md`
