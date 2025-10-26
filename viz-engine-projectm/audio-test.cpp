// Gate #013C - Job A - Audio Injector Test
// Gate #019 - Job R1 - Envelope Follower Validation
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Validate Pearson r >= 0.78 for envelope follower

#include "audio-injector.hpp"
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

namespace {

constexpr int kSampleRate = 44100;
constexpr int kDurationSeconds = 6;
constexpr size_t kChunkSamples = static_cast<size_t>(kSampleRate / 10); // 100 ms windows
constexpr float kPearsonTarget = 0.78f;  // Gate #019: Lowered from 0.90 to 0.78
constexpr float kPi = 3.14159265358979323846f;
constexpr float kRmsWindowMs = 100.0f;

float pearson_r(const std::vector<float>& x, const std::vector<float>& y) {
    if (x.size() != y.size() || x.empty()) return 0.0f;

    const size_t n = x.size();
    double sum_x = 0.0;
    double sum_y = 0.0;
    double sum_xy = 0.0;
    double sum_x2 = 0.0;
    double sum_y2 = 0.0;

    for (size_t i = 0; i < n; ++i) {
        sum_x += x[i];
        sum_y += y[i];
        sum_xy += static_cast<double>(x[i]) * y[i];
        sum_x2 += static_cast<double>(x[i]) * x[i];
        sum_y2 += static_cast<double>(y[i]) * y[i];
    }

    const double numerator = n * sum_xy - sum_x * sum_y;
    const double denominator = std::sqrt((n * sum_x2 - sum_x * sum_x) *
                                         (n * sum_y2 - sum_y * sum_y));

    if (denominator < 1e-12) return 0.0f;
    return static_cast<float>(numerator / denominator);
}

float compute_chunk_rms(const int16_t* samples, size_t count) {
    if (!samples || count == 0) return 0.0f;

    double sum_sq = 0.0;
    for (size_t i = 0; i < count; ++i) {
        const float sample = static_cast<float>(samples[i]) / 32768.0f;
        sum_sq += sample * sample;
    }

    return static_cast<float>(std::sqrt(sum_sq / static_cast<double>(count)));
}

std::vector<float> compute_rms_series(const std::vector<int16_t>& samples) {
    std::vector<float> rms_values;
    rms_values.reserve((samples.size() + kChunkSamples - 1) / kChunkSamples);

    for (size_t offset = 0; offset < samples.size(); offset += kChunkSamples) {
        const size_t count = std::min(kChunkSamples, samples.size() - offset);
        rms_values.push_back(compute_chunk_rms(samples.data() + offset, count));
    }

    return rms_values;
}

std::vector<int16_t> generate_sine_burst() {
    const float frequency_hz = 440.0f; // A4
    std::vector<int16_t> samples(static_cast<size_t>(kSampleRate) * kDurationSeconds);

    for (size_t i = 0; i < samples.size(); ++i) {
        const float t = static_cast<float>(i) / kSampleRate;
        float amplitude = 0.0f;

        if (t >= 2.0f && t < 4.0f) {
            amplitude = 0.7f * std::sin(2.0f * kPi * frequency_hz * t);
        }

        samples[i] = static_cast<int16_t>(amplitude * 32767.0f);
    }

    return samples;
}

std::vector<float> expected_sine_burst_envelope() {
    std::vector<float> envelope;
    envelope.reserve(kDurationSeconds * 10);

    for (int window = 0; window < kDurationSeconds * 10; ++window) {
        const float t = window / 10.0f;
        const bool active = (t >= 2.0f && t < 4.0f);
        const float amplitude = active ? 0.7f : 0.0f;
        // RMS of a pure sine with amplitude A equals A / sqrt(2)
        envelope.push_back(amplitude / std::sqrt(2.0f));
    }

    return envelope;
}

std::vector<int16_t> generate_amplitude_modulated_sine() {
    const float carrier_hz = 440.0f;
    const float mod_hz = 2.0f;
    const float carrier_amplitude = 0.8f;
    const float mod_depth = 0.6f; // envelope varies between 0.2 and 1.0

    std::vector<int16_t> samples(static_cast<size_t>(kSampleRate) * kDurationSeconds);

    for (size_t i = 0; i < samples.size(); ++i) {
        const float t = static_cast<float>(i) / kSampleRate;
        const float envelope = 1.0f - mod_depth / 2.0f +
                               (mod_depth / 2.0f) * std::sin(2.0f * kPi * mod_hz * t);
        const float sample = carrier_amplitude * envelope *
                             std::sin(2.0f * kPi * carrier_hz * t);
        samples[i] = static_cast<int16_t>(sample * 32767.0f);
    }

    return samples;
}

std::vector<float> expected_amplitude_modulated_envelope() {
    std::vector<float> envelope, window;
    envelope.reserve(kDurationSeconds * 10);

    const size_t window_samples = static_cast<size_t>((kRmsWindowMs * kSampleRate / 1000.0f) + 0.5f);
    window.assign(window_samples, 0.0f);

    const auto samples = generate_amplitude_modulated_sine();

    size_t window_pos = 0;
    double sum_squares = 0.0;
    bool window_filled = false;

    for (size_t i = 0; i < samples.size(); ++i) {
        const float sample = static_cast<float>(samples[i]) / 32768.0f;
        const float squared = sample * sample;

        if (window_filled) {
            sum_squares -= window[window_pos];
        }

        window[window_pos] = squared;
        sum_squares += squared;
        window_pos = (window_pos + 1) % window_samples;

        if (!window_filled && window_pos == 0) {
            window_filled = true;
        }

        if ((i + 1) % kChunkSamples == 0) {
            if (window_filled) {
                envelope.push_back(static_cast<float>(
                    std::sqrt(sum_squares / static_cast<double>(window_samples))
                ));
            } else {
                envelope.push_back(0.0f);
            }
        }
    }

    return envelope;
}

struct TestCaseResult {
    std::string name;
    float correlation;
    float threshold;
    bool pass;
};

// Gate #019B: Test envelope follower via AudioBuffer (hybrid: inst + rms100)
TestCaseResult run_envelope_test(const std::string& name,
                                 const std::vector<int16_t>& samples,
                                 const std::vector<float>& expected,
                                 bool use_rms100 = false,
                                 float threshold = 0.78f) {
    // Gate #019B: Create AudioBuffer and feed samples through it
    audio::AudioBuffer buffer(8192);
    std::vector<float> envelope_values;
    envelope_values.reserve(expected.size());
    
    // Process samples in chunks and capture envelope at chunk boundaries
    for (size_t offset = 0; offset < samples.size(); offset += kChunkSamples) {
        const size_t count = std::min(kChunkSamples, samples.size() - offset);
        buffer.write(samples.data() + offset, count, 1);  // Mono
        
        // Gate #019B: Select envelope type based on test scenario
        float env_value = use_rms100 ? buffer.envelope_rms100() : buffer.envelope_inst();
        envelope_values.push_back(env_value);
    }
    
    // Compare measured envelope to expected
    const float correlation = pearson_r(expected, envelope_values);
    return {name, correlation, threshold, correlation >= threshold};
}

void print_result(const TestCaseResult& result) {
    std::cout << result.name << '\n';
    std::cout << "  Pearson r = " << std::fixed << std::setprecision(4)
              << result.correlation << " (target >= " << std::setprecision(2) 
              << result.threshold << ")\n";
    std::cout << "  Result: " << (result.pass ? "PASS" : "FAIL") << "\n\n";
}

} // namespace

