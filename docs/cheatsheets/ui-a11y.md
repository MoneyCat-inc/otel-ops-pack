# UI & Accessibility Guardrails Cheat Sheet

**Issue**: Inline styles and missing accessibility features break compliance  
**Solution**: Strict guardrails with utility classes and ARIA implementation

## 🚨 **Critical Guardrails**

### **Never Use Inline Styles**
```typescript
// ❌ WRONG - Never do this
<div style="color: red; font-size: 16px;">Error message</div>

// ✅ CORRECT - Use utility classes
<div className="text-red-500 text-base">Error message</div>
```

### **Never Use dangerouslySetInnerHTML**
```typescript
// ❌ WRONG - Security risk
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ CORRECT - Use proper components
<div>{sanitizeContent(userContent)}</div>
```

## 🎨 **Utility Class System**

### **Design System Implementation**
```css
/* app/ui.css - Centralized utility classes */

/* Colors */
.text-red-500 { color: #ef4444; }
.text-green-500 { color: #10b981; }
.text-yellow-500 { color: #f59e0b; }
.text-blue-500 { color: #3b82f6; }

.bg-red-50 { background-color: #fef2f2; }
.bg-green-50 { background-color: #f0fdf4; }
.bg-yellow-50 { background-color: #fffbeb; }

/* Typography */
.text-xs { font-size: 0.75rem; line-height: 1rem; }
.text-sm { font-size: 0.875rem; line-height: 1.25rem; }
.text-base { font-size: 1rem; line-height: 1.5rem; }
.text-lg { font-size: 1.125rem; line-height: 1.75rem; }
.text-xl { font-size: 1.25rem; line-height: 1.75rem; }

.font-medium { font-weight: 500; }
.font-semibold { font-weight: 600; }
.font-bold { font-weight: 700; }

/* Spacing */
.p-1 { padding: 0.25rem; }
.p-2 { padding: 0.5rem; }
.p-3 { padding: 0.75rem; }
.p-4 { padding: 1rem; }

.m-1 { margin: 0.25rem; }
.m-2 { margin: 0.5rem; }
.m-3 { margin: 0.75rem; }
.m-4 { margin: 1rem; }

/* Layout */
.flex { display: flex; }
.flex-col { flex-direction: column; }
.items-center { align-items: center; }
.justify-center { justify-content: center; }
.justify-between { justify-content: space-between; }

/* Responsive */
@media (max-width: 768px) {
  .mobile-hidden { display: none; }
  .mobile-full { width: 100%; }
}

/* Accessibility */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.focus-visible:focus {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
  .animate-spin { animation: none; }
  .animate-pulse { animation: none; }
  .transition-all { transition: none; }
}
```

## ♿ **ARIA Implementation**

### **Live Regions for Feedback**
```typescript
// ✅ CORRECT - ARIA live region for dynamic content
function StatusMessage({ message, type }: { message: string; type: 'success' | 'error' | 'info' }) {
  return (
    <div 
      role="status" 
      aria-live="polite"
      className={`p-3 rounded-md ${
        type === 'success' ? 'bg-green-50 text-green-800' :
        type === 'error' ? 'bg-red-50 text-red-800' :
        'bg-blue-50 text-blue-800'
      }`}
    >
      {message}
    </div>
  )
}

// ✅ CORRECT - Alert for urgent messages
function AlertMessage({ message }: { message: string }) {
  return (
    <div 
      role="alert" 
      aria-live="assertive"
      className="bg-red-50 text-red-800 p-3 rounded-md"
    >
      {message}
    </div>
  )
}
```

### **Form Accessibility**
```typescript
// ✅ CORRECT - Proper form labels and associations
function AccessibleForm() {
  const [email, setEmail] = useState('')
  const [error, setError] = useState('')
  
  return (
    <form>
      <div className="mb-4">
        <label 
          htmlFor="email-input" 
          className="block text-sm font-medium text-gray-700 mb-1"
        >
          Email Address
        </label>
        <input
          id="email-input"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          aria-describedby={error ? "email-error" : undefined}
          aria-invalid={error ? "true" : "false"}
          className={`w-full p-2 border rounded-md focus-visible ${
            error ? 'border-red-500' : 'border-gray-300'
          }`}
        />
        {error && (
          <div 
            id="email-error" 
            role="alert" 
            className="text-red-600 text-sm mt-1"
          >
            {error}
          </div>
        )}
      </div>
    </form>
  )
}
```

### **Keyboard Navigation**
```typescript
// ✅ CORRECT - Keyboard accessible components
function AccessibleButton({ 
  children, 
  onClick, 
  disabled = false,
  ariaLabel 
}: {
  children: React.ReactNode
  onClick: () => void
  disabled?: boolean
  ariaLabel?: string
}) {
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      onClick()
    }
  }
  
  return (
    <button
      onClick={onClick}
      onKeyDown={handleKeyDown}
      disabled={disabled}
      aria-label={ariaLabel}
      className={`
        px-4 py-2 rounded-md font-medium transition-colors
        ${disabled 
          ? 'bg-gray-300 text-gray-500 cursor-not-allowed' 
          : 'bg-blue-500 text-white hover:bg-blue-600 focus-visible'
        }
      `}
    >
      {children}
    </button>
  )
}
```

## 🎯 **Skip Links**

