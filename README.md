# DevOps Release Tracker - Jenkins CI/CD Pipeline

Two-sprint Agile + DevOps project: Node.js Express app with Jenkins pipeline, Docker containerization, AWS EC2 deployment, and comprehensive testing.

## 📋 **Submission Guide** → [SUBMISSION.md](SUBMISSION.md)

**For reviewers:** Start here for the 6 required artifacts mapped to the grading rubric (Agile, DevOps, Delivery, Prototype, Reflection).

---

## Quick Links to Required Artifacts

| Rubric Dimension | Weight | Artifact |
|---|---|---|
| **Agile Practice** | 25% | [Backlog & Sprint Plans](docs/PLANNING.md), [Sprint 1](docs/SPRINT1_PLAN.md), [Sprint 2](docs/SPRINT2_PLAN.md) |
| **DevOps Practice** | 25% | [CI/CD Configuration](docs/CICD.md), [Testing Evidence](docs/TESTING.md) |
| **Delivery Discipline** | 20% | [Git Commit History](https://github.com/nabbi007/Jenkins-CI-CD/commits/main) (64 commits) |
| **Prototype Quality** | 20% | [Live App](http://54.74.21.91:80), [Tests: 10/10 passing](docs/TESTING.md) |
| **Reflection** | 10% | [Sprint Reviews](docs/REVIEWS.md), [Retrospectives](docs/RETROSPECTIVES.md) |

---

## 🚀 Live Deployment

- **App URL:** http://54.74.21.91:80
- **Health Check:** http://54.74.21.91:80/health
- **Test Status:** ✅ 10/10 passing

## 🔧 Local Development

```bash
npm ci           # Install dependencies
npm test         # Run tests (10 cases, 100% pass)
npm start        # Start on http://localhost:3000
```

## 📦 Project Structure

```
├── SUBMISSION.md           # ← Start here for grading
├── Jenkinsfile             # CI/CD pipeline (7 stages)
├── package.json            # Dependencies (Express, Jest)
├── src/app.js              # Express API (307 LOC)
├── test/app.test.js        # Tests (10 cases)
├── public/                 # Web UI (HTML/CSS/JS)
├── docs/                   # Required submission artifacts
│   ├── PLANNING.md         # Product backlog
│   ├── SPRINT1_PLAN.md     # Sprint 1 execution
│   ├── SPRINT2_PLAN.md     # Sprint 2 execution
│   ├── CICD.md             # Pipeline evidence
│   ├── TESTING.md          # Test results
│   ├── REVIEWS.md          # Sprint reviews
│   └── RETROSPECTIVES.md   # Lessons learned
└── infra/terraform/        # AWS infrastructure as code
```

---

## Key Metrics

- **Total Commits:** 64 (incremental development)
- **Test Coverage:** 10 Jest test cases, 100% passing
- **Pipeline:** 7 stages (Checkout → Install → Build → Test → ECR → Docker → Deploy)
- **Infrastructure:** AWS EC2 t3.micro + ECR in eu-west-1
- **App Endpoints:** 10 RESTful endpoints with health/metrics
- **Sprints:** 2 completed with reviews and retrospectives
