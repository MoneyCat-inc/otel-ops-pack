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

  async function initGate() {
    const el = $('gate-latest');
    const ll = $('gate-links');
    if (!el) return;
    const data = await load('../DELT/ARTF/gate-verification-results.json') || await load('status/tests.json') || {};
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
      <p><strong>Commit:</strong> <span class="pill" id="commit-pill">${esc(commit || '—')}</span> <button class="btn" id="copy-commit">Copy</button></p>
      <p><strong>Reasons:</strong> ${esc(reasons)}</p>
    `;
    const box = el.closest('.status');
    if (box) {
      if (verdict !== 'READY') { box.classList.remove('ready'); box.classList.add('not-ready'); }
      else { box.classList.add('ready'); box.classList.remove('not-ready'); }
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
  }

  function setRefmapPlaceholder(reason) {
    const host = $('refmap');
    if (!host) return;
    host.innerHTML = '';
    const msg = document.createElement('div');
    msg.className = 'refmap-placeholder';
    msg.setAttribute('role', 'status');
    msg.setAttribute('aria-live', 'polite');
    msg.textContent = `Reference map unavailable — ${reason}`;
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
      const tagLine = tagEntries.length ? tagEntries.map(([k,v])=>`${esc(k)}=${v}`).join(' · ') : '—';
      const pinnedTags = ['operations','governance'];
      const pinnedLine = pinnedTags.map(k => `${k}=${tagCounts[k]||0}`).join(' · ');

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
          pill.textContent = isNaN(dt) ? 'Last generated —' : `Last generated ${dt.toLocaleString()}`;
          pill.classList.add('ok');
        } else {
          pill.textContent = 'Last generated —';
          pill.classList.add('warn');
        }
        header.appendChild(pill);
        refmap.appendChild(header);

        // Summary
        const summary = document.createElement('div');
        summary.innerHTML = `
          <p><strong>Nodes/Edges:</strong> ${nodesCount}/${edgesArr.length} ${missing>0?`<span class='pill'>missing: ${missing}</span>`:''}</p>
          <p><strong>Docs by Importance:</strong> P0=${m.stats?.importanceCounts?.P0||0} · P1=${m.stats?.importanceCounts?.P1||0} · P2=${m.stats?.importanceCounts?.P2||0} · P3=${m.stats?.importanceCounts?.P3||0}</p>
          <p><strong>P1 by Tag:</strong> ${pinnedLine} · Top: ${tagLine}</p>
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
