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
    , envelope_inst_(0.0f)
    , rms_window_size_(0)
    , rms_window_pos_(0)
    , rms_sum_squares_(0.0)
    , rms_window_filled_(false)
{
    // Gate #019: Initialize instantaneous envelope follower
    init_envelope(10.0f, 250.0f, 44100.0f);  // 10ms attack, 250ms release @ 44.1kHz
    
    // Gate #019C: Initialize exact 100ms windowed RMS
    init_rms_window(100.0f, 44100.0f);  // 100ms window @ 44.1kHz
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
    
    // Gate #019: Update instantaneous envelope follower with attack/release
    // Attack when signal rises, release when signal falls
    float error = abs_sample - envelope_inst_;
    if (error > 0.0f) {
        // Attack: signal rising
        envelope_inst_ += attack_coeff_ * error;
    } else {
        // Release: signal falling
        envelope_inst_ += release_coeff_ * error;
    }
    
    // Gate #019C: Update exact 100ms windowed RMS
    if (rms_window_size_ > 0) {
        float sample_squared = sample * sample;
        
        // Subtract old value if window is full
        if (rms_window_filled_) {
            rms_sum_squares_ -= rms_window_[rms_window_pos_];
        }
        
        // Add new squared sample
        rms_window_[rms_window_pos_] = sample_squared;
        rms_sum_squares_ += sample_squared;
        
        // Advance position
        rms_window_pos_ = (rms_window_pos_ + 1) % rms_window_size_;
        
        // Mark as filled after first complete pass
        if (rms_window_pos_ == 0) {
            rms_window_filled_ = true;
        }
    }
}

void AudioBuffer::init_envelope(float attack_ms, float release_ms, float sample_rate) {
    // Gate #019: Calculate instantaneous envelope follower coefficients
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

void AudioBuffer::init_rms_window(float window_ms, float sample_rate) {
    // Gate #019C: Initialize exact windowed RMS (sliding window)
    // Calculate window size in samples
    rms_window_size_ = static_cast<size_t>((window_ms * sample_rate / 1000.0f) + 0.5f);
    
    // Minimum window size
    if (rms_window_size_ < 1) rms_window_size_ = 1;
    
    // Allocate circular buffer for squared samples
    rms_window_.resize(rms_window_size_, 0.0f);
    rms_window_pos_ = 0;
    rms_sum_squares_ = 0.0;
    rms_window_filled_ = false;
}

} // namespace audio


