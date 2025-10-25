/**
 * BossCat Hub - Metrics Panel Loader v1
 * Cache-busting version for GitHub Pages deployment
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
      : { gate: '—', error: '—', canary: 0, otel: '—', ts: '' };
    
    // Update metrics
    const gateEl = $('gateScore');
    const errorEl = $('errorRate');
    const canaryEl = $('canaryCount');
    const otelEl = $('otelHealth');
    
    if (gateEl) gateEl.textContent = data.gate ?? '—';
    if (errorEl) errorEl.textContent = data.error ?? '—';
    if (canaryEl) canaryEl.textContent = data.canary ?? '—';
    if (otelEl) otelEl.textContent = data.otel ?? '—';
    
    // Optional: Last update timestamp
    const updatedEl = $('kpiUpdated');
    if (updatedEl && data.ts) {
      updatedEl.textContent = new Date(data.ts).toLocaleString();
    }
    
    console.info('[Hub v1] Metrics loaded', {
      source: '/docs/status/kpis.json',
      timestamp: data.ts || 'unknown'
    });
    
  } catch (err) {
    console.error('[Hub v1] Metrics load failed:', err);
    
    // Fallback values
    ['gateScore', 'errorRate', 'canaryCount', 'otelHealth'].forEach(id => {
      const el = $(id);
      if (el) el.textContent = '—';
    });
  }
})();

