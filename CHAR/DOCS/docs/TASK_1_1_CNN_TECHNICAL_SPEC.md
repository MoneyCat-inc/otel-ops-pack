# 🎯 Task 1.1: CNN Vowel Classifier - Technical Specification

## 📊 Executive Summary

**Objective**: Replace the LPC stub with a robust CNN vowel classifier to achieve <5% false positives on vowel classification across 10+ devices.

**Critical Success Factors**:
- <10ms inference time per 256-sample frame
- >95% accuracy on TIMIT test set
- <2MB model size for WASM deployment
- Graceful fallback to improved LPC if CNN fails

---

## 🏗️ Model Architecture Specification

### **1.1 Input Representation**

#### **Spectrogram Generation**
```typescript
interface SpectrogramConfig {
  windowSize: 512;        // 32ms at 16kHz
  hopSize: 256;           // 16ms overlap
  nFFT: 512;              // Frequency resolution
  sampleRate: 16000;      // Target sample rate
  windowType: 'hann';     // Hann window for smooth transitions
}

interface SpectrogramInput {
  audioBuffer: Float32Array;  // 256 samples (16ms at 16kHz)
  timestamp: number;
  sampleRate: number;
}
```

#### **Feature Extraction Pipeline**
1. **Preprocessing**: Apply Hann window, zero-padding to 512 samples
2. **STFT**: Compute Short-Time Fourier Transform
3. **Magnitude**: Extract magnitude spectrum (256 frequency bins)
4. **Log Scale**: Apply log10 transformation for perceptual scaling
5. **Normalization**: Z-score normalization (μ=0, σ=1)

#### **Input Tensor Shape**
- **Dimensions**: `[1, 1, 256]` (batch_size, channels, frequency_bins)
- **Data Type**: `float32`
- **Range**: Normalized to [-3, 3] after log scaling

### **1.2 CNN Architecture**

#### **Layer Configuration**
```python
class VowelCNN(nn.Module):
    def __init__(self, num_classes=5):
        super().__init__()
        
        # Feature extraction layers
        self.conv1 = nn.Conv1d(1, 32, kernel_size=7, padding=3)
        self.bn1 = nn.BatchNorm1d(32)
        self.pool1 = nn.MaxPool1d(2)
        
        self.conv2 = nn.Conv1d(32, 64, kernel_size=5, padding=2)
        self.bn2 = nn.BatchNorm1d(64)
        self.pool2 = nn.MaxPool1d(2)
        
        self.conv3 = nn.Conv1d(64, 128, kernel_size=3, padding=1)
        self.bn3 = nn.BatchNorm1d(128)
        self.pool3 = nn.MaxPool1d(2)
        
        # Classification head
        self.dropout = nn.Dropout(0.5)
        self.fc1 = nn.Linear(128 * 32, 256)  # 128 * 32 = 4096
        self.fc2 = nn.Linear(256, num_classes)
        
    def forward(self, x):
        # Feature extraction
        x = F.relu(self.bn1(self.conv1(x)))
        x = self.pool1(x)  # [1, 32, 128]
        
        x = F.relu(self.bn2(self.conv2(x)))
        x = self.pool2(x)  # [1, 64, 64]
        
        x = F.relu(self.bn3(self.conv3(x)))
        x = self.pool3(x)  # [1, 128, 32]
        
        # Classification
        x = x.view(x.size(0), -1)  # Flatten
        x = self.dropout(x)
        x = F.relu(self.fc1(x))
        x = self.fc2(x)
        
        return F.softmax(x, dim=1)
```

#### **Architecture Rationale**
- **1D Convolutions**: Optimized for frequency-domain features
- **Progressive Filter Sizes**: 7→5→3 kernels capture multi-scale patterns
- **Batch Normalization**: Stabilizes training and improves convergence
- **Max Pooling**: Reduces dimensionality while preserving important features
- **Dropout**: Prevents overfitting with 50% dropout rate

#### **Model Size Estimation**
- **Parameters**: ~1.2M parameters
- **Model Size**: ~4.8MB (float32) → ~1.2MB (quantized int8)
- **Memory Usage**: ~2MB during inference

---

## 📚 Training Strategy

### **2.1 Dataset Preparation**

