# Base image
FROM oven/bun:1 as base

# Set working directory
WORKDIR /app

# Install dependencies
FROM base as dependencies
COPY package.json bun.lockb* ./
RUN bun install --frozen-lockfile

# Build the application
FROM dependencies as build
COPY . .
RUN bun run build

# Production image
FROM base as production
ENV NODE_ENV=production

# Copy built application from build stage
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/next.config.mjs ./next.config.mjs
COPY --from=build /app/db ./db
COPY --from=build /app/drizzle ./drizzle

# Install only production dependencies
RUN bun install --production --frozen-lockfile

# Create a directory for the database
RUN mkdir -p /app/data

# Expose the port the app will run on
EXPOSE 3000

# Command to run the application
CMD ["bun", "run", "start"]
