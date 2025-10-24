// Gate #013B - Native Audio Bridge for ProjectM
// ECRR: BossCat - Monitor FIFO and log audio stats (PulseAudio handles actual feed)
// Authority: BossCat OEM | Executor: Cursor{Implementer}
//
// Strategy: This bridge monitors the audio FIFO to verify data flow and compute stats.
// ProjectMSDL (SDL UI) will continue to use PulseAudio pipe-source for actual audio capture.
// This provides evidence that audio is flowing without requiring IPC between processes.

#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <fcntl.h>
#include <unistd.h>
#include <vector>
#include <chrono>

struct AudioStats {
    float rms = 0.0f;
    float peak = 0.0f;
    float ema = 0.0f;
    uint64_t samples = 0;
    std::chrono::steady_clock::time_point last_print;
};

inline float i16_to_f32(int16_t s) {
    return s / 32768.0f;
}

void update_stats(AudioStats& stats, const int16_t* buf, size_t count) {
    float sum_sq = 0.0f;
    float max_val = 0.0f;
    
    for (size_t i = 0; i < count; i++) {
        float val = std::abs(i16_to_f32(buf[i]));
        sum_sq += val * val;
        if (val > max_val) max_val = val;
    }
    
    stats.rms = std::sqrt(sum_sq / count);
    stats.peak = max_val;
    stats.ema = 0.1f * stats.rms + 0.9f * stats.ema;
    stats.samples += count;
}

void maybe_print_stats(AudioStats& stats) {
    auto now = std::chrono::steady_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - stats.last_print);
    
    if (elapsed.count() >= 500) {
        fprintf(stderr, "[pm-bridge] samples=%lu rms=%.4f peak=%.4f ema=%.4f\n",
                stats.samples, stats.rms, stats.peak, stats.ema);
        stats.last_print = now;
    }
}

int main() {
    const char* fifo_path = getenv("PM_AUDIO_FIFO");
    if (!fifo_path) fifo_path = "/tmp/pm-audio.pcm";
    
    fprintf(stderr, "[pm-bridge] Starting (monitor mode)\n");
    fprintf(stderr, "[pm-bridge] FIFO: %s\n", fifo_path);
    
    int fd = open(fifo_path, O_RDONLY);
    if (fd < 0) {
        perror("[pm-bridge] FIFO open failed");
        return 1;
    }
    
    fprintf(stderr, "[pm-bridge] FIFO opened, monitoring stream...\n");
    
    AudioStats stats;
    stats.last_print = std::chrono::steady_clock::now();
    std::vector<int16_t> buffer(4096);
    
    while (true) {
        ssize_t bytes = read(fd, buffer.data(), buffer.size() * sizeof(int16_t));
        
        if (bytes < 0) {
            perror("[pm-bridge] Read error");
            break;
        }
        
        if (bytes == 0) {
            fprintf(stderr, "[pm-bridge] EOF, reopening...\n");
            close(fd);
            sleep(1);
            fd = open(fifo_path, O_RDONLY);
            if (fd < 0) break;
            continue;
        }
        
        size_t samples = bytes / sizeof(int16_t);
        update_stats(stats, buffer.data(), samples);
        maybe_print_stats(stats);
    }
    
    close(fd);
    return 0;
}