#### **Primary Dataset: TIMIT**
- **Vowel Classes**: /a/, /e/, /i/, /o/, /u/ (5 classes)
- **Samples**: ~6,000 vowel instances across 630 speakers
- **Quality**: Professional recordings, phonetically aligned
- **Split**: 70% train, 15% validation, 15% test

#### **Augmentation Strategy**
```python
class VowelAugmentation:
    def __init__(self):
        self.time_stretch_range = (0.8, 1.2)
        self.pitch_shift_range = (-200, 200)  # cents
        self.noise_levels = [0.01, 0.05, 0.1]  # SNR ratios
        
    def augment(self, audio, sample_rate):
        # Time stretching
        if random.random() < 0.3:
            audio = librosa.effects.time_stretch(
                audio, rate=random.uniform(*self.time_stretch_range)
            )
        
        # Pitch shifting
        if random.random() < 0.3:
            audio = librosa.effects.pitch_shift(
                audio, sr=sample_rate, 
                n_steps=random.uniform(*self.pitch_shift_range) / 100
            )
        
        # Add noise
        if random.random() < 0.2:
            noise_level = random.choice(self.noise_levels)
            noise = np.random.normal(0, noise_level, len(audio))
            audio = audio + noise
            
        return audio
```

#### **Secondary Dataset: LibriSpeech**
- **Purpose**: Cross-domain validation
- **Samples**: ~10,000 vowel instances
- **Conditions**: Various recording environments
- **Usage**: Test generalization, not training

### **2.2 Training Configuration**

#### **Hyperparameters**
```python
TRAINING_CONFIG = {
    'batch_size': 64,
    'learning_rate': 0.001,
    'weight_decay': 1e-4,
    'epochs': 100,
    'early_stopping_patience': 10,
    'optimizer': 'adam',
    'scheduler': 'cosine_annealing',
    'loss_function': 'cross_entropy',
    'validation_split': 0.15,
    'test_split': 0.15
}
```

#### **Training Pipeline**
1. **Data Loading**: Custom DataLoader with augmentation
2. **Model Initialization**: Xavier uniform weight initialization
3. **Training Loop**: Adam optimizer with cosine annealing
4. **Validation**: Monitor accuracy and loss every epoch
5. **Early Stopping**: Stop if validation loss doesn't improve for 10 epochs
6. **Model Selection**: Save best model based on validation accuracy

#### **Evaluation Metrics**
```python
def evaluate_model(model, test_loader):
    metrics = {
        'accuracy': 0.0,
        'precision': np.zeros(5),
        'recall': np.zeros(5),
        'f1_score': np.zeros(5),
        'confusion_matrix': np.zeros((5, 5))
    }
    
    # Calculate metrics...
    return metrics
```

---

## ⚡ WASM Integration Specification

### **3.1 Model Conversion Pipeline**

#### **ONNX Export**
```python
def export_to_onnx(model, input_shape=(1, 1, 256)):
    # Set model to evaluation mode
    model.eval()
    
    # Create dummy input
    dummy_input = torch.randn(input_shape)
    
    # Export to ONNX
    torch.onnx.export(
        model,
        dummy_input,
        "vowel_classifier.onnx",
        export_params=True,
        opset_version=11,
        do_constant_folding=True,
        input_names=['spectrogram'],
        output_names=['vowel_probabilities'],
        dynamic_axes={
            'spectrogram': {0: 'batch_size'},
            'vowel_probabilities': {0: 'batch_size'}
        }
    )
```

#### **Quantization Strategy**
```python
def quantize_model(onnx_model_path):
    # Quantize to int8 for size reduction
    from onnxruntime.quantization import quantize_dynamic
    
    quantized_model = quantize_dynamic(
        onnx_model_path,
        "vowel_classifier_quantized.onnx",
        weight_type=QuantType.QUInt8
    )
    
    return quantized_model
```

### **3.2 WASM Runtime Integration**

