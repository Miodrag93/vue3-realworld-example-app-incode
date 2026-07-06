### Build stage: install deps with pnpm and produce the static build
FROM node:20-alpine AS builder

WORKDIR /app

RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

# Vite inlines VITE_ prefixed vars into the bundle at build time, so the
# backend URL must be supplied here rather than at container runtime.
# Default is empty: nginx.conf proxies /api/ to the backend's ClusterIP
# Service internally, so the browser only ever calls this app's own origin.
ARG VITE_API_HOST=""
ENV VITE_API_HOST=${VITE_API_HOST}

RUN pnpm build

### Runtime stage: serve the static build via an unprivileged nginx
FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
