# OpenRouter MCP Server
# Multi-stage build for smaller image

FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source
COPY tsconfig.json ./
COPY src/ ./src/

# Build TypeScript
RUN npm run build

# --- Production stage ---
FROM node:20-alpine AS production

WORKDIR /app

# Copy package files and install production deps only
COPY package*.json ./
RUN npm ci --omit=dev

# Copy built files from builder
COPY --from=builder /app/dist ./dist

# Environment variable for API key (set at runtime)
ENV OPENROUTER_API_KEY=""

# Run the MCP server
CMD ["node", "dist/index.js"]
