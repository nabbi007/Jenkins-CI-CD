# Sprint 1: Foundation & CI/CD Baseline

## Sprint Goal

Deliver the first working software increment with API endpoints, automated testing, and establish CI/CD automation baseline.

## Sprint Duration

**Dates:** Week 1 (6 working days)  
**Capacity:** 30 story points

---

## Planned Stories

| Story ID | Title | Estimate | Status |
|----------|-------|----------|--------|
| US-01 | Express API Foundation | 3 SP | ✅ Done |
| US-02 | Automated Testing | 5 SP | ✅ Done |
| US-03 | Docker Containerization | 3 SP | ✅ Done |
| US-04 | Jenkins CI/CD Pipeline | 8 SP | ✅ Done |

**Total Planned:** 19 SP

---

## Unplanned Work (Stretch Goals)

| Story ID | Title | Estimate | Status |
|----------|-------|----------|--------|
| US-05 | EC2 Deployment | 5 SP | ✅ Done |

**Total Unplanned:** 5 SP

---

## Sprint Capacity Summary

| Metric | Value |
|--------|-------|
| **Planned Estimate** | 19 SP |
| **Delivered Estimate** | 24 SP |
| **Planned + Stretch** | 24 SP |
| **Velocity** | 24 SP |
| **Sprint Goal** | ✅ Achieved |

---

## Key Deliverables

### 1. Express Application (US-01)
- ✅ GET / endpoint (returns service metadata)
- ✅ GET /health endpoint (returns status)
- ✅ GET /metrics endpoint (returns metrics)
- ✅ POST /api/deployments (create records)
- ✅ GET /api/deployments (list records)
- ✅ PATCH /api/deployments/:id/status (update status)
- ✅ GET /api/dashboard (summary dashboard)

### 2. Automated Testing (US-02)
- ✅ Jest test framework integration
- ✅ 8 test cases (100% pass rate)
- ✅ Route coverage (success, error, edge cases)
- ✅ npm test command in CI pipeline

**Test Results Screenshot:** `initial_test.png`

### 3. Docker Packaging (US-03)
- ✅ Multi-stage Dockerfile
- ✅ Alpine base image (minimal size)
- ✅ npm dependencies installed
- ✅ Application copied and configured
- ✅ Port 3000 exposed
- ✅ .dockerignore for optimization

### 4. Jenkins Pipeline (US-04)
- ✅ 7-stage Jenkinsfile created
- ✅ Checkout → Install/Build → Test → Docker Build → Push → Deploy
- ✅ Docker agent for Node.js stages
- ✅ AWS credential handling
- ✅ ECR integration
- ✅ Health check verification

**Pipeline Screenshot:** `first_successful_build.png`

### 5. EC2 Deployment (US-05 - Stretch)
- ✅ Terraform infrastructure code
- ✅ Security group configuration
- ✅ SSH-based deployment script
- ✅ Container lifecycle management
- ✅ URL output at end of pipeline

---

## Daily Standup Summary

### Day 1: Project Setup & Planning
- Set up repository structure
- Defined product vision and backlog
- Created initial application skeleton
- Estimated all stories

### Days 2-3: Express Application & Tests
- Implemented all API endpoints
- Created Jest test suite (8 test cases)
- All tests passing locally
- Documented API contracts

### Day 4: Containerization & CI/CD
- Created production Dockerfile
- Set up Jenkinsfile with 7 stages
- Configured Docker agents
- Integrated AWS ECR credentials

### Days 5-6: Deployment & Polish
- Created Terraform infrastructure
- Automated EC2 deployment
- Added health check verification
- Fixed Docker and npm caching issues
- Final testing and documentation

---

## Risks & Mitigations

| Risk | Mitigation | Outcome |
|------|-----------|---------|
| npm cache permission errors | Set NPM_CONFIG_CACHE env var | ✅ Resolved |
| Missing Docker agent | Added Docker agent config to pipeline | ✅ Resolved |
| Missing public directory | Added COPY public to Dockerfile | ✅ Resolved (Sprint 2) |
| AWS credential expiration | Used session token support | ✅ Resolved (Sprint 3) |

---

## Lessons Learned

✅ **What Went Well:**
- Small incremental commits kept progress visible
- Early testing integration reduced uncertainty
- Clear acceptance criteria made definition of done objective

⚠️ **Challenges:**
- Docker caching with npm required environment variable fixes
- Infrastructure setup more complex than initial estimate
- AWS credential handling required multiple iterations

💡 **Improvements for Sprint 2:**
- Add structured logging for operational visibility
- Create web UI for better user experience
- Add local verification script

---

## Evidence & Artifacts

- **Test Output:** `docs/evidence/sprint-1-test.log`
- **Docker Build:** `docs/evidence/sprint-1-docker-build.log`
- **Smoke Test:** `docs/evidence/sprint-1-local-smoke.json`
- **Pipeline Success:** `docs/evidence/sprint-1-pipeline-success-simulated.log`
- **Pipeline Failure (simulated):** `docs/evidence/sprint-1-pipeline-failure-simulated.log`

---

## Sprint Retrospective Notes

See: `docs/sprint-1/retrospective.md`

---

## Next Sprint Preview

Sprint 2 will focus on:
- Adding structured logging and monitoring endpoints (US-06)
- Building web UI for deployment management (US-07)
- Creating verification automation script (US-08)
- Improving operational visibility and user experience

---

*Sprint 1 completed successfully on Day 6*
