# Sprint 1 Retrospective

## What Went Well

1. Small feature branches with merge commits kept delivery traceable.
2. Early test integration reduced uncertainty during Docker and pipeline work.
3. Runbook captured infrastructure assumptions before deployment scripting.

## What Did Not Go Well

1. Initial test tooling required adjustment for restricted runtime environments.
2. Evidence generation steps were initially manual and inconsistent.

## Improvements for Sprint 2

1. Add structured request logging and health/metrics endpoint to improve operational visibility.
2. Add reusable local verification script to standardize pre-merge checks (test + build + smoke).
