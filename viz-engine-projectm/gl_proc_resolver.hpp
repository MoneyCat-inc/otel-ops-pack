// PR #942 Migration - GL Proc Resolver
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Platform-adaptive OpenGL function pointer resolver for projectM

#ifndef GL_PROC_RESOLVER_HPP
#define GL_PROC_RESOLVER_HPP

#include <cstddef>

// projectM callback signature for GL proc resolution.
// Signature verified against PR #942 headers.
typedef void* (*projectm_gl_load_proc_t)(const char* name, void* user_data);

namespace gl_resolver {

// GLX resolver (for Linux/X11/GLX contexts)
// Used when GL context is created via GLX (e.g., Xvfb with GLX extension)
void* glx_resolve(const char* name, void* user_data);

// SDL resolver (for SDL-created GL contexts)
// Used when GL context is created via SDL_GL_CreateContext
void* sdl_resolve(const char* name, void* user_data);

// EGL resolver (for EGL contexts)
// Used when GL context is created via EGL
void* egl_resolve(const char* name, void* user_data);

// Auto-detect and return appropriate resolver based on available backends
// Returns GLX resolver by default (matches current Xvfb setup)
projectm_gl_load_proc_t get_resolver();

// Log resolver selection (for diagnostics)
void log_resolver_selection(const char* backend_name);

} // namespace gl_resolver

#endif // GL_PROC_RESOLVER_HPP
