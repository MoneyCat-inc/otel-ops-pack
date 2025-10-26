# Scorebot - Visual Quality Metrics & Validation
# ECRR: BossCat Mission - Automated visual scoring
# Authority: BossCat OEM | Executor: Cursor{Implementer}

# Gate #018: Pinned to digest for supply-chain security
FROM python:3.11-slim@sha256:8eb5fc663972b871c528fef04be4eaa9ab8ab4539a5316c4b8c133771214a617

# Install dependencies for image analysis
# MAJOR FIX: Use pip opencv-python only, add runtime libs
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install Python packages
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/

# Environment defaults
ENV VIZ_ENGINE_URL=http://viz-engine:7001
ENV SAMPLE_INTERVAL_MS=1000
ENV FAIL_ON_SKEW=true
ENV FAIL_ON_BLACKOUT=true

# Expose metrics API
EXPOSE 7010

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD python src/health_check.py || exit 1

# Start scorebot server
CMD ["python", "src/server.py"]

