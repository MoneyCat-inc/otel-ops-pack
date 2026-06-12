// PR #942 Migration - projectM Library Integration Implementation
// ECRR: BossCat OEM | Executor: Cursor{Implementer}

#include "projectm_renderer.hpp"
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <stdexcept>

// Include projectM headers (PR #942)
#include <projectM-4/projectM.h>

// GLX includes (for GL context creation)
#ifdef __linux__
#include <GL/glx.h>
#include <GL/gl.h>
#include <X11/Xlib.h>
#endif

namespace pm_renderer {

ProjectMRenderer::ProjectMRenderer()
    : instance_(nullptr)
    , gl_context_(nullptr)
    , gl_display_(nullptr)
    , width_(0)
    , height_(0)
    , context_created_(false)
{
    std::fprintf(stderr, "[pm-renderer] ProjectMRenderer created\n");
}

ProjectMRenderer::~ProjectMRenderer() {
    shutdown();
}

bool ProjectMRenderer::initialize(int width, int height, const std::string& preset_path) {
    if (instance_) {
        std::fprintf(stderr, "[pm-renderer] Already initialized\n");
        return false;
    }

    width_ = width;
    height_ = height;

    std::fprintf(stderr, "[pm-renderer] Initializing: %dx%d, presets: %s\n",
                width, height, preset_path.c_str());

    // Step 1: Create GL context
    auto ctx_result = create_gl_context(width, height);
    if (ctx_result != ContextResult::Success) {
        std::fprintf(stderr, "[pm-renderer] Failed to create GL context\n");
        return false;
    }

    // Step 2: Make context current (CRITICAL: must be current before projectM creation)
    if (!make_context_current()) {
        std::fprintf(stderr, "[pm-renderer] Failed to make GL context current\n");
        destroy_gl_context();
        return false;
    }

    // Step 3: Verify context is current (diagnostics)
    if (!verify_context_current()) {
        std::fprintf(stderr, "[pm-renderer] WARNING: GL context verification failed\n");
        // Continue anyway, but log warning
    }

    // Step 4: Get GL version string (for diagnostics)
    const GLubyte* version_str = glGetString(GL_VERSION);
    if (version_str) {
        gl_version_ = reinterpret_cast<const char*>(version_str);
        std::fprintf(stderr, "[pm-renderer] GL Version: %s\n", gl_version_.c_str());
    }

    // Step 5: Get resolver and backend name
    auto resolver = gl_resolver::get_resolver();
    if (!resolver) {
        std::fprintf(stderr, "[pm-renderer] ERROR: No GL proc resolver available\n");
        destroy_gl_context();
        return false;
    }

    backend_name_ = "GLX";  // Default for Xvfb setup
    std::fprintf(stderr, "[pm-renderer] Using resolver: %s\n", backend_name_.c_str());

    // Step 6: Create projectM instance with resolver-aware API
    try {
        std::fprintf(stderr, "[pm-renderer] Creating projectM instance with GL proc resolver...\n");
        std::fprintf(stderr, "[pm-renderer] Resolver function: %p\n", (void*)resolver);

        instance_ = projectm_create_with_opengl_load_proc(resolver, nullptr);
    } catch (const std::exception& e) {
        std::fprintf(stderr, "[pm-renderer] Exception creating projectM: %s\n", e.what());
        destroy_gl_context();
        return false;
    }

    if (!instance_) {
        std::fprintf(stderr, "[pm-renderer] Failed to create projectM instance\n");
        destroy_gl_context();
        return false;
    }

    // Configure viewport size (required for rendering)
    projectm_set_window_size(instance_, static_cast<size_t>(width_), static_cast<size_t>(height_));

    // Load preset file or URL if provided
    if (!preset_path.empty()) {
        std::fprintf(stderr, "[pm-renderer] Loading preset: %s\n", preset_path.c_str());
        projectm_load_preset_file(instance_, preset_path.c_str(), false);
    }

    // Log comprehensive initialization diagnostics
    std::fprintf(stderr, "[pm-renderer] ===== Initialization Complete =====\n");
    std::fprintf(stderr, "[pm-renderer] Backend: %s\n", backend_name_.c_str());
    std::fprintf(stderr, "[pm-renderer] GL Version: %s\n", gl_version_.c_str());
    
    // Get GL vendor and renderer (for diagnostics)
    const GLubyte* vendor_str = glGetString(GL_VENDOR);
    const GLubyte* renderer_str = glGetString(GL_RENDERER);
    if (vendor_str) {
        std::fprintf(stderr, "[pm-renderer] GL Vendor: %s\n", reinterpret_cast<const char*>(vendor_str));
    }
    if (renderer_str) {
        std::fprintf(stderr, "[pm-renderer] GL Renderer: %s\n", reinterpret_cast<const char*>(renderer_str));
    }
    
    // Verify context is still current
    if (verify_context_current()) {
        std::fprintf(stderr, "[pm-renderer] Context verification: PASS\n");
    } else {
        std::fprintf(stderr, "[pm-renderer] Context verification: FAIL (WARNING)\n");
    }
    
    std::fprintf(stderr, "[pm-renderer] Resolution: %dx%d\n", width_, height_);
    std::fprintf(stderr, "[pm-renderer] Preset path: %s\n", preset_path.c_str());
    std::fprintf(stderr, "[pm-renderer] ====================================\n");
    
    std::fprintf(stderr, "[pm-renderer] Successfully initialized projectM\n");
    return true;
}

void ProjectMRenderer::shutdown() {
    if (instance_) {
        std::fprintf(stderr, "[pm-renderer] Destroying projectM instance\n");
        projectm_destroy(instance_);
        instance_ = nullptr;
    }

    destroy_gl_context();
}

void ProjectMRenderer::feed_audio(const float* samples, size_t count) {
    if (!instance_ || !samples || count == 0) return;
    
    // projectM expects interleaved stereo samples
    // count is total samples (frames * 2 for stereo)
    if (count < 2) {
        return;
    }
    if (count % 2 != 0) {
        std::fprintf(stderr, "[pm-renderer] WARNING: odd sample count, dropping last sample\n");
        count -= 1;
    }
    unsigned int frames = static_cast<unsigned int>(count / 2);
    projectm_pcm_add_float(instance_, samples, frames, PROJECTM_STEREO);
}

bool ProjectMRenderer::render_frame() {
    if (!instance_) return false;
    
    projectm_opengl_render_frame(instance_);
    return true;
}

ProjectMRenderer::ContextResult ProjectMRenderer::create_gl_context(int width, int height) {
#ifdef __linux__
    // Open X display
    const char* display_name = std::getenv("DISPLAY");
    if (!display_name) {
        std::fprintf(stderr, "[pm-renderer] DISPLAY environment variable not set\n");
        return ContextResult::Failed;
    }

    gl_display_ = XOpenDisplay(display_name);
    if (!gl_display_) {
        std::fprintf(stderr, "[pm-renderer] Failed to open X display: %s\n", display_name);
        return ContextResult::Failed;
    }

    // Get default screen
    int screen = DefaultScreen((Display*)gl_display_);

    // Choose visual with GL support
    int attribs[] = {
        GLX_RGBA,
        GLX_DOUBLEBUFFER,
        GLX_DEPTH_SIZE, 24,
        GLX_RED_SIZE, 8,
        GLX_GREEN_SIZE, 8,
        GLX_BLUE_SIZE, 8,
        None
    };

    XVisualInfo* vis_info = glXChooseVisual((Display*)gl_display_, screen, attribs);
    if (!vis_info) {
        std::fprintf(stderr, "[pm-renderer] Failed to choose GLX visual\n");
        XCloseDisplay((Display*)gl_display_);
        gl_display_ = nullptr;
        return ContextResult::Failed;
    }

    // Create GLX context
    gl_context_ = glXCreateContext((Display*)gl_display_, vis_info, nullptr, True);
    XFree(vis_info);

    if (!gl_context_) {
        std::fprintf(stderr, "[pm-renderer] Failed to create GLX context\n");
        XCloseDisplay((Display*)gl_display_);
        gl_display_ = nullptr;
        return ContextResult::Failed;
    }

    context_created_ = true;
    std::fprintf(stderr, "[pm-renderer] GLX context created successfully\n");
    return ContextResult::Success;
#else
    std::fprintf(stderr, "[pm-renderer] GL context creation not implemented for this platform\n");
    return ContextResult::Failed;
#endif
}

bool ProjectMRenderer::make_context_current() {
#ifdef __linux__
    if (!gl_context_ || !gl_display_) return false;

    int screen = DefaultScreen((Display*)gl_display_);
    Window root = RootWindow((Display*)gl_display_, screen);

    // Create a dummy window for the context
    // Note: For headless rendering, we might need a pbuffer instead
    XSetWindowAttributes swa;
    swa.colormap = XCreateColormap((Display*)gl_display_, root,
                                    DefaultVisual((Display*)gl_display_, screen), AllocNone);
    swa.event_mask = ExposureMask | KeyPressMask;
    
    Window win = XCreateWindow((Display*)gl_display_, root, 0, 0, width_, height_,
                                0, CopyFromParent, InputOutput, CopyFromParent,
                                CWColormap | CWEventMask, &swa);
    
    if (!win) {
        std::fprintf(stderr, "[pm-renderer] Failed to create window\n");
        return false;
    }

    // Make context current
    if (!glXMakeCurrent((Display*)gl_display_, win, (GLXContext)gl_context_)) {
        std::fprintf(stderr, "[pm-renderer] Failed to make GLX context current\n");
        XDestroyWindow((Display*)gl_display_, win);
        return false;
    }

    std::fprintf(stderr, "[pm-renderer] GL context made current\n");
    return true;
#else
    return false;
#endif
}

void ProjectMRenderer::destroy_gl_context() {
#ifdef __linux__
    if (gl_context_) {
        if (glXGetCurrentContext() == (GLXContext)gl_context_) {
            glXMakeCurrent((Display*)gl_display_, None, nullptr);
        }
        glXDestroyContext((Display*)gl_display_, (GLXContext)gl_context_);
        gl_context_ = nullptr;
    }

    if (gl_display_) {
        XCloseDisplay((Display*)gl_display_);
        gl_display_ = nullptr;
    }

    context_created_ = false;
#endif
}

bool ProjectMRenderer::verify_context_current() {
#ifdef __linux__
    GLXContext current = glXGetCurrentContext();
    if (current != (GLXContext)gl_context_) {
        std::fprintf(stderr, "[pm-renderer] WARNING: Context mismatch\n");
        return false;
    }
    return true;
#else
    return false;
#endif
}

} // namespace pm_renderer
