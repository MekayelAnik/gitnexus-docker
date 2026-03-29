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
- **Web UI** - Built-in web interface for browsing indexed repositories
- **Wiki Generation** - AI-powered wiki generation with OpenAI, Ollama, vLLM, or any OpenAI-compatible API
- **Secure by Design** - API key auth, CORS, TLS termination (bring your own certs)
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
| `1.4.10` | Production | Specific version | Version pinning for consistency |

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
      - "8010:8010"   # MCP endpoint
      - "4747:4747"   # Web UI
    volumes:
      - /path/to/your/repos:/data:rw
    environment:
      - PORT=8010
      - INTERNAL_PORT=38011
      - WEB_UI_PORT=4747
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
      - ANALYZE_SKIP_EMBEDDINGS=true
      - ANALYZE_VERBOSE=false
      # Optional: require Bearer token auth at HAProxy layer
      # - API_KEY=replace-with-strong-secret
      # Optional: Wiki generation (requires LLM API key)
      # - WIKI_ENABLED=true
      # - OPENAI_API_KEY=sk-...
      # - WIKI_MODEL=gpt-4o
    hostname: gitnexus-mcp
    domainname: local
```

**Deploy:**
```bash
docker compose up -d
docker compose logs -f gitnexus-mcp
```

### Docker CLI

```bash
docker run -d \
  --name=gitnexus-mcp \
  --restart=unless-stopped \
  -p 8010:8010 \
  -p 4747:4747 \
  -v /path/to/your/repos:/data:rw \
  -e PORT=8010 \
  -e INTERNAL_PORT=38011 \
  -e WEB_UI_PORT=4747 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Dhaka \
  -e NODE_ENV=production \
  -e PROTOCOL=SHTTP \
  -e ENABLE_HTTPS=false \
  -e HTTP_VERSION_MODE=auto \
  -e DATA_DIR=/data \
  -e ANALYZE_SKIP_EMBEDDINGS=true \
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
      - "8010:8010"   # MCP endpoint (HAProxy)
      - "4747:4747"   # Web UI
    volumes:
      - /path/to/your/repos:/data:rw
      - /path/to/certs:/etc/haproxy/certs:ro   # TLS certificates
    environment:
      # Core
      - PORT=8010
      - INTERNAL_PORT=38011
      - WEB_UI_PORT=4747
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
```

### Full-Featured Docker CLI (GPU + Auth)

```bash
docker run -d \
  --name=gitnexus-mcp \
  --restart=unless-stopped \
  --gpus all \
  -p 8010:8010 \
  -p 4747:4747 \
  -v /path/to/your/repos:/data:rw \
  -v /path/to/certs:/etc/haproxy/certs:ro \
  -e PORT=8010 \
  -e WEB_UI_PORT=4747 \
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
      - "4747:4747"
    volumes:
      - /path/to/your/repos:/data:rw
    environment:
      - PORT=8010
      - PROTOCOL=SHTTP
      - ENABLE_HTTPS=false
      - DATA_DIR=/data
      - ANALYZE_SKIP_EMBEDDINGS=true
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
  ollama-data:
```

### Access Endpoints

| Service | Endpoint | Description |
|:--------|:---------|:------------|
| **MCP (SHTTP)** | `http://host-ip:8010/mcp` | Streamable HTTP MCP endpoint (recommended) |
| **MCP (SSE)** | `http://host-ip:8010/sse` | Server-Sent Events MCP endpoint |
| **MCP (WS)** | `ws://host-ip:8010/message` | WebSocket MCP endpoint |
| **Web UI** | `http://host-ip:4747` | GitNexus Web UI for browsing repositories |
| **Health** | `http://host-ip:8010/healthz` | Health check endpoint |

When HTTPS is enabled (`ENABLE_HTTPS=true`), use TLS endpoints:

| Service | Endpoint |
|:--------|:---------|
| **MCP (SHTTP)** | `https://host-ip:8010/mcp` |
| **MCP (SSE)** | `https://host-ip:8010/sse` |
| **MCP (WS)** | `wss://host-ip:8010/message` |

> **Security Warning:** The container defaults to HTTP (`ENABLE_HTTPS=false`) for easier local setup. Use `ENABLE_HTTPS=true` with your own certificates for production. See [CERTIFICATE_SETUP_GUIDE.md](CERTIFICATE_SETUP_GUIDE.md) for instructions.
>
> **ARM Devices:** Allow 60-120 seconds for initialization (analysis + server startup).

---

## Configuration

