// Progressive enhancement: read JSON and render a simple card list.
// Offline-first guard: graceful fallback with no console noise, no layout shift
(function(){
  const el = document.querySelector('[data-bsky-latest]');
  if (!el) return;
  
  const src = el.getAttribute('data-src') || 'bluesky-latest.json';
  const fallback = el.dataset.fallback || '<p>Follow us on <a href="https://bsky.app/profile/resonai.bsky.social">Bluesky</a></p>';
  
  // Offline-first: timeout after 3s to prevent hanging
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 3000);
  
  fetch(src, { cache:'no-store', signal: controller.signal })
    .then(r => {
      clearTimeout(timeoutId);
      return r.ok ? r.json() : Promise.reject('HTTP error');
    })
    .then(data => {
      if (!data || !Array.isArray(data.posts) || data.posts.length === 0) {
        el.innerHTML = fallback;
        return;
      }
      
      const list = document.createElement('ul');
      list.className = 'bsky-list';
      list.setAttribute('role','list');
      
      data.posts.forEach(p => {
        const li = document.createElement('li');
        li.className = 'bsky-card';
        
        // XSS-safe: use textContent instead of innerHTML
        const textEl = document.createElement('p');
        textEl.className = 'bsky-text';
        textEl.textContent = p.text || '';
        
        const metaEl = document.createElement('div');
        metaEl.className = 'bsky-meta';
        
        const time = document.createElement('time');
        time.setAttribute('datetime', p.createdAt);
        time.textContent = new Date(p.createdAt).toLocaleString();
        metaEl.appendChild(time);
        
        if (p.url) {
          const sep = document.createTextNode(' · ');
          const link = document.createElement('a');
          link.className = 'bsky-link';
          link.href = p.url;
          link.textContent = 'View';
          link.target = '_blank';
          link.rel = 'noopener noreferrer';
          metaEl.appendChild(sep);
          metaEl.appendChild(link);
        }
        
        li.appendChild(textEl);
        li.appendChild(metaEl);
        list.appendChild(li);
      });
      
      el.innerHTML = '';
      el.appendChild(list);
    })
    .catch(err => {
      clearTimeout(timeoutId);
      // Silent fallback - no console.error to avoid noise
      el.innerHTML = fallback;
    });
})();

