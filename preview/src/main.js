import './style.css';

function updateTimestamp(element) {
  element.textContent = new Date().toLocaleTimeString();
}

function initialiseTimestamp() {
  const timestamp = document.querySelector('[data-last-update]');
  if (!timestamp) return;

  updateTimestamp(timestamp);
  setInterval(() => updateTimestamp(timestamp), 1000);
}

function syncIndicatorMotion() {
  const indicators = Array.from(document.querySelectorAll('[data-indicator]'));
  if (!indicators.length) {
    return;
  }

  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

  const applyMotionPreference = (disableMotion) => {
    indicators.forEach((indicator) => {
      indicator.classList.toggle('app__status-indicator--static', disableMotion);
    });
  };

  applyMotionPreference(prefersReducedMotion.matches);
  prefersReducedMotion.addEventListener('change', (event) => {
    applyMotionPreference(event.matches);
  });
}

function registerPipelineWorker() {
  if (!('Worker' in window)) {
    return;
  }

  try {
    const worker = new Worker('/workers/pipeline.js', { type: 'module' });
    worker.postMessage({ type: 'ping' });
    worker.addEventListener('message', (event) => {
      if (event.data?.type === 'pong') {
        worker.terminate();
      }
    });
  } catch (error) {
    console.warn('Pipeline worker registration skipped', error);
  }
}

initialiseTimestamp();
syncIndicatorMotion();
registerPipelineWorker();
