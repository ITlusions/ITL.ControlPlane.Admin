FROM python:3.11-alpine AS builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev

# Copy requirements and install
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --target ./python-packages -r requirements.txt

# ========== Runtime Stage ==========
FROM python:3.11-alpine

# ITL Control Plane Admin Portal
# Platform administration with Docker/Kubernetes infrastructure access
LABEL maintainer="ITL Platform Team"
LABEL description="Admin portal for platform operators with full infrastructure access"

WORKDIR /app

# Install only runtime dependencies
RUN apk add --no-cache curl

# Copy installed packages from builder
COPY --from=builder /build/python-packages /usr/local/lib/python3.11/site-packages

# Copy application files
COPY main.py .
COPY src/ src/
COPY templates/ templates/
COPY static/ static/
COPY config/ config/

# Create data directory and aggressive cleanup
RUN mkdir -p data && chmod 777 data && \
    find /usr/local/lib/python3.11/site-packages -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/python3.11/site-packages -type f -name "*.pyc" -delete && \
    find /usr/local/lib/python3.11/site-packages -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/python3.11/site-packages -type d -name "*docs*" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/python3.11/site-packages -type d -name "*examples*" -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/python3.11/site-packages -type f -name "*.md" -delete && \
    find /usr/local/lib/python3.11/site-packages -type f -name "*.txt" -path "*/dist-info/*" ! -name "RECORD" -delete

# Expose port (Admin uses 8091)
EXPOSE 8091

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8091/health || exit 1

# Run the application
ENV PORT=8091
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8091"]
