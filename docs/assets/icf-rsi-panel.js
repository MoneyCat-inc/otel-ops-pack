/**
 * ICF/RSI Status Panel
 * Directive 012: BOSS-CATX-OBSV-OTDA
 * 
 * Displays Iterative Convergence Framework and Rhetorical Style Integrity metrics
 * on the BossCat status dashboard.
 * 
 * CSP-compliant: No inline JavaScript
 * Budget: ~60 LOC
 */

(function () {
  'use strict';
  
  const $ = (id) => document.getElementById(id);
  
  // Try multiple known locations for metrics
  const CANDIDATES = [
    '../artifacts/rsi/metrics.json',
    './artifacts/rsi/metrics.json',
    '../DELT/ARTF/rsi/metrics.json',
    './status/rsi-metrics.json'
  ];

  async function fetchFirst(urls) {
    for (const url of urls) {
      try {
        const res = await fetch(url, { cache: 'no-store' });
        if (res.ok) return await res.json();
      } catch (_) { 
        // Try next candidate
      }
    }
    return null;
  }

  function set(id, value) { 
    const el = $(id); 
    if (el) el.textContent = value; 
  }
  
  function pct(n) { 
    return (Math.round((n || 0) * 1000) / 10).toFixed(1) + '%'; 
  }

  function classifyWarn(count) {
    const num = Number(count) || 0;
    if (num >= 5) return 'badge danger';
    if (num >= 1) return 'badge warning';
    return 'badge success';
  }

  function render(data) {
    if (!data) {
      set('icf-rate', '—');
      set('icf-warn', '—');
      set('icf-lii', '—');
      set('icf-dppl', '—');
      return;
    }

    const rate = data.convergence_rate_7d;
    const warns = data.warnings_7d ?? 0;
    const lii = data.LII ?? data.lii ?? null;
    const dppl = data.deltaPPL ?? data.delta_perplexity ?? null;

    set('icf-rate', rate != null ? pct(rate) : '—');
    set('icf-warn', warns);
    set('icf-lii', lii != null ? lii.toFixed(3) : '—');
    set('icf-dppl', dppl != null ? dppl.toFixed(3) : '—');

    // Apply semantic styling to warnings count
    const warnEl = $('icf-warn');
    if (warnEl) {
      warnEl.className = classifyWarn(warns);
    }
  }

  async function init() {
    const data = await fetchFirst(CANDIDATES);
    render(data);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init, { once: true });
  } else {
    init();
  }
})();

