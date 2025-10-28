/**
 * Visualizer App Logic - Gate #031 (Phase 1 MVP)
 * Evidence-as-Code UI with machine-verifiable proof artifacts
 */

// Configuration
const CONFIG = {
  artifactsPath: '../../artifacts/visualizer/',
  defaultService: 'iona-app',
  defaultLookback: 60,
  pollInterval: 5000, // 5 seconds
  icfPath: '../../artifacts/icf/convergence-report.json'
};

// State
let currentService = CONFIG.defaultService;
let currentLookback = CONFIG.defaultLookback;
let latestProofFile = null;
let polling = false;

// Initialize on load
document.addEventListener('DOMContentLoaded', () => {
  initializeControls();
  initializeFromQueryString();
  loadLatestProof();
  loadICFData();
});

/**
 * Initialize control event listeners
 */
function initializeControls() {
  const servicePicker = document.getElementById('service-picker');
  const timeRange = document.getElementById('time-range');
  const runProofBtn = document.getElementById('run-proof-btn');
  const refreshBtn = document.getElementById('refresh-btn');

  servicePicker.addEventListener('change', (e) => {
    currentService = e.target.value;
    console.log(`Service changed to: ${currentService}`);
  });

  timeRange.addEventListener('change', (e) => {
    currentLookback = parseInt(e.target.value);
    console.log(`Time range changed to: ${currentLookback} minutes`);
  });

  runProofBtn.addEventListener('click', handleRunProof);
  refreshBtn.addEventListener('click', () => loadLatestProof());
}

/**
 * Initialize from querystring parameters
 */
function initializeFromQueryString() {
  const params = new URLSearchParams(window.location.search);
  const service = params.get('service');
  
  if (service) {
    currentService = service;
    document.getElementById('service-picker').value = service;
  }
}

/**
 * Handle Run Proof button click
 */
async function handleRunProof() {
  const btn = document.getElementById('run-proof-btn');
  const statusSpan = document.getElementById('proof-status');
  
  btn.disabled = true;
  statusSpan.textContent = '⏳';
  
  try {
    console.log(`Running proof for ${currentService} (${currentLookback}m lookback)...`);
    
    // In Phase 1, we show instructions to run the script manually
    // Phase 3 will add automated script invocation
    showProofInstructions();
    
    // Poll for new proof file
    setTimeout(() => {
      loadLatestProof();
      btn.disabled = false;
      statusSpan.textContent = '▶';
    }, 2000);
    
  } catch (error) {
    console.error('Error running proof:', error);
    showError('Failed to initiate proof generation');
    btn.disabled = false;
    statusSpan.textContent = '▶';
  }
}

/**
 * Show manual proof instructions
 */
function showProofInstructions() {
  const message = `
To generate proof artifacts, run in PowerShell:

pwsh -File scripts/visualizer/proof-adapter.ps1 -ServiceName "${currentService}" -LookbackMinutes ${currentLookback}

The proof artifact will be saved to artifacts/visualizer/
Then click Refresh to load the results.

(Automated invocation coming in Gate #033 - Phase 3)
  `.trim();
  
  alert(message);
}

/**
 * Load latest proof artifact from artifacts/visualizer/
 */
async function loadLatestProof() {
  try {
    // In Phase 1, we look for a specific proof file pattern
    // Phase 3 will add automatic file listing
    const proofFile = await findLatestProofFile();
    
    if (!proofFile) {
      console.log('No proof artifacts found yet');
      updateUIWithMessage('No proof artifacts found. Click "Run Proof" to generate.');
      return;
    }
    
    const proof = await loadProofFile(proofFile);
    updateUIWithProof(proof);
    latestProofFile = proofFile;
    
  } catch (error) {
    console.error('Error loading proof:', error);
    showError(`Failed to load proof artifact: ${error.message}`);
  }
}

/**
 * Find latest proof file (Phase 1: stub implementation)
 */
async function findLatestProofFile() {
  // Phase 1: Try common patterns
  // Phase 3 will add proper file listing
  const patterns = [
    'proof-latest.json',
    `proof-${currentService}-latest.json`,
    'unified-proof-latest.json'
  ];
  
  for (const pattern of patterns) {
    try {
      const response = await fetch(CONFIG.artifactsPath + pattern);
      if (response.ok) {
        return pattern;
      }
    } catch (e) {
      // File doesn't exist, continue
    }
  }
  
  return null;
}

/**
 * Load proof file content
 */
async function loadProofFile(filename) {
  const response = await fetch(CONFIG.artifactsPath + filename);
  
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
  
  return await response.json();
}

/**
 * Update UI with proof data
 */
