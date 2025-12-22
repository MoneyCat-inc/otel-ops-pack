// MoneyCat Inc - Website JavaScript
// See C:\otel\docs\comfort cat for canonical creative reference

(function() {
  'use strict';

  // Mobile Navigation Toggle
  const navToggle = document.querySelector('.nav-toggle');
  const navLinks = document.querySelector('.nav-links');

  if (navToggle && navLinks) {
    navToggle.addEventListener('click', function() {
      const isExpanded = navToggle.getAttribute('aria-expanded') === 'true';
      navToggle.setAttribute('aria-expanded', !isExpanded);
      navLinks.style.display = isExpanded ? 'none' : 'flex';
      
      // Update toggle button animation
      navToggle.classList.toggle('active');
    });

    // Close mobile menu when clicking outside
    document.addEventListener('click', function(event) {
      if (window.innerWidth <= 768) {
        if (!navToggle.contains(event.target) && !navLinks.contains(event.target)) {
          navLinks.style.display = 'none';
          navToggle.setAttribute('aria-expanded', 'false');
          navToggle.classList.remove('active');
        }
      }
    });

    // Handle window resize
    window.addEventListener('resize', function() {
      if (window.innerWidth > 768) {
        navLinks.style.display = 'flex';
        navToggle.setAttribute('aria-expanded', 'false');
        navToggle.classList.remove('active');
      } else {
        navLinks.style.display = 'none';
      }
    });
  }

  // Contact Form Handling
  const contactForm = document.querySelector('.contact-form');
  if (contactForm) {
    contactForm.addEventListener('submit', function(event) {
      event.preventDefault();
      
      // Get form data
      const formData = new FormData(contactForm);
      const data = Object.fromEntries(formData);
      
      // Basic validation
      if (!data.name || !data.email || !data.subject || !data.message) {
        alert('Please fill in all required fields.');
        return;
      }

      // Email validation
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(data.email)) {
        alert('Please enter a valid email address.');
        return;
      }

      // In a real implementation, this would send to a server
      // For now, we'll just show a success message
      alert('Thank you for your message! We\'ll get back to you soon. 🐾');
      contactForm.reset();
    });
  }

  // Smooth scroll for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      const href = this.getAttribute('href');
      if (href !== '#' && href.length > 1) {
        e.preventDefault();
        const target = document.querySelector(href);
        if (target) {
          target.scrollIntoView({
            behavior: 'smooth',
            block: 'start'
          });
        }
      }
    });
  });

  // Add loading states to buttons
  document.querySelectorAll('.btn').forEach(button => {
    if (button.type === 'submit') {
      button.addEventListener('click', function() {
        if (this.closest('form') && this.closest('form').checkValidity()) {
          this.textContent = 'Sending...';
          this.disabled = true;
        }
      });
    }
  });

  // Respect reduced motion preference
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  if (prefersReducedMotion.matches) {
    document.documentElement.style.setProperty('--animation-duration', '0.01ms');
  }

})();
