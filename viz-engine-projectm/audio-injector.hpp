// Gate #013C - Job A - Audio Injector Header
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Ring buffer with PCM format conversion (int16 → float32)

#ifndef AUDIO_INJECTOR_HPP
#define AUDIO_INJECTOR_HPP

#include <vector>
#include <cstdint>
#include <cstddef>

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
    float envelope() const { return envelope_; }  // Gate #019: Envelope follower output
    
private:
    std::vector<float> buffer_;
    size_t capacity_;
    size_t write_pos_;
    size_t read_pos_;
    size_t size_;
    
    // Stats
    float rms_;
    float peak_;
    float envelope_;  // Gate #019: Attack/release envelope follower
    
    // Gate #019: Envelope follower coefficients
    float attack_coeff_;   // Attack time constant
    float release_coeff_;  // Release time constant
    
    void update_stats(float sample);
    void init_envelope(float attack_ms = 20.0f, float release_ms = 150.0f, float sample_rate = 44100.0f);
};

} // namespace audio

#endif // AUDIO_INJECTOR_HPP


