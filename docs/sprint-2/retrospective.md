# Sprint 2 Final Retrospective

## Improvements Achieved

1. Delivery confidence improved with a reusable local verification script before merge.
2. Post-deploy confidence improved through health endpoint checks and deployment script verification.
3. Runtime transparency improved through structured request logging and metrics reporting.

## Key Lessons Learned

1. Defining evidence artifacts early prevents gaps at submission time.
2. Small, mergeable feature branches create better traceability than large one-shot commits.
3. Health checks should be treated as a release gate, not just an observability convenience.

## Next Iteration Opportunities

1. Add automated rollback on failed deploy health checks.
2. Publish metrics to an external monitoring backend (e.g., CloudWatch, Prometheus).
3. Add branch protection and mandatory Jenkins status checks before merge.
