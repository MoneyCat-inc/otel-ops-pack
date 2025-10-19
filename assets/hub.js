/**
 * BossCat Hub - Metrics Panel Loader
 * Fetches nightly KPIs and populates hero metrics panel
 */

(async function initHubMetrics() {
  'use strict';
  
  const $ = (id) => document.getElementById(id);
  
  try {
    const response = await fetch('/docs/status/kpis.json', {
      cache: 'no-store',
      headers: { 'Accept': 'application/json' }
    });
    
    const data = response.ok 
      ? await response.json() 
      : { gate: '—', error: '—', canary: 0, otel: '—' };
    
    const gateEl = $('gateScore');
    const errorEl = $('errorRate');
    const canaryEl = $('canaryCount');
    const otelEl = $('otelHealth');
    
    if (gateEl) gateEl.textContent = data.gate ?? '—';
    if (errorEl) errorEl.textContent = data.error ?? '—';
    if (canaryEl) canaryEl.textContent = data.canary ?? '—';
    if (otelEl) otelEl.textContent = data.otel ?? '—';
    
    console.info('[Hub] Metrics loaded', { source: '/docs/status/kpis.json' });
    
  } catch (err) {
    console.error('[Hub] Metrics load failed:', err);
    ['gateScore', 'errorRate', 'canaryCount', 'otelHealth'].forEach(id => {
      const el = $(id);
      if (el) el.textContent = '—';
    });
  }
})();

