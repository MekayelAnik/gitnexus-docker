#!/usr/bin/env bash
set -euo pipefail

FORCE_BUILD="${FORCE_BUILD:-false}"
GHCR_REPO="${GHCR_REPO:-}"
VERSION="${VERSION:-}"

if [[ -z "$GHCR_REPO" || -z "$VERSION" ]]; then
    echo "Missing required inputs. Expected GHCR_REPO and VERSION" >&2
    exit 1
fi

if [[ "$FORCE_BUILD" == "true" ]]; then
    echo "skip_build=false"
    exit 0
fi

# Try docker manifest inspect first
if docker manifest inspect "${GHCR_REPO}:${VERSION}" >/dev/null 2>&1; then
    echo "Image version already present in GHCR; skipping build"
    echo "skip_build=true"
    exit 0
fi

# Fallback: check GHCR API anonymously via curl (avoids Docker Hub rate limits)
# Extract owner/image from ghcr.io/owner/image format
GHCR_PATH="${GHCR_REPO#ghcr.io/}"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://ghcr.io/v2/${GHCR_PATH}/manifests/${VERSION}" \
    -H "Accept: application/vnd.oci.image.index.v1+json" 2>/dev/null || echo "000")

if [[ "$API_STATUS" == "200" ]]; then
    echo "Image version found via GHCR API (anonymous); skipping build"
    echo "skip_build=true"
    exit 0
fi

echo "Image version not found in GHCR; building"
echo "skip_build=false"
