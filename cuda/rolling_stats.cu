/**
 * 🐾 BossCat Rolling Statistics CUDA Kernel
 * GPU-accelerated rolling mean and standard deviation calculation
 * Part of GPU Pattern-Sifter EPIC - Lane T1
 */

#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <stdio.h>
#include <math.h>

/**
 * CUDA kernel for rolling mean calculation
 * @param input Input data array
 * @param output Mean values array
 * @param n Total number of data points
 * @param window Window size for rolling calculation
 * @param stride Stride between window positions
 */
__global__ void rolling_mean_kernel(const float* input, float* output, 
                                   int n, int window, int stride) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int output_idx = idx * stride;
    
    if (output_idx >= n - window + 1) return;
    
    float sum = 0.0f;
    for (int i = 0; i < window; i++) {
        sum += input[output_idx + i];
    }
    output[idx] = sum / window;
}

/**
 * CUDA kernel for rolling standard deviation calculation
 * @param input Input data array
 * @param output Standard deviation values array
 * @param n Total number of data points
 * @param window Window size for rolling calculation
 * @param stride Stride between window positions
 */
__global__ void rolling_stddev_kernel(const float* input, float* output, 
                                     int n, int window, int stride) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int output_idx = idx * stride;
    
    if (output_idx >= n - window + 1) return;
    
    // Calculate mean first
    float sum = 0.0f;
    for (int i = 0; i < window; i++) {
        sum += input[output_idx + i];
    }
    float mean = sum / window;
    
    // Calculate variance
    float variance = 0.0f;
    for (int i = 0; i < window; i++) {
        float diff = input[output_idx + i] - mean;
        variance += diff * diff;
    }
    
    output[idx] = sqrtf(variance / window);
}

/**
 * Host function to launch rolling statistics kernels
 * @param h_input Host input data
 * @param h_mean_output Host output for means
 * @param h_stddev_output Host output for standard deviations
 * @param n Number of data points
 * @param window Window size
 * @param stride Stride between calculations
 * @return 0 on success, error code on failure
 */
extern "C" int launch_rolling_stats(const float* h_input, float* h_mean_output, 
                                   float* h_stddev_output, int n, int window, int stride) {
    // Calculate output size
    int output_size = (n - window) / stride + 1;
    
    // Allocate device memory
    float *d_input, *d_mean_output, *d_stddev_output;
    size_t input_size = n * sizeof(float);
    size_t output_size_bytes = output_size * sizeof(float);
    
    cudaError_t err;
    
    err = cudaMalloc(&d_input, input_size);
    if (err != cudaSuccess) return err;
    
    err = cudaMalloc(&d_mean_output, output_size_bytes);
    if (err != cudaSuccess) {
        cudaFree(d_input);
        return err;
    }
    
    err = cudaMalloc(&d_stddev_output, output_size_bytes);
    if (err != cudaSuccess) {
        cudaFree(d_input);
        cudaFree(d_mean_output);
        return err;
    }
    
    // Copy input to device
    err = cudaMemcpy(d_input, h_input, input_size, cudaMemcpyHostToDevice);
    if (err != cudaSuccess) {
        cudaFree(d_input);
        cudaFree(d_mean_output);
        cudaFree(d_stddev_output);
        return err;
    }
    
    // Launch kernels
    int block_size = 256;
    int grid_size = (output_size + block_size - 1) / block_size;
    
    rolling_mean_kernel<<<grid_size, block_size>>>(
        d_input, d_mean_output, n, window, stride);
    
    rolling_stddev_kernel<<<grid_size, block_size>>>(
        d_input, d_stddev_output, n, window, stride);
    
    // Wait for kernels to complete
    err = cudaDeviceSynchronize();
    if (err != cudaSuccess) {
        cudaFree(d_input);
        cudaFree(d_mean_output);
        cudaFree(d_stddev_output);
        return err;
    }
    
    // Copy results back to host
    err = cudaMemcpy(h_mean_output, d_mean_output, output_size_bytes, cudaMemcpyDeviceToHost);
    if (err != cudaSuccess) {
        cudaFree(d_input);
        cudaFree(d_mean_output);
        cudaFree(d_stddev_output);
        return err;
    }
    
    err = cudaMemcpy(h_stddev_output, d_stddev_output, output_size_bytes, cudaMemcpyDeviceToHost);
    if (err != cudaSuccess) {
        cudaFree(d_input);
        cudaFree(d_mean_output);
        cudaFree(d_stddev_output);
        return err;
    }
    
    // Clean up device memory
    cudaFree(d_input);
    cudaFree(d_mean_output);
    cudaFree(d_stddev_output);
    
    return cudaSuccess;
}

/**
 * CPU reference implementation for parity checking
 */
extern "C" void cpu_rolling_stats(const float* input, float* mean_output, 
                                 float* stddev_output, int n, int window, int stride) {
    int output_size = (n - window) / stride + 1;
    
    for (int i = 0; i < output_size; i++) {
        int start_idx = i * stride;
        float sum = 0.0f;
        
        // Calculate mean
        for (int j = 0; j < window; j++) {
            sum += input[start_idx + j];
        }
        float mean = sum / window;
        mean_output[i] = mean;
        
        // Calculate standard deviation
        float variance = 0.0f;
        for (int j = 0; j < window; j++) {
            float diff = input[start_idx + j] - mean;
            variance += diff * diff;
        }
        stddev_output[i] = sqrtf(variance / window);
    }
}