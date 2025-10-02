# Cross-Origin Isolation Cheat Sheet

**Issue**: Service Worker strips COOP/COEP headers, breaking cross-origin isolation  
**Solution**: Configure headers directly or use coi-serviceworker workaround

## 🚨 **Required Headers**

```http
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

## 🔧 **Implementation Options**

### **Option 1: Next.js Config (Recommended)**
```javascript
// next.config.js
module.exports = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Cross-Origin-Opener-Policy',
            value: 'same-origin',
          },
          {
            key: 'Cross-Origin-Embedder-Policy',
            value: 'require-corp',
          },
        ],
      },
    ]
  },
}
```

### **Option 2: Vercel Headers**
```json
// vercel.json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Cross-Origin-Opener-Policy",
          "value": "same-origin"
        },
        {
          "key": "Cross-Origin-Embedder-Policy",
          "value": "require-corp"
        }
      ]
    }
  ]
}
```

### **Option 3: coi-serviceworker (Workaround)**
```javascript
// If Service Worker strips headers
import 'coi-serviceworker'

// Or add to public/sw.js
importScripts('https://unpkg.com/coi-serviceworker@0.1.7/dist/coi-serviceworker.min.js')
```

## 🚨 **Common Pitfalls**

### **Fonts/CDN Assets Blocked**
**Problem**: External fonts fail to load  
**Solution**: Add CORS headers or use `Cross-Origin-Resource-Policy`

```http
Cross-Origin-Resource-Policy: cross-origin
Access-Control-Allow-Origin: *
```

### **Service Worker Interference**
**Problem**: SW strips headers after page load  
**Solution**: Use `coi-serviceworker` or configure headers in SW

```javascript
// In service worker
self.addEventListener('fetch', event => {
  if (event.request.url.includes('your-domain.com')) {
    event.respondWith(
      fetch(event.request).then(response => {
        const newResponse = response.clone()
        newResponse.headers.set('Cross-Origin-Opener-Policy', 'same-origin')
        newResponse.headers.set('Cross-Origin-Embedder-Policy', 'require-corp')
        return newResponse
      })
    )
  }
})
```

## 🔍 **Verification**

### **Check Headers**
```javascript
// In browser console
console.log('COOP:', window.crossOriginIsolated)
console.log('Headers:', document.querySelector('meta[http-equiv="Cross-Origin-Opener-Policy"]'))
```

### **Test SharedArrayBuffer**
```javascript
// Should not throw error
const buffer = new SharedArrayBuffer(1024)
console.log('Cross-origin isolation working!')
```

## 🎯 **Quick Fixes**

### **If Headers Missing**
1. Check `next.config.js` headers configuration
2. Verify Vercel deployment includes headers
3. Use `coi-serviceworker` as fallback

### **If Assets Blocked**
1. Add `Cross-Origin-Resource-Policy: cross-origin`
2. Configure CDN CORS headers
3. Use local assets instead of CDN

### **If Service Worker Conflicts**
1. Use `coi-serviceworker` package
2. Configure SW to preserve headers
3. Disable SW temporarily for testing

## 📋 **Testing Checklist**

- [ ] Headers present in Network tab
- [ ] `window.crossOriginIsolated === true`
- [ ] SharedArrayBuffer works
- [ ] External fonts load
- [ ] Service Worker doesn't strip headers

---

**Remember**: Cross-origin isolation is required for SharedArrayBuffer and high-performance audio processing!
