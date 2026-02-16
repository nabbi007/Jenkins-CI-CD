const express = require('express');

const app = express();
const startedAt = Date.now();

const metrics = {
  totalRequests: 0,
  totalErrors: 0
};

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

app.get('/', (req, res) => {
  res.status(200).json({
    service: 'jenkins-ci-cd-demo',
    version: '1.0.0',
    status: 'ok'
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    uptimeSeconds: Math.floor((Date.now() - startedAt) / 1000),
    timestamp: new Date().toISOString()
  });
});

app.get('/metrics', (req, res) => {
  res.status(200).json(metrics);
});

app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

module.exports = app;
