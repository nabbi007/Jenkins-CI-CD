# Backlog & Sprint Planning

## Table of Contents

1. [Product Vision](#product-vision)
2. [Product Backlog](#product-backlog)
3. [Definition of Done](#definition-of-done)
4. [Sprint 1 Details](#sprint-1-details)
5. [Sprint 2 Details](#sprint-2-details)

---

## Product Vision

**Name:** DevOps Release Tracker

**Purpose:** A web-based application for tracking deployment records, managing release state, and monitoring operational health in a CI/CD pipeline.

**Target Users:** DevOps engineers, release managers, and platform teams

**Core Value Proposition:** Provide visibility into deployment records and release status through an automated, containerized, Jenkins-driven CI/CD workflow.

**Success Metrics:**
- Automated testing with 100% passing rate
- Fully containerized and deployable via Jenkins
- AWS ECR integration for image registry
- Web UI accessible from EC2 deployment
- Health checks and operational metrics

---

## Product Backlog

### User Story Format
- **ID**: Story identifier (US-XX)
- **Title**: One-line summary
- **Priority**: High/Medium/Low
- **Estimate**: Fibonacci (1, 2, 3, 5, 8, 13)
- **Acceptance Criteria**: Testable conditions

---

### US-01: Express API Foundation
**Priority:** High | **Estimate:** 3 SP

As a developer, I want a minimal Express service foundation so that I have a deployable web API.

**Acceptance Criteria:**
- [ ] GET / returns 200 with service metadata JSON
- [ ] Service listens on PORT env var (default 3000)
- [ ] App starts with npm start
- [ ] Service includes basic health endpoint structure

**Delivered in:** Sprint 1 ✅

---

### US-02: Automated Testing
**Priority:** High | **Estimate:** 5 SP

As a developer, I want unit and integration tests so that regressions are caught before deployment.

**Acceptance Criteria:**
- [ ] npm test runs Jest suite
- [ ] At least 8 test cases covering success and error paths
- [ ] Test run exits non-zero on failure
- [ ] Tests run in CI pipeline automatically

**Delivered in:** Sprint 1 ✅

---

### US-03: Docker Containerization
**Priority:** High | **Estimate:** 3 SP

As a DevOps engineer, I want Docker image build capability so that deployments are environment-consistent.

**Acceptance Criteria:**
- [ ] Production-ready Dockerfile exists
- [ ] Image builds successfully with docker build
- [ ] Container runs and exposes app port
- [ ] Image size optimized for Alpine base

**Delivered in:** Sprint 1 ✅

---

### US-04: Jenkins CI/CD Pipeline
**Priority:** High | **Estimate:** 8 SP

As a DevOps engineer, I want an automated pipeline so that delivery is consistent and reproducible.

**Acceptance Criteria:**
- [ ] Jenkinsfile defines 7 stages: Checkout, Install/Build, Test, Resolve ECR, Docker Build, Push Image, Deploy
- [ ] Pipeline stops on build/test failure
- [ ] AWS credentials consumed from Jenkins store
- [ ] Docker agent used for Node.js stages
- [ ] Deployment health checks integrated

**Delivered in:** Sprint 1 ✅

---

### US-05: EC2 Deployment & Health Checks
**Priority:** High | **Estimate:** 5 SP

As an operator, I want automated EC2 deployment so that latest releases are accessible to end users.

**Acceptance Criteria:**
- [ ] Pipeline deploys to EC2 via SSH
- [ ] Old containers cleaned up before new deployment
- [ ] Health check verifies app accessibility after deploy
- [ ] App reachable via EC2 public IP post-deployment
- [ ] Deployment output includes accessible URL

**Delivered in:** Sprint 1/2 ✅

---

### US-06: Structured Logging & Monitoring
**Priority:** Medium | **Estimate:** 3 SP

As an operator, I want structured logging and metrics so that operational visibility is improved.

**Acceptance Criteria:**
- [ ] Request logs include method, path, status, duration
- [ ] GET /health endpoint returns uptime and status
- [ ] GET /metrics endpoint returns request and error counts
- [ ] Logs output JSON format for parsing

**Delivered in:** Sprint 2 ✅

---

### US-07: Web UI for Deployments
**Priority:** Medium | **Estimate:** 5 SP

As a user, I want a web UI so that I can visualize and manage deployments without API knowledge.

**Acceptance Criteria:**
- [ ] Web UI accessible at root path (/)
- [ ] Dashboard shows deployment summary
- [ ] Deployment list with status display
- [ ] Create and update deployment forms
- [ ] Responsive design (mobile-friendly)

**Delivered in:** Sprint 2 ✅

---

### US-08: Deployment Verification Automation
**Priority:** Medium | **Estimate:** 3 SP

As a developer, I want local verification script so that regressions are caught before push.

**Acceptance Criteria:**
- [ ] npm run verify:local runs complete local workflow
- [ ] Workflow includes: install, test, build, smoke test, cleanup
- [ ] Script exits non-zero on any failure
- [ ] Reusable across CI and local development

**Delivered in:** Sprint 2 ✅

---

## Definition of Done

A work item is considered **Done** when:

1. ✅ Code is committed to feature branch with clear commit message
2. ✅ Merged to main via pull request
3. ✅ All acceptance criteria are met and tested
4. ✅ Automated tests pass (both local and CI)
5. ✅ No critical lint/code quality issues
6. ✅ Documentation is updated (README, runbook, or inline comments)
7. ✅ Evidence is captured (test logs, screenshots)
8. ✅ Pipeline runs successfully (if applicable)
9. ✅ Deployment verified (if applicable)
10. ✅ Code review approved (peer or self-review documented)

