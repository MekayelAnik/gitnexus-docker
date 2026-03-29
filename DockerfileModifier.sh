#!/bin/bash
set -ex
# Set variables first
REPO_NAME='gitnexus-mcp'
BASE_IMAGE=$(cat ./build_data/base-image 2>/dev/null || echo "node:22-bookworm-slim")
GITNEXUS_VERSION=$(cat ./build_data/version 2>/dev/null || exit 1)
GITNEXUS_MCP_PKG="gitnexus@${GITNEXUS_VERSION}"
SUPERGATEWAY_PKG='supergateway@latest'
DOCKERFILE_NAME="Dockerfile.$REPO_NAME"

# Create a temporary file safely
TEMP_FILE=$(mktemp "${DOCKERFILE_NAME}.XXXXXX") || {
    echo "Error creating temporary file" >&2
    exit 1
}

# Check if this is a publication build
if [ -e ./build_data/publication ]; then
    # For publication builds, create a minimal Dockerfile that just tags the existing image
    {
        echo "ARG BASE_IMAGE=$BASE_IMAGE"
        echo "ARG GITNEXUS_VERSION=$GITNEXUS_VERSION"
        echo "FROM $BASE_IMAGE"
    } > "$TEMP_FILE"
else
    # Write the Dockerfile content to the temporary file first
    {
        echo "ARG BASE_IMAGE=$BASE_IMAGE"
        echo "ARG GITNEXUS_VERSION=$GITNEXUS_VERSION"
        cat << EOF
FROM $BASE_IMAGE AS build

# Author info:
LABEL org.opencontainers.image.authors="MOHAMMAD MEKAYEL ANIK <mekayel.anik@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/mekayelanik/GitNexus-docker"

# Copy the entrypoint script into the container and make it executable
COPY ./resources/ /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/banner.sh \
    && if [ -f /usr/local/bin/build-timestamp.txt ]; then chmod +r /usr/local/bin/build-timestamp.txt; fi \
    && mkdir -p /etc/haproxy \
    && mv -vf /usr/local/bin/haproxy.cfg.template /etc/haproxy/haproxy.cfg.template \
    && ls -la /etc/haproxy/haproxy.cfg.template

# Install required packages (Debian-based: haproxy, gosu, build tools for native deps)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash haproxy gosu netcat-openbsd openssl ca-certificates iproute2 tzdata \
    python3 make g++ git && \
    rm -rf /var/lib/apt/lists/*

# Create the data directory for repositories
RUN mkdir -p /data && chown node:node /data

# Check if package exists before installing
RUN echo "Checking if package exists: ${GITNEXUS_MCP_PKG}" && \
    if npm view ${GITNEXUS_MCP_PKG} >/dev/null 2>&1; then \
        echo "Package found, installing..." && \
        npm install -g ${GITNEXUS_MCP_PKG} --omit=dev --no-audit --no-fund --loglevel error && \
        echo "Package installed successfully"; \
    else \
        echo "ERROR: Package ${GITNEXUS_MCP_PKG} not found in registry!" >&2; \
        echo "Available versions:" && \
        npm view gitnexus versions --json | tr -d '\[\],' | tr '"' '\n' | grep -v '^\$' | head -10; \
        exit 1; \
    fi

# Install Supergateway
RUN echo "Installing Supergateway..." && \
    npm install -g ${SUPERGATEWAY_PKG} --omit=dev --no-audit --no-fund --loglevel error && \
    npm cache clean --force && \
    rm -rf /root/.npm /tmp/* /var/tmp/* && \
    rm -rf /usr/local/lib/node_modules/npm/man /usr/local/lib/node_modules/npm/docs /usr/local/lib/node_modules/npm/html

# Clean up build tools to reduce image size
RUN apt-get purge -y python3 make g++ && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Use an ARG for the default port
ARG PORT=8010

# Add ARG for API key
ARG API_KEY=""

# Set an ENV variable from the ARG for runtime
ENV PORT=\${PORT}
ENV API_KEY=\${API_KEY}

# Health check using nc (netcat) to check if the port is open
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \\
    CMD nc -z localhost \${PORT:-8010} || exit 1

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

EOF
    } > "$TEMP_FILE"
fi

# Atomically replace the target file with the temporary file
if mv -f "$TEMP_FILE" "$DOCKERFILE_NAME"; then
    echo "Dockerfile for $REPO_NAME created successfully."
else
    echo "Error: Failed to create Dockerfile for $REPO_NAME" >&2
    rm -f "$TEMP_FILE"
    exit 1
fi
