// Gate #013C - Job A - ProjectM Injector Implementation
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Wrapper for projectM audio feed

#include "projectm-injector.hpp"

namespace audio {

ProjectMInjector::ProjectMInjector(AudioBuffer& buffer)
    : buffer_(buffer)
{}

size_t ProjectMInjector::prepare_samples(float* output, size_t count) {
    if (!output || count == 0) return 0;
    
    // Drain samples from buffer
    size_t samples_read = buffer_.read(output, count);
    
    // If underrun, buffer.read() already zero-filled the rest
    return samples_read;
}

} // namespace audio


