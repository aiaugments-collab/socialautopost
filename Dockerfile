# Build stage
FROM node:20-alpine3.19 AS builder

# Build-time arguments
ARG NEXT_PUBLIC_VERSION
ENV NEXT_PUBLIC_VERSION=$NEXT_PUBLIC_VERSION

# Install build dependencies
RUN apk add --no-cache \
    g++ \
    make \
    py3-pip \
    bash \
    && rm -rf /var/cache/apk/*

# Install global npm packages
RUN npm --no-update-notifier --no-fund --global install pnpm@10.6.1

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package.json pnpm-*.yaml ./
COPY apps/*/package.json apps/*/
COPY libraries/*/package.json libraries/*/

# Copy the entire libraries directory structure (needed for Prisma schema and postinstall script)
COPY libraries/ ./libraries/

# Install dependencies (this will run postinstall script which needs Prisma schema)
RUN pnpm install --no-frozen-lockfile

# Copy the rest of the source code
COPY apps/ ./apps/
COPY var/ ./var/
COPY tsconfig.*.json ./
COPY *.json ./
COPY *.js ./
COPY *.ts ./

# Build the application with optimizations
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
RUN NODE_OPTIONS="--max-old-space-size=1536" pnpm run build

# Production stage
FROM node:20-alpine3.19 AS production

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    nginx \
    curl \
    && rm -rf /var/cache/apk/*

# Create nginx user and directories
RUN adduser -D -g 'www' www && \
    mkdir -p /www /uploads && \
    chown -R www:www /var/lib/nginx /www /uploads

# Install global runtime packages
RUN npm --no-update-notifier --no-fund --global install pnpm@10.6.1 pm2

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app ./

# Copy nginx configuration
COPY var/docker/nginx.conf /etc/nginx/nginx.conf

# Create uploads directory with proper permissions
RUN mkdir -p /uploads && chown -R www:www /uploads

# Expose port 80 for Coolify
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:80/api/health || curl -f http://localhost:80/ || exit 1

# Start command with proper signal handling
CMD ["sh", "-c", "nginx && pnpm run pm2"]
