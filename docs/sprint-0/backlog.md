# Product Backlog (Refined)

## Prioritization and Estimation

Priority scale: `High` > `Medium` > `Low`  
Estimation model: Story points using Fibonacci-like sizing (`1, 2, 3, 5, 8`)

## User Stories with Acceptance Criteria

### US-01 (High, 3 SP)
As a developer, I want a minimal Express service so that I have a deployable web API foundation.

Acceptance Criteria:
- `GET /` returns HTTP `200` and JSON with app metadata.
- Service listens on `PORT` env var with default `3000`.
- App starts locally with `npm start`.

### US-02 (High, 5 SP)
As a developer, I want unit/integration tests so that regressions are caught before deployment.

Acceptance Criteria:
- `npm test` runs automatically in CI.
- At least one route success case and one error/edge case are tested.
- Test run exits non-zero on failure.

### US-03 (High, 3 SP)
As a DevOps engineer, I want a Docker image build process so that deployments are environment-consistent.

Acceptance Criteria:
- Repository includes a production-ready `Dockerfile`.
- Image builds successfully with `docker build`.
- Container runs and exposes app port.

### US-04 (High, 8 SP)
As a DevOps engineer, I want a Jenkins pipeline (checkout, build, test, image, push, deploy) so that delivery is automated.

Acceptance Criteria:
- Jenkinsfile defines stages: Checkout, Install/Build, Test, Docker Build, Push Image, Deploy.
- Pipeline stops on test or build failure.
- Credentials are consumed via Jenkins credentials store.

### US-05 (High, 5 SP)
As an operator, I want deployment to EC2 over SSH so that the latest release is reachable via public IP/DNS.

Acceptance Criteria:
- Pipeline deploy stage SSHs to EC2 and runs new container.
- Old container is removed/replaced cleanly.
- App is reachable through EC2 public endpoint after deploy.

### US-06 (Medium, 3 SP)
As an operator, I want basic monitoring/logging endpoints so that I can verify runtime health quickly.

Acceptance Criteria:
- `GET /health` returns service status and uptime.
- Request logs include method, path, and response time.
- Errors are logged with consistent structure.

### US-07 (Medium, 3 SP)
As a maintainer, I want a clear runbook and evidence artifacts so that anyone can reproduce and assess the pipeline.

Acceptance Criteria:
- Runbook documents Jenkins plugins, credentials, and setup.
- Evidence folder includes successful test and pipeline outputs.
- Sprint reviews and retrospectives exist for both execution sprints.

## Backlog Order (Top to Bottom)
1. US-01
2. US-02
3. US-03
4. US-04
5. US-05
6. US-06
7. US-07
