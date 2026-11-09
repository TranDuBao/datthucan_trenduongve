# Node.js Production Dockerfile for Layered Express Backend
FROM node:22-alpine AS builder

WORKDIR /app

# Install native build tools for node-gyp (required for bcrypt)
RUN apk add --no-cache python3 make g++

# Copy package manifests
COPY package*.json ./

# Install all dependencies including devDependencies for build
RUN npm install

# Copy source code (node_modules and dist are excluded via .dockerignore)
COPY . .

# Build TypeScript to dist/
RUN npm run build

# Prune devDependencies to keep production node_modules minimal
RUN npm prune --omit=dev

# Production stage
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copy package manifests & production node_modules from builder
COPY package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/server.js"]
