// Gate #013C - Job B - Audio Integration Test
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: 60s AM-sine integration test (underrun <1%, Pearson r ≥0.70)

#include "audio-injector.hpp"
#include "projectm-injector.hpp"
#include <algorithm>
#include <cmath>
#include <chrono>
#include <iostream>
#include <iomanip>
#include <vector>
#include <thread>

namespace {

constexpr int kSampleRate = 44100;
constexpr int kTestDurationSeconds = 60;
constexpr int kChunkSamples = 2205;  // 50ms chunks
constexpr float kPearsonTarget = 0.70f;
constexpr float kUnderrunTarget = 0.01f;  // <1%
constexpr float kPi = 3.14159265358979323846f;

float pearson_r(const std::vector<float>& x, const std::vector<float>& y) {
    if (x.size() != y.size() || x.empty()) return 0.0f;

    const size_t n = x.size();
    double sum_x = 0.0, sum_y = 0.0, sum_xy = 0.0, sum_x2 = 0.0, sum_y2 = 0.0;

    for (size_t i = 0; i < n; ++i) {
        sum_x += x[i];
        sum_y += y[i];
        sum_xy += static_cast<double>(x[i]) * y[i];
        sum_x2 += static_cast<double>(x[i]) * x[i];
        sum_y2 += static_cast<double>(y[i]) * y[i];
    }

    const double num = n * sum_xy - sum_x * sum_y;
    const double denom = std::sqrt((n * sum_x2 - sum_x * sum_x) * 
                                   (n * sum_y2 - sum_y * sum_y));

    return (denom < 1e-12) ? 0.0f : static_cast<float>(num / denom);
}

// Generate AM-sine (carrier=440Hz, mod=2Hz)
std::vector<int16_t> generate_am_sine_chunk(size_t chunk_idx, size_t chunk_size) {
    const float carrier_hz = 440.0f;
    const float mod_hz = 2.0f;
    const float carrier_amp = 0.8f;
    const float mod_depth = 0.6f;

    std::vector<int16_t> samples(chunk_size);
    const size_t offset = chunk_idx * chunk_size;

    for (size_t i = 0; i < chunk_size; ++i) {
        const float t = (offset + i) / static_cast<float>(kSampleRate);
        const float envelope = 1.0f - mod_depth / 2.0f +
                              (mod_depth / 2.0f) * std::sin(2.0f * kPi * mod_hz * t);
        const float sample = carrier_amp * envelope *
                           std::sin(2.0f * kPi * carrier_hz * t);
        samples[i] = static_cast<int16_t>(sample * 32767.0f);
    }

    return samples;
}

// Compute expected RMS at time t
float expected_rms_at_time(float t) {
    const float carrier_amp = 0.8f;
    const float mod_hz = 2.0f;
    const float mod_depth = 0.6f;

    const float envelope = 1.0f - mod_depth / 2.0f +
                          (mod_depth / 2.0f) * std::sin(2.0f * kPi * mod_hz * t);
    const float amplitude = carrier_amp * envelope;
    return amplitude / std::sqrt(2.0f);  // RMS of sine
}

struct TestMetrics {
    size_t total_chunks = 0;
    size_t underrun_count = 0;
    std::vector<float> measured_rms;
    std::vector<float> expected_rms;
    float max_jitter_ms = 0.0f;
};

TestMetrics run_integration_test() {
    TestMetrics metrics;
    audio::AudioBuffer buffer(8192);  // Ring buffer
    audio::ProjectMInjector injector(buffer);

    const size_t total_chunks = (kSampleRate * kTestDurationSeconds) / kChunkSamples;
    std::vector<float> output_buffer(kChunkSamples);

    std::cout << "Starting 60s AM-sine integration test...\n";
    std::cout << "  Sample rate: " << kSampleRate << " Hz\n";
    std::cout << "  Chunk size: " << kChunkSamples << " samples (50ms)\n";
    std::cout << "  Total chunks: " << total_chunks << "\n\n";

    auto test_start = std::chrono::steady_clock::now();

    for (size_t chunk_idx = 0; chunk_idx < total_chunks; ++chunk_idx) {
        auto chunk_start = std::chrono::steady_clock::now();

        // Generate and feed audio
        auto samples = generate_am_sine_chunk(chunk_idx, kChunkSamples);
        buffer.write(samples.data(), kChunkSamples, 1);  // Mono

        // Simulate renderer consuming audio (this is where projectM::feedPCM would be called)
        size_t samples_consumed = injector.prepare_samples(output_buffer.data(), kChunkSamples);

        // Track underruns
        if (samples_consumed < kChunkSamples) {
            ++metrics.underrun_count;
        }

        // Track RMS every 50ms
        const float t = chunk_idx * kChunkSamples / static_cast<float>(kSampleRate);
        metrics.measured_rms.push_back(injector.rms());
        metrics.expected_rms.push_back(expected_rms_at_time(t));

        ++metrics.total_chunks;

        // Measure timing jitter
        auto chunk_end = std::chrono::steady_clock::now();
        auto chunk_duration_ms = std::chrono::duration<float, std::milli>(chunk_end - chunk_start).count();
        metrics.max_jitter_ms = std::max(metrics.max_jitter_ms, chunk_duration_ms);

        // Simulate 50ms real-time cadence
        std::this_thread::sleep_until(chunk_start + std::chrono::milliseconds(50));

        // Progress indicator
        if (chunk_idx % 200 == 0) {  // Every 10s
            std::cout << "  Progress: " << (chunk_idx * 100 / total_chunks) << "%\r" << std::flush;
        }
    }

    auto test_end = std::chrono::steady_clock::now();
    auto test_duration_s = std::chrono::duration<float>(test_end - test_start).count();

    std::cout << "  Progress: 100%\n";
    std::cout << "  Actual duration: " << std::fixed << std::setprecision(1) 
              << test_duration_s << "s\n\n";

    return metrics;
}

void print_results(const TestMetrics& metrics) {
    const float underrun_ratio = static_cast<float>(metrics.underrun_count) / metrics.total_chunks;
    const float pearson = pearson_r(metrics.expected_rms, metrics.measured_rms);

    std::cout << "Integration Test Results\n";
    std::cout << "========================\n\n";

    std::cout << "Buffer Health:\n";
    std::cout << "  Total chunks: " << metrics.total_chunks << "\n";
    std::cout << "  Underruns: " << metrics.underrun_count << "\n";
    std::cout << "  Underrun ratio: " << std::fixed << std::setprecision(4) 
              << (underrun_ratio * 100.0f) << "% (target <" 
              << (kUnderrunTarget * 100.0f) << "%)\n";
    std::cout << "  Result: " << (underrun_ratio < kUnderrunTarget ? "PASS" : "FAIL") << "\n\n";

    std::cout << "Signal Tracking:\n";
    std::cout << "  Pearson r: " << std::fixed << std::setprecision(4) << pearson 
              << " (target >=" << kPearsonTarget << ")\n";
    std::cout << "  Result: " << (pearson >= kPearsonTarget ? "PASS" : "FAIL") << "\n\n";

    std::cout << "Stability:\n";
    std::cout << "  Max tick jitter: " << std::fixed << std::setprecision(2) 
              << metrics.max_jitter_ms << " ms\n\n";

    std::cout << "========================\n";

    const bool all_pass = (underrun_ratio < kUnderrunTarget) && (pearson >= kPearsonTarget);

    if (all_pass) {
        std::cout << "Gate #013C Job B: INTEGRATION PASS\n";
        std::cout << "  Buffer health and signal tracking verified\n";
        std::cout << "  Ready for renderer integration\n";
    } else {
        std::cout << "Gate #013C Job B: INTEGRATION FAIL\n";
        if (underrun_ratio >= kUnderrunTarget) {
            std::cout << "  - Underrun ratio too high\n";
        }
        if (pearson < kPearsonTarget) {
            std::cout << "  - Signal tracking correlation too low\n";
        }
    }
}

} // namespace

int main() {
    std::cout << "Gate #013C - Job B - Audio Integration Test\n";
    std::cout << "============================================\n\n";

    const auto metrics = run_integration_test();
    print_results(metrics);

    const float underrun_ratio = static_cast<float>(metrics.underrun_count) / metrics.total_chunks;
    const float pearson = pearson_r(metrics.expected_rms, metrics.measured_rms);

    return (underrun_ratio < kUnderrunTarget && pearson >= kPearsonTarget) ? 0 : 1;
}