#### **ONNX Runtime WASM Setup**
```typescript
class CNNVowelClassifier {
  private session: ort.InferenceSession | null = null;
  private isLoaded = false;
  
  async load(): Promise<void> {
    try {
      // Initialize ONNX Runtime WASM
      await ort.env.wasm.wasmPath = '/wasm/ort-wasm.wasm';
      await ort.env.wasm.simd = true;  // Enable SIMD for performance
      
      // Load quantized model
      const modelBuffer = await fetch('/models/vowel_classifier_quantized.onnx')
        .then(res => res.arrayBuffer());
      
      this.session = await ort.InferenceSession.create(modelBuffer, {
        executionProviders: ['wasm'],
        graphOptimizationLevel: 'all'
      });
      
      this.isLoaded = true;
      console.log('CNN Vowel Classifier loaded successfully');
      
    } catch (error) {
      console.error('Failed to load CNN classifier:', error);
      throw new Error('CNN classifier initialization failed');
    }
  }
  
  async classify(spectrogram: Float32Array): Promise<VowelClassification> {
    if (!this.session) {
      throw new Error('Model not loaded');
    }
    
    // Prepare input tensor
    const inputTensor = new ort.Tensor('float32', spectrogram, [1, 1, 256]);
    
    // Run inference
    const startTime = performance.now();
    const results = await this.session.run({
      spectrogram: inputTensor
    });
    const inferenceTime = performance.now() - startTime;
    
    // Extract probabilities
    const probabilities = results.vowel_probabilities.data as Float32Array;
    const predictedClass = this.getPredictedClass(probabilities);
    const confidence = Math.max(...probabilities);
    
    return {
      vowel: predictedClass,
      confidence,
      probabilities: Array.from(probabilities),
      inferenceTime,
      method: 'cnn'
    };
  }
  
  private getPredictedClass(probabilities: Float32Array): VowelClass {
    const classIndex = probabilities.indexOf(Math.max(...probabilities));
    return ['a', 'e', 'i', 'o', 'u'][classIndex] as VowelClass;
  }
}
```

#### **Performance Optimization**
```typescript
class PerformanceOptimizer {
  private static readonly PERFORMANCE_TARGETS = {
    maxInferenceTime: 10,  // ms
    maxModelSize: 2,       // MB
    maxMemoryUsage: 5      // MB
  };
  
  static async optimizeForDevice(): Promise<OptimizationConfig> {
    const deviceInfo = await this.getDeviceInfo();
    
    if (deviceInfo.isLowEnd) {
      return {
        enableSIMD: false,
        enableThreading: false,
        quantizationLevel: 'int8',
        batchSize: 1
      };
    } else {
      return {
        enableSIMD: true,
        enableThreading: true,
        quantizationLevel: 'int8',
        batchSize: 4
      };
    }
  }
  
  private static async getDeviceInfo(): Promise<DeviceInfo> {
    // Detect device capabilities
    const cores = navigator.hardwareConcurrency || 2;
    const memory = (navigator as any).deviceMemory || 4;
    
    return {
      cores,
      memory,
      isLowEnd: cores < 4 || memory < 4
    };
  }
}
```

---

## 🔧 AudioWorklet Integration

### **4.1 Enhanced LPC Processor**

