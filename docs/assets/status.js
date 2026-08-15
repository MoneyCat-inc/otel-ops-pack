(() => {
  function $(id) { return document.getElementById(id); }
  async function load(url) {
    try {
      const r = await fetch(url, { cache: 'no-store' });
      if (!r.ok) throw new Error('bad');
      return await r.json();
    } catch { return null; }
  }
  function esc(s) {
    return String(s ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }
  
    // Resolve base for published status bundle and fetch helper (handles Pages subpaths)
    function resolveStatusBase() {
      try {
        const qp = new URLSearchParams(window.location.search);
        const fromQuery = qp.get('status_base');
        if (fromQuery) return String(fromQuery).replace(/\/$/, '');
        if (window.STATUS_BASE) return String(window.STATUS_BASE).replace(/\/$/, '');
        const meta = document.querySelector('meta[name="status-base"]');
        if (meta && meta.content) return String(meta.content).replace(/\/$/, '');
        const segs = window.location.pathname.split('/').filter(Boolean);
        const projectRoot = segs.length ? `/${segs[0]}` : '';
        return projectRoot;
      } catch { return '' }
    }
    async function fetchLatestStatusJson() {
      const base = resolveStatusBase();
      // Prefer live published KPIs; LATEST.json is legacy and 404s on Pages.
      const candidates = [
        `${base}/docs/status/kpis.json`,
        `${base}/docs/status/tests.json`,
        `${base}/status/LATEST.json`,
      ];
      let lastErr;
      for (const url of candidates) {
        try {
          const r = await fetch(url, { cache: 'no-store' });
          if (!r.ok) { lastErr = new Error(`status ${r.status} for ${url}`); continue; }
          return await r.json();
        } catch (e) { lastErr = e; }
      }
      throw lastErr || new Error('no status json');
    }

    async function initGate() {
      const el = $('gate-latest');
      const ll = $('gate-links');
      if (!el) return;
      let legacyUsed = false;
      let data = await load('../artifacts/gate-verification-results.json');
      if (!data) {
        data = await load('../DELT/ARTF/gate-verification-results.json');
        legacyUsed = !!data;
      }
      if (!data) {
        data = await load('status/tests.json');
      }
      data = data || {};
      if (legacyUsed) {
        console.warn('BossCat status: gate evidence loaded from legacy DELT/ARTF directory. Migrate consumers to artifacts/.');
      }
    const verdict = data.verdict || 'UNKNOWN';
    const ts = data.timestamp || data.endedAt || '';
    const branch = data.branch || '';
    const commit = data.commit || '';
    const gate = data.gate || 'IONA';
    const site = data.site || 'ci';
    const reasons = (data.reasons && data.reasons.length) ? data.reasons.join('; ') : 'None';

    el.innerHTML = `
      <p><strong>Verdict:</strong> ${esc(verdict)}</p>
      <p><strong>Gate/Site:</strong> <span class="pill">${esc(gate)}</span> / <span class="pill">${esc(site)}</span></p>
      <p><strong>Timestamp:</strong> ${esc(ts)}</p>
      <p><strong>Branch:</strong> ${esc(branch)}</p>
      <p><strong>Commit:</strong> <span class="pill" id="commit-pill">${esc(commit || 'n/a')}</span> <button class="btn" id="copy-commit">Copy</button></p>
      <p><strong>Reasons:</strong> ${esc(reasons)}</p>
    `;
    const box = el.closest('.status');
    if (box) {
      const readyVerdicts = new Set(['READY', 'APPROVED', 'GREEN']);
      if (!readyVerdicts.has(String(verdict).toUpperCase())) {
        box.classList.remove('ready');
        box.classList.add('not-ready');
      } else {
        box.classList.add('ready');
        box.classList.remove('not-ready');
      }
    }

    // GitHub links
    const repo = 'MoneyCat-inc/otel-ops-pack';
    const commitUrl = commit ? `https://github.com/${repo}/commit/${encodeURIComponent(commit)}` : '';
    const branchUrl = branch ? `https://github.com/${repo}/tree/${encodeURIComponent(branch)}` : '';
    if (ll) {
      ll.classList.add('links');
      ll.innerHTML = `
        ${commitUrl ? `<a class="btn" href="${commitUrl}" target="_blank" rel="noopener">View Commit</a>` : ''}
        ${branchUrl ? `<a class="btn" href="${branchUrl}" target="_blank" rel="noopener">View Branch</a>` : ''}
        ${branchUrl ? `<a class="btn" href="https://github.com/${repo}/pull/new/${encodeURIComponent(branch)}" target="_blank" rel="noopener">Open PR</a>` : ''}
      `;
    }

    const copyBtn = $('copy-commit');
    const pill = $('commit-pill');
    if (copyBtn && pill && commit) {
      copyBtn.addEventListener('click', async () => {
        try { await navigator.clipboard.writeText(commit); copyBtn.textContent = 'Copied'; setTimeout(()=>copyBtn.textContent='Copy', 1200); } catch {}
      });
    } else if (copyBtn) {
      copyBtn.disabled = true;
    }

    // Gate & Site panel (lightweight signal mapping)
    try {
      const gatePerf = document.getElementById('gate-perf');
      const gateOtel = document.getElementById('gate-otel');
      const gateRes = document.getElementById('gate-res');
      const gateEcrr = document.getElementById('gate-ecrr');
      const siteBuild = document.getElementById('site-build');
      const siteLinks = document.getElementById('site-links-metric');
      const siteA11y = document.getElementById('site-a11y');
      const siteCsp = document.getElementById('site-csp');

      // Use verdict as coarse signal; finer metrics can be wired later
      const isReady = (v => {
        try { return ['READY', 'APPROVED', 'GREEN'].includes(String(v).toUpperCase()); }
        catch { return false; }
      })(verdict);
      if (gatePerf) gatePerf.textContent = isReady ? 'OK' : 'HOLD';
      if (gateOtel) gateOtel.textContent = (data.checks && data.checks['docs/status.html']) ? 'OK' : '-';
      if (gateRes) gateRes.textContent = '-';
      if (gateEcrr) gateEcrr.textContent = verdict;
      if (siteBuild) siteBuild.textContent = 'OK';
      if (siteLinks) siteLinks.textContent = '-';
      if (siteA11y) siteA11y.textContent = '-';
      if (siteCsp) siteCsp.textContent = 'OK';
        // Try Pages status bundle to override coarse signals
        try {
          const j = await fetchLatestStatusJson();
          if (gatePerf && j.gate && j.gate.perf) gatePerf.textContent = j.gate.perf;
          if (gateOtel && j.gate && j.gate.trace) gateOtel.textContent = j.gate.trace;
          if (siteLinks && j.site && j.site.links) siteLinks.textContent = j.site.links;
          if (siteA11y && j.site && j.site.a11y) siteA11y.textContent = j.site.a11y;
          if (siteCsp && j.site && j.site.csp) siteCsp.textContent = j.site.csp;
        } catch {}
    } catch {}
  }

  function setRefmapPlaceholder(reason) {
    const host = $('refmap');
    if (!host) return;
    host.innerHTML = '';
    const msg = document.createElement('div');
    msg.className = 'refmap-placeholder';
    msg.setAttribute('role', 'status');
    msg.setAttribute('aria-live', 'polite');
    msg.textContent = `Reference map unavailable - ${reason}`;
    host.appendChild(msg);
  }

  async function initRefMap() {
    try {
      const r = await fetch('reference/reference-map.json', { cache: 'no-store' });
      const v = await fetch('reference/reference-map-validation.json', { cache: 'no-store' });
      if (!r.ok) { setRefmapPlaceholder('missing JSON'); return; }
      const m = await r.json();
      const nodesCount = (m.nodes || []).length;
      const edgesArr = (m.edges || []);
      const list = (m.nodes || []).slice(0,6).map(n => `- ${esc(n.id)} (${esc(n.type)})`).join('<br>');
      let missing = 0;
      if (v.ok) {
        const rep = await v.json();
        missing = (rep.counts && rep.counts.missing) || 0;
      }
      const tagCounts = {};
      for (const n of (m.nodes||[])) {
        if (n.type === 'doc' && n.importance === 'P1' && Array.isArray(n.tags)) {
          for (const t of n.tags) tagCounts[t] = (tagCounts[t]||0) + 1;
        }
      }
      const tagEntries = Object.entries(tagCounts).sort((a,b)=>b[1]-a[1]).slice(0,6);
      const tagLine = tagEntries.length ? tagEntries.map(([k,v])=>`${esc(k)}=${v}`).join(' | ') : '-';
      const pinnedTags = ['operations','governance'];
      const pinnedLine = pinnedTags.map(k => `${k}=${tagCounts[k]||0}`).join(' | ');

      const refmap = $('refmap');
      if (refmap) {
        // Header pill
        const header = document.createElement('div');
        header.className = 'refmap-header';
        const pill = document.createElement('span');
        pill.id = 'refmap-updated-pill';
        pill.className = 'pill';
        if (m.generated_at) {
          const dt = new Date(m.generated_at);
          pill.textContent = isNaN(dt) ? 'Last generated -' : `Last generated ${dt.toLocaleString()}`;
          pill.classList.add('ok');
        } else {
          pill.textContent = 'Last generated -';
          pill.classList.add('warn');
        }
        header.appendChild(pill);
        refmap.appendChild(header);

        // Summary
        const summary = document.createElement('div');
        summary.innerHTML = `
          <p><strong>Nodes/Edges:</strong> ${nodesCount}/${edgesArr.length} ${missing>0?`<span class='pill'>missing: ${missing}</span>`:''}</p>
          <p><strong>Docs by Importance:</strong> P0=${m.stats?.importanceCounts?.P0||0} | P1=${m.stats?.importanceCounts?.P1||0} | P2=${m.stats?.importanceCounts?.P2||0} | P3=${m.stats?.importanceCounts?.P3||0}</p>
          <p><strong>P1 by Tag:</strong> ${pinnedLine} | Top: ${tagLine}</p>
          <p><strong>Sample:</strong><br>${list}</p>
        `;
        refmap.appendChild(summary);
      }

      try {
        const picked = edgesArr.slice(0, 12);
        const nodesSet = new Set();
        for (const e of picked) {
          const a = e[0], b = e[1];
          if (a) nodesSet.add(a);
          if (b) nodesSet.add(b);
        }
        const nodes = Array.from(nodesSet);
        let graph = 'flowchart LR\n';
        graph += 'classDef p0 fill:#ffe5e5,stroke:#c00,stroke-width:2px;\n';
        graph += 'classDef p1 fill:#fff7cc,stroke:#aa0,stroke-width:1.5px;\n';
        for (const n of nodes) graph += `  ${String(n).replace(/[^a-zA-Z0-9_]/g,'_')}[${esc(n)}]\n`;
        for (const e of picked) {
          const a = String(e[0]||'').replace(/[^a-zA-Z0-9_]/g,'_');
          const b = String(e[1]||'').replace(/[^a-zA-Z0-9_]/g,'_');
          if (a && b) graph += `  ${a} --> ${b}\n`;
        }
        const topDocs = (m.nodes||[]).filter(n => n.type==='doc' && (n.importance==='P0'||n.importance==='P1')).slice(0,3);
        if (topDocs.length) {
          graph += '  docsHub[Docs] \n';
          for (const d of topDocs) {
            const dn = (d.id||'doc').replace(/[^a-zA-Z0-9_]/g,'_');
            graph += `  ${dn}[${esc(d.title || d.id)}]\n`;
            graph += `  docsHub --> ${dn}\n`;
            if (d.importance==='P0') graph += `  class ${dn} p0;\n`;
            if (d.importance==='P1') graph += `  class ${dn} p1;\n`;
          }
        }
        if (window.mermaid) {
          window.mermaid.initialize({ startOnLoad: false, theme: 'default', securityLevel: 'strict', deterministicIds: true, deterministicIDSeed: 'refmap' });
          const host = $('refmap-graph');
          if (host) {
            host.innerHTML = '';
            const el = document.createElement('div');
            el.className = 'mermaid';
            el.textContent = graph;
            host.appendChild(el);
            try { await window.mermaid.run({ querySelector: '#refmap-graph .mermaid' }); } catch {}
          }
        }
      } catch {}
    } catch {}
  }

  // Init
  (async () => { await initGate(); await initRefMap(); })();
})();
