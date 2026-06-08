# GitNexus MCP Server
### Multi-Architecture Docker Image for Distributed Deployment

<div align="left">

[![Docker Pulls](https://img.shields.io/docker/pulls/mekayelanik/gitnexus-mcp.svg?style=flat-square)](https://hub.docker.com/r/mekayelanik/gitnexus-mcp)
[![Docker Stars](https://img.shields.io/docker/stars/mekayelanik/gitnexus-mcp.svg?style=flat-square)](https://hub.docker.com/r/mekayelanik/gitnexus-mcp)
[![License](https://img.shields.io/badge/license-GPL-blue.svg?style=flat-square)](https://raw.githubusercontent.com/MekayelAnik/GitNexus-docker/refs/heads/main/LICENSE)

**[Upstream GitHub](https://github.com/abhigyanpatwari/GitNexus)** | **[NPM Package](https://www.npmjs.com/package/gitnexus)** | **[Docker Hub](https://hub.docker.com/r/mekayelanik/gitnexus-mcp)**

</div>

---

> **Disclaimer:** This is an **unofficial** Docker image. GitNexus is developed by [Abhigyan Patwari / Akon Labs](https://github.com/abhigyanpatwari/GitNexus) under the [PolyForm Noncommercial License 1.0.0](https://github.com/abhigyanpatwari/GitNexus/blob/main/LICENSE). Docker packaging independently maintained by [Mohammad Mekayel Anik](https://github.com/MekayelAnik) under GPL v3.

---

## Table of Contents

- [Overview](#overview)
- [Supported Architectures](#supported-architectures)
- [Available Tags](#available-tags)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [GitNexus-Specific Configuration](#gitnexus-specific-configuration)
- [Wiki Generation](#wiki-generation)
- [MCP Client Configuration](#mcp-client-configuration)
- [Network Configuration](#network-configuration)
- [Updating](#updating)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)
- [Support & License](#support--license)

---

## Buy Me a Coffee

**If you found value in this project, you can buy me a coffee to keep me inspired.**

<p align="center">
<a href="https://07mekayel07.gumroad.com/coffee" target="_blank">
<img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217" height="60">
</a>
</p>

## Overview

[GitNexus](https://github.com/abhigyanpatwari/GitNexus) is a code intelligence MCP server: knowledge graph (LadybugDB), Tree-sitter indexing, embeddings, wiki docs, AI code search. Packaged with HAProxy + mcp-proxy bridge — API key auth, CORS, HTTP/1.1, HTTP/2, HTTP/3 (QUIC).

### Key Features

- **Multi-Architecture** - Native x86-64 and ARM64
- **Modern MCP Bridge** - [mcp-proxy](https://github.com/sparfenyuk/mcp-proxy) stdio↔SHTTP/SSE; stateful, no spawn-per-request leak
- **Auto-Analysis** - Indexes all repos in the data directory on startup
- **Self-Hosted Web UI** - Built-in interface on the same port as MCP
- **Wiki Generation** - AI-powered wiki via OpenAI, Ollama, vLLM, or compatible API
- **Secure by Design** - API key auth, CORS, TLS termination, security headers
- **High Performance** - ZSTD compression for faster deployments

---

## Supported Architectures

| Architecture | Tag Prefix | Status |
|:-------------|:-----------|:------:|
| **x86-64** | `amd64-<version>` | Stable |
| **ARM64** | `arm64v8-<version>` | Stable |

> Multi-arch images automatically select the correct architecture for your system.

---

## Available Tags

| Tag | Stability | Description | Use Case |
|:----|:---------:|:------------|:---------|
| `latest` | Production | Latest stable release | **Recommended for production** |
| `1.6.6` | Production | Specific version | Version pinning for consistency |

### System Requirements

- **Docker Engine:** 23.0+
- **RAM:** 1GB min (2GB+ for embeddings)
- **CPU:** Single core (multi-core recommended)
- **GPU:** Optional NVIDIA for embeddings (see [GPU Support](#gpu-support))
- **Storage:** Depends on repo sizes

> **CRITICAL:** Do NOT expose directly to the internet without a reverse proxy, SSL/TLS, auth, and firewall.

---

## Quick Start

### Docker Compose (Recommended)

```yaml
services:
  gitnexus-mcp:
    image: mekayelanik/gitnexus-mcp:latest
    container_name: gitnexus-mcp
    restart: unless-stopped
    ports:
      - "8010:8010"   # MCP + Web UI + API (all via HAProxy)
    volumes:
      - /path/to/your/repos:/data:rw
      - gitnexus-registry:/home/node/.gitnexus   # Persist index registry
      - gitnexus-cache:/home/node/.cache          # Persist embedding models
    environment:
      - PORT=8010
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Dhaka
      - NODE_ENV=production
      - PROTOCOL=SHTTP
      - ENABLE_HTTPS=false
      - HTTP_VERSION_MODE=auto
      # GitNexus Analysis Options
      - DATA_DIR=/data
      - ANALYZE_FORCE=false
      - ANALYZE_VERBOSE=false
      # Optional: require Bearer token auth at HAProxy layer
      # - API_KEY=replace-with-strong-secret
      # Optional: Wiki generation (requires LLM API key)
      # - WIKI_ENABLED=true
      # - OPENAI_API_KEY=sk-...
      # - WIKI_MODEL=gpt-4o
    hostname: gitnexus-mcp
    domainname: local

volumes:
  gitnexus-registry:
    driver: local
  gitnexus-cache:
    driver: local
```

**Deploy:**
```bash
docker compose up -d
docker compose logs -f gitnexus-mcp
```

### Docker CLI

```bash
docker volume create gitnexus-registry && docker volume create gitnexus-cache
docker run -d \
  --name=gitnexus-mcp \
  --restart=unless-stopped \
  -p 8010:8010 \
  -v /path/to/your/repos:/data:rw \
  -v gitnexus-registry:/home/node/.gitnexus \
  -v gitnexus-cache:/home/node/.cache \
  -e PORT=8010 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Dhaka \
  -e NODE_ENV=production \
  -e PROTOCOL=SHTTP \
  -e ENABLE_HTTPS=false \
  -e HTTP_VERSION_MODE=auto \
  -e DATA_DIR=/data \
  mekayelanik/gitnexus-mcp:latest
```

### Full-Featured Docker Compose (GPU + HTTPS + Wiki + Auth)

```yaml
services:
  gitnexus-mcp:
    image: mekayelanik/gitnexus-mcp:latest
    container_name: gitnexus-mcp
    restart: unless-stopped
    ports:
      - "8010:8010"   # MCP + Web UI + API (all via HAProxy)
    volumes:
      - /path/to/your/repos:/data:rw
      - gitnexus-registry:/home/node/.gitnexus   # Persist index registry
      - gitnexus-cache:/home/node/.cache          # Persist embedding models
      - /path/to/certs:/etc/haproxy/certs:ro      # TLS certificates
      # GPU: mount host CUDA libs (remove if no GPU)
      - /usr/local/cuda/lib64:/usr/local/cuda/lib64:ro
    environment:
      # Core
      - PORT=8010
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Dhaka
      - NODE_ENV=production
      # MCP Transport (SHTTP, SSE, or WS)
      - PROTOCOL=SHTTP
      # Security
      - API_KEY=replace-with-a-strong-secret
      - CORS=*
      - ENABLE_HTTPS=true
      - TLS_CERT_PATH=/etc/haproxy/certs/server.crt
      - TLS_KEY_PATH=/etc/haproxy/certs/server.key
      - TLS_MIN_VERSION=TLSv1.3
      - HTTP_VERSION_MODE=auto
      # Repository Analysis
      - DATA_DIR=/data
      - ANALYZE_FORCE=false
      - ANALYZE_SKILLS=true
      - ANALYZE_EMBEDDINGS=true
      - ANALYZE_VERBOSE=false
      # Wiki Generation
      - WIKI_ENABLED=true
      - OPENAI_API_KEY=sk-your-key-here
      - WIKI_MODEL=gpt-4o-mini
      # Web UI
      - ENABLE_WEB_UI=true
    # NVIDIA GPU (optional — remove if no GPU)
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu, compute, utility]
    hostname: gitnexus-mcp
    domainname: local

volumes:
  gitnexus-registry:
    driver: local
  gitnexus-cache:
    driver: local
```

### Full-Featured Docker CLI (GPU + Auth)

```bash
docker volume create gitnexus-registry && docker volume create gitnexus-cache
docker run -d \
  --name=gitnexus-mcp \
  --restart=unless-stopped \
  --gpus all \
  -p 8010:8010 \
  -v /path/to/your/repos:/data:rw \
  -v gitnexus-registry:/home/node/.gitnexus \
  -v gitnexus-cache:/home/node/.cache \
  -v /path/to/certs:/etc/haproxy/certs:ro \
  -v /usr/local/cuda/lib64:/usr/local/cuda/lib64:ro \
  -e PORT=8010 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Dhaka \
  -e NODE_ENV=production \
  -e PROTOCOL=SHTTP \
  -e API_KEY=replace-with-a-strong-secret \
  -e CORS='*' \
  -e ENABLE_HTTPS=true \
  -e TLS_CERT_PATH=/etc/haproxy/certs/server.crt \
  -e TLS_KEY_PATH=/etc/haproxy/certs/server.key \
  -e HTTP_VERSION_MODE=auto \
  -e DATA_DIR=/data \
  -e ANALYZE_SKILLS=true \
  -e ANALYZE_EMBEDDINGS=true \
  -e WIKI_ENABLED=true \
  -e OPENAI_API_KEY=sk-your-key-here \
  -e WIKI_MODEL=gpt-4o-mini \
  mekayelanik/gitnexus-mcp:latest
```

### Local Ollama + GitNexus (Docker Compose)

```yaml
services:
  gitnexus-mcp:
    image: mekayelanik/gitnexus-mcp:latest
    container_name: gitnexus-mcp
    restart: unless-stopped
    ports:
      - "8010:8010"
    volumes:
      - /path/to/your/repos:/data:rw
      - gitnexus-registry:/home/node/.gitnexus   # Persist index registry
      - gitnexus-cache:/home/node/.cache          # Persist embedding models
    environment:
      - PORT=8010
      - PROTOCOL=SHTTP
      - ENABLE_HTTPS=false
      - DATA_DIR=/data
      - ANALYZE_VERBOSE=false
      # Wiki via local Ollama
      - WIKI_ENABLED=true
      - WIKI_BASE_URL=http://ollama:11434/v1
      - WIKI_MODEL=llama3
      - OPENAI_API_KEY=not-needed

  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    volumes:
      - ollama-data:/root/.ollama
    # Uncomment for GPU
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: all
    #           capabilities: [compute, utility]

volumes:
  gitnexus-registry:
    driver: local
  gitnexus-cache:
    driver: local
  ollama-data:
```

### Access Endpoints

All services are accessible on a **single port** (default `8010`) via HAProxy:

| Service | Endpoint | Description |
|:--------|:---------|:------------|
| **Web UI** | `http://host-ip:8010/` | GitNexus web interface |
| **MCP (SHTTP)** | `http://host-ip:8010/mcp` | Streamable HTTP (recommended) |
| **MCP (SSE)** | `http://host-ip:8010/sse` | Server-Sent Events |
| **REST API** | `http://host-ip:8010/api/*` | REST API (repos, search, graph) |
| **Health** | `http://host-ip:8010/healthz` | Health check |

With `ENABLE_HTTPS=true`, use TLS endpoints:

| Service | Endpoint |
|:--------|:---------|
| **Web UI** | `https://host-ip:8010/` |
| **MCP (SHTTP)** | `https://host-ip:8010/mcp` |
| **MCP (SSE)** | `https://host-ip:8010/sse` |

> **Single-Port Architecture:** HAProxy routes `/mcp`,`/sse`→mcp-proxy, `/api/*`→GitNexus API, `/*`→web UI; `/healthz` answered locally. Set `ENABLE_WEB_UI=false` for MCP-only.

> **Smart Healthcheck:** Reports healthy during analysis/wiki phases to avoid false unhealthy status.

> **Security Warning:** Defaults to HTTP. Use `ENABLE_HTTPS=true` with own certs for production. See [CERTIFICATE_SETUP_GUIDE.md](CERTIFICATE_SETUP_GUIDE.md). ARM devices: allow 60-120s for init.

---

## Configuration

### Volumes

| Mount | Container Path | Purpose |
|:------|:---------------|:--------|
| Repository data | `/data` | Root directory containing repos to analyze (required) |
| Index registry | `/home/node/.gitnexus` | Repo-to-index registry. **Persist** to avoid re-registration |
| Embedding cache | `/home/node/.cache` | HuggingFace models, ONNX cache. **Persist** to avoid re-download |
| TLS certificates | `/etc/haproxy/certs` | TLS cert/key files (only with `ENABLE_HTTPS=true`) |

> Indexes live in `.gitnexus/` within each repo. The registry at `/home/node/.gitnexus` stores pointers.

### Complete Environment Variables Reference

#### Networking & Ports

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `PORT` | `8010` | `1`-`65535` | External HAProxy port (MCP + Web UI + API) |
| `PROTOCOL` | `SHTTP` | `SHTTP`, `SSE` | MCP transport (WS unsupported by mcp-proxy) |
| `MCP_PROXY_STATELESS` | `false` | `true`,`false` | `false`=shared child no TTL; `true`=per-request isolation |
| `GITNEXUS_MAX_MEM_MB` | `0` | `0` or `>=16384` | `prlimit --as` MiB cap. LadybugDB mmaps ~16 GiB virtual; lower caps break DB tools |
| `HAPROXY_FRONTEND_MAXCONN` | `0` | `0`-`N` | HAProxy frontend max conns (0=off) |
| `HAPROXY_SERVER_MAXCONN` | `0` | `0`-`N` | HAProxy→mcp-proxy max conns (0=off) |

> **Internal ports** (`INTERNAL_PORT=38011`, `WEB_UI_PORT=4747`) are used by HAProxy; change only for in-container port conflicts. Static file server port (`39012`) is fixed.

#### Security & TLS

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `API_KEY` | *(empty)* | 5-256 printable chars | Bearer token auth (`Authorization: Bearer <key>`) |
| `CORS` | *(empty)* | `*`, comma-separated origins | CORS allowed origins |
| `ENABLE_HTTPS` | `false` | `true`, `false` | TLS termination in HAProxy (requires own certs) |
| `TLS_CERT_PATH` | `/etc/haproxy/certs/server.crt` | Any valid path | TLS certificate file |
| `TLS_KEY_PATH` | `/etc/haproxy/certs/server.key` | Any valid path | TLS private key file |
| `TLS_PEM_PATH` | `/etc/haproxy/certs/server.pem` | Any valid path | Combined PEM (auto-generated from cert+key) |
| `TLS_MIN_VERSION` | `TLSv1.3` | `TLSv1.2`, `TLSv1.3` | Minimum TLS version |
| `HTTP_VERSION_MODE` | `auto` | `auto`, `all`, `h1`, `h2`, `h3`, `h1+h2` | HTTP versions to enable |
| `RATE_LIMIT` | `0` | `0`-`N` | Max requests per `RATE_LIMIT_PERIOD` per IP (0=off) |
| `RATE_LIMIT_PERIOD` | `10s` | `10s`, `1m`, `1h`, etc. | Rate limit sliding window |
| `MAX_CONNECTIONS_PER_IP` | `0` | `0`-`N` | Max concurrent connections per IP (0=off) |
| `IP_ALLOWLIST` | *(empty)* | Comma-separated IPs/CIDRs | Allow only listed IPs (others blocked) |
| `IP_BLOCKLIST` | *(empty)* | Comma-separated IPs/CIDRs | Block listed IPs |

#### Container & System

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `PUID` | `1000` | Any positive integer | User ID |
| `PGID` | `1000` | Any positive integer | Group ID |
| `TZ` | `Asia/Dhaka` | [TZ database names](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | Timezone |
| `NODE_ENV` | `production` | `production`, `development` | Node.js environment |
| `ENABLE_WEB_UI` | `true` | `true`, `false` | Enable Web UI |

#### Repository Analysis

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `DATA_DIR` | `/data` | Any valid path | Root directory containing repos |
| `ANALYZE_FORCE` | `false` | `true`, `false` | Force full re-index (once per lifecycle) |
| `ANALYZE_SKILLS` | `false` | `true`, `false` | Generate skill files from communities |
| `ANALYZE_EMBEDDINGS` | `false` | `true`, `false` | Enable embeddings for semantic search |
| `ANALYZE_SKIP_GIT` | `false` | `true`, `false` | Index folders without `.git` |
| `ANALYZE_VERBOSE` | `false` | `true`, `false` | Log skipped files |

#### Embedding Override (HTTP Backend)

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `GITNEXUS_EMBEDDING_URL` | *(empty)* | OpenAI-compatible `/v1/embeddings` endpoint URL |
| `GITNEXUS_EMBEDDING_MODEL` | *(empty)* | Model name for API requests |
| `GITNEXUS_EMBEDDING_API_KEY` | `unused` | Bearer token for the endpoint |
| `GITNEXUS_EMBEDDING_DIMS` | `384` | Embedding dimensions (must match model) |

> **Local default:** `Snowflake/snowflake-arctic-embed-xs` (22M params, 384 dims, ~90MB). Auto-downloads when `ANALYZE_EMBEDDINGS=true`. Set URL + MODEL to use a remote API instead:

```yaml
# OpenAI
- GITNEXUS_EMBEDDING_URL=https://api.openai.com/v1
- GITNEXUS_EMBEDDING_MODEL=text-embedding-3-small
- GITNEXUS_EMBEDDING_API_KEY=sk-your-key
- GITNEXUS_EMBEDDING_DIMS=1536

# Self-hosted (OpenAI-compatible endpoint)
- GITNEXUS_EMBEDDING_URL=http://your-server:port/v1
- GITNEXUS_EMBEDDING_MODEL=Snowflake/snowflake-arctic-embed-xs
- GITNEXUS_EMBEDDING_DIMS=384
```

#### Cleanup

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `CLEAN_ON_START` | `false` | `true`, `false` | Run `gitnexus clean` before analysis |
| `CLEAN_ALL_FORCE` | `false` | `true`, `false` | Run `gitnexus clean --all --force` |

#### Wiki Generation

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `WIKI_ENABLED` | `false` | `true`, `false` | Enable wiki generation after analysis |
| `WIKI_MODEL` | `gpt-4o-mini` | Any model name | LLM model (e.g. `gpt-4o-mini`, `llama3`) |
| `WIKI_BASE_URL` | *(OpenAI default)* | Any URL | LLM API base URL |
| `WIKI_FORCE` | `false` | `true`, `false` | Force wiki regeneration |
| `OPENAI_API_KEY` | *(empty)* | Any string | API key for OpenAI or compatible provider |

> **Booleans:** `true`, `1`, `yes`, `on` are truthy. **Once per lifecycle:** `CLEAN_ON_START`, `CLEAN_ALL_FORCE`, `ANALYZE_FORCE`, `WIKI_FORCE` run once after creation; recreate to re-trigger.

#### One-Shot Operations (via `docker exec`)

```bash
docker exec gitnexus-mcp gitnexus clean              # Clean current repo index
docker exec gitnexus-mcp gitnexus clean --all --force # Delete ALL indexes
docker exec gitnexus-mcp gitnexus analyze --force     # Force full re-index
docker exec gitnexus-mcp gitnexus wiki --force        # Force wiki regeneration
```

### HTTPS Notes

- Provide own TLS cert/key. Merged into `TLS_PEM_PATH` automatically.
- `HTTP_VERSION_MODE=h3`/`auto` enables HTTP/3 only when HAProxy includes QUIC.

### API Key Authentication

- Set `API_KEY` to enforce auth at the proxy level.
- Header: `Authorization: Bearer <API_KEY>`.
- `/healthz` and CORS preflight bypass auth.

### Rate Limiting and IP Access Control

- **Rate limiting:** `RATE_LIMIT=100` allows 100 req/period/IP. Excess returns 429.
- **Connection limiting:** `MAX_CONNECTIONS_PER_IP=50` caps concurrent connections/IP.
- **IP blocklist/allowlist:** Block or allow specific IPs/CIDRs. Blocklist checked first. All disabled by default.

### Security Headers

HAProxy adds `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` (always), and `Strict-Transport-Security` (HTTPS only).

---

## GitNexus-Specific Configuration

### Volume Mount Structure

The container analyzes all subdirectories in `DATA_DIR` on startup. Mount repos as subdirectories.

```
/data/
├── my-project-1/    # auto-analyzed
├── my-project-2/    # auto-analyzed
└── another-repo/    # auto-analyzed
```

> Set `ANALYZE_SKIP_GIT=true` to index folders without `.git`.

---

## Wiki Generation

Supports cloud and local LLM providers via OpenAI-compatible API.

| Provider | `WIKI_BASE_URL` | `WIKI_MODEL` | `OPENAI_API_KEY` |
|:---------|:---------------|:-------------|:-----------------|
| OpenAI | *(default)* | `gpt-4o-mini` | `sk-your-key` |
| Ollama | `http://host.docker.internal:11434/v1` | `llama3` | `not-needed` |
| vLLM/llama.cpp | `http://your-server:8000/v1` | `your-model` | `not-needed` |

---

## GPU Support

GPU-accelerated embeddings via onnxruntime CUDA EP. **NVIDIA x64 only.** Falls back to CPU on ARM64 or without CUDA.

**Requirements:** NVIDIA driver + [Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) + CUDA toolkit on host.

**Setup:** Mount host CUDA libs + enable GPU passthrough:

```yaml
# docker-compose.yml additions
volumes:
  - /usr/local/cuda/lib64:/usr/local/cuda/lib64:ro
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu, compute, utility]
```

CLI: `docker run --gpus all -v /usr/local/cuda/lib64:/usr/local/cuda/lib64:ro ...`

**Verify:** Look for `CUDA runtime libraries: found (libcublasLt.so.12)` in startup logs. If `not found`, try alternate host paths: `/usr/local/cuda-12/targets/x86_64-linux/lib` or `/usr/lib/x86_64-linux-gnu`.

> The ONNX CUDA EP binary is in the image. Only host CUDA runtime libs (libcublas, libcufft, libcurand, libcudart, libcudnn, libnvrtc) need mounting.

---

## MCP Client Configuration

### Transport Support

| Client | SHTTP | SSE | Recommended |
|:-------|:-----:|:---:|:------------|
| **VS Code (Cline/Roo-Cline)** | Yes | Yes | SHTTP |
| **Claude Desktop** | Yes | Yes | SHTTP |
| **Claude CLI** | Yes | Yes | SHTTP |
| **Codex CLI** | Yes | Yes | SHTTP |
| **Codeium (Windsurf)** | Yes | Yes | SHTTP |
| **Cursor** | Yes | Yes | SHTTP |

---

### Claude Code / Claude Desktop

```bash
# With API_KEY
claude mcp add-json gitnexus '{"type":"http","url":"http://host-ip:8010/mcp","headers":{"Authorization":"Bearer <KEY>"}}'
# Without API_KEY
claude mcp add-json gitnexus '{"type":"http","url":"http://host-ip:8010/mcp"}'
```

### VS Code / Codex / Cursor / Windsurf

Same JSON format: VS Code (`mcp.servers`), Codex, Cursor (`mcpServers`), Windsurf (`mcpServers`).

```json
{
  "mcpServers": {
    "gitnexus": {
      "transport": "http",
      "url": "http://host-ip:8010/mcp"
    }
  }
}
```

Test with [MCP Inspector](https://github.com/modelcontextprotocol/inspector): `npx @modelcontextprotocol/inspector http://host-ip:8010/mcp`

---

## Network Configuration

| Mode | Config | Use Case |
|:-----|:-------|:---------|
| **Bridge** | `ports: ["8010:8010"]` | Default, isolated |
| **Host** | `network_mode: host` | Max performance (Linux) |
| **MACVLAN** | Dedicated LAN IP via `macvlan` driver | Advanced, direct LAN |

---

## Updating

### Docker Compose

```bash
docker compose pull
docker compose up -d
docker image prune -f
```

### Docker CLI

```bash
docker pull mekayelanik/gitnexus-mcp:latest
docker stop gitnexus-mcp && docker rm gitnexus-mcp
# Run your original docker run command
docker image prune -f
```

### One-Time Update with Watchtower

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once \
  gitnexus-mcp
```

---

## Troubleshooting

### Pre-Flight Checklist

- Docker Engine 23.0+, port 8010 available, latest image
- Correct DATA_DIR with repository subdirectories
- ARM devices: allow 60-120s startup time

### Common Issues

| Issue | Solution |
|:------|:---------|
| Container won't start | `docker logs gitnexus-mcp`, check port: `netstat -tulpn \| grep 8010` |
| Stays unhealthy | Normal during analysis. If persistent after startup, check logs |
| No repos analyzed | Verify mount: `ls -la /path/to/repos/` - must be subdirectories |
| Permission errors | Match PUID/PGID: `id $USER`, fix: `chown -R 1000:1000 /path/to/repos` |
| Client can't connect | Test: `curl http://localhost:8010/mcp`, check firewall |
| Wiki fails | Verify: `docker exec gitnexus-mcp env \| grep OPENAI_API_KEY` |

### Debug Info

```bash
docker --version && uname -a
docker logs gitnexus-mcp --tail 200 > logs.txt
docker inspect gitnexus-mcp > inspect.json
```

---

## Additional Resources

- [GitNexus GitHub](https://github.com/abhigyanpatwari/GitNexus) | [NPM](https://www.npmjs.com/package/gitnexus) | [MCP Inspector](https://github.com/modelcontextprotocol/inspector)
- [Docker Compose](https://docs.docker.com/compose/production/) | [Networking](https://docs.docker.com/network/) | [Security](https://docs.docker.com/engine/security/)
- [Diun](https://crazymax.dev/diun/) | [Watchtower](https://containrrr.dev/watchtower/)

---

## Buy Me a Coffee

**If you found value in this project, you can buy me a coffee to keep me inspired.**

<p align="center">
  <a href="https://07mekayel07.gumroad.com/coffee" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217" height="60">
  </a>
</p>

## Support & License

### Getting Help

- **Docker Image Issues:** [GitNexus-docker/issues](https://github.com/MekayelAnik/GitNexus-docker/issues)
- **GitNexus Upstream Issues:** [abhigyanpatwari/GitNexus/issues](https://github.com/abhigyanpatwari/GitNexus/issues) | [NPM](https://www.npmjs.com/package/gitnexus)

### Contributing

Contributions welcome: bug reports, feature suggestions, docs improvements, and beta testing.

### License

**Docker Image:** GPL v3 ([LICENSE](https://raw.githubusercontent.com/MekayelAnik/GitNexus-docker/refs/heads/main/LICENSE)). **Upstream:** PolyForm Noncommercial 1.0.0 ([LICENSE](https://github.com/abhigyanpatwari/GitNexus/blob/main/LICENSE)). Image license covers Docker packaging, scripts, and docs only. Users must comply with upstream license independently.

> Required Notice: Copyright Abhigyan Patwari (https://github.com/abhigyanpatwari/GitNexus)

### Credits

- **GitNexus** by [Abhigyan Patwari / Akon Labs](https://github.com/abhigyanpatwari/GitNexus)
- **Docker Image** by [Mohammad Mekayel Anik](https://github.com/MekayelAnik)

---

<div align="center">

[Back to Top](#gitnexus-mcp-server)

</div>
