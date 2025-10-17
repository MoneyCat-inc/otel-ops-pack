// ANTIclickbait Transparency Hub - Data-driven card grid
(async () => {
  const response = await fetch('data.json');
  const data = await response.json();

  const cards = data.cards;
  const categories = [...new Set(cards.map(card => card.category))].sort();

  const selectEl = document.getElementById('category');
  const gridEl = document.getElementById('cards');
  const countEl = document.getElementById('count');
  const updatedEl = document.getElementById('updated');

  if (updatedEl) {
    updatedEl.textContent = data.metadata.updated;
  }

  categories.forEach(category => {
    const option = document.createElement('option');
    option.value = category;
    option.textContent = category.charAt(0).toUpperCase() + category.slice(1);
    selectEl.appendChild(option);
  });

  const render = (filter) => {
    const filtered = filter === 'all'
      ? cards
      : cards.filter(card => card.category === filter);

    gridEl.innerHTML = filtered.map(card => {
      const scoreClass = card.score >= 90
        ? 'excellent'
        : card.score >= 80
          ? 'good'
          : card.score >= 70
            ? 'adequate'
            : 'poor';

      const claims = card.claims.map(claim => `<li>${claim}</li>`).join('');
      const sources = card.sources.map(source => (
        source.startsWith('http')
          ? `<a href="${source}" target="_blank" rel="noopener">Source</a>`
          : `<span>${source}</span>`
      )).join('');

      return `
        <div class="card">
          <div class="card-header">
            <div class="card-title">${card.title}</div>
            <div class="card-score ${scoreClass}">${card.score}</div>
          </div>
          <div class="card-category">${card.category}</div>
          <div class="card-section">
            <h4>Claims</h4>
            <ul>${claims}</ul>
          </div>
          <div class="card-section card-evidence">
            <h4>Evidence</h4>
            <p>${card.evidence}</p>
          </div>
          <div class="card-section card-limitations">
            <h4>Limitations</h4>
            <p>${card.limitations}</p>
          </div>
          <div class="card-sources">
            ${sources}
          </div>
        </div>
      `;
    }).join('');

    if (countEl) {
      countEl.textContent = `Showing ${filtered.length} of ${cards.length} cards`;
    }
  };

  selectEl.addEventListener('change', event => render(event.target.value));
  render('all');
})();
