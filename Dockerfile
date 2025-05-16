# Use Bun as the base image
FROM oven/bun:1.2.5 AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update -y && apt-get install -y \
    openssl \
    python3 \
    python3-pip \
    build-essential \
    g++ \
    make

# Copy package files first to leverage Docker layer caching
COPY package.json ./
# Check if bun.lock exists before copying
COPY bun.lock* ./

# Copy Drizzle files for database setup
COPY db ./db
COPY drizzle ./drizzle
COPY drizzle.config.ts ./

# Install dependencies with special handling for better-sqlite3
ENV PYTHON=/usr/bin/python3
# First install better-sqlite3 separately with specific options
RUN bun add better-sqlite3 --no-save
# Then install all dependencies
RUN bun install --frozen-lockfile

# Add sharp for image optimization
RUN bun add sharp

# Copy the rest of the application
COPY . .

# Note: All environment variables will be passed at runtime
# This is more secure than using ARG/ENV in the Dockerfile

# Build the Next.js application
RUN bun run build

# Production image, copy all the files and run next
FROM oven/bun:1.2.5 AS runner

WORKDIR /app

# Set to production environment
ENV NODE_ENV=production

# Install runtime dependencies
RUN apt-get update -y && apt-get install -y \
    openssl \
    python3 \
    build-essential \
    g++ \
    make && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user and set permissions
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    mkdir -p /app/data && \
    chmod 777 /app/data && \
    chown -R nextjs:nodejs /app

# Copy package files first
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./
COPY --from=builder --chown=nextjs:nodejs /app/bun.lock* ./

# Copy Drizzle files
COPY --from=builder --chown=nextjs:nodejs /app/db ./db
COPY --from=builder --chown=nextjs:nodejs /app/drizzle ./drizzle
COPY --from=builder --chown=nextjs:nodejs /app/drizzle.config.ts ./drizzle.config.ts

# Install dependencies with special handling for better-sqlite3
ENV PYTHON=/usr/bin/python3
USER root
RUN bun add better-sqlite3 --no-save && \
    bun install --production --frozen-lockfile && \
    chown -R nextjs:nodejs /app
USER nextjs

# Copy the rest of the application
COPY --from=builder --chown=nextjs:nodejs /app/next.config.mjs ./
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next

# Set the user to run the application
USER nextjs

# Expose the port the app runs on
EXPOSE 3000

# Run Drizzle migrations and start the application
CMD ["sh", "-c", "mkdir -p /app/data && chmod 777 /app/data && bunx drizzle-kit push && bun run start"]

# USAGE INSTRUCTIONS:
# Run the container with all environment variables passed at runtime:
# docker run -p 3000:3000 \
#   -e BETTER_AUTH_SECRET=your_secret \
#   -e BETTER_AUTH_URL=your_url \
#   -e NEXT_PUBLIC_BASE_URL=your_base_url \
#   -e NEXT_PUBLIC_PASSKEY_RP_ID=your_rp_id \
#   -e NEXT_PUBLIC_PASSKEY_ORIGIN=your_origin \
#   -v ./data:/app/data \
#   pesan-pms
#
# For production, consider using Docker secrets or environment files:
# docker run -p 3000:3000 --env-file .env.production -v ./data:/app/data pesan-pms
