const express = require('express');

const app = express();

app.get('/', (req, res) => {
  res.status(200).json({
    service: 'jenkins-ci-cd-demo',
    version: '1.0.0',
    status: 'ok'
  });
});

app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

module.exports = app;
