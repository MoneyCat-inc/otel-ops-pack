/**
 * 🐾 BossCat PFAC Multi-Pattern GPU Scan
 * GPU-accelerated Aho-Corasick pattern matching
 * Part of GPU Pattern-Sifter EPIC - Lane T4
 */

#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <stdio.h>
#include <string.h>
#include <vector>
#include <unordered_map>

/**
 * PFAC (Parallel Failure-less Aho-Corasick) State Machine
 * Simplified implementation for GPU pattern matching
 */
struct PFACState {
    int next[256];           // Next state transitions
    int failure;             // Failure link
    bool is_final;           // Final state flag
    int pattern_id;          // Pattern ID if final state
};

/**
 * PFAC State Machine Builder (CPU)
 * Builds the Aho-Corasick automaton from pattern set
 */
class PFACBuilder {
private:
    std::vector<PFACState> states;
    std::vector<std::string> patterns;
    
public:
    PFACBuilder() {
        // Initialize root state
        states.push_back(PFACState());
        for (int i = 0; i < 256; i++) {
            states[0].next[i] = 0;
        }
        states[0].failure = 0;
        states[0].is_final = false;
        states[0].pattern_id = -1;
    }
    
    void addPattern(const std::string& pattern) {
        patterns.push_back(pattern);
        buildAutomaton();
    }
    
    void buildAutomaton() {
        // Build goto function
        int state_id = 0;
        for (size_t p = 0; p < patterns.size(); p++) {
            const std::string& pattern = patterns[p];
            state_id = 0;
            
            for (char c : pattern) {
                unsigned char uc = static_cast<unsigned char>(c);
                if (states[state_id].next[uc] == 0) {
                    // Create new state
                    PFACState new_state;
                    for (int i = 0; i < 256; i++) {
                        new_state.next[i] = 0;
                    }
                    new_state.failure = 0;
                    new_state.is_final = false;
                    new_state.pattern_id = -1;
                    
                    states.push_back(new_state);
                    states[state_id].next[uc] = states.size() - 1;
                }
                state_id = states[state_id].next[uc];
            }
            
            // Mark final state
            states[state_id].is_final = true;
            states[state_id].pattern_id = p;
        }
        
        // Build failure function
        buildFailureFunction();
    }
    
    void buildFailureFunction() {
        std::vector<int> queue;
        queue.push_back(0);
        
        while (!queue.empty()) {
            int state = queue.front();
            queue.erase(queue.begin());
            
            for (int c = 0; c < 256; c++) {
                int next_state = states[state].next[c];
                if (next_state != 0) {
                    if (state == 0) {
                        states[next_state].failure = 0;
                    } else {
                        int fail = states[state].failure;
                        while (fail != 0 && states[fail].next[c] == 0) {
                            fail = states[fail].failure;
                        }
                        states[next_state].failure = states[fail].next[c];
                        if (states[next_state].failure == next_state) {
                            states[next_state].failure = 0;
                        }
                    }
                    queue.push_back(next_state);
                }
            }
        }
    }
    
    const std::vector<PFACState>& getStates() const { return states; }
    const std::vector<std::string>& getPatterns() const { return patterns; }
};

/**
 * CUDA kernel for PFAC pattern matching
 * @param text Input text to search
 * @param text_length Length of input text
 * @param states PFAC state machine
 * @param num_states Number of states
 * @param matches Output array for match results
 * @param max_matches Maximum number of matches
 */
__global__ void pfac_scan_kernel(
    const char* text,
    int text_length,
    const PFACState* states,
    int num_states,
    int* matches,
    int* num_matches,
    int max_matches
) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    
    __shared__ int shared_matches[256];
    __shared__ int shared_count;
    
    if (threadIdx.x == 0) {
        shared_count = 0;
    }
    __syncthreads();
    
    for (int i = tid; i < text_length; i += stride) {
        int state = 0;
        
        // Scan from position i
        for (int j = i; j < text_length; j++) {
            unsigned char c = static_cast<unsigned char>(text[j]);
            
            // Follow transitions
            while (state != 0 && states[state].next[c] == 0) {
                state = states[state].failure;
            }
            
            state = states[state].next[c];
            
            // Check for matches
            if (states[state].is_final) {
                int match_idx = atomicAdd(&shared_count, 1);
                if (match_idx < max_matches) {
                    shared_matches[match_idx * 3 + 0] = i;           // start
                    shared_matches[match_idx * 3 + 1] = j;           // end
                    shared_matches[match_idx * 3 + 2] = states[state].pattern_id; // pattern_id
                }
            }
        }
    }
    
    __syncthreads();
    
    // Copy shared results to global memory
    if (threadIdx.x == 0) {
        int global_offset = atomicAdd(num_matches, shared_count);
        for (int i = 0; i < shared_count && global_offset + i < max_matches; i++) {
            matches[(global_offset + i) * 3 + 0] = shared_matches[i * 3 + 0];
            matches[(global_offset + i) * 3 + 1] = shared_matches[i * 3 + 1];
            matches[(global_offset + i) * 3 + 2] = shared_matches[i * 3 + 2];
        }
    }
}