### **Navigation Accessibility**
```typescript
// ✅ CORRECT - Skip links for keyboard users
function SkipLinks() {
  return (
    <div className="sr-only focus-within:not-sr-only">
      <a 
        href="#main-content" 
        className="absolute top-0 left-0 bg-blue-500 text-white p-2 z-50"
      >
        Skip to main content
      </a>
      <a 
        href="#navigation" 
        className="absolute top-0 left-20 bg-blue-500 text-white p-2 z-50"
      >
        Skip to navigation
      </a>
    </div>
  )
}

function MainLayout({ children }: { children: React.ReactNode }) {
  return (
    <div>
      <SkipLinks />
      <nav id="navigation" className="bg-gray-100 p-4">
        {/* Navigation content */}
      </nav>
      <main id="main-content" className="p-4">
        {children}
      </main>
    </div>
  )
}
```

## 🎨 **Color Contrast**

### **WCAG AA Compliance**
```css
/* Ensure sufficient color contrast ratios */

/* Text on light backgrounds */
.text-gray-900 { color: #111827; } /* 16.75:1 on white */
.text-gray-700 { color: #374151; } /* 9.74:1 on white */
.text-gray-600 { color: #4b5563; } /* 7.16:1 on white */

/* Text on dark backgrounds */
.text-white { color: #ffffff; } /* 21:1 on black */
.text-gray-100 { color: #f3f4f6; } /* 12.63:1 on black */
.text-gray-200 { color: #e5e7eb; } /* 9.74:1 on black */

/* Interactive elements */
.btn-primary {
  background-color: #3b82f6; /* Blue-500 */
  color: #ffffff;
  /* 4.5:1 contrast ratio */
}

.btn-primary:hover {
  background-color: #2563eb; /* Blue-600 */
  /* Maintains contrast on hover */
}
```

## 🔄 **Reduced Motion**

### **Respect User Preferences**
```css
/* Default animations */
.animate-spin {
  animation: spin 1s linear infinite;
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

.transition-all {
  transition: all 0.3s ease-in-out;
}

/* Respect reduced motion preference */
@media (prefers-reduced-motion: reduce) {
  .animate-spin,
  .animate-pulse,
  .transition-all {
    animation: none;
    transition: none;
  }
  
  /* Provide alternative feedback */
  .animate-spin {
    opacity: 0.5;
  }
  
  .animate-pulse {
    opacity: 0.8;
  }
}
```

## 🚨 **Common Violations**

### **❌ What NOT to Do**
```typescript
// ❌ Inline styles
<div style={{ color: 'red', fontSize: '16px' }}>Error</div>

// ❌ Missing ARIA labels
<button onClick={handleClick}>Submit</button>

// ❌ No keyboard support
<div onClick={handleClick}>Click me</div>

// ❌ Missing form labels
<input type="email" onChange={handleChange} />

// ❌ No focus management
<Modal isOpen={isOpen} onClose={handleClose}>
  <div>Modal content</div>
</Modal>
```

### **✅ Correct Implementations**
```typescript
// ✅ Utility classes
<div className="text-red-500 text-base">Error</div>

// ✅ ARIA labels
<button onClick={handleClick} aria-label="Submit form">Submit</button>

// ✅ Keyboard support
<div 
  onClick={handleClick}
  onKeyDown={(e) => e.key === 'Enter' && handleClick()}
  tabIndex={0}
  role="button"
>
  Click me
</div>

// ✅ Form labels
<label htmlFor="email">Email</label>
<input id="email" type="email" onChange={handleChange} />

// ✅ Focus management
<Modal isOpen={isOpen} onClose={handleClose}>
  <div>
    <button 
      ref={focusRef}
      className="sr-only"
      onFocus={() => focusRef.current?.focus()}
    >
      Focus trap
    </button>
    <div>Modal content</div>
  </div>
</Modal>
```

## 📋 **Testing Checklist**

- [ ] No inline styles used
- [ ] No dangerouslySetInnerHTML
- [ ] All interactive elements have ARIA labels
- [ ] Forms have proper labels and associations
- [ ] Keyboard navigation works
- [ ] Skip links present
- [ ] Color contrast meets WCAG AA
- [ ] Reduced motion respected
- [ ] Focus management implemented
- [ ] Screen reader compatible

## 🔧 **Automated Testing**

### **Linting Rules**
```json
// .eslintrc.js
{
  "rules": {
    "react/no-inline-styles": "error",
    "react/no-danger": "error",
    "jsx-a11y/alt-text": "error",
    "jsx-a11y/anchor-has-content": "error",
    "jsx-a11y/aria-props": "error",
    "jsx-a11y/aria-proptypes": "error",
    "jsx-a11y/aria-unsupported-elements": "error",
    "jsx-a11y/click-events-have-key-events": "error",
    "jsx-a11y/heading-has-content": "error",
    "jsx-a11y/html-has-lang": "error",
    "jsx-a11y/img-redundant-alt": "error",
    "jsx-a11y/no-access-key": "error",
    "jsx-a11y/no-redundant-roles": "error",
    "jsx-a11y/role-has-required-aria-props": "error",
    "jsx-a11y/role-supports-aria-props": "error"
  }
}
```

---

**Remember**: Accessibility is not optional - it's a requirement for all users!
