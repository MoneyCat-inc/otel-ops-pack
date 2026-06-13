// BossCat Hub - Metrics Loader
(async () => {
  'use strict';
  
  const metrics = {
    gateScore: document.getElementById('gateScore'),
    errorRate: document.getElementById('errorRate'),
    canaryCount: document.getElementById('canaryCount'),
    otelHealth: document.getElementById('otelHealth')
  };
  const kpiUpdated = document.getElementById('kpiUpdated');
  
  // Show loading state
  Object.values(metrics).forEach(el => {
    if (el) el.textContent = 'Loading...';
  });
  if (kpiUpdated) kpiUpdated.textContent = 'Loading metrics…';
  
  try {
    const response = await fetch('/docs/status/kpis.json');
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    
    const data = await response.json();
    
    // Update metrics
    if (metrics.gateScore) metrics.gateScore.textContent = data.gate || '—';
    if (metrics.errorRate) metrics.errorRate.textContent = data.error || '—';
    if (metrics.canaryCount) metrics.canaryCount.textContent = data.canary || '—';
    if (metrics.otelHealth) {
      metrics.otelHealth.textContent = data.otel || '—';
      metrics.otelHealth.classList.remove('status-warn', 'status-fail');
      if (data.otel === 'warn') metrics.otelHealth.classList.add('status-warn');
      if (data.otel === 'fail') metrics.otelHealth.classList.add('status-fail');
    }

    if (kpiUpdated && data.ts) {
      const when = new Date(data.ts);
      const label = Number.isNaN(when.getTime())
        ? data.ts
        : when.toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
      kpiUpdated.innerHTML = `Last updated: <time datetime="${data.ts}">${label}</time> · <a href="docs/status.html">Status dashboard</a>`;
    }
    
    console.log('[Hub] Metrics loaded', { source: '/docs/status/kpis.json', data });
  } catch (err) {
    console.error('[Hub] Failed to load metrics:', err);
    
    // Show error state
    Object.values(metrics).forEach(el => {
      if (el) {
        el.textContent = 'Error';
        el.title = 'Failed to load metrics';
        el.style.color = '#ff6b6b';
      }
    });
    if (kpiUpdated) {
      kpiUpdated.innerHTML = 'Metrics offline — see <a href="docs/status.html">Status dashboard</a>';
    }
  }
  
  // Hide localhost link in production
  if (window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
    const localhostLink = document.querySelector('a[href="http://localhost:8080"]');
    if (localhostLink) {
      localhostLink.style.display = 'none';
    }
  }
})();