#### **Updated LPC Processor with CNN Integration**
```javascript
class EnhancedLPCProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    
    this.bufferSize = 1024;
    this.buffer = new Float32Array(this.bufferSize);
    this.bufferIndex = 0;
    
    // CNN classifier (loaded asynchronously)
    this.cnnClassifier = null;
    this.cnnLoaded = false;
    this.fallbackToLPC = true;
    
    // Performance monitoring
    this.inferenceCount = 0;
    this.totalInferenceTime = 0;
    this.fallbackCount = 0;
    
    // Load CNN classifier
    this.loadCNNClassifier();
  }
  
  async loadCNNClassifier() {
    try {
      // Import CNN classifier (loaded from main thread)
      const { CNNVowelClassifier } = await import('./cnn-classifier.js');
      this.cnnClassifier = new CNNVowelClassifier();
      await this.cnnClassifier.load();
      this.cnnLoaded = true;
      this.fallbackToLPC = false;
      
      console.log('CNN classifier loaded in AudioWorklet');
    } catch (error) {
      console.warn('CNN classifier failed to load, using LPC fallback:', error);
      this.fallbackToLPC = true;
    }
  }
  
  process(inputs, outputs, parameters) {
    const input = inputs[0];
    const output = outputs[0];
    
    if (input.length > 0) {
      const inputChannel = input[0];
      
      // Copy input to output (passthrough)
      if (output.length > 0) {
        output[0].set(inputChannel);
      }
      
      // Fill buffer for analysis
      for (let i = 0; i < inputChannel.length; i++) {
        this.buffer[this.bufferIndex] = inputChannel[i];
        this.bufferIndex = (this.bufferIndex + 1) % this.bufferSize;
      }
      
      // Analyze formants every 256 samples (16ms at 16kHz)
      if (this.bufferIndex % 256 === 0) {
        const formants = this.estimateFormants();
        
        // Send formant data to main thread
        this.port.postMessage({
          type: 'formants',
          f1: formants.f1,
          f2: formants.f2,
          f3: formants.f3,
          confidence: formants.confidence,
          method: formants.method,
          inferenceTime: formants.inferenceTime,
          timestamp: currentTime
        });
      }
    }
    
    return true;
  }
  
  async estimateFormants() {
    // Extract 256 samples for analysis
    const analysisBuffer = this.extractAnalysisBuffer();
    
    if (this.cnnLoaded && this.cnnClassifier) {
      try {
        // Use CNN classifier
        const spectrogram = this.computeSpectrogram(analysisBuffer);
        const classification = await this.cnnClassifier.classify(spectrogram);
        
        // Convert vowel classification to formant estimates
        const formants = this.vowelToFormants(classification.vowel);
        
        // Update performance metrics
        this.inferenceCount++;
        this.totalInferenceTime += classification.inferenceTime;
        
        return {
          f1: formants.f1,
          f2: formants.f2,
          f3: formants.f3,
          confidence: classification.confidence,
          method: 'cnn',
          inferenceTime: classification.inferenceTime
        };
        
      } catch (error) {
        console.warn('CNN inference failed, falling back to LPC:', error);
        this.fallbackCount++;
        this.fallbackToLPC = true;
      }
    }
    
    // Fallback to LPC analysis
    return this.estimateFormantsLPC(analysisBuffer);
  }
  
  vowelToFormants(vowel: string): { f1: number, f2: number, f3: number } {
    // Vowel-to-formant mapping based on acoustic phonetics
    const vowelFormants = {
      'a': { f1: 730, f2: 1090, f3: 2440 },  // /a/ as in "father"
      'e': { f1: 530, f2: 1840, f3: 2480 },  // /e/ as in "bed"
      'i': { f1: 270, f2: 2290, f3: 3010 },  // /i/ as in "beet"
      'o': { f1: 570, f2: 840, f3: 2410 },   // /o/ as in "boat"
      'u': { f1: 300, f2: 870, f3: 2240 }    // /u/ as in "boot"
    };
    
    return vowelFormants[vowel] || { f1: 500, f2: 1500, f3: 2500 };
  }
  
  extractAnalysisBuffer(): Float32Array {
    // Extract 256 samples centered around current position
    const start = (this.bufferIndex - 256 + this.bufferSize) % this.bufferSize;
    const analysisBuffer = new Float32Array(256);
    
    for (let i = 0; i < 256; i++) {
      analysisBuffer[i] = this.buffer[(start + i) % this.bufferSize];
    }
    
    return analysisBuffer;
  }
  
  computeSpectrogram(buffer: Float32Array): Float32Array {
    // Compute spectrogram using Web Audio API or custom FFT
    // This is a simplified implementation - in practice, use a proper FFT library
    const spectrogram = new Float32Array(256);
    
    // Apply Hann window
    for (let i = 0; i < buffer.length; i++) {
      const window = 0.5 * (1 - Math.cos(2 * Math.PI * i / (buffer.length - 1)));
      buffer[i] *= window;
    }
    
    // Compute magnitude spectrum (simplified)
    for (let i = 0; i < spectrogram.length; i++) {
      spectrogram[i] = Math.abs(buffer[i]);
    }
    
    // Apply log scaling and normalization
    for (let i = 0; i < spectrogram.length; i++) {
      spectrogram[i] = Math.log10(spectrogram[i] + 1e-10);
    }
    
    return spectrogram;
  }
  
  estimateFormantsLPC(buffer: Float32Array): { f1: number, f2: number, f3: number, confidence: number, method: string } {
    // Original LPC implementation as fallback
    const rms = this.calculateRMS(buffer);
    const spectralCentroid = this.calculateSpectralCentroid(buffer);
    
    const f1 = 200 + (spectralCentroid * 0.1);
    const f2 = 800 + (rms * 1000);
    const f3 = 2000 + (spectralCentroid * 0.2);
    
    return {
      f1: Math.max(200, Math.min(800, f1)),
      f2: Math.max(800, Math.min(3000, f2)),
      f3: Math.max(1500, Math.min(4000, f3)),
      confidence: 0.5, // Lower confidence for LPC fallback
      method: 'lpc-fallback'
    };
  }
  
  calculateRMS(buffer: Float32Array): number {
    let sum = 0;
    for (let i = 0; i < buffer.length; i++) {
      sum += buffer[i] * buffer[i];
    }
    return Math.sqrt(sum / buffer.length);
  }
  
  calculateSpectralCentroid(buffer: Float32Array): number {
    let weightedSum = 0;
    let magnitudeSum = 0;
    
    for (let i = 0; i < buffer.length; i++) {
      const magnitude = Math.abs(buffer[i]);
      weightedSum += i * magnitude;
      magnitudeSum += magnitude;
    }
    
    return magnitudeSum > 0 ? weightedSum / magnitudeSum : 0;
  }
}

registerProcessor('enhanced-lpc-processor', EnhancedLPCProcessor);
```

