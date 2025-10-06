# Multi-stage Docker build for Deployment Pipeline API
# Tetragrammaton YHWH Architecture Implementation

# YOD (Foundation) - Base image and build environment
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# HE (Interface) - Application build stage
FROM node:18-alpine AS app

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy dependencies from builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy application source
COPY src/ ./src/
COPY package*.json ./

# VAV (Validation) - File permissions and ownership
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# HE (Integration) - Health check and startup configuration
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Expose port
EXPOSE 3000

# Environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Start command
CMD ["node", "src/app.js"]
