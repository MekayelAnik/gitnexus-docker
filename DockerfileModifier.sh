#!/bin/bash
set -euxo pipefail
# Set variables first
REPO_NAME='gitnexus-mcp'
BASE_IMAGE=$(cat ./build_data/base-image 2>/dev/null || echo "node:22-slim")
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

# Generate build timestamp
RUN echo "Built: \$(date -u '+%Y-%m-%d %H:%M:%S UTC') | GitNexus v${GITNEXUS_VERSION}" > /tmp/build-timestamp.txt

# Copy the entrypoint script into the container and make it executable
COPY ./resources/ /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/banner.sh \
    && mv -f /tmp/build-timestamp.txt /usr/local/bin/build-timestamp.txt \
    && chmod +r /usr/local/bin/build-timestamp.txt \
    && mkdir -p /etc/haproxy \
    && mv -vf /usr/local/bin/haproxy.cfg.template /etc/haproxy/haproxy.cfg.template \
    && ls -la /etc/haproxy/haproxy.cfg.template

# Install runtime packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash haproxy gosu netcat-openbsd openssl ca-certificates iproute2 tzdata git && \
    rm -rf /var/lib/apt/lists/*

# Create the data directory for repositories
RUN mkdir -p /data && chown node:node /data

# Install build tools, compile native deps, optimize, then remove build tools in single layer
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    python3 make g++ binutils && \
    echo "Installing ${GITNEXUS_MCP_PKG}..." && \
    npm install -g ${GITNEXUS_MCP_PKG} --omit=dev --no-audit --no-fund --loglevel error && \
    echo "Installing Supergateway..." && \
    npm install -g ${SUPERGATEWAY_PKG} --omit=dev --no-audit --no-fund --loglevel error && \
    # --- Size optimizations (saves ~60-120 MB) --- \
    # 1. Strip native binaries \
    find /usr/local/lib/node_modules -name '*.node' -exec strip --strip-all {} + 2>/dev/null || true && \
    find /usr/local/lib/node_modules -name '*.so*' -exec strip --strip-unneeded {} + 2>/dev/null || true && \
    # 2. Deduplicate onnxruntime .so files (identical copies -> symlinks) \
    cd /usr/local/lib/node_modules && \
    find . -path '*/onnxruntime-node/bin/napi-v3/linux/*' -name 'libonnxruntime.so.*.*.*' | while read f; do \
      dir=\$(dirname "\$f"); base=\$(echo "\$f" | sed 's/\.[0-9]*\.[0-9]*\$//'); \
      if [ -f "\$base" ] && [ ! -L "\$base" ]; then ln -sf "\$(basename "\$f")" "\$base"; fi; \
    done 2>/dev/null || true && \
    # 3. Remove non-native-platform onnxruntime binaries \
    find . -path '*/onnxruntime-node/bin/napi-v3/*' -mindepth 1 -maxdepth 1 -type d | while read d; do \
      case "\$d" in */linux_*) ;; *) rm -rf "\$d" ;; esac; \
    done 2>/dev/null || true && \
    cd / && \
    # 4. Remove tree-sitter build artifacts (keep src/*.json, src/*.wasm for runtime) \
    find /usr/local/lib/node_modules -path '*/tree-sitter*' \\( -name '*.o' -o -name '*.a' \\) -delete 2>/dev/null || true && \
    find /usr/local/lib/node_modules -path '*/tree-sitter*/build' -type d -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/node_modules -path '*/tree-sitter*/src' \\( -name '*.cc' -o -name '*.c' -o -name '*.h' \\) -delete 2>/dev/null || true && \
    # 5. Remove node_modules junk (docs, tests, maps, editor configs) \
    find /usr/local/lib/node_modules \\( \
      -name '*.md' -o -name '*.map' -o -name '*.ts' ! -name '*.d.ts' -o \
      -name 'CHANGELOG*' -o -name 'HISTORY*' -o \
      -name '.eslintrc*' -o -name '.prettierrc*' -o -name '.editorconfig' -o \
      -name '.npmignore' -o -name '.travis.yml' -o -name '.github' -o \
      -name 'tsconfig.json' -o -name 'jest.config*' -o -name '.nycrc*' -o \
      -name 'Makefile' -o -name 'Gruntfile*' -o -name 'Gulpfile*' -o \
      -name '*.gyp' -o -name '*.gypi' -o -name 'binding.gyp' \
    \\) -delete 2>/dev/null || true && \
    find /usr/local/lib/node_modules -type d \\( \
      -name 'test' -o -name 'tests' -o -name '__tests__' -o \
      -name 'example' -o -name 'examples' -o -name 'docs' -o \
      -name '.github' -o -name 'benchmark' -o -name 'benchmarks' \
    \\) -exec rm -rf {} + 2>/dev/null || true && \
    # 6. Clean npm and build caches \
    npm cache clean --force && \
    rm -rf /root/.npm /tmp/* /var/tmp/* && \
    rm -rf /usr/local/lib/node_modules/npm/man /usr/local/lib/node_modules/npm/docs /usr/local/lib/node_modules/npm/html && \
    # 7. Remove build tools \
    apt-get purge -y python3 make g++ binutils && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Use an ARG for the default port
ARG PORT=8010

# Add ARG for API key
ARG API_KEY=""

# NVIDIA GPU support (used by onnxruntime when host passes --gpus)
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Set ENV variables for runtime
ENV PORT=\${PORT}
ENV API_KEY=\${API_KEY}
ENV DATA_DIR=/data

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