### **4.2 WorkletManager Integration**

#### **Updated WorkletManager with CNN Support**
```typescript
export function useEnhancedWorkletManager(audioContext: AudioContext | null) {
  const [state, setState] = useState<EnhancedWorkletState>({
    isLoaded: false,
    isActive: false,
    processors: {
      pitch: null,
      energy: null,
      lpc: null,
    },
    data: {
      pitch: 0,
      confidence: 0,
      rms: 0,
      highFreq: 0,
      lowFreq: 0,
      f1: 0,
      f2: 0,
      f3: 0,
      timestamp: 0,
      detectionMethod: 'lpc', // 'cnn' or 'lpc-fallback'
      inferenceTime: 0,
    },
    error: null,
    cnnStatus: 'loading', // 'loading', 'loaded', 'failed'
  });

  const loadWorklets = async () => {
    if (!audioContext) {
      setState(prev => ({ ...prev, error: 'AudioContext not available' }));
      return;
    }

    try {
      setState(prev => ({ ...prev, error: null }));

      // Load enhanced worklet modules
      await Promise.all([
        audioContext.audioWorklet.addModule('/worklets/pitch-processor.js'),
        audioContext.audioWorklet.addModule('/worklets/energy-processor.js'),
        audioContext.audioWorklet.addModule('/worklets/enhanced-lpc-processor.js'),
      ]);

      // Create worklet processors
      const pitchProcessor = new AudioWorkletNode(audioContext, 'pitch-processor');
      const energyProcessor = new AudioWorkletNode(audioContext, 'energy-processor');
      const lpcProcessor = new AudioWorkletNode(audioContext, 'enhanced-lpc-processor');

      // Set up message handlers
      lpcProcessor.port.onmessage = (event) => {
        if (event.data.type === 'formants') {
          setState(prev => ({
            ...prev,
            data: {
              ...prev.data,
              f1: event.data.f1,
              f2: event.data.f2,
              f3: event.data.f3,
              detectionMethod: event.data.method,
              inferenceTime: event.data.inferenceTime,
              timestamp: event.data.timestamp,
            },
          }));
          
          // Update CNN status based on detection method
          if (event.data.method === 'cnn') {
            setState(prev => ({ ...prev, cnnStatus: 'loaded' }));
          } else if (event.data.method === 'lpc-fallback') {
            setState(prev => ({ ...prev, cnnStatus: 'failed' }));
          }
        }
      };

      // ... other processor handlers ...

      setState(prev => ({
        ...prev,
        isLoaded: true,
        processors: {
          pitch: pitchProcessor,
          energy: energyProcessor,
          lpc: lpcProcessor,
        },
      }));

      console.log('Enhanced worklets loaded successfully');

    } catch (error) {
      console.error('Worklet loading failed:', error);
      setState(prev => ({
        ...prev,
        error: error instanceof Error ? error.message : 'Unknown error',
        cnnStatus: 'failed',
      }));
    }
  };

  // ... rest of the implementation ...

  return {
    ...state,
    loadWorklets,
    connectWorklets,
    disconnectWorklets,
    configureWorklets,
  };
}
```

