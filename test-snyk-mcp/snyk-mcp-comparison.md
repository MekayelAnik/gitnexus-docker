# Snyk MCP Server Comparison: CLI MCP vs SAW-MCP

## For Python AI project security scanning via Claude Code

---

## Quick Comparison Table

| Feature | **Snyk CLI MCP** (`snyk mcp`) | **Snyk SAW-MCP** (`snyk/saw-mcp`) |
|---|---|---|
| **Purpose** | Local code/dependency/container/IaC scanning | DAST (web app) scanning via Snyk API & Web (formerly Probely) |
| **Scan Types** | SCA, SAST, Container, IaC, SBOM, AIBOM | DAST only (web application dynamic scanning) |
| **Local Code Scanning** | Yes - scans local files and dependencies directly | No - scans remote web targets via API |
| **Tool Count** | 11 tools | 51 tools |
| **Transport** | stdio or SSE (`snyk mcp -t stdio` or `snyk mcp -t sse`) | stdio (via uvx/python) |
| **Auth Required** | Snyk account (`snyk auth` - browser OAuth) | Snyk API & Web API key (`MCP_SAW_API_KEY`) from plus.probely.app |
| **Python Support** | Excellent - SCA scans pip/pipenv/poetry deps; AIBOM specifically for Python AI projects | N/A - does not scan Python code or dependencies |
| **AI-Specific** | Yes - `snyk_aibom` generates AI Bill of Materials (CycloneDX v1.6) for Python AI projects | No AI-specific features |
| **Maturity** | Production - bundled in Snyk CLI v1.1298.0+ | New (created Feb 2026) - 131 commits, 5 stars, 3 forks |
| **Installation** | `npm install -g snyk` (already in CLI) | `uvx --from git+https://github.com/snyk/saw-mcp.git saw-mcp` |
| **License** | Proprietary (Snyk CLI) | Apache 2.0 |

---

## Snyk CLI MCP - Tool Details

| Tool Name | Description |
|---|---|
| `snyk_sca_scan` | Software Composition Analysis - scans open source dependencies for known vulnerabilities |
| `snyk_code_scan` | SAST - static analysis of source code for security flaws |
| `snyk_container_scan` | Scans container images for OS package and dependency vulnerabilities |
| `snyk_iac_scan` | Analyzes Infrastructure as Code (Terraform, CloudFormation, etc.) for misconfigurations |
| `snyk_sbom_scan` | Analyzes existing SBOM files for vulnerabilities |
| `snyk_aibom` | Generates AI Bill of Materials for Python projects (CycloneDX v1.6 JSON) |
| `snyk_auth` | Authenticates user with Snyk |
| `snyk_auth_status` | Checks current authentication status |
| `snyk_trust` | Trusts a folder before scanning (security gate) |
| `snyk_version` | Displays CLI version information |
| `snyk_logout` | Logs out of current Snyk session |

### Claude Code Configuration

```json
{
  "mcpServers": {
    "SnykMCP": {
      "command": "snyk",
      "args": ["mcp", "-t", "stdio"]
    }
  }
}
```

---

## Snyk SAW-MCP (saw-mcp) - Tool Details

Tool names use `probely_*` prefix (legacy naming from Probely acquisition).

| Category | Key Tools |
|---|---|
| Targets | `probely_list_targets`, `probely_create_web_target`, `probely_get_target`, `probely_delete_target` |
| Scans | `probely_start_scan`, `probely_stop_scan`, `probely_list_scans`, `probely_get_scan` |
| Findings | `probely_list_findings`, `probely_get_finding`, `probely_update_finding`, bulk update |
| Auth Config | `probely_configure_form_login`, `probely_configure_sequence_login`, `probely_configure_2fa` |
| Sequences | `probely_create_sequence` (Playwright-based login recording) |
| Credentials | `probely_create_credential`, `probely_list_credentials` |
| API Targets | `probely_create_api_target_from_openapi`, `probely_create_api_target_from_postman` |
| Reports | Create and download scan reports |
| Generic | `probely_request` (raw API access to any endpoint) |

### Claude Code Configuration

```json
{
  "mcpServers": {
    "SAW": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/snyk/saw-mcp.git", "saw-mcp"],
      "env": {
        "MCP_SAW_API_KEY": "your-api-key"
      }
    }
  }
}
```

---

## Recommendation for Python AI Projects

### Use Snyk CLI MCP (clear winner for your use case)

**Why:**

1. **Scans local code and dependencies directly** - exactly what you need for development-time security in Claude Code
2. **SCA scanning** (`snyk_sca_scan`) - finds vulnerabilities in pip/pipenv/poetry dependencies (e.g., insecure versions of torch, transformers, langchain, etc.)
3. **SAST scanning** (`snyk_code_scan`) - finds security flaws in your Python source code (SQL injection, path traversal, hardcoded secrets, etc.)
4. **AIBOM generation** (`snyk_aibom`) - specifically designed for Python AI projects, inventories AI models, datasets, and tools in CycloneDX format
5. **No API key management** - uses browser-based OAuth via `snyk auth`; free tier available
6. **Production mature** - bundled directly in the Snyk CLI, backed by Snyk's full vulnerability database

### When to use SAW-MCP instead

Only if you need **DAST scanning** of deployed web applications (e.g., scanning your AI app's HTTP API endpoints for runtime vulnerabilities like XSS, CSRF, authentication bypass). SAW-MCP does NOT scan local code or dependencies.

### Ideal Setup: Use Both

For comprehensive coverage of a Python AI web application:
- **Snyk CLI MCP** for development-time SCA + SAST + AIBOM (local scanning)
- **SAW-MCP** for post-deployment DAST scanning of your running web app

### Quick Start

```bash
# Install Snyk CLI
npm install -g snyk

# Authenticate (opens browser)
snyk auth

# Add to Claude Code
claude mcp add-json SnykMCP '{"type":"stdio","command":"snyk","args":["mcp","-t","stdio"]}'
```

Then in Claude Code, simply ask: "Scan this Python project for vulnerabilities" and the agent will use `snyk_sca_scan` and `snyk_code_scan` automatically.
