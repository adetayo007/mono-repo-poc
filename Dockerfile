# Base image
FROM node:18-alpine AS base

# Set working directory
WORKDIR /app

# Install dependencies separately for caching
COPY package.json pnpm-lock.yaml ./
# Use the latest pnpm version to avoid lockfile compatibility issues
RUN npm install -g pnpm@latest && pnpm install --frozen-lockfile

# Copy all project files
COPY . .

# Install dependencies for web and merchant applications
RUN pnpm --filter=web install
RUN pnpm --filter=merchant install

# Build the apps (web and merchant)
RUN pnpm turbo run build --filter=web --filter=merchant

# ------ Separate image stage for production

# Production image
FROM node:18-alpine AS production

# Set working directory
WORKDIR /app

# Copy the pnpm and node_modules from the previous image
COPY --from=base /app/node_modules ./node_modules
COPY --from=base /app/package.json ./
COPY --from=base /app/apps ./apps
COPY --from=base /app/packages ./packages

# Use environment variables if needed
ENV NODE_ENV=production

# Install production dependencies
RUN pnpm install --prod

# Expose the port for the web application (adjust if necessary)
EXPOSE 3000

# Command to run the application (change according to your setup)
CMD ["pnpm", "turbo", "start", "--filter=web"]