---

## 📊 Evaluation Pipeline & Acceptance Criteria

### **5.1 Performance Benchmarks**

#### **Accuracy Requirements**
```typescript
interface AccuracyRequirements {
  overallAccuracy: number;        // >95%
  perClassAccuracy: number[];     // >90% for each vowel
  confusionMatrix: number[][];    // 5x5 matrix
  f1Score: number;               // >0.95 macro-averaged
}

interface PerformanceRequirements {
  inferenceTime: number;          // <10ms per frame
  modelSize: number;             // <2MB compressed
  memoryUsage: number;           // <5MB during inference
  loadingTime: number;           // <500ms initial load
}
```

#### **Test Suite Implementation**
```typescript
class CNNEvaluationSuite {
  async runAccuracyTests(): Promise<AccuracyResults> {
    const testData = await this.loadTIMITTestSet();
    const results: AccuracyResults = {
      overallAccuracy: 0,
      perClassAccuracy: [0, 0, 0, 0, 0],
      confusionMatrix: Array(5).fill(null).map(() => Array(5).fill(0)),
      f1Score: 0
    };
    
    for (const testCase of testData) {
      const prediction = await this.classifier.classify(testCase.spectrogram);
      const actualClass = testCase.vowel;
      const predictedClass = prediction.vowel;
      
      // Update confusion matrix
      const actualIndex = this.vowelToIndex(actualClass);
      const predictedIndex = this.vowelToIndex(predictedClass);
      results.confusionMatrix[actualIndex][predictedIndex]++;
      
      // Update accuracy
      if (actualClass === predictedClass) {
        results.overallAccuracy++;
        results.perClassAccuracy[actualIndex]++;
      }
    }
    
    // Calculate final metrics
    results.overallAccuracy /= testData.length;
    results.perClassAccuracy = results.perClassAccuracy.map(acc => acc / testData.length);
    results.f1Score = this.calculateF1Score(results.confusionMatrix);
    
    return results;
  }
  
  async runPerformanceTests(): Promise<PerformanceResults> {
    const testSpectrograms = this.generateTestSpectrograms(1000);
    const results: PerformanceResults = {
      inferenceTimes: [],
      memoryUsage: [],
      modelSize: 0,
      loadingTime: 0
    };
    
    // Measure loading time
    const loadStart = performance.now();
    await this.classifier.load();
    results.loadingTime = performance.now() - loadStart;
    
    // Measure model size
    results.modelSize = await this.getModelSize();
    
    // Measure inference performance
    for (const spectrogram of testSpectrograms) {
      const memoryBefore = this.getMemoryUsage();
      const inferenceStart = performance.now();
      
      await this.classifier.classify(spectrogram);
      
      const inferenceTime = performance.now() - inferenceStart;
      const memoryAfter = this.getMemoryUsage();
      
      results.inferenceTimes.push(inferenceTime);
      results.memoryUsage.push(memoryAfter - memoryBefore);
    }
    
    return results;
  }
}
```

### **5.2 Acceptance Criteria Validation**

#### **Automated Testing Pipeline**
```typescript
class AcceptanceCriteriaValidator {
  async validateAllCriteria(): Promise<ValidationResults> {
    const results: ValidationResults = {
      accuracy: await this.validateAccuracy(),
      performance: await this.validatePerformance(),
      integration: await this.validateIntegration(),
      fallback: await this.validateFallback(),
      overall: false
    };
    
    results.overall = results.accuracy.passed && 
                     results.performance.passed && 
                     results.integration.passed && 
                     results.fallback.passed;
    
    return results;
  }
  
  private async validateAccuracy(): Promise<CriteriaResult> {
    const evaluation = new CNNEvaluationSuite();
    const accuracyResults = await evaluation.runAccuracyTests();
    
    const passed = accuracyResults.overallAccuracy > 0.95 &&
                  accuracyResults.perClassAccuracy.every(acc => acc > 0.90) &&
                  accuracyResults.f1Score > 0.95;
    
    return {
      passed,
      details: accuracyResults,
      message: passed ? 'Accuracy requirements met' : 'Accuracy requirements not met'
    };
  }
  
  private async validatePerformance(): Promise<CriteriaResult> {
    const evaluation = new CNNEvaluationSuite();
    const performanceResults = await evaluation.runPerformanceTests();
    
    const avgInferenceTime = performanceResults.inferenceTimes.reduce((a, b) => a + b) / performanceResults.inferenceTimes.length;
    const maxMemoryUsage = Math.max(...performanceResults.memoryUsage);
    
    const passed = avgInferenceTime < 10 &&
                  performanceResults.modelSize < 2 &&
                  maxMemoryUsage < 5 &&
                  performanceResults.loadingTime < 500;
    
    return {
      passed,
      details: performanceResults,
      message: passed ? 'Performance requirements met' : 'Performance requirements not met'
    };
  }
}
```

