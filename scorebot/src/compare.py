#!/usr/bin/env python3
"""
Preset A/B Comparison - Gate #010
ECRR: BossCat Mission - Quantified preset evaluation
Authority: BossCat OEM | Executor: Cursor{Implementer}
"""

import time
import requests
from metrics import compute_composite_score


def compare_presets(viz_engine_url, preset_a, preset_b, duration_seconds=12, sample_interval=0.5):
    """
    Compare two presets and return winner based on composite scores
    
    Args:
        viz_engine_url: md3-engine URL
        preset_a: Name of preset A
        preset_b: Name of preset B
        duration_seconds: Test duration per preset
        sample_interval: Sampling interval in seconds
    
    Returns:
        dict: Comparison results with winner
    """
    results = {}
    
    for preset_name in [preset_a, preset_b]:
        # Load preset
        try:
            load_response = requests.post(
                f'{viz_engine_url}/preset',
                json={'name': preset_name, 'blend': 1.0},
                timeout=5
            )
            if load_response.status_code != 200:
                results[preset_name] = {'error': 'Failed to load preset'}
                continue
        except Exception as e:
            results[preset_name] = {'error': str(e)}
            continue
        
        # Wait for blend to complete
        time.sleep(1.5)
        
        # Sample metrics over duration
        samples = []
        num_samples = int(duration_seconds / sample_interval)
        
        for i in range(num_samples):
            try:
                # CRITICAL FIX: Use scorebot URL directly, not port replacement
                # Assume scorebot is at http://scorebot:7010 or http://localhost:7010
                scorebot_url = viz_engine_url.replace('viz-engine', 'scorebot').replace('md3-engine', 'scorebot').replace('7001', '7010')
                if 'localhost' in viz_engine_url:
                    scorebot_url = 'http://localhost:7010'
                
                metrics_response = requests.get(
                    f'{scorebot_url}/metrics',
                    timeout=2
                )
                if metrics_response.status_code == 200:
                    samples.append(metrics_response.json())
            except Exception as e:
                print(f'[compare] Metrics fetch error: {e}')
                pass
            
            time.sleep(sample_interval)
        
        # Compute aggregate metrics
        if len(samples) == 0:
            results[preset_name] = {'error': 'No samples collected'}
            continue
        
        scores = [s.get('score', 0) for s in samples]
        reactivity_values = [s.get('reactivity_r', 0) for s in samples]
        motion_values = [s.get('motion_magnitude', 0) for s in samples]
        
        results[preset_name] = {
            'samples': len(samples),
            'score_avg': sum(scores) / len(scores),
            'score_max': max(scores),
            'score_min': min(scores),
            'reactivity_avg': sum(reactivity_values) / len(reactivity_values),
            'motion_avg': sum(motion_values) / len(motion_values),
            'final_metrics': samples[-1] if samples else {}
        }
    
    # Determine winner
    if preset_a in results and preset_b in results:
        score_a = results[preset_a].get('score_avg', 0)
        score_b = results[preset_b].get('score_avg', 0)
        
        if score_a > score_b:
            winner = preset_a
            margin = score_a - score_b
        elif score_b > score_a:
            winner = preset_b
            margin = score_b - score_a
        else:
            winner = 'tie'
            margin = 0.0
    else:
        winner = 'error'
        margin = 0.0
    
    return {
        'preset_a': preset_a,
        'preset_b': preset_b,
        'results': results,
        'winner': winner,
        'margin': margin,
        'duration_seconds': duration_seconds
    }

