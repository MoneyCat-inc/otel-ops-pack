#!/usr/bin/env python3
"""
Scorebot Metrics Computation - Gate #010
ECRR: BossCat Mission - Audio reactivity metrics
Authority: BossCat OEM | Executor: Cursor{Implementer}

Computes visual quality and audio reactivity metrics
"""

import numpy as np


def compute_reactivity(bass_history, frame_delta_history, max_lag=3):
    """
    Compute audio-visual reactivity using Pearson correlation
    
    Args:
        bass_history: List of bass values over time
        frame_delta_history: List of frame delta values over time
        max_lag: Maximum lag in frames to check
    
    Returns:
        float: Maximum correlation coefficient in [-lag, +lag] range
    """
    if len(bass_history) < 10 or len(frame_delta_history) < 10:
        return 0.0
    
    # Ensure equal length
    min_len = min(len(bass_history), len(frame_delta_history))
    bass = np.array(bass_history[-min_len:])
    deltas = np.array(frame_delta_history[-min_len:])
    
    max_corr = 0.0
    
    for lag in range(-max_lag, max_lag + 1):
        if lag == 0:
            x, y = bass, deltas
        elif lag > 0:
            # Positive lag: bass leads deltas
            if len(bass) <= lag:
                continue
            x = bass[:-lag] if lag > 0 else bass
            y = deltas[lag:]
        else:
            # Negative lag: deltas lead bass
            if len(deltas) <= abs(lag):
                continue
            x = bass[abs(lag):]
            y = deltas[:lag] if lag < 0 else deltas
        
        # Ensure equal length after lag
        min_lag_len = min(len(x), len(y))
        if min_lag_len < 5:
            continue
            
        x = x[-min_lag_len:]
        y = y[-min_lag_len:]
        
        # Pearson correlation
        if np.std(x) > 0 and np.std(y) > 0:
            corr = np.corrcoef(x, y)[0, 1]
            max_corr = max(max_corr, abs(corr))
    
    return float(max_corr)


def compute_color_variance(frame):
    """
    Compute color variance across channels
    
    Args:
        frame: BGR image
    
    Returns:
        float: Sum of channel variances (normalized)
    """
    b, g, r = frame[:, :, 0], frame[:, :, 1], frame[:, :, 2]
    
    var_b = np.var(b) / (255.0 ** 2)
    var_g = np.var(g) / (255.0 ** 2)
    var_r = np.var(r) / (255.0 ** 2)
    
    return float(var_b + var_g + var_r)


def compute_composite_score(metrics):
    """
    Compute composite score for preset ranking (Gate #010)
    
    Score formula:
    score = 0.40*reactivity_r + 0.25*motion_energy + 0.20*color_var - 0.15*black_pct
    
    Args:
        metrics: Dictionary of computed metrics
    
    Returns:
        float: Composite score (0-100)
    """
    reactivity = metrics.get('reactivity_r', 0.0)
    motion = metrics.get('motion_magnitude', 0.0)
    color_var = metrics.get('color_var', 0.0)
    black_pct = metrics.get('black_ratio', 0.0)
    
    # Normalize motion to [0, 1] (assume max ~0.5 for active visuals)
    motion_norm = min(1.0, motion / 0.5)
    
    # Compute weighted score
    score = (
        0.40 * reactivity +
        0.25 * motion_norm +
        0.20 * color_var -
        0.15 * black_pct
    )
    
    # Scale to 0-100
    return float(max(0.0, min(100.0, score * 100.0)))


def gate_010_validate(metrics):
    """
    Validate against Gate #010 thresholds
    
    Thresholds:
    - aspect_ok == true
    - black_ratio < 0.95
    - motion_magnitude >= 0.15
    - reactivity_r >= 0.35
    
    Args:
        metrics: Dictionary of computed metrics
    
    Returns:
        tuple: (ok, failures) where ok is bool and failures is list of strings
    """
    failures = []
    
    # Aspect ratio check
    if not metrics.get('aspect_ok', False):
        aspect_error = metrics.get('aspect_error', 0.0)
        failures.append(f"Aspect ratio error: {aspect_error:.2%}")
    
    # Blackout check
    black_ratio = metrics.get('black_ratio', 1.0)
    if black_ratio >= 0.95:
        failures.append(f"Blackout detected: {black_ratio:.2%} black pixels")
    
    # Motion check
    motion = metrics.get('motion_magnitude', 0.0)
    if motion < 0.15:
        failures.append(f"Low motion: {motion:.4f} (threshold: >= 0.15)")
    
    # Reactivity check (Gate #010 new requirement)
    reactivity = metrics.get('reactivity_r', 0.0)
    if reactivity < 0.35:
        failures.append(f"Low audio reactivity: {reactivity:.3f} (threshold: >= 0.35)")
    
    ok = len(failures) == 0
    
    return ok, failures

