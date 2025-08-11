FROM node:20-alpine3.19

# Build-time arguments
ARG NEXT_PUBLIC_VERSION
ENV NEXT_PUBLIC_VERSION=$NEXT_PUBLIC_VERSION

# Install system dependencies
RUN apk add --no-cache \
    g++ \
    make \
    py3-pip \
    bash \
    nginx \
    curl \
    && rm -rf /var/cache/apk/*

# Create nginx user and directories
RUN adduser -D -g 'www' www && \
    mkdir -p /www /uploads && \
    chown -R www:www /var/lib/nginx /www /uploads

# Install global npm packages
RUN npm --no-update-notifier --no-fund --global install pnpm@10.6.1 pm2

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package.json pnpm-*.yaml ./
COPY apps/*/package.json apps/*/
COPY libraries/*/package.json libraries/*/

# Install dependencies
RUN pnpm install --no-frozen-lockfile

# Copy source code
COPY . .

# Copy nginx configuration
COPY var/docker/nginx.conf /etc/nginx/nginx.conf

# Build the application
RUN NODE_OPTIONS="--max-old-space-size=4096" pnpm run build

# Create uploads directory with proper permissions
RUN mkdir -p /uploads && chown -R www:www /uploads

# Expose port 80 for Coolify
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:80/api/health || curl -f http://localhost:80/ || exit 1

# Start command with proper signal handling
CMD ["sh", "-c", "nginx && pnpm run pm2"]
