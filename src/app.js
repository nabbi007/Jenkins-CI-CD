const path = require('path');
const express = require('express');

const app = express();
const startedAt = Date.now();
const uiDir = path.join(__dirname, '..', 'public');

const metrics = {
  totalRequests: 0,
  totalErrors: 0
};

const allowedDeploymentStatuses = new Set([
  'pending',
  'running',
  'succeeded',
  'failed',
  'rolled_back'
]);

let deploymentIdCounter = 1002;
let deployments = [];

function buildSeedDeployments() {
  return [
    {
      id: 'dep-1001',
      serviceName: 'payments-api',
      version: '1.2.0',
      environment: 'staging',
      owner: 'platform-team',
      status: 'succeeded',
      notes: 'Seeded deployment record',
      startedAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
      updatedAt: new Date(Date.now() - 28 * 60 * 1000).toISOString(),
      completedAt: new Date(Date.now() - 28 * 60 * 1000).toISOString()
    }
  ];
}

function resetState() {
  deploymentIdCounter = 1002;
  deployments = buildSeedDeployments();
  metrics.totalRequests = 0;
  metrics.totalErrors = 0;
}

function parseJsonBody(req, res, next) {
  if (req.body && typeof req.body === 'object') {
    return next();
  }

  if (!['POST', 'PUT', 'PATCH'].includes(req.method)) {
    return next();
  }

  const contentType = req.headers['content-type'] || '';
  if (!contentType.includes('application/json')) {
    req.body = {};
    return next();
  }

  let rawBody = '';
  if (typeof req.setEncoding === 'function') {
    req.setEncoding('utf8');
  }

  req.on('data', (chunk) => {
    rawBody += chunk;
  });

  req.on('end', () => {
    if (!rawBody) {
      req.body = {};
      return next();
    }

    try {
      req.body = JSON.parse(rawBody);
      return next();
    } catch (error) {
      return res.status(400).json({ error: 'Invalid JSON payload' });
    }
  });

  return req.on('error', next);
}

function buildStatusSummary(records) {
  const summary = {};

  for (const status of allowedDeploymentStatuses) {
    summary[status] = 0;
  }

  for (const record of records) {
    if (!summary[record.status] && summary[record.status] !== 0) {
      summary[record.status] = 0;
    }

    summary[record.status] += 1;
  }

  return summary;
}

function buildEnvironmentOptions(records) {
  const environments = new Set(records.map((record) => record.environment));
  return Array.from(environments).sort();
}

function validateDeploymentPayload(payload) {
  const requiredFields = ['serviceName', 'version', 'environment', 'owner'];
  const missingFields = requiredFields.filter((field) => {
    const value = payload[field];
    return typeof value !== 'string' || !value.trim();
  });

  return missingFields;
}

resetState();

app.use((req, res, next) => {
  const start = process.hrtime.bigint();
  metrics.totalRequests += 1;

  res.on('finish', () => {
    const durationMs = Number(process.hrtime.bigint() - start) / 1e6;

    if (res.statusCode >= 400) {
      metrics.totalErrors += 1;
    }

    console.log(
      JSON.stringify({
        level: 'info',
        event: 'http_request',
        method: req.method,
        path: req.originalUrl,
        statusCode: res.statusCode,
        durationMs: Number(durationMs.toFixed(2))
      })
    );
  });

  next();
});

app.use(parseJsonBody);

app.get('/ui', (req, res) => {
  res.sendFile(path.join(uiDir, 'index.html'));
});
app.use('/ui', express.static(uiDir));

app.get('/', (req, res) => {
  res.status(200).json({
    service: 'devops-release-tracker',
    version: '2.0.0',
    status: 'ok',
    description: 'Tracks deployment records and release status for CI/CD workflows.',
    endpoints: [
      'GET /health',
      'GET /metrics',
      'GET /api/options',
      'GET /api/deployments',
      'POST /api/deployments',
      'PATCH /api/deployments/:id/status',
      'GET /api/dashboard',
      'GET /ui'
    ]
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    uptimeSeconds: Math.floor((Date.now() - startedAt) / 1000),
    timestamp: new Date().toISOString(),
    deploymentRecords: deployments.length
  });
});

app.get('/metrics', (req, res) => {
  res.status(200).json({
    ...metrics,
    trackedDeployments: deployments.length
  });
});

app.get('/api/options', (req, res) => {
  res.status(200).json({
    statuses: Array.from(allowedDeploymentStatuses),
    environments: buildEnvironmentOptions(deployments)
  });
});

app.get('/api/deployments', (req, res) => {
  const environmentFilter = req.query.environment;
  const statusFilter = req.query.status;

  const items = deployments.filter((record) => {
    const matchesEnvironment = environmentFilter ? record.environment === environmentFilter : true;
    const matchesStatus = statusFilter ? record.status === statusFilter : true;
    return matchesEnvironment && matchesStatus;
  });

  res.status(200).json({
    count: items.length,
    items
  });
});

app.get('/api/deployments/:id', (req, res) => {
  const deployment = deployments.find((record) => record.id === req.params.id);

  if (!deployment) {
    return res.status(404).json({ error: 'Deployment not found' });
  }

  return res.status(200).json(deployment);
});

app.post('/api/deployments', (req, res) => {
  const payload = req.body || {};
  const missingFields = validateDeploymentPayload(payload);

  if (missingFields.length > 0) {
    return res.status(400).json({
      error: 'Invalid deployment payload',
      missingFields
    });
  }

  const now = new Date().toISOString();
  const deployment = {
    id: `dep-${deploymentIdCounter}`,
    serviceName: payload.serviceName.trim(),
    version: payload.version.trim(),
    environment: payload.environment.trim(),
    owner: payload.owner.trim(),
    status: 'pending',
    notes: typeof payload.notes === 'string' ? payload.notes.trim() : '',
    startedAt: now,
    updatedAt: now,
    completedAt: null
  };

  deploymentIdCounter += 1;
  deployments.unshift(deployment);

  return res.status(201).json(deployment);
});

app.patch('/api/deployments/:id/status', (req, res) => {
  const deployment = deployments.find((record) => record.id === req.params.id);

  if (!deployment) {
    return res.status(404).json({ error: 'Deployment not found' });
  }

  const nextStatus = typeof req.body.status === 'string' ? req.body.status.trim().toLowerCase() : '';

  if (!allowedDeploymentStatuses.has(nextStatus)) {
    return res.status(400).json({
      error: 'Invalid deployment status',
      allowedStatuses: Array.from(allowedDeploymentStatuses)
    });
  }

  deployment.status = nextStatus;
  deployment.updatedAt = new Date().toISOString();
  deployment.notes = typeof req.body.notes === 'string' ? req.body.notes.trim() : deployment.notes;

  if (['succeeded', 'failed', 'rolled_back'].includes(nextStatus)) {
    deployment.completedAt = deployment.updatedAt;
  } else {
    deployment.completedAt = null;
  }

  return res.status(200).json(deployment);
});

app.get('/api/dashboard', (req, res) => {
  res.status(200).json({
    status: 'ok',
    generatedAt: new Date().toISOString(),
    summary: {
      deploymentCount: deployments.length,
      latestDeploymentId: deployments[0] ? deployments[0].id : null,
      totalRequests: metrics.totalRequests,
      totalErrors: metrics.totalErrors
    },
    deploymentsByStatus: buildStatusSummary(deployments),
    recentDeployments: deployments.slice(0, 5)
  });
});

app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

app.resetState = resetState;

module.exports = app;
