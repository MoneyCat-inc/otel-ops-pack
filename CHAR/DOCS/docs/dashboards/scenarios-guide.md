# Custom Scenario Framework Guide

## Overview

The custom scenario framework allows you to define repeatable load patterns for stress testing your observability pipeline. Scenarios are defined in JSON format and can be loaded into the stress testing suite to automatically configure generators.

## Scenario Format

### Basic Scenario Structure

```json
{
  "scenarios": {
    "scenario-name": {
      "name": "Human Readable Name",
      "description": "Description of what this scenario tests",
      "duration": 120,
      "settings": {
        "multiSource": {
          "frequency": 5,
          "enabled": true
        },
        "metrics": {
          "volume": 8,
          "enabled": false
        },
        "noise": {
          "intensity": 2,
          "enabled": false
        },
        "probes": {
          "interval": 5,
          "enabled": true
        },
        "traces": {
          "rate": 3,
          "enabled": true
        },
        "system": {
          "intensity": 4,
          "enabled": true
        },
        "fixture": {
          "speed": 2,
          "enabled": false
        }
      },
      "expectedThroughput": "~25 logs/sec",
      "useCase": "Staging validation, performance testing"
    }
  }
}
```

### Multi-Phase Scenario Structure

For complex scenarios with multiple phases (ramp-ups, burst tests):

```json
{
  "scenarios": {
    "ramp-up": {
      "name": "Ramp-Up Test",
      "description": "Gradually increasing load to find breaking points",
      "duration": 300,
      "phases": [
        {
          "name": "Phase 1 - Warm-up",
          "duration": 60,
          "settings": {
            "multiSource": { "frequency": 2, "enabled": true },
            "metrics": { "volume": 3, "enabled": false },
            "noise": { "intensity": 1, "enabled": false },
            "probes": { "interval": 10, "enabled": true },
            "traces": { "rate": 1, "enabled": false },
            "system": { "intensity": 2, "enabled": false },
            "fixture": { "speed": 1, "enabled": false }
          }
        },
        {
          "name": "Phase 2 - Moderate",
          "duration": 60,
          "settings": {
            "multiSource": { "frequency": 5, "enabled": true },
            "metrics": { "volume": 8, "enabled": true },
            "noise": { "intensity": 2, "enabled": false },
            "probes": { "interval": 5, "enabled": true },
            "traces": { "rate": 3, "enabled": true },
            "system": { "intensity": 4, "enabled": true },
            "fixture": { "speed": 2, "enabled": false }
          }
        }
      ],
      "expectedThroughput": "2→25→50 logs/sec",
      "useCase": "Breaking point analysis, capacity planning"
    }
  }
}
```

## Generator Settings

### Multi-Source Log Generator
- **frequency**: 1-10 (logs per second across all services)
- **enabled**: true/false

### Synthetic Metrics Generator
- **volume**: 1-20 (metrics per second)
- **enabled**: true/false

### Randomized Noise Generator
- **intensity**: 1-5 (Low to Extreme)
- **enabled**: true/false

### Health Check Probes
- **interval**: 1-30 (seconds between probes)
- **enabled**: true/false

### Synthetic Traces Generator
- **rate**: 1-15 (traces per second)
- **enabled**: true/false

### System Metrics Generator
- **intensity**: 1-10 (Very Low to Peak)
- **enabled**: true/false

### Fixture Replay
- **speed**: 1-10 (replay speed multiplier)
- **enabled**: true/false

## Loading Scenarios in the UI

### Scenario Selector Integration

```javascript
// Load scenario from JSON file
async function loadScenario(scenarioName) {
  try {
    const response = await fetch('scenarios-example.json');
    const data = await response.json();
    const scenario = data.scenarios[scenarioName];
    
    if (scenario) {
      applyScenarioSettings(scenario);
      logActivity(`📋 Scenario loaded: ${scenario.name}`, 'info');
    }
  } catch (error) {
    logActivity(`❌ Failed to load scenario: ${error.message}`, 'error');
  }
}

// Apply scenario settings to generators
function applyScenarioSettings(scenario) {
  if (scenario.phases) {
    // Multi-phase scenario
    runMultiPhaseScenario(scenario);
  } else {
    // Single-phase scenario
    applyGeneratorSettings(scenario.settings);
  }
}

// Apply settings to individual generators
function applyGeneratorSettings(settings) {
  // Multi-Source
  if (settings.multiSource.enabled) {
    document.getElementById('multiSourceFreq').value = settings.multiSource.frequency;
    if (!generators.multiSource.active) toggleMultiSource();
  }
  
  // Metrics
  if (settings.metrics.enabled) {
    document.getElementById('metricsVolume').value = settings.metrics.volume;
    if (!generators.metrics.active) toggleMetrics();
  }
  
  // Noise
  if (settings.noise.enabled) {
    document.getElementById('noiseIntensity').value = settings.noise.intensity;
    if (!generators.noise.active) toggleNoise();
  }
  
  // Probes
  if (settings.probes.enabled) {
    document.getElementById('probeInterval').value = settings.probes.interval;
    if (!generators.probes.active) toggleProbes();
  }
  
  // Traces
  if (settings.traces.enabled) {
    document.getElementById('tracesRate').value = settings.traces.rate;
    if (!generators.traces.active) toggleTraces();
  }
  
  // System
  if (settings.system.enabled) {
    document.getElementById('systemIntensity').value = settings.system.intensity;
    if (!generators.system.active) toggleSystemMetrics();
  }
  
  // Fixture
  if (settings.fixture.enabled) {
    document.getElementById('fixtureSpeed').value = settings.fixture.speed;
    if (!generators.fixture.active) toggleFixtureReplay();
  }
  
  // Update slider displays
  updateSliderTexts();
}
```

