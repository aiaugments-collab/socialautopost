FROM node:20-alpine3.19
ARG NEXT_PUBLIC_VERSION
ENV NEXT_PUBLIC_VERSION=$NEXT_PUBLIC_VERSION
RUN apk add --no-cache g++ make py3-pip bash nginx
RUN adduser -D -g 'www' www
RUN mkdir /www
RUN chown -R www:www /var/lib/nginx
RUN chown -R www:www /www

RUN npm --no-update-notifier --no-fund --global install pnpm@10.6.1 pm2

WORKDIR /app

COPY package*.json pnpm-*.yaml ./
COPY libraries/nestjs-libraries/package*.json ./libraries/nestjs-libraries/
COPY apps/backend/package*.json ./apps/backend/
COPY apps/frontend/package*.json ./apps/frontend/
COPY apps/workers/package*.json ./apps/workers/
COPY apps/cron/package*.json ./apps/cron/

RUN pnpm install --frozen-lockfile

COPY . .
COPY var/docker/nginx.conf /etc/nginx/nginx.conf

RUN NODE_OPTIONS="--max-old-space-size=4096" pnpm run build

EXPOSE 80 3000

CMD ["sh", "-c", "nginx && pnpm run pm2"]
