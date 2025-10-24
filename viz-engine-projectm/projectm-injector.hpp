// Gate #013C - Job A - ProjectM Injector Header
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Wrapper for projectM::feedPCM() with AudioBuffer integration

#ifndef PROJECTM_INJECTOR_HPP
#define PROJECTM_INJECTOR_HPP

#include "audio-injector.hpp"
#include <cstddef>

namespace audio {

// ProjectM audio injector (wraps projectM::feedPCM calls)
// Note: This is an interface; actual projectM integration happens in Job B
class ProjectMInjector {
public:
    explicit ProjectMInjector(AudioBuffer& buffer);
    
    // Drain buffer and prepare samples for projectM
    // Returns number of samples prepared
    size_t prepare_samples(float* output, size_t count);
    
    // Get buffer stats for telemetry
    float rms() const { return buffer_.rms(); }
    float peak() const { return buffer_.peak(); }
    size_t available() const { return buffer_.available(); }
    
private:
    AudioBuffer& buffer_;
};

} // namespace audio

#endif // PROJECTM_INJECTOR_HPP


