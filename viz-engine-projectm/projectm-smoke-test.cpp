// PR #942 Migration - Smoke Test
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Minimal runtime test for projectM with new GL proc resolver API

#include "projectm_renderer.hpp"
#include <cstdio>
#include <cstdlib>
#include <exception>
#include <filesystem>
#include <string>

int main(int argc, char* argv[]) {
    std::fprintf(stderr, "=== projectM PR #942 Smoke Test ===\n\n");

    // Get preset path from environment or argument
    std::string preset_path = "/app/presets";
    if (argc > 1) {
        preset_path = argv[1];
    } else if (const char* env_path = std::getenv("PM_PRESET_DIR")) {
        preset_path = env_path;
    }

    // If a directory is provided, pick the first .milk preset if available
    try {
        std::filesystem::path preset_candidate(preset_path);
        if (std::filesystem::is_directory(preset_candidate)) {
            std::string selected;
            for (const auto& entry : std::filesystem::directory_iterator(preset_candidate)) {
                if (!entry.is_regular_file()) continue;
                auto ext = entry.path().extension().string();
                if (ext == ".milk" || ext == ".prjm") {
                    selected = entry.path().string();
                    break;
                }
            }
            if (!selected.empty()) {
                std::fprintf(stderr, "Preset directory detected; selected: %s\n", selected.c_str());
                preset_path = selected;
            } else {
                std::fprintf(stderr, "Preset directory detected; no .milk preset found, using idle://\n");
                preset_path = "idle://";
            }
        }
    } catch (const std::exception& e) {
        std::fprintf(stderr, "Preset path check failed: %s\n", e.what());
        preset_path = "idle://";
    }

    std::fprintf(stderr, "Preset path: %s\n", preset_path.c_str());
    std::fprintf(stderr, "Display: %s\n", std::getenv("DISPLAY") ? std::getenv("DISPLAY") : "(not set)");

    // Create renderer
    pm_renderer::ProjectMRenderer renderer;

    // Initialize (creates GL context, makes it current, creates projectM)
    std::fprintf(stderr, "\nStep 1: Initializing projectM...\n");
    if (!renderer.initialize(1920, 1080, preset_path)) {
        std::fprintf(stderr, "FAILED: Initialization failed\n");
        return 1;
    }

    std::fprintf(stderr, "SUCCESS: projectM initialized\n");
    std::fprintf(stderr, "  Backend: %s\n", renderer.get_backend_name());
    std::fprintf(stderr, "  GL Version: %s\n", renderer.get_gl_version());

    // Feed some dummy audio (silence)
    std::fprintf(stderr, "\nStep 2: Feeding audio samples...\n");
    const size_t sample_count = 8820;  // 0.2s @ 44.1kHz stereo
    float* silence = new float[sample_count];
    for (size_t i = 0; i < sample_count; ++i) {
        silence[i] = 0.0f;
    }
    renderer.feed_audio(silence, sample_count);
    delete[] silence;
    std::fprintf(stderr, "SUCCESS: Audio samples fed\n");

    // Render one frame
    std::fprintf(stderr, "\nStep 3: Rendering frame...\n");
    if (!renderer.render_frame()) {
        std::fprintf(stderr, "FAILED: Frame render failed\n");
        renderer.shutdown();
        return 1;
    }
    std::fprintf(stderr, "SUCCESS: Frame rendered\n");

    // Cleanup
    std::fprintf(stderr, "\nStep 4: Shutting down...\n");
    renderer.shutdown();
    std::fprintf(stderr, "SUCCESS: Cleanup complete\n");

    std::fprintf(stderr, "\n=== Smoke Test PASSED ===\n");
    return 0;
}