int main() {
    std::cout << "Gate #019B - Hybrid Envelope Detector Validation Test\n";
    std::cout << "======================================================\n\n";

    // Gate #019B: Test instantaneous envelope on Sine Burst (transients)
    const auto burst_result = run_envelope_test(
        "Test 1: Sine Burst (Instantaneous Envelope)",
        generate_sine_burst(),
        expected_sine_burst_envelope(),
        false,  // use_rms100 = false (use instantaneous)
        0.90f); // Higher threshold for transients

    // Gate #019B: Test 100ms RMS envelope on AM Sine (slow modulation)
    const auto am_result = run_envelope_test(
        "Test 2: AM Sine (100ms RMS Envelope)",
        generate_amplitude_modulated_sine(),
        expected_amplitude_modulated_envelope(),
        true,   // use_rms100 = true (use RMS envelope)
        0.88f); // Target for slow modulation

    print_result(burst_result);
    print_result(am_result);

    const bool all_green = burst_result.pass && am_result.pass;

    std::cout << "--------------------------------------------------\n";
    if (all_green) {
        std::cout << "Gate #019B: HYBRID ENVELOPE DETECTOR VALIDATION PASS\n";
        std::cout << "  Instantaneous envelope (10ms/250ms): validated for transients\n";
        std::cout << "  100ms RMS envelope: validated for slow modulation\n";
        std::cout << "  AudioBuffer hybrid integration confirmed\n";
        return 0;
    }

    std::cout << "Gate #019B: HYBRID ENVELOPE DETECTOR VALIDATION FAIL\n";
    if (!burst_result.pass) {
        std::cout << "  - Sine burst (instantaneous) correlation below target\n";
    }
    if (!am_result.pass) {
        std::cout << "  - AM sine (RMS100) correlation below target\n";
    }
    return 1;
}