### Core Environment Variables

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `PORT` | `8010` | External HAProxy port for MCP endpoint |
| `INTERNAL_PORT` | `38011` | Internal supergateway port |
| `WEB_UI_PORT` | `4747` | GitNexus Web UI port |
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |
| `TZ` | `Asia/Dhaka` | Container timezone ([TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)) |
| `NODE_ENV` | `production` | Node.js environment |
| `PROTOCOL` | `SHTTP` | MCP transport: `SHTTP`, `SSE`, or `WS` |
| `API_KEY` | *(empty)* | Enables Bearer token auth (`Authorization: Bearer <API_KEY>`) |
| `CORS` | *(empty)* | Comma-separated CORS origins, supports `*` |
| `ENABLE_HTTPS` | `false` | Enables TLS termination in HAProxy (requires your own certs) |
| `TLS_CERT_PATH` | `/etc/haproxy/certs/server.crt` | TLS cert path |
| `TLS_KEY_PATH` | `/etc/haproxy/certs/server.key` | TLS private key path |
| `TLS_PEM_PATH` | `/etc/haproxy/certs/server.pem` | Combined PEM file used by HAProxy |
| `TLS_MIN_VERSION` | `TLSv1.3` | Minimum TLS protocol (`TLSv1.2` or `TLSv1.3`) |
| `HTTP_VERSION_MODE` | `auto` | `auto`, `all`, `h1`, `h2`, `h3`, `h1+h2` |
| `ENABLE_WEB_UI` | `true` | Enable/disable GitNexus Web UI |

### HTTPS Notes

- **No auto-generated certificates.** You must provide your own TLS cert and key.
- If `TLS_CERT_PATH` and `TLS_KEY_PATH` exist, they are merged into `TLS_PEM_PATH`.
- `HTTP_VERSION_MODE=h3` (or `auto`) enables HTTP/3 only when HAProxy build includes QUIC.
- See [CERTIFICATE_SETUP_GUIDE.md](CERTIFICATE_SETUP_GUIDE.md) for step-by-step instructions.

### API Key Authentication Notes

- Set `API_KEY` to enforce authentication at the reverse proxy level.
- Expected header format: `Authorization: Bearer <API_KEY>`.
- Localhost health checks remain accessible for liveness/readiness probes.

---

## GitNexus-Specific Configuration

### Repository Analysis

On startup, the container analyzes all subdirectories inside `DATA_DIR`. Mount your repositories as subdirectories of the data volume.

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `DATA_DIR` | `/data` | Root directory containing repositories to analyze |
| `ANALYZE_FORCE` | `false` | Force full re-index of all repositories |
| `ANALYZE_SKILLS` | `false` | Generate repo-specific skill files from detected communities |
| `ANALYZE_SKIP_EMBEDDINGS` | `false` | Skip embedding generation (faster startup) |
| `ANALYZE_SKIP_AGENTS_MD` | `false` | Preserve custom AGENTS.md/CLAUDE.md edits |
| `ANALYZE_EMBEDDINGS` | `false` | Enable embedding generation (slower, better search) |
| `ANALYZE_VERBOSE` | `false` | Log skipped files when parsers are unavailable |

### Cleanup Options

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `CLEAN_ON_START` | `false` | Run `gitnexus clean` before analysis |
| `CLEAN_ALL_FORCE` | `false` | Run `gitnexus clean --all --force` (deletes ALL indexes) |

### Volume Mount Structure

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

---

## Wiki Generation

GitNexus can generate AI-powered wiki documentation for your repositories. It supports both cloud providers (OpenAI, Anthropic) and local AI servers (Ollama, vLLM, llama.cpp, etc.) via the OpenAI-compatible API.

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `WIKI_ENABLED` | `false` | Enable wiki generation after analysis |
| `WIKI_MODEL` | `gpt-4o-mini` | Model to use (e.g., `gpt-4o-mini`, `gpt-4o`, `llama3`, `mistral`) |
| `WIKI_BASE_URL` | *(gitnexus default)* | API base URL for the LLM provider |
| `WIKI_FORCE` | `false` | Force full wiki regeneration |
| `OPENAI_API_KEY` | *(empty)* | API key for OpenAI or compatible providers |

### Example: OpenAI

```yaml
environment:
  - WIKI_ENABLED=true
  - OPENAI_API_KEY=sk-your-key-here
  - WIKI_MODEL=gpt-4o-mini
```

### Example: Local Ollama Server

```yaml
environment:
  - WIKI_ENABLED=true
  - WIKI_BASE_URL=http://host.docker.internal:11434/v1
  - WIKI_MODEL=llama3
  - OPENAI_API_KEY=not-needed
```

### Example: Local vLLM / llama.cpp Server

```yaml
environment:
  - WIKI_ENABLED=true
  - WIKI_BASE_URL=http://your-vllm-server:8000/v1
  - WIKI_MODEL=your-model-name
  - OPENAI_API_KEY=not-needed
```

---

## GPU Support

