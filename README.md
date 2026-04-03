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

**If you found value in this project, you can buy me a coffee to keep me inspired.**

<p align="center">
<a href="https://07mekayel07.gumroad.com/coffee" target="_blank">
<img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217" height="60">
</a>
</p>

## Overview

[GitNexus](https://github.com/abhigyanpatwari/GitNexus) is a code intelligence MCP server that builds a knowledge graph of your codebase using LadybugDB, indexes repositories with Tree-sitter parsing, generates embeddings, creates wiki documentation, and provides AI-powered code search. This image packages GitNexus for distributed deployment with HAProxy, supporting multiple transports, API key auth, CORS, and HTTP/1.1, HTTP/2, HTTP/3 (QUIC).

### Key Features

- **Multi-Architecture Support** - Native x86-64 and ARM64 support
- **Multiple Transport Protocols** - Streamable HTTP, SSE, and WebSocket (selectable via env var)
- **Repository Auto-Analysis** - Automatically indexes all repositories in the data directory on startup
- **Self-Hosted Web UI** - Built-in web interface served on the same port as MCP
- **Wiki Generation** - AI-powered wiki with OpenAI, Ollama, vLLM, or any OpenAI-compatible API
- **Secure by Design** - API key auth (case-insensitive Bearer), CORS, TLS termination, security headers
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
- **RAM:** 1GB min (2GB+ recommended for embeddings)
- **CPU:** Single core sufficient (multi-core recommended)
- **GPU:** Optional NVIDIA GPU for accelerated embeddings (see [GPU Support](#gpu-support))
- **Storage:** Depends on repository sizes

> **CRITICAL:** Do NOT expose this container directly to the internet without proper security (reverse proxy, SSL/TLS, auth, firewall).

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

All services are accessible on a **single port** (default `8010`) via HAProxy:

| Service | Endpoint | Description |
|:--------|:---------|:------------|
| **Web UI** | `http://host-ip:8010/` | GitNexus web interface |
| **MCP (SHTTP)** | `http://host-ip:8010/mcp` | Streamable HTTP (recommended) |
| **MCP (SSE)** | `http://host-ip:8010/sse` | Server-Sent Events |
| **MCP (WS)** | `ws://host-ip:8010/message` | WebSocket |
| **REST API** | `http://host-ip:8010/api/*` | REST API (repos, search, graph) |
| **Health** | `http://host-ip:8010/healthz` | Health check |

With `ENABLE_HTTPS=true`, use TLS endpoints:

| Service | Endpoint |
|:--------|:---------|
| **Web UI** | `https://host-ip:8010/` |
| **MCP (SHTTP)** | `https://host-ip:8010/mcp` |
| **MCP (SSE)** | `https://host-ip:8010/sse` |
| **MCP (WS)** | `wss://host-ip:8010/message` |

> **Single-Port Architecture:** HAProxy routes all traffic on port 8010: `/mcp`, `/healthz` to Supergateway; `/api/*` to GitNexus API; `/*` to the web UI. The web UI auto-discovers the API at the same origin. Set `ENABLE_WEB_UI=false` for MCP-only mode.

> **Smart Healthcheck:** During `gitnexus analyze` and `gitnexus wiki` phases, the healthcheck reports healthy so the container is not marked unhealthy during long runs. Once services start, it checks the real `/healthz` endpoint.

> **Security Warning:** Defaults to HTTP for local setup. Use `ENABLE_HTTPS=true` with your own certs for production. See [CERTIFICATE_SETUP_GUIDE.md](CERTIFICATE_SETUP_GUIDE.md).
> **ARM Devices:** Allow 60-120s for initialization.

---

## Configuration

### Volumes

| Mount | Container Path | Purpose |
|:------|:---------------|:--------|
| Repository data | `/data` | Root directory containing repositories to analyze (required) |
| Index registry | `/home/node/.gitnexus` | Registry mapping repos to indexes. **Persist** with a named volume to avoid re-registration on recreation |
| TLS certificates | `/etc/haproxy/certs` | TLS cert/key files (only with `ENABLE_HTTPS=true`) |

> **Index storage:** Actual indexes live inside `.gitnexus/` within each repo directory and persist via the host mount. The registry at `/home/node/.gitnexus` only stores pointers -- without it, GitNexus must re-discover all repos on startup.

### Complete Environment Variables Reference

#### Networking & Ports

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `PORT` | `8010` | `1`-`65535` | External HAProxy port (MCP + Web UI + API) |
| `PROTOCOL` | `SHTTP` | `SHTTP`, `SSE`, `WS` | MCP transport protocol |

> **Internal ports** (`INTERNAL_PORT=38011`, `WEB_UI_PORT=4747`) are used by HAProxy and should only change if you have port conflicts inside the container. The static file server port (`39012`) is fixed.

#### Security & TLS

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `API_KEY` | *(empty)* | 5-256 printable chars | Bearer token auth (`Authorization: Bearer <key>`) |
| `CORS` | *(empty)* | `*`, comma-separated origins | CORS allowed origins (e.g. `https://example.com`) |
| `ENABLE_HTTPS` | `false` | `true`, `false` | TLS termination in HAProxy (requires your own certs) |
| `TLS_CERT_PATH` | `/etc/haproxy/certs/server.crt` | Any valid path | TLS certificate file |
| `TLS_KEY_PATH` | `/etc/haproxy/certs/server.key` | Any valid path | TLS private key file |
| `TLS_PEM_PATH` | `/etc/haproxy/certs/server.pem` | Any valid path | Combined PEM (auto-generated from cert+key) |
| `TLS_MIN_VERSION` | `TLSv1.3` | `TLSv1.2`, `TLSv1.3` | Minimum TLS version |
| `HTTP_VERSION_MODE` | `auto` | `auto`, `all`, `h1`, `h2`, `h3`, `h1+h2` | HTTP versions to enable |

#### Container & System

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `PUID` | `1000` | Any positive integer | User ID for permissions |
| `PGID` | `1000` | Any positive integer | Group ID for permissions |
| `TZ` | `Asia/Dhaka` | [TZ database names](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | Timezone |
| `NODE_ENV` | `production` | `production`, `development` | Node.js environment |
| `ENABLE_WEB_UI` | `true` | `true`, `false` | Enable/disable Web UI |

#### Repository Analysis

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `DATA_DIR` | `/data` | Any valid path | Root directory containing repos to analyze |
| `ANALYZE_FORCE` | `false` | `true`, `false` | Force full re-index (once per container lifecycle) |
| `ANALYZE_SKILLS` | `false` | `true`, `false` | Generate skill files from detected communities |
| `ANALYZE_EMBEDDINGS` | `false` | `true`, `false` | Enable embeddings for semantic search (slower, better) |
| `ANALYZE_SKIP_GIT` | `false` | `true`, `false` | Index folders without `.git` directory |
| `ANALYZE_VERBOSE` | `false` | `true`, `false` | Log skipped files when parsers unavailable |

#### Cleanup

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `CLEAN_ON_START` | `false` | `true`, `false` | Run `gitnexus clean` before analysis (once per lifecycle) |
| `CLEAN_ALL_FORCE` | `false` | `true`, `false` | Run `gitnexus clean --all --force` (once per lifecycle) |

#### Wiki Generation

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `WIKI_ENABLED` | `false` | `true`, `false` | Enable wiki generation after analysis |
| `WIKI_MODEL` | `gpt-4o-mini` | Any model name | LLM model (e.g. `gpt-4o-mini`, `llama3`, `mistral`) |
| `WIKI_BASE_URL` | *(OpenAI default)* | Any URL | LLM API base URL (e.g. `http://ollama:11434/v1`) |
| `WIKI_FORCE` | `false` | `true`, `false` | Force wiki regeneration (once per lifecycle) |
| `OPENAI_API_KEY` | *(empty)* | Any string | API key for OpenAI or compatible providers |

> **Boolean values:** `true`, `1`, `yes`, `on` are all accepted as truthy. Everything else is falsy.

> **Once per lifecycle:** `CLEAN_ON_START`, `CLEAN_ALL_FORCE`, `ANALYZE_FORCE`, and `WIKI_FORCE` run only once after creation, skipped on restarts. To re-trigger, recreate the container (`docker compose down && docker compose up -d`).

#### One-Shot Operations (via `docker exec`)

```bash
docker exec gitnexus-mcp gitnexus clean                # Clean current repo index
docker exec gitnexus-mcp gitnexus clean --all --force   # Delete ALL indexes
docker exec gitnexus-mcp gitnexus analyze --force       # Force full re-index
docker exec gitnexus-mcp gitnexus wiki --force          # Force wiki regeneration
```

### HTTPS Notes

- You must provide your own TLS cert and key (no auto-generation).
- `TLS_CERT_PATH` + `TLS_KEY_PATH` are merged into `TLS_PEM_PATH` automatically.
- `HTTP_VERSION_MODE=h3` (or `auto`) enables HTTP/3 only when HAProxy includes QUIC.
- See [CERTIFICATE_SETUP_GUIDE.md](CERTIFICATE_SETUP_GUIDE.md) for setup instructions.

### API Key Authentication Notes

- Set `API_KEY` to enforce auth at the reverse proxy level.
- Header: `Authorization: Bearer <API_KEY>` (case-insensitive).
- Keys may contain any printable characters including regex special chars.
- `/healthz` and CORS preflight (OPTIONS) bypass authentication.

### Security Headers

HAProxy automatically adds these headers to all responses:

| Header | Value | Condition |
|:-------|:------|:----------|
| `X-Content-Type-Options` | `nosniff` | Always |
| `X-Frame-Options` | `DENY` | Always |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | HTTPS only |

---

## GitNexus-Specific Configuration

### Volume Mount Structure

The container analyzes all subdirectories inside `DATA_DIR` on startup. Mount your repositories as subdirectories.

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

GitNexus can generate AI-powered wiki documentation for your repositories. It supports cloud (OpenAI, Anthropic) and local (Ollama, vLLM, llama.cpp) providers via the OpenAI-compatible API.

| Provider | `WIKI_BASE_URL` | `WIKI_MODEL` | `OPENAI_API_KEY` |
|:---------|:---------------|:-------------|:-----------------|
| OpenAI | *(default)* | `gpt-4o-mini` | `sk-your-key` |
| Ollama | `http://host.docker.internal:11434/v1` | `llama3` | `not-needed` |
| vLLM/llama.cpp | `http://your-server:8000/v1` | `your-model` | `not-needed` |

---

## GPU Support

GitNexus uses onnxruntime-node for embeddings. **NVIDIA GPUs** supported (AMD/Intel not supported). Install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html), verify with `docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi`. Use `deploy.resources.reservations.devices` in Compose or `--gpus all` in CLI. Auto-falls back to CPU.

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

All use the same JSON format in their respective config files: VS Code (`.vscode/settings.json`, key `mcp.servers`), Codex (`~/.codex/config.json`), Cursor (`~/.cursor/mcp.json`), Windsurf (`.codeium/mcp_settings.json`) -- all use key `mcpServers`.

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

| Network Mode | Complexity | Performance | Use Case |
|:-------------|:----------:|:-----------:|:---------|
| **Bridge** | Easy | Good | Default, isolated |
| **Host** | Moderate | Excellent | Direct host access |
| **MACVLAN** | Advanced | Excellent | Dedicated IP |

### Bridge Network (Default)

```yaml
services:
  gitnexus-mcp:
    image: mekayelanik/gitnexus-mcp:latest
    ports:
      - "8010:8010"
```

**Benefits:** Container isolation, easy setup, works everywhere.
**Access:** `http://localhost:8010` (Web UI + MCP)

### Host Network (Linux Only)

```yaml
services:
  gitnexus-mcp:
    image: mekayelanik/gitnexus-mcp:latest
    network_mode: host
```

**Benefits:** Maximum performance, no NAT overhead. Linux only, shares host network namespace.
**Access:** `http://localhost:8010` (Web UI + MCP)

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

**Benefits:** Dedicated IP, direct LAN access. Linux only, requires additional setup.
**Access:** `http://192.168.1.100:8010` (Web UI + MCP)

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
| Container won't start | `docker logs gitnexus-mcp`, check port: `sudo netstat -tulpn \| grep 8010` |
| Stays unhealthy | Smart healthcheck tolerates long analysis. If persistent after startup, check logs |
| No repos analyzed | Verify mount: `ls -la /path/to/repos/` - repos must be subdirectories |
| Permission errors | Match PUID/PGID: `id $USER`, fix: `sudo chown -R 1000:1000 /path/to/repos` |
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

Contributions welcome: bug reports via GitHub Issues, feature suggestions, documentation improvements, and beta testing.

### License

**Docker Image:** GPL v3 ([LICENSE](https://raw.githubusercontent.com/MekayelAnik/GitNexus-docker/refs/heads/main/LICENSE)). **Upstream:** PolyForm Noncommercial 1.0.0 ([LICENSE](https://github.com/abhigyanpatwari/GitNexus/blob/main/LICENSE)). Image license covers only Docker packaging, scripts, and docs. Users must independently comply with upstream license terms.

### Credits

- **GitNexus** by [Abhigyan Patwari / Akon Labs](https://github.com/abhigyanpatwari/GitNexus)
- **Docker Image** by [Mohammad Mekayel Anik](https://github.com/MekayelAnik)

---

<div align="center">

[Back to Top](#gitnexus-mcp-server)

</div>