/**
 * Host function to launch PFAC scan
 * @param patterns Vector of patterns to search for
 * @param text Input text
 * @param matches Output matches
 * @return Number of matches found
 */
extern "C" int launch_pfac_scan(
    const std::vector<std::string>& patterns,
    const std::string& text,
    std::vector<int>& matches
) {
    // Build PFAC state machine
    PFACBuilder builder;
    for (const auto& pattern : patterns) {
        builder.addPattern(pattern);
    }
    
    const auto& states = builder.getStates();
    int num_states = states.size();
    
    // Allocate device memory
    PFACState* d_states;
    char* d_text;
    int* d_matches;
    int* d_num_matches;
    
    size_t states_size = num_states * sizeof(PFACState);
    size_t text_size = text.length() * sizeof(char);
    size_t matches_size = 10000 * 3 * sizeof(int); // Max 10k matches
    
    cudaError_t err;
    
    err = cudaMalloc(&d_states, states_size);
    if (err != cudaSuccess) return -1;
    
    err = cudaMalloc(&d_text, text_size);
    if (err != cudaSuccess) {
        cudaFree(d_states);
        return -1;
    }
    
    err = cudaMalloc(&d_matches, matches_size);
    if (err != cudaSuccess) {
        cudaFree(d_states);
        cudaFree(d_text);
        return -1;
    }
    
    err = cudaMalloc(&d_num_matches, sizeof(int));
    if (err != cudaSuccess) {
        cudaFree(d_states);
        cudaFree(d_text);
        cudaFree(d_matches);
        return -1;
    }
    
    // Copy data to device
    err = cudaMemcpy(d_states, states.data(), states_size, cudaMemcpyHostToDevice);
    if (err != cudaSuccess) goto cleanup;
    
    err = cudaMemcpy(d_text, text.c_str(), text_size, cudaMemcpyHostToDevice);
    if (err != cudaSuccess) goto cleanup;
    
    err = cudaMemset(d_num_matches, 0, sizeof(int));
    if (err != cudaSuccess) goto cleanup;
    
    // Launch kernel
    int block_size = 256;
    int grid_size = (text.length() + block_size - 1) / block_size;
    
    pfac_scan_kernel<<<grid_size, block_size>>>(
        d_text, text.length(), d_states, num_states,
        d_matches, d_num_matches, 10000
    );
    
    err = cudaDeviceSynchronize();
    if (err != cudaSuccess) goto cleanup;
    
    // Copy results back
    int num_matches;
    err = cudaMemcpy(&num_matches, d_num_matches, sizeof(int), cudaMemcpyDeviceToHost);
    if (err != cudaSuccess) goto cleanup;
    
    matches.resize(num_matches * 3);
    if (num_matches > 0) {
        err = cudaMemcpy(matches.data(), d_matches, num_matches * 3 * sizeof(int), cudaMemcpyDeviceToHost);
        if (err != cudaSuccess) goto cleanup;
    }
    
cleanup:
    cudaFree(d_states);
    cudaFree(d_text);
    cudaFree(d_matches);
    cudaFree(d_num_matches);
    
    return (err == cudaSuccess) ? num_matches : -1;
}

/**
 * CPU reference implementation for validation
 */
extern "C" int cpu_pfac_scan(
    const std::vector<std::string>& patterns,
    const std::string& text,
    std::vector<int>& matches
) {
    matches.clear();
    
    for (size_t i = 0; i < text.length(); i++) {
        for (size_t p = 0; p < patterns.size(); p++) {
            const std::string& pattern = patterns[p];
            if (i + pattern.length() <= text.length()) {
                if (text.substr(i, pattern.length()) == pattern) {
                    matches.push_back(i);                    // start
                    matches.push_back(i + pattern.length() - 1); // end
                    matches.push_back(p);                    // pattern_id
                }
            }
        }
    }
    
    return matches.size() / 3;
}