#!/usr/bin/env python3
"""
Scorebot - Visual Quality Metrics Server
ECRR: BossCat Mission - Automated visual scoring
Authority: BossCat OEM | Executor: Cursor{Implementer}

Endpoints:
- GET /score - Current frame quality score
- GET /metrics - Detailed metrics
- POST /validate - Validate current state (returns OK/FAIL)
"""

import os
import time
import json
from flask import Flask, jsonify, request
import requests
import cv2
import numpy as np
from PIL import Image
from io import BytesIO
from metrics import compute_reactivity, compute_color_variance, compute_composite_score, gate_010_validate
from compare import compare_presets

app = Flask(__name__)

# Configuration
VIZ_ENGINE_URL = os.getenv('VIZ_ENGINE_URL', 'http://viz-engine:7001')
SAMPLE_INTERVAL = int(os.getenv('SAMPLE_INTERVAL_MS', 1000)) / 1000.0
FAIL_ON_SKEW = os.getenv('FAIL_ON_SKEW', 'true').lower() == 'true'
FAIL_ON_BLACKOUT = os.getenv('FAIL_ON_BLACKOUT', 'true').lower() == 'true'

# Thresholds
THRESHOLD_ASPECT_ERROR = 0.05  # 5% aspect ratio deviation
THRESHOLD_BLACK_PIXELS = 0.95  # 95% black = blackout
THRESHOLD_MIN_MOTION = 0.01    # Minimum optical flow magnitude
THRESHOLD_MIN_FPS = 30         # Minimum acceptable FPS

# State
last_frame = None
metrics_history = []
frame_delta_history = []
bass_history = []


def _candidate_frame_sources():
    """Yield candidate snapshot URLs in priority order."""
    seen = set()

    frame_tap = os.getenv('FRAME_TAP_URL')
    if frame_tap:
        seen.add(frame_tap)
        yield frame_tap

    default = f'{VIZ_ENGINE_URL}/snap.jpg'
    if default not in seen:
        seen.add(default)
        yield default

    # Investor demo fallback: md3-engine HTTP server (public 7001)
    fallback_hosts = [
        'http://md3-engine:7001/snap.jpg',
        'http://localhost:7001/snap.jpg'
    ]
    for url in fallback_hosts:
        if url not in seen:
            seen.add(url)
            yield url


def fetch_snapshot():
    """Fetch current frame from viz-engine or fallback sources."""
    for url in _candidate_frame_sources():
        try:
            response = requests.get(url, timeout=5)
            if response.status_code != 200:
                print(f'[scorebot] Snapshot warning: {url} returned {response.status_code}')
                continue

            try:
                img = Image.open(BytesIO(response.content))
                return cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
            except Exception as img_err:
                print(f'[scorebot] Snapshot decode error from {url}: {img_err}')
                continue
        except Exception as req_err:
            print(f'[scorebot] Snapshot fetch error from {url}: {req_err}')

    print('[scorebot] Snapshot error: all frame sources failed')
    return None


def compute_metrics(frame, audio_state=None):
    """Compute visual quality metrics (Gate #010 enhanced)"""
    global last_frame, frame_delta_history, bass_history
    
    h, w = frame.shape[:2]
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    
    # 1. Aspect ratio check
    expected_aspect = 16 / 9
    actual_aspect = w / h
    aspect_error = abs(actual_aspect - expected_aspect) / expected_aspect
    aspect_ok = aspect_error < THRESHOLD_ASPECT_ERROR
    
    # 2. Black frame detection
    black_pixels = np.sum(gray < 10)
    black_ratio = black_pixels / (w * h)
    blackout = black_ratio > THRESHOLD_BLACK_PIXELS
    
    # 3. Motion energy (optical flow)
    motion_magnitude = 0.0
    frame_delta = 0.0
    if last_frame is not None:
        # Optical flow
        flow = cv2.calcOpticalFlowFarneback(
            last_frame, gray, None,
            pyr_scale=0.5, levels=3, winsize=15,
            iterations=3, poly_n=5, poly_sigma=1.2, flags=0
        )
        motion_magnitude = np.mean(np.sqrt(flow[..., 0]**2 + flow[..., 1]**2))
        
        # Frame delta for reactivity analysis
        frame_delta = float(np.mean(np.abs(gray.astype(float) - last_frame.astype(float))) / 255.0)
        frame_delta_history.append(frame_delta)
        
        # Keep last 512 frames
        if len(frame_delta_history) > 512:
            frame_delta_history.pop(0)
    
    last_frame = gray.copy()
    motion_ok = motion_magnitude > THRESHOLD_MIN_MOTION
    
    # 4. Luma/chroma balance
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    luma_mean = np.mean(hsv[:, :, 2])
    chroma_mean = np.mean(hsv[:, :, 1])
    
    # 5. Color variance (Gate #010)
    color_var = compute_color_variance(frame)
    
    # 6. Audio reactivity (Gate #010)
    reactivity_r = 0.0
    if audio_state and 'bass_history' in audio_state:
        bass_history = audio_state['bass_history']
        if len(bass_history) >= 10 and len(frame_delta_history) >= 10:
            reactivity_r = compute_reactivity(bass_history, frame_delta_history, max_lag=3)
    
    # 7. Composite score (Gate #010)
    metrics_dict = {
        'motion_magnitude': float(motion_magnitude),
        'reactivity_r': reactivity_r,
        'color_var': color_var,
        'black_ratio': float(black_ratio)
    }
    composite_score = compute_composite_score(metrics_dict)
    
    return {
        'timestamp': time.time(),
        'width': int(w),
        'height': int(h),
        'aspect_ratio': float(actual_aspect),
        'aspect_error': float(aspect_error),
        'aspect_ok': bool(aspect_ok),
        'black_ratio': float(black_ratio),
        'blackout': bool(blackout),
        'motion_magnitude': float(motion_magnitude),
        'motion_ok': bool(motion_ok),
        'luma_mean': float(luma_mean),
        'chroma_mean': float(chroma_mean),
        'color_var': float(color_var),
        'reactivity_r': float(reactivity_r),
        'score': float(composite_score)
    }


