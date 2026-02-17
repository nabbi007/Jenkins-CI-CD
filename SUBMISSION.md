# Agile & DevOps Submission

**Project:** DevOps Release Tracker  
**Date:** February 17, 2026  
**Repository:** [github.com/nabbi007/Jenkins-CI-CD](https://github.com/nabbi007/Jenkins-CI-CD)  
**Live App:** http://54.74.21.91:80

---

## Grading Compliance Summary

| Dimension | Weight | Status | Evidence |
|-----------|--------|--------|----------|
| Agile Practice | 25% | ✅ | Backlog, AC, Sprint Plans |
| DevOps Practice | 25% | ✅ | Jenkins Pipeline, Tests |
| Delivery Discipline | 20% | ✅ | 65 incremental commits |
| Prototype Quality | 20% | ✅ | Live app, 10/10 tests |
| Reflection | 10% | ✅ | Retrospectives |

---

## 1. Agile Practice (25%)

### 1.1 Product Backlog

**8 User Stories** with consistent acceptance criteria:

| ID | Story | Points | Priority |
|----|-------|--------|----------|
| US-01 | Express API Foundation | 3 | High |
| US-02 | Automated Testing | 5 | High |
| US-03 | Docker Containerization | 3 | High |
| US-04 | Jenkins CI/CD Pipeline | 8 | High |
| US-05 | EC2 Deployment | 5 | High |
| US-06 | Logging & Monitoring | 3 | Medium |
| US-07 | Web UI Dashboard | 5 | Medium |
| US-08 | Verification Scripts | 3 | Medium |

**Total:** 35 Story Points

---

### 1.2 User Stories (Full Format)

#### US-01: Express API Foundation
**As a** developer  
**I want** a minimal Express service  
**So that** I have a deployable web API

**Acceptance Criteria:**
- [ ] GET / returns 200 with JSON metadata
- [ ] Service listens on PORT (default 3000)
- [ ] App starts with `npm start`
- [ ] Health endpoint returns status

**Status:** ✅ Done (Sprint 1)

---

#### US-02: Automated Testing
**As a** developer  
**I want** unit and integration tests  
**So that** regressions are caught early

**Acceptance Criteria:**
- [ ] `npm test` runs Jest suite
- [ ] Minimum 8 test cases
- [ ] Tests exit non-zero on failure
- [ ] Tests run automatically in CI

**Status:** ✅ Done (Sprint 1)

---

#### US-03: Docker Containerization
**As a** DevOps engineer  
**I want** Docker image builds  
**So that** deployments are consistent

**Acceptance Criteria:**
- [ ] Dockerfile exists
- [ ] `docker build` succeeds
- [ ] Container exposes app port
- [ ] Alpine base for small image

**Status:** ✅ Done (Sprint 1)

---

#### US-04: Jenkins CI/CD Pipeline
**As a** DevOps engineer  
**I want** an automated pipeline  
**So that** delivery is reproducible

**Acceptance Criteria:**
- [ ] Jenkinsfile with 7 stages
- [ ] Pipeline stops on failure
- [ ] AWS credentials from Jenkins store
- [ ] Docker agent for Node stages
- [ ] Health checks after deploy

**Status:** ✅ Done (Sprint 1)

---

#### US-05: EC2 Deployment
**As an** operator  
**I want** automated EC2 deployment  
**So that** users access latest releases

**Acceptance Criteria:**
- [ ] Pipeline deploys via SSH
- [ ] Old containers cleaned up
- [ ] Health check verifies app
- [ ] Public IP accessible
- [ ] URL printed in output

**Status:** ✅ Done (Sprint 1/2)

---

#### US-06: Logging & Monitoring
**As an** operator  
**I want** structured logging  
**So that** issues are visible

**Acceptance Criteria:**
- [ ] Logs include method, path, status
- [ ] GET /health returns uptime
- [ ] GET /metrics returns counters
- [ ] JSON format for parsing

**Status:** ✅ Done (Sprint 2)

---

#### US-07: Web UI Dashboard
**As a** user  
**I want** a web interface  
**So that** I can manage deployments visually

**Acceptance Criteria:**
- [ ] UI at root path (/)
- [ ] Dashboard shows summary
- [ ] Deployment list with status
- [ ] Create/update forms
- [ ] Responsive design

**Status:** ✅ Done (Sprint 2)

---

#### US-08: Verification Scripts
**As a** developer  
**I want** local verification  
**So that** regressions are caught pre-push

**Acceptance Criteria:**
- [ ] `npm run verify:local` runs workflow
- [ ] Includes install, test, build, smoke
- [ ] Exits non-zero on failure
- [ ] Works in CI and local

**Status:** ✅ Done (Sprint 2)

---

### 1.3 Definition of Done

A story is **Done** when:

1. ✅ Code committed with clear message
2. ✅ Merged to main branch
3. ✅ All acceptance criteria met
4. ✅ Tests pass (local + CI)
5. ✅ Documentation updated
6. ✅ Pipeline runs successfully
7. ✅ Deployment verified

---

### 1.4 Sprint Planning

#### Sprint 1 (Feb 10-14)
- **Goal:** Core API + CI/CD pipeline
- **Capacity:** 24 SP
- **Committed:** US-01 to US-05 (24 SP)
- **Delivered:** 24 SP (100%)

#### Sprint 2 (Feb 15-17)
- **Goal:** UI + Monitoring + Polish
- **Capacity:** 20 SP
- **Committed:** US-06 to US-08 (11 SP)
- **Delivered:** 11 SP (100%)

---

## 2. DevOps Practice (25%)

### 2.1 CI/CD Pipeline

**7-Stage Jenkins Pipeline:**

```
1. Checkout        → Clone repository
2. Install/Build   → npm ci (Docker agent)
3. Test            → npm test (10 cases)
4. Resolve ECR     → AWS credential check
5. Docker Build    → Build image
6. Push to ECR     → Push to registry
7. Deploy          → SSH to EC2 + health check
```

**Key Features:**
- Docker agent: `node:18-alpine`
- AWS session token support
- Health check verification
- URL output on success

---

### 2.2 Pipeline Screenshots

| Screenshot | Description |
|------------|-------------|
| ![First Build](first_successful_build.png) | Sprint 1 pipeline success |
| ![Final Pipeline](final_pipeline.png) | Sprint 2 final pipeline |

---

### 2.3 Test Integration

**10 Test Cases (100% pass):**

| Test | Endpoint | Status |
|------|----------|--------|
| 1 | GET / (UI) | ✅ |
| 2 | GET /health | ✅ |
| 3 | GET /metrics | ✅ |
| 4 | GET /api/info | ✅ |
| 5 | GET /api/options | ✅ |
| 6 | GET /api/deployments | ✅ |
| 7 | POST /api/deployments | ✅ |
| 8 | PATCH /api/deployments/:id | ✅ |
| 9 | GET /api/dashboard | ✅ |
| 10 | 404 handling | ✅ |

**Test Screenshots:**

| Screenshot | Description |
|------------|-------------|
| ![Initial Tests](initial_test.png) | Sprint 1 (8 tests) |
| ![Final Tests](final_test.png) | Sprint 2 (10 tests) |

---

### 2.4 Monitoring

- **Health:** `GET /health` → uptime, status
- **Metrics:** `GET /metrics` → request counts
- **Logging:** JSON format with timestamps

---

## 3. Delivery Discipline (20%)

### 3.1 Commit History

```bash
$ git rev-list --count HEAD
65 commits (exceeds 25+ requirement)
```

### 3.2 Commit Pattern

**Incremental commits throughout:**

```
955a914 docs(readme): update submission guide
773ce30 refactor: remove unnecessary docs
359aad0 fix: update asset paths
3faaa4e fix: include public in Docker
4453c5c feat: serve UI at root path
03aff0d feat: ui integration
85cafc1 feat: output app URL
0fa6407 ci: add AWS session token
df61340 fix: npm cache permissions
...
```

**Commit Types:**
- `feat:` New features
- `fix:` Bug fixes
- `ci:` Pipeline updates
- `docs:` Documentation
- `refactor:` Code cleanup
- `test:` Test additions

**NOT seen:**
- ❌ Big-bang commits
- ❌ Bundled changes
- ❌ Vague messages

---

## 4. Prototype Quality (20%)

### 4.1 Working Application

| Metric | Value |
|--------|-------|
| **URL** | http://54.74.21.91:80 |
| **Health** | http://54.74.21.91:80/health |
| **Status** | ✅ Running |
| **Tests** | 10/10 passing |

### 4.2 Acceptance Criteria Met

All 8 user stories:
- ✅ US-01: API Foundation
- ✅ US-02: Automated Testing
- ✅ US-03: Docker Container
- ✅ US-04: Jenkins Pipeline
- ✅ US-05: EC2 Deployment
- ✅ US-06: Logging/Monitoring
- ✅ US-07: Web UI Dashboard
- ✅ US-08: Verification Scripts

---

## 5. Reflection (10%)

### 5.1 Sprint 1 Retrospective

**What Went Well:**
- Pipeline base established quickly
- Docker Alpine efficient
- Test-first caught issues early

**Challenges:**
- npm cache EACCES error
- Docker agent unavailable

**Improvements Applied:**
- Added `NPM_CONFIG_CACHE` env var
- Switched to `node:18-alpine` agent

---

### 5.2 Sprint 2 Retrospective

**What Went Well:**
- UI integration smooth
- Health checks reliable
- Infrastructure scaled well

**Challenges:**
- UI routing at /ui not ideal
- Public dir missing in Docker

**Improvements Applied:**
- Refactored to serve UI at /
- Added `COPY public ./public`
- Fixed asset paths in HTML

**Lessons Learned:**
- Plan asset paths early
- Health checks prevent silent failures
- Structured logging aids debugging

---

## 6. Project Structure

```
Jenkins_CI-CD/
├── SUBMISSION.md        ← This document
├── Jenkinsfile          ← CI/CD (7 stages)
├── Dockerfile           ← Container config
├── package.json         ← Dependencies
├── src/
│   ├── app.js           ← Express API (307 LOC)
│   └── server.js        ← Server startup
├── test/
│   └── app.test.js      ← Jest tests (10 cases)
├── public/
│   ├── index.html       ← Web UI
│   ├── app.js           ← Frontend JS
│   └── styles.css       ← Styling
├── docs/
│   ├── PLANNING.md      ← Backlog details
│   ├── SPRINT1_PLAN.md  ← Sprint 1
│   ├── SPRINT2_PLAN.md  ← Sprint 2
│   ├── CICD.md          ← Pipeline docs
│   ├── TESTING.md       ← Test evidence
│   ├── REVIEWS.md       ← Sprint reviews
│   └── RETROSPECTIVES.md← Lessons learned
└── infra/terraform/     ← AWS IaC
```

---

## 7. Evidence Summary

| Artifact | Location |
|----------|----------|
| Product Backlog | [docs/PLANNING.md](docs/PLANNING.md) |
| Sprint 1 Plan | [docs/SPRINT1_PLAN.md](docs/SPRINT1_PLAN.md) |
| Sprint 2 Plan | [docs/SPRINT2_PLAN.md](docs/SPRINT2_PLAN.md) |
| CI/CD Config | [Jenkinsfile](Jenkinsfile) |
| Test Suite | [test/app.test.js](test/app.test.js) |
| Pipeline Evidence | [docs/CICD.md](docs/CICD.md) |
| Test Evidence | [docs/TESTING.md](docs/TESTING.md) |
| Sprint Reviews | [docs/REVIEWS.md](docs/REVIEWS.md) |
| Retrospectives | [docs/RETROSPECTIVES.md](docs/RETROSPECTIVES.md) |

---

## 8. Final Checklist

- [x] Backlog with 8 prioritized stories
- [x] Acceptance criteria for ALL stories
- [x] Sprint plans aligned with backlog
- [x] Definition of Done documented
- [x] CI/CD pipeline working (7 stages)
- [x] Tests integrated (10/10 passing)
- [x] Health/metrics monitoring
- [x] Incremental commits (65 total)
- [x] Working prototype deployed
- [x] Retrospectives with improvements

**Status:** ✅ Ready for Grading
