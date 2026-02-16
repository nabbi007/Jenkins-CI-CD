# Sprint 2 Review

## Sprint Goal Outcome

Sprint goal met: operational reliability and observability were improved while delivering the next increment.

## Delivered Stories

| Story ID | Title | Status |
|---|---|---|
| US-05 | Harden EC2 deployment and post-deploy verification | Done |
| US-06 | Add health/monitoring endpoint and structured logging | Done |
| US-07 | Improve repeatability with verification automation and updated evidence docs | Done |

## Demonstrated Improvements from Sprint 1 Retro

1. Structured logging and runtime monitoring added:
   - Request logs now include method, path, status code, and duration.
   - New `GET /health` and `GET /metrics` endpoints.
2. Reusable verification workflow added:
   - `npm run verify:local` performs test/build/smoke/cleanup steps consistently.

## Evidence

- Sprint 2 test output: `docs/evidence/sprint-2-test.log`
- Verification workflow log: `docs/evidence/sprint-2-verify-local.log`
- Simulated successful pipeline run: `docs/evidence/sprint-2-pipeline-success-simulated.log`
- Monitoring health response: `docs/evidence/sprint-2-health-check.json`
- Monitoring metrics response: `docs/evidence/sprint-2-metrics-check.json`
