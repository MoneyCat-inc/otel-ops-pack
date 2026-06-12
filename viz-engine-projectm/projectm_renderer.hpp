// PR #942 Migration - projectM Library Integration
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Wrapper for projectM library with GL context management

#ifndef PROJECTM_RENDERER_HPP
#define PROJECTM_RENDERER_HPP

#include "gl_proc_resolver.hpp"
#include <cstddef>
#include <string>
#include <projectM-4/projectM.h>

namespace pm_renderer {

// GL context creation result
enum class ContextResult {
    Success,
    Failed,
    AlreadyCurrent
};

// projectM Renderer wrapper
// Manages GL context lifecycle and projectM instance
class ProjectMRenderer {
public:
    ProjectMRenderer();
    ~ProjectMRenderer();

    // Non-copyable, non-movable (for now)
    ProjectMRenderer(const ProjectMRenderer&) = delete;
    ProjectMRenderer& operator=(const ProjectMRenderer&) = delete;

    // Initialize: create GL context and projectM instance
    // Returns true on success
    // PRECONDITION: Display must be available (e.g., DISPLAY=:99)
    bool initialize(int width, int height, const std::string& preset_path);

    // Cleanup: destroy projectM instance and GL context
    void shutdown();

    // Feed audio samples to projectM
    // samples: interleaved stereo float32 samples [-1.0, 1.0]
    // count: number of samples (not frames)
    void feed_audio(const float* samples, size_t count);

    // Render one frame
    // Returns true on success
    bool render_frame();

    // Check if initialized
    bool is_initialized() const { return instance_ != nullptr; }

    // Get GL version string (for diagnostics)
    const char* get_gl_version() const { return gl_version_.c_str(); }

    // Get renderer backend name (for diagnostics)
    const char* get_backend_name() const { return backend_name_.c_str(); }

private:
    // Create GL context (GLX for Xvfb)
    ContextResult create_gl_context(int width, int height);
    
    // Make GL context current
    bool make_context_current();
    
    // Destroy GL context
    void destroy_gl_context();
    
    // Verify GL context is current (for diagnostics)
    bool verify_context_current();

    projectm_handle instance_;
    void* gl_context_;  // GLXContext or equivalent
    void* gl_display_; // Display* for GLX
    int width_;
    int height_;
    std::string gl_version_;
    std::string backend_name_;
    bool context_created_;
};

} // namespace pm_renderer

#endif // PROJECTM_RENDERER_HPP