@app.route('/')
def status():
    """Service status"""
    return jsonify({
        'service': 'scorebot',
        'status': 'running',
        'viz_engine': VIZ_ENGINE_URL,
        'sample_interval': SAMPLE_INTERVAL
    })


@app.route('/score')
def get_score():
    """Get current quality score (Gate #010: includes reactivity)"""
    frame = fetch_snapshot()
    if frame is None:
        return jsonify({'error': 'Failed to fetch frame'}), 503
    
    # MINOR FIX: Get audio state for consistent scoring
    audio_state = None
    try:
        audio_response = requests.get(f'{VIZ_ENGINE_URL}/audio/history?frames=512', timeout=2)
        if audio_response.status_code == 200:
            audio_data = audio_response.json()
            audio_state = {'bass_history': audio_data.get('bass', [])}
    except Exception as e:
        print(f'[scorebot] Audio history fetch error in /score: {e}')
        pass
    
    metrics = compute_metrics(frame, audio_state)
    return jsonify({
        'score': metrics['score'],
        'reactivity_r': metrics.get('reactivity_r', 0.0),
        'timestamp': metrics['timestamp']
    })


@app.route('/metrics')
def get_metrics():
    """Get detailed metrics (Gate #010: includes reactivity)"""
    frame = fetch_snapshot()
    if frame is None:
        return jsonify({'error': 'Failed to fetch frame'}), 503
    
    # CRITICAL FIX: Get audio state for ALL metrics calls, not just /validate
    audio_state = None
    try:
        audio_response = requests.get(f'{VIZ_ENGINE_URL}/audio/history?frames=512', timeout=2)
        if audio_response.status_code == 200:
            audio_data = audio_response.json()
            # Get actual bass history time series
            audio_state = {'bass_history': audio_data.get('bass', [])}
    except Exception as e:
        print(f'[scorebot] Audio history fetch error: {e}')
        pass
    
    metrics = compute_metrics(frame, audio_state)
    
    # Add to history (keep last 60 samples)
    metrics_history.append(metrics)
    if len(metrics_history) > 60:
        metrics_history.pop(0)
    
    return jsonify(metrics)


@app.route('/validate', methods=['POST'])
def validate():
    """Validate current visual state (Gate #010 thresholds)"""
    frame = fetch_snapshot()
    if frame is None:
        return jsonify({
            'ok': False,
            'verdict': 'FAIL',
            'reason': 'Cannot fetch frame from viz-engine'
        }), 503
    
    # Get audio state from viz-engine
    # CRITICAL FIX: Get actual time series, not repeated average
    audio_state = None
    try:
        audio_response = requests.get(f'{VIZ_ENGINE_URL}/audio/history?frames=512', timeout=2)
        if audio_response.status_code == 200:
            audio_data = audio_response.json()
            # Get actual bass history time series
            audio_state = {'bass_history': audio_data.get('bass', [])}
    except Exception as e:
        print(f'[scorebot] Audio history fetch error: {e}')
        pass
    
    metrics = compute_metrics(frame, audio_state)
    
    # Apply Gate #010 validation
    ok, failures = gate_010_validate(metrics)
    verdict = 'PASS' if ok else 'FAIL'
    
    result = {
        'ok': ok,
        'verdict': verdict,
        'score': metrics['score'],
        'timestamp': metrics['timestamp'],
        'metrics': metrics,
        'gate': 'GATE_010'
    }
    
    if not ok:
        result['failures'] = failures
    
    return jsonify(result), 200 if ok else 400


@app.route('/history')
def get_history():
    """Get metrics history"""
    return jsonify({
        'count': len(metrics_history),
        'samples': metrics_history
    })


@app.route('/compare')
def compare():
    """A/B compare two presets (Gate #010)"""
    preset_a = request.args.get('A')
    preset_b = request.args.get('B')
    duration = int(request.args.get('seconds', 12))
    
    if not preset_a or not preset_b:
        return jsonify({'error': 'Missing A or B parameter'}), 400
    
    try:
        result = compare_presets(VIZ_ENGINE_URL, preset_a, preset_b, duration)
        return jsonify(result)
    except Exception as e:
        print(f'[scorebot] Compare error: {e}')
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    print(f'[scorebot] Starting on port 7010')
    print(f'[scorebot] Viz engine: {VIZ_ENGINE_URL}')
    app.run(host='0.0.0.0', port=7010, debug=False)

