# syntax=docker.io/docker/dockerfile:1

FROM node:20-alpine AS base

FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /
COPY package.json package-lock.json* ./
RUN npm ci

FROM base AS builder
WORKDIR /
COPY --from=deps /node_modules ./node_modules
COPY . .
RUN npm run build

FROM base AS runner
WORKDIR /

# کپی کامل برای standalone اجرا:
COPY --from=builder /.next/standalone ./
COPY --from=builder /.next/static ./.next/static
COPY --from=builder /public ./public
COPY --from=builder /node_modules ./node_modules  # این خط حیاتی هست!
COPY package.json ./ # اختیاری

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]