---

## 🚀 Implementation Timeline

### **Week 1: Model Development**
- **Days 1-2**: Implement CNN architecture and training pipeline
- **Days 3-4**: Train model on TIMIT dataset with augmentation
- **Days 5-7**: Evaluate model accuracy and optimize hyperparameters

### **Week 2: WASM Integration**
- **Days 1-2**: Export model to ONNX and implement quantization
- **Days 3-4**: Integrate ONNX Runtime WASM with performance optimization
- **Days 5-7**: Implement AudioWorklet integration with fallback logic

### **Week 3: Testing & Validation**
- **Days 1-2**: Implement comprehensive test suite and evaluation pipeline
- **Days 3-4**: Run acceptance criteria validation and performance benchmarks
- **Days 5-7**: Cross-browser testing and device compatibility validation

### **Week 4: Integration & Deployment**
- **Days 1-2**: Integrate with existing Resonai audio pipeline
- **Days 3-4**: Performance optimization and memory management
- **Days 5-7**: Final testing and documentation

---

## ⚠️ Risk Mitigation & Contingency Plans

### **High-Risk Scenarios**

#### **Risk 1: CNN Model Performance**
- **Scenario**: Model fails to achieve >95% accuracy or >10ms inference time
- **Mitigation**: Implement progressive model optimization, quantization, and pruning
- **Contingency**: Fall back to improved LPC with spectral analysis and machine learning features

#### **Risk 2: WASM Compatibility Issues**
- **Scenario**: Model fails to load on certain browsers or devices
- **Mitigation**: Test on wide range of devices, implement progressive loading, add WebGL fallback
- **Contingency**: Use server-side inference with WebSocket streaming

#### **Risk 3: AudioWorklet Integration Complexity**
- **Scenario**: Integration causes audio dropouts or performance issues
- **Mitigation**: Implement buffering, async processing, and graceful degradation
- **Contingency**: Process audio on main thread with Web Workers

### **Medium-Risk Scenarios**

#### **Risk 4: Model Size Constraints**
- **Scenario**: Model exceeds 2MB size limit after quantization
- **Mitigation**: Implement model pruning, knowledge distillation, and feature selection
- **Contingency**: Use smaller model architecture or server-side processing

#### **Risk 5: Cross-Browser Performance Variations**
- **Scenario**: Significant performance differences across browsers
- **Mitigation**: Implement browser-specific optimizations and feature detection
- **Contingency**: Use browser-specific model variants or fallback strategies

---

## 📈 Success Metrics & Monitoring

### **Real-Time Metrics**
- CNN inference time per frame (target: <10ms)
- Model loading time (target: <500ms)
- Memory usage during inference (target: <5MB)
- Fallback rate to LPC (target: <5%)
- Accuracy on live audio (target: >95%)

### **Daily Monitoring**
- Test suite execution results
- Performance benchmark trends
- Cross-browser compatibility status
- Memory leak detection

### **Weekly Assessment**
- Overall milestone progress
- Risk assessment and mitigation status
- Performance optimization opportunities
- Integration testing results

---

*This technical specification provides a comprehensive roadmap for implementing the CNN vowel classifier as a replacement for the LPC stub. The specification includes detailed architecture, training strategy, WASM integration, AudioWorklet implementation, evaluation pipeline, and risk mitigation strategies to ensure successful delivery within the 4-week timeline.*
