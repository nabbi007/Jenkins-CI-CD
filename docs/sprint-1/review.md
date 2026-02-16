# Sprint 1 Review

## Increment Delivered

1. Working Express API service:
   - `GET /` returns metadata JSON.
2. Automated tests:
   - Jest-based route tests for success and not-found paths.
3. Containerization:
   - Production `Dockerfile` and `.dockerignore` included.
4. CI/CD automation baseline:
   - `Jenkinsfile` with required stages.
   - `scripts/deploy-ec2.sh` for SSH deployment and cleanup.

## Evidence

- Test output: `docs/evidence/sprint-1-test.log`
- Docker build output: `docs/evidence/sprint-1-docker-build.log`
- Local container smoke response: `docs/evidence/sprint-1-local-smoke.json`
- Simulated successful Jenkins run log: `docs/evidence/sprint-1-pipeline-success-simulated.log`
- Simulated failed Jenkins run log: `docs/evidence/sprint-1-pipeline-failure-simulated.log`

## Demo Notes

- `npm test` passes all suites.
- Docker image builds successfully.
- Containerized app returns expected JSON from `/`.
- Jenkins pipeline file includes checkout/build/test/build-image/push/deploy sequence.