## Scenario Types

### 1. Light Load Test
- **Purpose**: Baseline testing, development environments
- **Throughput**: ~3 logs/sec
- **Duration**: 60 seconds
- **Use Case**: Daily development validation

### 2. Medium Load Test
- **Purpose**: Staging validation, performance testing
- **Throughput**: ~25 logs/sec
- **Duration**: 120 seconds
- **Use Case**: Pre-production validation

### 3. Chaos Engineering Test
- **Purpose**: Resilience testing, error injection
- **Throughput**: ~80 logs/sec
- **Duration**: 180 seconds
- **Use Case**: Production resilience validation

### 4. Ramp-Up Test
- **Purpose**: Breaking point analysis, capacity planning
- **Throughput**: 2→25→50→100+ logs/sec
- **Duration**: 300 seconds (4 phases)
- **Use Case**: Capacity planning, breaking point analysis

### 5. Burst Test
- **Purpose**: Spike handling, recovery testing
- **Throughput**: 1→150+→5 logs/sec (cyclical)
- **Duration**: 240 seconds (cyclical)
- **Use Case**: Traffic spike handling, recovery validation

## Versioning Scenarios

### Scenario Metadata
```json
{
  "metadata": {
    "version": "1.0",
    "author": "BossCat OEM",
    "created": "2025-01-08",
    "description": "Custom stress testing scenarios for Resonai [OTel] observability pipeline validation"
  }
}
```

### Version Control Best Practices
- Store scenarios in version control
- Tag scenario versions for releases
- Document scenario changes in commit messages
- Use semantic versioning for scenario files

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Stress Test Pipeline
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  stress-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Start SigNoz
        run: |
          docker-compose up -d
          sleep 30  # Wait for services to start
      
      - name: Run Light Load Test
        run: |
          python -m http.server 3000 &
          sleep 5
          # Load light-load scenario and run test
          curl -X POST http://localhost:3000/docs/dashboards/stress-testing.html \
            -d '{"scenario": "light-load", "duration": 60}'
      
      - name: Run Medium Load Test
        run: |
          # Load medium-load scenario and run test
          curl -X POST http://localhost:3000/docs/dashboards/stress-testing.html \
            -d '{"scenario": "medium-load", "duration": 120}'
      
      - name: Collect Results
        run: |
          # Export test results and metrics
          curl http://localhost:8080/api/v1/logs > results.json
      
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: stress-test-results
          path: results.json
```

### Automated Scenario Execution
```bash
#!/bin/bash
# stress-test-runner.sh

SCENARIOS=("light-load" "medium-load" "chaos-test")
RESULTS_DIR="test-results"

mkdir -p $RESULTS_DIR

for scenario in "${SCENARIOS[@]}"; do
  echo "Running scenario: $scenario"
  
  # Start web server
  python -m http.server 3000 &
  SERVER_PID=$!
  sleep 5
  
  # Load and run scenario
  curl -X POST http://localhost:3000/docs/dashboards/stress-testing.html \
    -d "{\"scenario\": \"$scenario\"}" \
    -H "Content-Type: application/json"
  
  # Wait for scenario completion
  sleep 120  # Adjust based on scenario duration
  
  # Collect results
  curl "http://localhost:8080/api/v1/logs?filter=scenario=$scenario" \
    > "$RESULTS_DIR/$scenario-results.json"
  
  # Stop web server
  kill $SERVER_PID
  
  echo "Completed scenario: $scenario"
done

echo "All scenarios completed. Results saved to $RESULTS_DIR/"
```

## Best Practices

### Scenario Design
1. **Start Simple**: Begin with light load scenarios
2. **Gradual Increase**: Build up to higher loads systematically
3. **Document Expectations**: Include expected throughput and use cases
4. **Test Regularly**: Run scenarios in CI/CD pipelines
5. **Monitor Thresholds**: Set appropriate alert thresholds for each scenario

### Performance Considerations
1. **Resource Limits**: Monitor system resources during tests
2. **Recovery Time**: Allow time between high-load scenarios
3. **Baseline Establishment**: Establish performance baselines
4. **Threshold Tuning**: Adjust alert thresholds based on scenario results

### Troubleshooting
1. **Check SigNoz Health**: Ensure SigNoz is running before tests
2. **Validate OTel Collector**: Verify collector is receiving data
3. **Monitor System Resources**: Watch CPU, memory, and disk usage
4. **Review Logs**: Check activity logs for error messages
5. **Verify Scenarios**: Ensure scenario JSON is valid

## Example Scenarios

See `scenarios-example.json` for complete examples including:
- Light Load Test
- Medium Load Test  
- Chaos Engineering Test
- Ramp-Up Test
- Burst Test

Each scenario includes detailed settings, expected throughput, and use case descriptions.
