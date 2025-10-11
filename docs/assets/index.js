// Index page interactions - CSP-compliant
// Authority: AUTO-BOTS-COMP-ALFA (COMP lane)

// Update timestamp
function updateTimestamp() {
  const el = document.getElementById('timestamp');
  if (el) {
    el.textContent = new Date().toLocaleString();
  }
}

// Smooth scroll for anchor links
function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });
}

// Initialize on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    updateTimestamp();
    setInterval(updateTimestamp, 1000);
    initSmoothScroll();
  });
} else {
  updateTimestamp();
  setInterval(updateTimestamp, 1000);
  initSmoothScroll();
}

