# Jenkins CI/CD Project

This repository contains a two-sprint Agile + DevOps simulation centered on a real Node.js application and Jenkins-based CI/CD delivery.

## App: DevOps Release Tracker

The app is an Express API for tracking deployment records and release state, designed to be built/tested/containerized/deployed through Jenkins.

Core endpoints:

- `GET /` - app metadata and API map
- `GET /health` - runtime health and uptime
- `GET /metrics` - request/error counters
- `GET /api/deployments` - list deployment records
- `POST /api/deployments` - create deployment record
- `PATCH /api/deployments/:id/status` - update deployment state
- `GET /api/dashboard` - deployment and operational summary

## Local Run

```bash
npm ci
npm test
npm start
```

## DevOps Flow

- CI/CD pipeline: `Jenkinsfile`
- Docker image build: `Dockerfile`
- Deploy to EC2 over SSH: `scripts/deploy-ec2.sh`
- Local pre-merge verification: `scripts/verify-local.sh`
