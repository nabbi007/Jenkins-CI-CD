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
    const res = createResponse({ eventEmitter: require('events').EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(200);
    expect(res._getJSONData()).toMatchObject({
      service: 'jenkins-ci-cd-demo',
      status: 'ok'
    });
  });

  it('returns 404 on unknown routes', async () => {
    const req = createRequest({ method: 'GET', url: '/does-not-exist' });
    const res = createResponse({ eventEmitter: require('events').EventEmitter });

    await executeRequest(req, res);

    expect(res.statusCode).toBe(404);
    expect(res._getJSONData()).toEqual({ error: 'Not Found' });
  });
});
