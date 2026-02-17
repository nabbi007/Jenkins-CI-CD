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
  beforeEach(() => {
    app.resetState();
  });

  it('serves the web interface at GET /', async () => {
    const req = createRequest({ method: 'GET', url: '/' });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(200);
    expect(String(res.getHeader('content-type'))).toContain('text/html');
  });

  it('returns metadata on GET /api/info', async () => {
    const req = createRequest({ method: 'GET', url: '/api/info' });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(200);
    expect(res._getJSONData()).toMatchObject({
      service: 'devops-release-tracker',
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
    expect(payload.deploymentRecords).toBeGreaterThan(0);
  });

  it('returns metrics on GET /metrics', async () => {
    const req = createRequest({ method: 'GET', url: '/metrics' });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(200);

    const payload = res._getJSONData();
    expect(payload).toHaveProperty('totalRequests');
    expect(payload).toHaveProperty('totalErrors');
    expect(payload).toHaveProperty('trackedDeployments');
  });

  it('returns backend options for UI on GET /api/options', async () => {
    const req = createRequest({ method: 'GET', url: '/api/options' });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(200);
    const payload = res._getJSONData();
    expect(payload.statuses).toEqual(
      expect.arrayContaining(['pending', 'running', 'succeeded', 'failed', 'rolled_back'])
    );
    expect(payload.environments).toEqual(expect.arrayContaining(['staging']));
  });

  it('creates and lists deployment records', async () => {
    const createReq = createRequest({
      method: 'POST',
      url: '/api/deployments',
      headers: { 'content-type': 'application/json' },
      body: {
        serviceName: 'orders-api',
        version: '3.4.1',
        environment: 'production',
        owner: 'release-team',
        notes: 'Canary rollout'
      }
    });
    const createRes = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(createReq, createRes);

    expect(createRes.statusCode).toBe(201);

    const createdDeployment = createRes._getJSONData();
    expect(createdDeployment.id).toMatch(/^dep-\d+$/);
    expect(createdDeployment.status).toBe('pending');
    expect(createdDeployment.serviceName).toBe('orders-api');

    const listReq = createRequest({ method: 'GET', url: '/api/deployments' });
    const listRes = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(listReq, listRes);

    expect(listRes.statusCode).toBe(200);
    const listPayload = listRes._getJSONData();
    expect(listPayload.count).toBeGreaterThanOrEqual(2);
    expect(listPayload.items[0].id).toBe(createdDeployment.id);
  });

  it('rejects invalid deployment payload', async () => {
    const req = createRequest({
      method: 'POST',
      url: '/api/deployments',
      headers: { 'content-type': 'application/json' },
      body: {
        version: '3.4.1',
        owner: 'release-team'
      }
    });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(400);
    const payload = res._getJSONData();
    expect(payload.error).toBe('Invalid deployment payload');
    expect(payload.missingFields).toEqual(
      expect.arrayContaining(['serviceName', 'environment'])
    );
  });

  it('updates deployment status', async () => {
    const createReq = createRequest({
      method: 'POST',
      url: '/api/deployments',
      headers: { 'content-type': 'application/json' },
      body: {
        serviceName: 'inventory-api',
        version: '5.0.0',
        environment: 'production',
        owner: 'devops-team'
      }
    });
    const createRes = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(createReq, createRes);
    const createdDeployment = createRes._getJSONData();

    const patchReq = createRequest({
      method: 'PATCH',
      url: `/api/deployments/${createdDeployment.id}/status`,
      headers: { 'content-type': 'application/json' },
      body: {
        status: 'succeeded',
        notes: 'Deployment passed smoke checks'
      }
    });
    const patchRes = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(patchReq, patchRes);

    expect(patchRes.statusCode).toBe(200);
    const payload = patchRes._getJSONData();
    expect(payload.status).toBe('succeeded');
    expect(payload.notes).toBe('Deployment passed smoke checks');
    expect(payload.completedAt).not.toBeNull();
  });

  it('returns dashboard summary', async () => {
    const req = createRequest({ method: 'GET', url: '/api/dashboard' });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(200);
    const payload = res._getJSONData();
    expect(payload.status).toBe('ok');
    expect(payload.summary).toHaveProperty('deploymentCount');
    expect(payload.summary).toHaveProperty('totalRequests');
    expect(payload).toHaveProperty('deploymentsByStatus');
  });

  it('returns 404 on unknown routes', async () => {
    const req = createRequest({ method: 'GET', url: '/does-not-exist' });
    const res = createResponse({ eventEmitter: EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(404);
    expect(res._getJSONData()).toEqual({ error: 'Not Found' });
  });
});
