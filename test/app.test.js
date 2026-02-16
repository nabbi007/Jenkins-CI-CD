const { EventEmitter } = require('events');
const { createRequest, createResponse } = require('node-mocks-http');

const app = require('../src/app');

function executeRequest(req, res) {
  return new Promise((resolve) => {
    res.on('end', resolve);
    app(req, res);
  });
}

describe('Express service', () => {
  it('returns metadata on GET /', async () => {
    const req = createRequest({ method: 'GET', url: '/' });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(200);
    expect(res._getJSONData()).toMatchObject({
      service: 'jenkins-ci-cd-demo',
      status: 'ok'
    });
  });

  it('returns healthy status data on GET /health', async () => {
    const req = createRequest({ method: 'GET', url: '/health' });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(200);

    const payload = res._getJSONData();
    expect(payload.status).toBe('ok');
    expect(typeof payload.uptimeSeconds).toBe('number');
    expect(typeof payload.timestamp).toBe('string');
  });

  it('returns metrics on GET /metrics', async () => {
    const req = createRequest({ method: 'GET', url: '/metrics' });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(200);

    const payload = res._getJSONData();
    expect(payload).toHaveProperty('totalRequests');
    expect(payload).toHaveProperty('totalErrors');
  });

  it('returns 404 on unknown routes', async () => {
    const req = createRequest({ method: 'GET', url: '/does-not-exist' });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(404);
    expect(res._getJSONData()).toEqual({ error: 'Not Found' });
  });
});
