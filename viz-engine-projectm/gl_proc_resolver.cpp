// PR #942 Migration - GL Proc Resolver Implementation
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Platform-adaptive OpenGL function pointer resolver

#include "gl_proc_resolver.hpp"
#include <cstdio>
#include <cstring>

#ifdef __linux__
// GLX resolver (primary for Xvfb/GLX setup)
#include <GL/glx.h>
#include <X11/Xlib.h>

namespace gl_resolver {

void* glx_resolve(const char* name, void* user_data) {
    (void)user_data;
    if (!name) return nullptr;
    
    // Use GLX extension function (ARB version is standard)
    void* proc = (void*)glXGetProcAddressARB((const GLubyte*)name);
    
    // Fallback to non-ARB version if ARB fails
    if (!proc) {
        proc = (void*)glXGetProcAddress((const GLubyte*)name);
    }
    
    return proc;
}

} // namespace gl_resolver
#endif // __linux__

// SDL resolver (if SDL is available)
#ifdef HAVE_SDL2
#include <SDL2/SDL.h>

namespace gl_resolver {

void* sdl_resolve(const char* name, void* user_data) {
    (void)user_data;
    if (!name) return nullptr;
    return (void*)SDL_GL_GetProcAddress(name);
}

} // namespace gl_resolver
#endif // HAVE_SDL2

// EGL resolver (if EGL is available)
#ifdef HAVE_EGL
#include <EGL/egl.h>

namespace gl_resolver {

void* egl_resolve(const char* name, void* user_data) {
    (void)user_data;
    if (!name) return nullptr;
    return (void*)eglGetProcAddress(name);
}

} // namespace gl_resolver
#endif // HAVE_EGL

namespace gl_resolver {

// Auto-detect resolver based on available backends
// Priority: GLX > SDL > EGL
projectm_gl_load_proc_t get_resolver() {
#ifdef __linux__
    // Check if GLX is available (primary for Xvfb setup)
    // We assume GLX is available since we use Xvfb with +extension GLX
    log_resolver_selection("GLX");
    return glx_resolve;
#elif defined(HAVE_SDL2)
    log_resolver_selection("SDL");
    return sdl_resolve;
#elif defined(HAVE_EGL)
    log_resolver_selection("EGL");
    return egl_resolve;
#else
    // Fallback: return nullptr (will cause projectM init to fail, which is correct)
    log_resolver_selection("NONE (no backend available)");
    return nullptr;
#endif
}

void log_resolver_selection(const char* backend_name) {
    std::fprintf(stderr, "[gl-resolver] Selected backend: %s\n", backend_name);
}

} // namespace gl_resolver
