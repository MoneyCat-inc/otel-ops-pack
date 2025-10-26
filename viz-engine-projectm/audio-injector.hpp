// Gate #013C - Job A - Audio Injector Header
// Gate #019B - Hybrid Envelope Detector
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Ring buffer with PCM format conversion (int16 → float32)

#ifndef AUDIO_INJECTOR_HPP
#define AUDIO_INJECTOR_HPP

#include <vector>
#include <cstdint>
#include <cstddef>
#include <cmath>      // Gate #019B: For std::sqrt in envelope_rms100() getter
#include <algorithm>  // Gate #019B: For std::max in envelope_rms100() getter

namespace audio {

// Convert int16 PCM to float32 [-1.0, 1.0]
inline float i16_to_f32(int16_t sample) {
    return sample / 32768.0f;
}

// Ring buffer for audio samples
class AudioBuffer {
public:
    explicit AudioBuffer(size_t capacity = 4096);
    
    // Write samples (int16 PCM) - returns samples written
    size_t write(const int16_t* samples, size_t count, int channels = 1);
    
    // Read samples (float32) - returns samples read
    size_t read(float* output, size_t count);
    
    // Query buffer state
    size_t available() const { return size_; }
    size_t space() const { return capacity_ - size_; }
    bool empty() const { return size_ == 0; }
    bool full() const { return size_ >= capacity_; }
    
    // Stats for evidence
    float rms() const { return rms_; }
    float peak() const { return peak_; }
    float envelope_inst() const { return envelope_inst_; }  // Gate #019: Instantaneous envelope
    // Gate #019C: Exact 100ms windowed RMS envelope
    float envelope_rms100() const { 
        if (!rms_window_filled_ || rms_window_size_ == 0) return 0.0f;
        return std::sqrt(rms_sum_squares_ / static_cast<double>(rms_window_size_));
    }
    
private:
    std::vector<float> buffer_;
    size_t capacity_;
    size_t write_pos_;
    size_t read_pos_;
    size_t size_;
    
    // Stats
    float rms_;
    float peak_;
    float envelope_inst_;  // Gate #019: Instantaneous attack/release envelope
    
    // Gate #019C: Exact 100ms windowed RMS envelope
    std::vector<float> rms_window_;  // Circular buffer for windowed RMS
    size_t rms_window_size_;         // Window size in samples (100ms worth)
    size_t rms_window_pos_;          // Current position in window
    double rms_sum_squares_;         // Running sum of squares in window
    bool rms_window_filled_;         // True after first full window
    
    // Gate #019: Instantaneous envelope coefficients
    float attack_coeff_;   // Attack time constant
    float release_coeff_;  // Release time constant
    
    void update_stats(float sample);
    void init_envelope(float attack_ms = 10.0f, float release_ms = 250.0f, float sample_rate = 44100.0f);
    void init_rms_window(float window_ms = 100.0f, float sample_rate = 44100.0f);
};

} // namespace audio

#endif // AUDIO_INJECTOR_HPP


