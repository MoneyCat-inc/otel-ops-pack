#!/usr/bin/env python3
"""
GPU-Accelerated Voice Analysis Script
Optimized for RTX 2080 Super - processes audio data with PyTorch GPU acceleration
"""

import torch
import torchaudio
import numpy as np
import json
import time
import os
from datetime import datetime
from pathlib import Path

class VoiceAnalyzer:
    def __init__(self):
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        print(f"Using device: {self.device}")
        
        # Load pre-trained models (you can replace these with your specific models)
        self.sample_rate = 16000
        
        # Example: Load a simple feature extractor
        # In practice, you'd load your actual voice training models here
        self.feature_extractor = self._create_feature_extractor()
        
    def _create_feature_extractor(self):
        """Create a simple feature extractor for demonstration"""
        # This is a placeholder - replace with your actual model
        return torch.nn.Sequential(
            torch.nn.Conv1d(1, 64, kernel_size=3, padding=1),
            torch.nn.ReLU(),
            torch.nn.AdaptiveAvgPool1d(128)
        ).to(self.device)
    
    def analyze_audio_file(self, audio_path):
        """Analyze an audio file and return features"""
        try:
            # Load audio
            waveform, sample_rate = torchaudio.load(audio_path)
            
            # Resample if needed
            if sample_rate != self.sample_rate:
                resampler = torchaudio.transforms.Resample(sample_rate, self.sample_rate)
                waveform = resampler(waveform)
            
            # Move to GPU
            waveform = waveform.to(self.device)
            
            # Extract features
            with torch.no_grad():
                features = self.feature_extractor(waveform)
                features = features.cpu().numpy()
            
            return {
                'file': audio_path,
                'features_shape': features.shape,
                'duration': waveform.shape[1] / self.sample_rate,
                'timestamp': datetime.now().isoformat(),
                'gpu_used': self.device.type == 'cuda'
            }
            
        except Exception as e:
            return {
                'file': audio_path,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def batch_analyze(self, audio_dir, output_file):
        """Analyze all audio files in a directory"""
        audio_dir = Path(audio_dir)
        results = []
        
        # Find audio files
        audio_extensions = ['.wav', '.mp3', '.flac', '.m4a']
        audio_files = []
        for ext in audio_extensions:
            audio_files.extend(audio_dir.glob(f'**/*{ext}'))
        
        print(f"Found {len(audio_files)} audio files to process")
        
        # Process each file
        for i, audio_file in enumerate(audio_files):
            print(f"Processing {i+1}/{len(audio_files)}: {audio_file.name}")
            result = self.analyze_audio_file(str(audio_file))
            results.append(result)
        
        # Save results
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        return results

def main():
    """Main function for GPU voice analysis"""
    print("=== GPU Voice Analysis ===")
    print(f"PyTorch version: {torch.__version__}")
    print(f"CUDA available: {torch.cuda.is_available()}")
    print(f"GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU'}")
    
    # Initialize analyzer
    analyzer = VoiceAnalyzer()
    
    # Create sample audio directory if it doesn't exist
    audio_dir = Path("C:/logs/audio_samples")
    audio_dir.mkdir(parents=True, exist_ok=True)
    
    # Create a sample audio file for testing
    sample_file = audio_dir / "test_sample.wav"
    if not sample_file.exists():
        print("Creating sample audio file for testing...")
        # Generate a simple sine wave as test audio
        duration = 2.0  # seconds
        sample_rate = 16000
        frequency = 440  # A4 note
        
        t = torch.linspace(0, duration, int(sample_rate * duration))
        waveform = torch.sin(2 * torch.pi * frequency * t).unsqueeze(0)
        
        torchaudio.save(str(sample_file), waveform, sample_rate)
        print(f"Created sample file: {sample_file}")
    
    # Run analysis
    output_file = "C:/otel/.agent/reports/voice_analysis_results.json"
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    print(f"Analyzing audio files in: {audio_dir}")
    results = analyzer.batch_analyze(audio_dir, output_file)
    
    # Print summary
    successful = sum(1 for r in results if 'error' not in r)
    print(f"\nAnalysis complete!")
    print(f"Successfully processed: {successful}/{len(results)} files")
    print(f"Results saved to: {output_file}")
    
    # GPU memory info
    if torch.cuda.is_available():
        print(f"GPU memory allocated: {torch.cuda.memory_allocated() / 1024**2:.1f} MB")
        print(f"GPU memory cached: {torch.cuda.memory_reserved() / 1024**2:.1f} MB")

if __name__ == "__main__":
    main()

