// PR #942 Migration - GL Diagnostics Utility
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Standalone utility to diagnose GL context and resolver availability

#include "gl_proc_resolver.hpp"
#include <cstdio>
#include <cstdlib>

#ifdef __linux__
#include <GL/glx.h>
#include <GL/gl.h>
#include <X11/Xlib.h>
#endif

void print_gl_info() {
#ifdef __linux__
    const char* display_name = std::getenv("DISPLAY");
    if (!display_name) {
        std::fprintf(stderr, "ERROR: DISPLAY environment variable not set\n");
        return;
    }

    std::fprintf(stderr, "Display: %s\n", display_name);

    Display* dpy = XOpenDisplay(display_name);
    if (!dpy) {
        std::fprintf(stderr, "ERROR: Failed to open X display\n");
        return;
    }

    int screen = DefaultScreen(dpy);
    std::fprintf(stderr, "Screen: %d\n", screen);

    // Check GLX extension
    int glx_major, glx_minor;
    if (!glXQueryVersion(dpy, &glx_major, &glx_minor)) {
        std::fprintf(stderr, "ERROR: GLX not available\n");
        XCloseDisplay(dpy);
        return;
    }

    std::fprintf(stderr, "GLX Version: %d.%d\n", glx_major, glx_minor);

    // Choose visual
    int attribs[] = {
        GLX_RGBA,
        GLX_DOUBLEBUFFER,
        GLX_DEPTH_SIZE, 24,
        None
    };

    XVisualInfo* vis_info = glXChooseVisual(dpy, screen, attribs);
    if (!vis_info) {
        std::fprintf(stderr, "ERROR: Failed to choose GLX visual\n");
        XCloseDisplay(dpy);
        return;
    }

    // Create context
    GLXContext ctx = glXCreateContext(dpy, vis_info, nullptr, True);
    if (!ctx) {
        std::fprintf(stderr, "ERROR: Failed to create GLX context\n");
        XFree(vis_info);
        XCloseDisplay(dpy);
        return;
    }

    // Create dummy window
    XSetWindowAttributes swa;
    swa.colormap = XCreateColormap(dpy, RootWindow(dpy, screen),
                                    vis_info->visual, AllocNone);
    swa.event_mask = ExposureMask | KeyPressMask;
    
    Window win = XCreateWindow(dpy, RootWindow(dpy, screen), 0, 0, 100, 100,
                                0, vis_info->depth, InputOutput, vis_info->visual,
                                CWColormap | CWEventMask, &swa);

    // Make context current
    if (!glXMakeCurrent(dpy, win, ctx)) {
        std::fprintf(stderr, "ERROR: Failed to make GLX context current\n");
        glXDestroyContext(dpy, ctx);
        XFree(vis_info);
        XCloseDisplay(dpy);
        return;
    }

    std::fprintf(stderr, "GL Context: Current\n");

    // Get GL info
    const GLubyte* version = glGetString(GL_VERSION);
    const GLubyte* vendor = glGetString(GL_VENDOR);
    const GLubyte* renderer = glGetString(GL_RENDERER);
    const GLubyte* glsl_version = glGetString(GL_SHADING_LANGUAGE_VERSION);

    if (version) std::fprintf(stderr, "GL Version: %s\n", version);
    if (vendor) std::fprintf(stderr, "GL Vendor: %s\n", vendor);
    if (renderer) std::fprintf(stderr, "GL Renderer: %s\n", renderer);
    if (glsl_version) std::fprintf(stderr, "GLSL Version: %s\n", glsl_version);

    // Test resolver
    std::fprintf(stderr, "\nTesting GL Proc Resolver:\n");
    auto resolver = gl_resolver::get_resolver();
    if (resolver) {
        std::fprintf(stderr, "Resolver: Available\n");
        
        // Test loading a common function
        void* proc = resolver("glGetString", nullptr);
        std::fprintf(stderr, "glGetString: %s\n", proc ? "Loaded" : "Failed");
        
        proc = resolver("glClear", nullptr);
        std::fprintf(stderr, "glClear: %s\n", proc ? "Loaded" : "Failed");
        
        proc = resolver("glGenTextures", nullptr);
        std::fprintf(stderr, "glGenTextures: %s\n", proc ? "Loaded" : "Failed");
    } else {
        std::fprintf(stderr, "Resolver: NOT AVAILABLE\n");
    }

    // Cleanup
    glXMakeCurrent(dpy, None, nullptr);
    glXDestroyContext(dpy, ctx);
    XDestroyWindow(dpy, win);
    XFree(vis_info);
    XCloseDisplay(dpy);

    std::fprintf(stderr, "\nDiagnostics: PASS\n");
#else
    std::fprintf(stderr, "ERROR: GL diagnostics not implemented for this platform\n");
#endif
}

int main() {
    std::fprintf(stderr, "=== GL Diagnostics Utility ===\n\n");
    print_gl_info();
    return 0;
}
