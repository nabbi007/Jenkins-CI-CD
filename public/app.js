const elements = {
  deployments: document.getElementById('stat-deployments'),
  requests: document.getElementById('stat-requests'),
  errors: document.getElementById('stat-errors'),
  deploymentsBody: document.getElementById('deployments-body'),
  refreshBtn: document.getElementById('refresh-btn'),
  toast: document.getElementById('toast'),
  createForm: document.getElementById('create-form'),
  statusForm: document.getElementById('status-form'),
  statusId: document.getElementById('status-id'),
  statusSelect: document.getElementById('status-select'),
  environmentOptions: document.getElementById('environment-options')
};

const state = {
  statuses: [],
  environments: [],
  deployments: []
};

function showToast(message, type = 'ok') {
  elements.toast.textContent = message;
  elements.toast.className = '';
  elements.toast.classList.add('show', type);
  window.clearTimeout(showToast.timeoutId);
  showToast.timeoutId = window.setTimeout(() => {
    elements.toast.className = '';
  }, 2300);
}

async function fetchJson(url, options = {}) {
  const response = await fetch(url, options);
  const payload = await response.json().catch(() => ({}));

  if (!response.ok) {
    const reason = payload.error || `Request failed (${response.status})`;
    throw new Error(reason);
  }

  return payload;
}

function renderStatusOptions() {
  elements.statusSelect.innerHTML = '';

  state.statuses.forEach((status) => {
    const option = document.createElement('option');
    option.value = status;
    option.textContent = status;
    elements.statusSelect.appendChild(option);
  });
}

function renderEnvironmentOptions() {
  elements.environmentOptions.innerHTML = '';

  state.environments.forEach((environment) => {
    const option = document.createElement('option');
    option.value = environment;
    elements.environmentOptions.appendChild(option);
  });
}

function renderStats(dashboard) {
  elements.deployments.textContent = String(dashboard.summary.deploymentCount || 0);
  elements.requests.textContent = String(dashboard.summary.totalRequests || 0);
  elements.errors.textContent = String(dashboard.summary.totalErrors || 0);
}

function createCell(text) {
  const td = document.createElement('td');
  td.textContent = text;
  return td;
}

function renderDeployments() {
  const tbody = elements.deploymentsBody;
  tbody.innerHTML = '';

  if (state.deployments.length === 0) {
    const emptyRow = document.createElement('tr');
    const td = document.createElement('td');
    td.colSpan = 7;
    td.textContent = 'No deployments found.';
    emptyRow.appendChild(td);
    tbody.appendChild(emptyRow);
    return;
  }

  state.deployments.forEach((deployment) => {
    const tr = document.createElement('tr');
    tr.appendChild(createCell(deployment.id));
    tr.appendChild(createCell(deployment.serviceName));
    tr.appendChild(createCell(deployment.version));
    tr.appendChild(createCell(deployment.environment));

    const statusTd = document.createElement('td');
    const statusChip = document.createElement('span');
    statusChip.className = `status-chip status-${String(deployment.status).replace('-', '_')}`;
    statusChip.textContent = deployment.status;
    statusTd.appendChild(statusChip);
    tr.appendChild(statusTd);

    tr.appendChild(createCell(deployment.owner));

    const actionTd = document.createElement('td');
    const useIdBtn = document.createElement('button');
    useIdBtn.type = 'button';
    useIdBtn.className = 'use-id-btn';
    useIdBtn.dataset.id = deployment.id;
    useIdBtn.textContent = 'Use ID';
    actionTd.appendChild(useIdBtn);
    tr.appendChild(actionTd);

    tbody.appendChild(tr);
  });
}

async function loadState() {
  const [options, dashboard, deployments] = await Promise.all([
    fetchJson('/api/options'),
    fetchJson('/api/dashboard'),
    fetchJson('/api/deployments')
  ]);

  state.statuses = options.statuses || [];
  state.environments = options.environments || [];
  state.deployments = deployments.items || [];

  renderStatusOptions();
  renderEnvironmentOptions();
  renderStats(dashboard);
  renderDeployments();
}

async function onCreateSubmit(event) {
  event.preventDefault();
  const formData = new FormData(elements.createForm);

  const payload = {
    serviceName: String(formData.get('serviceName') || '').trim(),
    version: String(formData.get('version') || '').trim(),
    environment: String(formData.get('environment') || '').trim(),
    owner: String(formData.get('owner') || '').trim(),
    notes: String(formData.get('notes') || '').trim()
  };

  try {
    const created = await fetchJson('/api/deployments', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    elements.createForm.reset();
    elements.statusId.value = created.id;
    showToast(`Created ${created.id}`, 'ok');
    await loadState();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function onStatusSubmit(event) {
  event.preventDefault();
  const formData = new FormData(elements.statusForm);
  const id = String(formData.get('id') || '').trim();

  const payload = {
    status: String(formData.get('status') || '').trim(),
    notes: String(formData.get('notes') || '').trim()
  };

  if (!id) {
    showToast('Deployment ID is required', 'error');
    return;
  }

  try {
    const updated = await fetchJson(`/api/deployments/${encodeURIComponent(id)}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    elements.statusForm.reset();
    elements.statusId.value = updated.id;
    showToast(`Updated ${updated.id} to ${updated.status}`, 'ok');
    await loadState();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

function onDeploymentsClick(event) {
  const target = event.target;
  if (!(target instanceof HTMLButtonElement)) {
    return;
  }

  if (target.classList.contains('use-id-btn')) {
    elements.statusId.value = target.dataset.id || '';
    elements.statusId.focus();
    showToast(`Selected ${target.dataset.id}`, 'ok');
  }
}

async function initialize() {
  elements.refreshBtn.addEventListener('click', async () => {
    try {
      await loadState();
      showToast('Data refreshed', 'ok');
    } catch (error) {
      showToast(error.message, 'error');
    }
  });

  elements.createForm.addEventListener('submit', onCreateSubmit);
  elements.statusForm.addEventListener('submit', onStatusSubmit);
  elements.deploymentsBody.addEventListener('click', onDeploymentsClick);

  try {
    await loadState();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

initialize();
