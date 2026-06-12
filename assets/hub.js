// BossCat Hub - Metrics Loader
(async () => {
  'use strict';
  
  const metrics = {
    gateScore: document.getElementById('gateScore'),
    errorRate: document.getElementById('errorRate'),
    canaryCount: document.getElementById('canaryCount'),
    otelHealth: document.getElementById('otelHealth')
  };
  
  // Show loading state
  Object.values(metrics).forEach(el => {
    if (el) el.textContent = 'Loading...';
  });
  
  try {
    const response = await fetch('/docs/status/kpis.json');
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    
    const data = await response.json();
    
    // Update metrics
    if (metrics.gateScore) metrics.gateScore.textContent = data.gate || '—';
    if (metrics.errorRate) metrics.errorRate.textContent = data.error || '—';
    if (metrics.canaryCount) metrics.canaryCount.textContent = data.canary || '—';
    if (metrics.otelHealth) metrics.otelHealth.textContent = data.otel || '—';
    
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
  }
  
  // Hide localhost link in production
  if (window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
    const localhostLink = document.querySelector('a[href="http://localhost:8080"]');
    if (localhostLink) {
      localhostLink.style.display = 'none';
    }
  }
})();