function updateUIWithProof(proof) {
  console.log('Proof loaded:', proof);
  
  // Update Traces
  updatePanel('traces', proof.traces || proof.signals?.traces);
  
  // Update Logs
  updatePanel('logs', proof.logs || proof.signals?.logs);
  
  // Update Metrics (Phase 2)
  // Currently shows as PLANNED
  
  // Update Health
  updateHealthPanel(proof.health || proof.collector_health);
  
  // Update overall status badge
  updateOverallStatus(proof);
}

/**
 * Update individual panel (traces/logs)
 */
function updatePanel(panelName, data) {
  const countEl = document.getElementById(`${panelName}-count`);
  const timestampEl = document.getElementById(`${panelName}-timestamp`);
  const statusEl = document.getElementById(`${panelName}-status`);
  
  if (!data) {
    countEl.textContent = '0';
    timestampEl.textContent = 'No data';
    setStatusBadge(statusEl, 'AMBER');
    return;
  }
  
  countEl.textContent = data.count || data.result_count || 0;
  
  if (data.last_seen || data.timestamp) {
    const ts = new Date(data.last_seen || data.timestamp);
    timestampEl.textContent = ts.toLocaleString();
  } else {
    timestampEl.textContent = 'Unknown';
  }
  
  const count = data.count || data.result_count || 0;
  setStatusBadge(statusEl, count > 0 ? 'GREEN' : 'AMBER');
}

/**
 * Update health panel
 */
function updateHealthPanel(health) {
  const pipelineEl = document.getElementById('health-pipeline');
  const collectorEl = document.getElementById('health-collector');
  const statusEl = document.getElementById('health-status');
  
  if (!health) {
    pipelineEl.textContent = 'Unknown';
    collectorEl.textContent = 'Unknown';
    setStatusBadge(statusEl, 'AMBER');
    return;
  }
  
  pipelineEl.textContent = health.pipeline_status || health.status || 'OK';
  collectorEl.textContent = health.collector_status || health.otelcol_status || 'OK';
  
  const isHealthy = (health.pipeline_status === 'OK' || health.status === 'ok');
  setStatusBadge(statusEl, isHealthy ? 'GREEN' : 'AMBER');
}

/**
 * Update overall status
 */
function updateOverallStatus(proof) {
  const overall = proof.overall_status || proof.status;
  console.log(`Overall status: ${overall}`);
}

/**
 * Set status badge appearance
 */
function setStatusBadge(element, status) {
  element.textContent = status;
  element.className = 'status-badge';
  element.setAttribute('data-status', status);
  
  if (status === 'GREEN') {
    element.classList.add('green');
  } else if (status === 'AMBER') {
    element.classList.add('amber');
  } else if (status === 'RED') {
    element.classList.add('red');
  }
}

/**
 * Update UI with message when no proof available
 */
function updateUIWithMessage(message) {
  ['traces', 'logs'].forEach(panelName => {
    const countEl = document.getElementById(`${panelName}-count`);
    const timestampEl = document.getElementById(`${panelName}-timestamp`);
    const statusEl = document.getElementById(`${panelName}-status`);
    
    countEl.textContent = '—';
    timestampEl.textContent = message;
    setStatusBadge(statusEl, 'PENDING');
  });
  
  const healthStatus = document.getElementById('health-status');
  setStatusBadge(healthStatus, 'PENDING');
}

/**
 * Load ICF data (Phase 1: lightweight)
 */
async function loadICFData() {
  try {
    const response = await fetch(CONFIG.icfPath);
    if (!response.ok) {
      document.getElementById('icf-actions').innerHTML = '<div class="info-message">ICF data not available. Run ICF analyzer to generate.</div>';
      return;
    }
    
    const icf = await response.json();
    renderICFActions(icf);
    
  } catch (error) {
    console.log('ICF data not available:', error.message);
    document.getElementById('icf-actions').innerHTML = '<div class="info-message">ICF data not available.</div>';
  }
}

/**
 * Render ICF last 5 actions
 */
function renderICFActions(icf) {
  const container = document.getElementById('icf-actions');
  const actions = icf.last_5_improvements || icf.improvement_actions || [];
  
  if (actions.length === 0) {
    container.innerHTML = '<div class="info-message">No improvement actions recorded yet.</div>';
    return;
  }
  
  const html = `
    <table class="icf-actions-table">
      <thead>
        <tr>
          <th>Date</th>
          <th>Gate</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
        ${actions.slice(0, 5).map(action => `
          <tr>
            <td>${action.date || action.timestamp || 'N/A'}</td>
            <td>${action.gate || 'N/A'}</td>
            <td>${action.description || action.action || 'N/A'}</td>
          </tr>
        `).join('')}
      </tbody>
    </table>
  `;
  
  container.innerHTML = html;
}

/**
 * Show error message
 */
function showError(message) {
  console.error(message);
  // Phase 2 will add proper error toasts
  alert(`Error: ${message}`);
}

// Log ICF contribution
console.log('[ICF] Visualizer MVP loaded - icf.contribution=visualizer.mvp');

