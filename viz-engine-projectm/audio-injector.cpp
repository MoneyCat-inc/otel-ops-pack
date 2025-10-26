// Gate #013C - Job A - Audio Injector Implementation
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Ring buffer with PCM format conversion & stats tracking

#include "audio-injector.hpp"
#include <cmath>
#include <algorithm>
#include <cstring>

namespace audio {

AudioBuffer::AudioBuffer(size_t capacity)
    : buffer_(capacity, 0.0f)
    , capacity_(capacity)
    , write_pos_(0)
    , read_pos_(0)
    , size_(0)
    , rms_(0.0f)
    , peak_(0.0f)
    , envelope_(0.0f)
{
    // Gate #019: Initialize envelope follower with default parameters
    init_envelope(20.0f, 150.0f, 44100.0f);  // 20ms attack, 150ms release @ 44.1kHz
}

size_t AudioBuffer::write(const int16_t* samples, size_t count, int channels) {
    if (!samples || count == 0) return 0;
    
    size_t samples_to_write = std::min(count / channels, space());
    
    // Handle back-pressure: if full, drop oldest samples
    if (samples_to_write < count / channels) {
        size_t drop_count = (count / channels) - samples_to_write;
        read_pos_ = (read_pos_ + drop_count) % capacity_;
        size_ -= std::min(size_, drop_count);
    }
    
    // Convert and write samples
    for (size_t i = 0; i < samples_to_write; ++i) {
        float sample;
        
        if (channels == 1) {
            // Mono
            sample = i16_to_f32(samples[i]);
        } else if (channels == 2) {
            // Stereo: downmix to mono (average L+R)
            float left = i16_to_f32(samples[i * 2]);
            float right = i16_to_f32(samples[i * 2 + 1]);
            sample = (left + right) * 0.5f;
        } else {
            // Unsupported channel count, take first channel
            sample = i16_to_f32(samples[i * channels]);
        }
        
        buffer_[write_pos_] = sample;
        write_pos_ = (write_pos_ + 1) % capacity_;
        ++size_;
        
        update_stats(sample);
    }
    
    return samples_to_write;
}

size_t AudioBuffer::read(float* output, size_t count) {
    if (!output || count == 0) return 0;
    
    size_t samples_to_read = std::min(count, size_);
    
    for (size_t i = 0; i < samples_to_read; ++i) {
        output[i] = buffer_[read_pos_];
        read_pos_ = (read_pos_ + 1) % capacity_;
        --size_;
    }
    
    // Zero-fill if underrun
    if (samples_to_read < count) {
        std::memset(output + samples_to_read, 0, (count - samples_to_read) * sizeof(float));
    }
    
    return samples_to_read;
}

void AudioBuffer::update_stats(float sample) {
    float abs_sample = std::abs(sample);
    
    // Update peak (max absolute value)
    if (abs_sample > peak_) {
        peak_ = abs_sample;
    }
    
    // Update RMS (exponential moving average for efficiency)
    const float alpha = 0.01f;  // Smoothing factor
    rms_ = alpha * (sample * sample) + (1.0f - alpha) * rms_;
    
    // Gate #019: Update envelope follower with attack/release
    // Attack when signal rises, release when signal falls
    float error = abs_sample - envelope_;
    if (error > 0.0f) {
        // Attack: signal rising
        envelope_ += attack_coeff_ * error;
    } else {
        // Release: signal falling
        envelope_ += release_coeff_ * error;
    }
}

void AudioBuffer::init_envelope(float attack_ms, float release_ms, float sample_rate) {
    // Gate #019: Calculate envelope follower coefficients
    // Convert time constants (ms) to per-sample coefficients
    // Formula: coeff = 1 - exp(-1 / (time_ms * sample_rate / 1000))
    // This gives proper exponential attack/release behavior
    
    float attack_samples = attack_ms * sample_rate / 1000.0f;
    float release_samples = release_ms * sample_rate / 1000.0f;
    
    // Prevent division by zero
    if (attack_samples < 1.0f) attack_samples = 1.0f;
    if (release_samples < 1.0f) release_samples = 1.0f;
    
    attack_coeff_ = 1.0f - std::exp(-1.0f / attack_samples);
    release_coeff_ = 1.0f - std::exp(-1.0f / release_samples);
}

} // namespace audio