GitNexus uses [onnxruntime-node](https://www.npmjs.com/package/onnxruntime-node) for embedding generation via HuggingFace transformers.js. NVIDIA GPUs can significantly accelerate this process.

### Supported GPUs

| GPU | Status | Notes |
|:----|:------:|:------|
| **NVIDIA (CUDA)** | Supported | Requires NVIDIA Container Toolkit on host |
| **AMD (ROCm)** | Not supported | onnxruntime-node lacks ROCm support |
| **Intel (oneAPI)** | Not supported | onnxruntime-node lacks oneAPI support |

### Docker Compose (NVIDIA GPU)

```yaml
services:
  gitnexus-mcp:
    image: mekayelanik/gitnexus-mcp:latest
    # ... other config ...
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [compute, utility]
```

### Docker CLI (NVIDIA GPU)

```bash
docker run -d \
  --gpus all \
  --name=gitnexus-mcp \
  # ... other flags ...
  mekayelanik/gitnexus-mcp:latest
```

### Prerequisites

1. Install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) on the host
2. Verify with: `docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi`

The container automatically uses GPU when available and falls back to CPU when not. No additional environment variables needed.

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

### VS Code (Cline/Roo-Cline)

Configure in `.vscode/settings.json`:

```json
{
  "mcp.servers": {
    "gitnexus": {
      "url": "http://host-ip:8010/mcp",
      "transport": "http"
    }
  }
}
```

---

### Claude Desktop App / Claude Code

**With API_KEY:**
```
claude mcp add-json gitnexus '{"type":"http","url":"http://localhost:8010/mcp","headers":{"Authorization":"Bearer <YOUR_API_KEY>"}}'
```

**Without API_KEY:**
```
claude mcp add-json gitnexus '{"type":"http","url":"http://localhost:8010/mcp"}'
```

---

### Codex CLI

Configure in `~/.codex/config.json`:

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

---

### Codeium (Windsurf)

Configure in `.codeium/mcp_settings.json`:

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

---

### Cursor

Configure in `~/.cursor/mcp.json`:

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

---

### Testing Configuration

Verify with [MCP Inspector](https://github.com/modelcontextprotocol/inspector):

```bash
npm install -g @modelcontextprotocol/inspector
mcp-inspector http://host-ip:8010/mcp
```

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
      - "4747:4747"
```

**Benefits:** Container isolation, easy setup, works everywhere
**Access:** `http://localhost:8010/mcp` and `http://localhost:4747`

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
**Access:** `http://localhost:8010/mcp` and `http://localhost:4747`

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
**Access:** `http://192.168.1.100:8010/mcp` and `http://192.168.1.100:4747`

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
- Ports 8010 and 4747 available
- Sufficient startup time (ARM devices: 60-120s)
- Latest image
- Correct DATA_DIR with repository subdirectories

### Common Issues

#### Container Won't Start

```bash
# Check Docker version
docker --version

# Verify port availability
sudo netstat -tulpn | grep -E '8010|4747'

# Check logs
docker logs gitnexus-mcp
```

#### No Repositories Analyzed

```bash
# Verify mount structure
ls -la /path/to/your/repos/

# Each repo should be a subdirectory
# /path/to/your/repos/project-a/
# /path/to/your/repos/project-b/
```

#### Permission Errors

```bash
# Get your IDs
id $USER

# Update configuration with correct PUID/PGID
# Fix volume permissions if needed
sudo chown -R 1000:1000 /path/to/your/repos
```

#### Client Cannot Connect

```bash
# Test MCP connectivity
curl http://localhost:8010/mcp
curl http://host-ip:8010/mcp

# Test Web UI
curl http://localhost:4747

# With HTTPS
curl -k https://localhost:8010/mcp

# Check firewall
sudo ufw status

# Verify container
docker inspect gitnexus-mcp | grep IPAddress
```

#### Wiki Generation Fails

```bash
# Ensure API key is set
docker exec gitnexus-mcp env | grep OPENAI_API_KEY

# For local AI servers, verify connectivity
docker exec gitnexus-mcp curl http://host.docker.internal:11434/v1/models
```

### Debug Information

When reporting issues, include:

```bash
# System info
docker --version && uname -a

# Container logs
docker logs gitnexus-mcp --tail 200 > logs.txt

# Container config
docker inspect gitnexus-mcp > inspect.json
```

---

## Additional Resources

### Documentation
- [GitNexus Official GitHub](https://github.com/abhigyanpatwari/GitNexus)
- [GitNexus NPM Package](https://www.npmjs.com/package/gitnexus)
- [MCP Inspector](https://github.com/modelcontextprotocol/inspector)

### Docker Resources
- [Docker Compose Best Practices](https://docs.docker.com/compose/production/)
- [Docker Networking](https://docs.docker.com/network/)
- [Docker Security](https://docs.docker.com/engine/security/)

### Monitoring
- [Diun - Update Notifier](https://crazymax.dev/diun/)
- [Watchtower](https://containrrr.dev/watchtower/)

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
