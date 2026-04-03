# GitNexus MCP Server
### Multi-Architecture Docker Image for Distributed Deployment

<div align="left">

[![Docker Pulls](https://img.shields.io/docker/pulls/mekayelanik/gitnexus-mcp.svg?style=flat-square)](https://hub.docker.com/r/mekayelanik/gitnexus-mcp)
[![Docker Stars](https://img.shields.io/docker/stars/mekayelanik/gitnexus-mcp.svg?style=flat-square)](https://hub.docker.com/r/mekayelanik/gitnexus-mcp)
[![License](https://img.shields.io/badge/license-GPL-blue.svg?style=flat-square)](https://raw.githubusercontent.com/MekayelAnik/GitNexus-docker/refs/heads/main/LICENSE)

**[Upstream GitHub](https://github.com/abhigyanpatwari/GitNexus)** | **[NPM Package](https://www.npmjs.com/package/gitnexus)** | **[Docker Hub](https://hub.docker.com/r/mekayelanik/gitnexus-mcp)**

</div>

---

> **Disclaimer:** This is an **unofficial** Docker image. GitNexus is developed and maintained by [Abhigyan Patwari / Akon Labs](https://github.com/abhigyanpatwari/GitNexus). The upstream project is licensed under the [PolyForm Noncommercial License 1.0.0](https://github.com/abhigyanpatwari/GitNexus/blob/main/LICENSE). This Docker packaging is independently maintained by [Mohammad Mekayel Anik](https://github.com/MekayelAnik) under the GPL v3 license.

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

**Your support encourages me to keep creating/supporting my open-source projects.** If you found value in this project, you can buy me a coffee to keep me inspired.

<p align="center">
<a href="https://07mekayel07.gumroad.com/coffee" target="_blank">
<img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217" height="60">
</a>
</p>

## Overview

[GitNexus](https://github.com/abhigyanpatwari/GitNexus) is a powerful code intelligence MCP server that builds a knowledge graph of your codebase using LadybugDB (embedded graph database), indexes repositories with Tree-sitter parsing, generates embeddings, creates wiki documentation, and provides AI-powered code search and navigation. This Docker image packages GitNexus for distributed/remote deployment with HAProxy as a reverse proxy, supporting multiple transport protocols, API key authentication, CORS, and HTTP/1.1, HTTP/2, and HTTP/3 (QUIC).

### Key Features

- **Multi-Architecture Support** - Native support for x86-64 and ARM64
- **Multiple Transport Protocols** - Streamable HTTP, SSE, and WebSocket support (selectable via env var)
- **Repository Auto-Analysis** - Automatically indexes all repositories in the data directory on startup
- **Self-Hosted Web UI** - Built-in web interface served on the same port as MCP (no external Vercel dependency)
- **Wiki Generation** - AI-powered wiki generation with OpenAI, Ollama, vLLM, or any OpenAI-compatible API
- **Secure by Design** - API key auth (case-insensitive Bearer), CORS, TLS termination, security headers (X-Content-Type-Options, X-Frame-Options, HSTS)
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
| `1.5.3` | Production | Specific version | Version pinning for consistency |

### System Requirements

- **Docker Engine:** 23.0+
- **RAM:** Minimum 1GB (2GB+ recommended for embedding generation)
- **CPU:** Single core sufficient (multi-core recommended for analysis)
- **GPU:** Optional NVIDIA GPU for accelerated embedding generation (see [GPU Support](#gpu-support))
- **Storage:** Depends on repository sizes being indexed

> **CRITICAL:** Do NOT expose this container directly to the internet without proper security measures (reverse proxy, SSL/TLS, authentication, firewall rules).

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
      - gitnexus-registry:/home/node/.gitnexus   # Persist index registry across recreations
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
```

**Deploy:**
```bash
docker compose up -d
docker compose logs -f gitnexus-mcp
```

### Docker CLI

```bash
docker volume create gitnexus-registry
docker run -d \
  --name=gitnexus-mcp \
  --restart=unless-stopped \
  -p 8010:8010 \
  -v /path/to/your/repos:/data:rw \
  -v gitnexus-registry:/home/node/.gitnexus \
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
      - /path/to/certs:/etc/haproxy/certs:ro   # TLS certificates
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
    # NVIDIA GPU (optional - remove if no GPU)
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [compute, utility]
    hostname: gitnexus-mcp
    domainname: local

volumes:
  gitnexus-registry:
    driver: local
```

### Full-Featured Docker CLI (GPU + Auth)

```bash
docker volume create gitnexus-registry
docker run -d \
  --name=gitnexus-mcp \
  --restart=unless-stopped \
  --gpus all \
  -p 8010:8010 \
  -v /path/to/your/repos:/data:rw \
  -v gitnexus-registry:/home/node/.gitnexus \
  -v /path/to/certs:/etc/haproxy/certs:ro \
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
  ollama-data:
```

### Access Endpoints

All services are accessible on a **single port** (default `8010`) via HAProxy routing:

| Service | Endpoint | Description |
|:--------|:---------|:------------|
| **Web UI** | `http://host-ip:8010/` | Self-hosted GitNexus web interface for browsing repositories |
| **MCP (SHTTP)** | `http://host-ip:8010/mcp` | Streamable HTTP MCP endpoint (recommended) |
| **MCP (SSE)** | `http://host-ip:8010/sse` | Server-Sent Events MCP endpoint |
| **MCP (WS)** | `ws://host-ip:8010/message` | WebSocket MCP endpoint |
| **REST API** | `http://host-ip:8010/api/*` | GitNexus REST API (repos, search, graph, etc.) |
| **Health** | `http://host-ip:8010/healthz` | Health check endpoint |

When HTTPS is enabled (`ENABLE_HTTPS=true`), use TLS endpoints:

| Service | Endpoint |
|:--------|:---------|
| **Web UI** | `https://host-ip:8010/` |
| **MCP (SHTTP)** | `https://host-ip:8010/mcp` |
| **MCP (SSE)** | `https://host-ip:8010/sse` |
| **MCP (WS)** | `wss://host-ip:8010/message` |

> **Single-Port Architecture:** HAProxy routes all traffic on port 8010:
> - `/mcp`, `/healthz` → Supergateway (MCP protocol)
> - `/api/*` → GitNexus API server
> - `/*` → Self-hosted web UI (static files)
>
> The web UI auto-discovers the API at the same origin — no CORS configuration or separate port needed. Set `ENABLE_WEB_UI=false` for MCP-only mode.

> **Smart Healthcheck:** The container uses an analysis-aware healthcheck script that understands the multi-phase startup. During `gitnexus analyze` and `gitnexus wiki` phases, it reports healthy so the container is not marked unhealthy during long analysis runs. Once services are running, it checks the real `/healthz` endpoint.

> **Security Warning:** The container defaults to HTTP (`ENABLE_HTTPS=false`) for easier local setup. Use `ENABLE_HTTPS=true` with your own certificates for production. See [CERTIFICATE_SETUP_GUIDE.md](CERTIFICATE_SETUP_GUIDE.md) for instructions.
>
> **ARM Devices:** Allow 60-120 seconds for initialization (analysis + server startup).

---

## Configuration

### Volumes

| Mount | Container Path | Purpose |
|:------|:---------------|:--------|
| Repository data | `/data` | Root directory containing repositories to analyze (required) |
| Index registry | `/home/node/.gitnexus` | Global registry mapping repos to their indexes. **Persist this** with a named volume to avoid re-registration on container recreation |
| TLS certificates | `/etc/haproxy/certs` | TLS cert/key files (only needed with `ENABLE_HTTPS=true`) |

> **Index storage:** GitNexus stores the actual index inside `.gitnexus/` within each repository directory. Since repos are mounted from the host, indexes automatically persist. The registry at `/home/node/.gitnexus` only stores pointers — but without it, GitNexus must re-discover and re-register all repos on startup.

### Complete Environment Variables Reference

#### Networking & Ports

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `PORT` | `8010` | `1`-`65535` | External HAProxy port (MCP + Web UI + API, all on one port) |
| `PROTOCOL` | `SHTTP` | `SHTTP`, `SSE`, `WS` | MCP transport protocol |

> **Internal ports** (`INTERNAL_PORT`, `WEB_UI_PORT`) default to `38011` and `4747` respectively. These are used internally by HAProxy and should only be changed if you have port conflicts inside the container. The static file server port (`39012`) is a fixed constant and not configurable.

#### Security & TLS

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `API_KEY` | *(empty)* | 5-256 printable chars | Enables Bearer token auth (`Authorization: Bearer <key>`) |
| `CORS` | *(empty)* | `*`, comma-separated origins | CORS allowed origins (e.g. `https://example.com,http://localhost:3000`) |
| `ENABLE_HTTPS` | `false` | `true`, `false` | Enables TLS termination in HAProxy (requires your own certs) |
| `TLS_CERT_PATH` | `/etc/haproxy/certs/server.crt` | Any valid path | Path to TLS certificate file |
| `TLS_KEY_PATH` | `/etc/haproxy/certs/server.key` | Any valid path | Path to TLS private key file |
| `TLS_PEM_PATH` | `/etc/haproxy/certs/server.pem` | Any valid path | Combined PEM file (auto-generated from cert+key) |
| `TLS_MIN_VERSION` | `TLSv1.3` | `TLSv1.2`, `TLSv1.3` | Minimum TLS protocol version |
| `HTTP_VERSION_MODE` | `auto` | `auto`, `all`, `h1`, `h2`, `h3`, `h1+h2` | HTTP protocol versions to enable |

#### Container & System

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `PUID` | `1000` | Any positive integer | User ID for file permissions |
| `PGID` | `1000` | Any positive integer | Group ID for file permissions |
| `TZ` | `Asia/Dhaka` | [TZ database names](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | Container timezone |
| `NODE_ENV` | `production` | `production`, `development` | Node.js environment |
| `ENABLE_WEB_UI` | `true` | `true`, `false` | Enable/disable GitNexus Web UI |

#### Repository Analysis

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `DATA_DIR` | `/data` | Any valid path | Root directory containing repositories to analyze |
| `ANALYZE_FORCE` | `false` | `true`, `false` | Force full re-index of all repositories (once per container lifecycle) |
| `ANALYZE_SKILLS` | `false` | `true`, `false` | Generate repo-specific skill files from detected communities |
| `ANALYZE_EMBEDDINGS` | `false` | `true`, `false` | Enable embedding generation for semantic search (slower, better search) |
| `ANALYZE_SKIP_GIT` | `false` | `true`, `false` | Index folders without requiring a `.git` directory |
| `ANALYZE_VERBOSE` | `false` | `true`, `false` | Log skipped files when parsers are unavailable |

#### Cleanup

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `CLEAN_ON_START` | `false` | `true`, `false` | Run `gitnexus clean` before analysis (once per container lifecycle) |
| `CLEAN_ALL_FORCE` | `false` | `true`, `false` | Run `gitnexus clean --all --force` (deletes ALL indexes, once per container lifecycle) |

#### Wiki Generation

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `WIKI_ENABLED` | `false` | `true`, `false` | Enable wiki generation after analysis |
| `WIKI_MODEL` | `gpt-4o-mini` | Any model name | LLM model (e.g. `gpt-4o-mini`, `gpt-4o`, `llama3`, `mistral`) |
| `WIKI_BASE_URL` | *(OpenAI default)* | Any URL | API base URL for LLM provider (e.g. `http://ollama:11434/v1`) |
| `WIKI_FORCE` | `false` | `true`, `false` | Force full wiki regeneration (once per container lifecycle) |
| `OPENAI_API_KEY` | *(empty)* | Any string | API key for OpenAI or compatible providers |

> **Boolean values:** `true`, `1`, `yes`, `on` are all accepted as truthy. Everything else is falsy.

> **Once per container lifecycle:** `CLEAN_ON_START`, `CLEAN_ALL_FORCE`, `ANALYZE_FORCE`, and `WIKI_FORCE` run only once after the container is created. They are skipped on subsequent restarts (e.g., crash recovery, `docker restart`). To re-trigger, recreate the container (`docker compose down && docker compose up -d`).

#### One-Shot Operations

For ad-hoc operations without setting env vars, use `docker exec`:

```bash
docker exec gitnexus-mcp gitnexus clean                # Clean current repo index
docker exec gitnexus-mcp gitnexus clean --all --force   # Delete ALL indexes
docker exec gitnexus-mcp gitnexus analyze --force       # Force full re-index
docker exec gitnexus-mcp gitnexus wiki --force          # Force wiki regeneration
```

### HTTPS Notes

- **No auto-generated certificates.** You must provide your own TLS cert and key.
- If `TLS_CERT_PATH` and `TLS_KEY_PATH` exist, they are merged into `TLS_PEM_PATH`.
- `HTTP_VERSION_MODE=h3` (or `auto`) enables HTTP/3 only when HAProxy build includes QUIC.
- See [CERTIFICATE_SETUP_GUIDE.md](CERTIFICATE_SETUP_GUIDE.md) for step-by-step instructions.

### API Key Authentication Notes

- Set `API_KEY` to enforce authentication at the reverse proxy level.
- Expected header format: `Authorization: Bearer <API_KEY>` (case-insensitive: `bearer`, `BEARER`, etc. all work).
- API keys may contain any printable characters including regex special characters (`.*+?$` etc.).
- Localhost health checks (`/healthz`) remain accessible without authentication for liveness/readiness probes.
- CORS preflight (OPTIONS) requests bypass authentication as required by the CORS specification.

### Security Headers

The following security headers are automatically added to all responses via HAProxy:

| Header | Value | Condition |
|:-------|:------|:----------|
| `X-Content-Type-Options` | `nosniff` | Always |
| `X-Frame-Options` | `DENY` | Always |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | HTTPS only |

---

## GitNexus-Specific Configuration

### Volume Mount Structure

On startup, the container analyzes all subdirectories inside `DATA_DIR`. Mount your repositories as subdirectories of the data volume.

```
/data/                       # DATA_DIR root
├── my-project-1/           # Repository 1 (auto-analyzed)
│   ├── .git/
│   └── src/
├── my-project-2/           # Repository 2 (auto-analyzed)
│   ├── .git/
│   └── lib/
└── another-repo/           # Repository 3 (auto-analyzed)
    ├── .git/
    └── ...
```

> **Tip:** Set `ANALYZE_SKIP_GIT=true` to index folders that don't have a `.git` directory (e.g., extracted archives or copied source trees).

---

## Wiki Generation

GitNexus can generate AI-powered wiki documentation for your repositories. It supports both cloud providers (OpenAI, Anthropic) and local AI servers (Ollama, vLLM, llama.cpp, etc.) via the OpenAI-compatible API. See the [Wiki Generation variables](#wiki-generation) in the table above.

| Provider | `WIKI_BASE_URL` | `WIKI_MODEL` | `OPENAI_API_KEY` |
|:---------|:---------------|:-------------|:-----------------|
| OpenAI | *(default)* | `gpt-4o-mini` | `sk-your-key` |
| Ollama | `http://host.docker.internal:11434/v1` | `llama3` | `not-needed` |
| vLLM/llama.cpp | `http://your-server:8000/v1` | `your-model` | `not-needed` |

---

## GPU Support

GitNexus uses onnxruntime-node for embedding generation. **NVIDIA GPUs** are supported for acceleration (AMD/Intel not supported by onnxruntime-node).

**Prerequisites:** Install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html), verify with `docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi`.

**Compose:** Add `deploy.resources.reservations.devices` (see Full-Featured example above).
**CLI:** Add `--gpus all` flag.

The container auto-detects GPU and falls back to CPU when unavailable.

---

## MCP Client Configuration

### Transport Support

| Client | SHTTP | SSE | WebSocket | Recommended |
|:-------|:-----:|:---:|:---------:|:------------|
| **VS Code (Cline/Roo-Cline)** | Yes | Yes | No | SHTTP |
| **Claude Desktop** | Yes | Yes | Experimental | SHTTP |
| **Claude CLI** | Yes | Yes | Experimental | SHTTP |
| **Codex CLI** | Yes | Yes | Experimental | SHTTP |
| **Codeium (Windsurf)** | Yes | Yes | Experimental | SHTTP |
| **Cursor** | Yes | Yes | Experimental | SHTTP |

---

### Claude Code / Claude Desktop

```bash
# With API_KEY
claude mcp add-json gitnexus '{"type":"http","url":"http://host-ip:8010/mcp","headers":{"Authorization":"Bearer <KEY>"}}'
# Without API_KEY
claude mcp add-json gitnexus '{"type":"http","url":"http://host-ip:8010/mcp"}'
```

### VS Code / Codex / Cursor / Windsurf

All use the same JSON format. Configure in the respective config file:
- **VS Code**: `.vscode/settings.json` (key: `mcp.servers`)
- **Codex**: `~/.codex/config.json` (key: `mcpServers`)
- **Cursor**: `~/.cursor/mcp.json` (key: `mcpServers`)
- **Windsurf**: `.codeium/mcp_settings.json` (key: `mcpServers`)

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

### Comparison

| Network Mode | Complexity | Performance | Use Case |
|:-------------|:----------:|:-----------:|:---------|
| **Bridge** | Easy | Good | Default, isolated |
| **Host** | Moderate | Excellent | Direct host access |
| **MACVLAN** | Advanced | Excellent | Dedicated IP |

---

### Bridge Network (Default)

```yaml
services:
  gitnexus-mcp:
    image: mekayelanik/gitnexus-mcp:latest
    ports:
      - "8010:8010"
```

**Benefits:** Container isolation, easy setup, works everywhere
**Access:** `http://localhost:8010` (Web UI), `http://localhost:8010/mcp` (MCP)

---

### Host Network (Linux Only)

```yaml
services:
  gitnexus-mcp:
    image: mekayelanik/gitnexus-mcp:latest
    network_mode: host
```

**Benefits:** Maximum performance, no NAT overhead, no port mapping needed
**Considerations:** Linux only, shares host network namespace
**Access:** `http://localhost:8010` (Web UI), `http://localhost:8010/mcp` (MCP)

---

### MACVLAN Network (Advanced)

```yaml
services:
  gitnexus-mcp:
    image: mekayelanik/gitnexus-mcp:latest
    mac_address: "AB:BC:CD:DE:EF:01"
    networks:
      macvlan-net:
        ipv4_address: 192.168.1.100

networks:
  macvlan-net:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1
```

**Benefits:** Dedicated IP, direct LAN access
**Considerations:** Linux only, requires additional setup
**Access:** `http://192.168.1.100:8010` (Web UI), `http://192.168.1.100:8010/mcp` (MCP)

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

- Docker Engine 23.0+
- Port 8010 available
- Sufficient startup time (ARM devices: 60-120s)
- Latest image
- Correct DATA_DIR with repository subdirectories

### Common Issues

| Issue | Solution |
|:------|:---------|
| Container won't start | `docker logs gitnexus-mcp`, check port conflicts: `sudo netstat -tulpn \| grep 8010` |
| Container stays unhealthy | This should not happen during analysis. The smart healthcheck tolerates long `analyze`/`wiki` phases. If unhealthy persists after startup completes, check `docker logs gitnexus-mcp` for errors |
| No repos analyzed | Verify mount: `ls -la /path/to/repos/` - each repo must be a subdirectory |
| Permission errors | Match PUID/PGID to host: `id $USER`, fix with `sudo chown -R 1000:1000 /path/to/repos` |
| Client can't connect | Test: `curl http://localhost:8010/mcp`, check firewall: `sudo ufw status` |
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

**Your support encourages me to keep creating/supporting my open-source projects.** If you found value in this project, you can buy me a coffee to keep me inspired.

<p align="center">
  <a href="https://07mekayel07.gumroad.com/coffee" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217" height="60">
  </a>
</p>

## Support & License

### Getting Help

**Docker Image Issues:**
- GitHub: [GitNexus-docker/issues](https://github.com/MekayelAnik/GitNexus-docker/issues)

**GitNexus Upstream Issues:**
- GitHub: [abhigyanpatwari/GitNexus/issues](https://github.com/abhigyanpatwari/GitNexus/issues)
- NPM: [npmjs.com/package/gitnexus](https://www.npmjs.com/package/gitnexus)

### Contributing

We welcome contributions:
1. Report bugs via GitHub Issues
2. Suggest features
3. Improve documentation
4. Test beta releases

### License

**Docker Image:** GPL v3 License. See [LICENSE](https://raw.githubusercontent.com/MekayelAnik/GitNexus-docker/refs/heads/main/LICENSE) for details.

**Upstream GitNexus:** PolyForm Noncommercial License 1.0.0. See [upstream LICENSE](https://github.com/abhigyanpatwari/GitNexus/blob/main/LICENSE).

This Docker image license applies only to the Docker packaging, scripts, and documentation. Users must independently comply with the upstream GitNexus license terms.

### Credits

- **GitNexus** by [Abhigyan Patwari / Akon Labs](https://github.com/abhigyanpatwari/GitNexus) - The upstream code intelligence MCP server
- **Docker Image** by [Mohammad Mekayel Anik](https://github.com/MekayelAnik) - Docker packaging and CI/CD

---

<div align="center">

[Back to Top](#gitnexus-mcp-server)

</div>
