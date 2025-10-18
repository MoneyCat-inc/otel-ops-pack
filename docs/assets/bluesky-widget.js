// Progressive enhancement: read JSON and render a simple card list.
(function(){
  const el = document.querySelector('[data-bsky-latest]');
  if (!el) return;
  const src = el.getAttribute('data-src') || 'bluesky-latest.json';
  fetch(src, { cache:'no-store' })
    .then(r => r.ok ? r.json() : null)
    .then(data => {
      if (!data || !Array.isArray(data.posts)) { el.innerHTML = el.dataset.fallback || ''; return; }
      const list = document.createElement('ul'); list.className = 'bsky-list'; list.setAttribute('role','list');
      data.posts.forEach(p => {
        const li = document.createElement('li'); li.className = 'bsky-card';
        li.innerHTML = `
          <p class="bsky-text">${(p.text||'').replace(/</g,'&lt;')}</p>
          <div class="bsky-meta">
            <time datetime="${p.createdAt}">${new Date(p.createdAt).toLocaleString()}</time>
            ${p.url ? ` · <a class="bsky-link" href="${p.url}">View</a>` : ''}
          </div>`;
        list.appendChild(li);
      });
      el.innerHTML = ''; el.appendChild(list);
    })
    .catch(() => { el.innerHTML = el.dataset.fallback || ''; });
})();

