# Entrypoint.sh Cross-Repo Comparison Report

Generated: 2026-04-01

## Repos Analyzed (17 total)

| Repo | Lines | Tier |
|------|------:|------|
| GitNexus-docker | 727 | Tier A (most features) |
| snyk-mcp-docker | 659 | Tier A- |
| fetch-mcp-docker | 651 | Tier B (older/divergent architecture) |
| branch-thinking-mcp-docker | 616 | Tier C+ (605-group + extras) |
| redis-mcp-server-docker | 607 | Tier C+ (605-group + extras) |
| brave-search, codegraph, context7, duckduckgo, filesystem, firecrawl, knowl-graph, perplexity, seq-thinking, time | 605-606 | Tier C (standard 605-group) |
| terminal-control-mcp-docker | 250 | Tier D (minimal) |
| pylint-mcp-docker | 32 | Tier E (completely different architecture) |

---

## Structural Identity of the 605-Group

The 10 "Tier C" repos (brave-search through time) are **functionally identical** -- they differ ONLY in:
- `DEFAULT_PORT` / `DEFAULT_INTERNAL_PORT` values
- `HAPROXY_SERVER_NAME` value
- MCP server launch command string (`mcp_server_cmd`)
- Display name in echo ("Launching X MCP with protocol...")

Two "605-group" repos have **small structural divergences**:
- **branch-thinking**: +10 lines for `MCP_SERVER_ENTRY` path validation (checks `/app/dist/index.js` exists), uses `gosu` instead of `su-exec`
- **redis-mcp-server**: Significant structural shift in PUID/PGID section (creates `node` user dynamically since Python Alpine base lacks it), uses `gosu` instead of `su-exec`

---

## Feature Matrix

```
Feature                    GitNex  snyk  605grp  fetch  term   pylint
------------------------------------------------------------------
TLS/HTTPS (certs)            Y      Y      Y       -      -      -
Auto-cert generation         Y*     Y      Y       -      -      -
validate_tls_days()          -      Y      Y       -      -      -
HTTP_VERSION_MODE (h1/h2/h3) Y      Y      Y       -      -      -
QUIC/H3 support              Y      Y      Y       -      -      -
CORS validation              Y      Y      Y       Y      Y      -
API_KEY auth                 Y      Y      Y       Y      Y      -
  min/max key length check   Y      Y      Y       -      -      -
PUID/PGID                    Y      Y      Y       Y      Y      Y
generate_haproxy_config()    Y      Y      Y       Y      -      -
haproxy.cfg.template         Y      Y      Y       Y      -      -
trap shutdown handler        Y      Y      Y       -      -      -
graceful shutdown()          Y      Y      Y       -      -      -
validate_port()              Y      Y      Y       Y      Y      -
supergateway                 Y      Y      Y       Y      Y      -
healthcheck endpoint         Y      Y      Y       Y      Y      -
streamable HTTP transport    Y      Y      Y       Y      Y      -
SSE transport                Y      Y      Y       Y      Y      -
is_true() helper             Y      Y      Y       -      -      -
prepare_tls_pem()            Y      Y      Y       -      -      -
resolve_listener_protocols() Y      Y      Y       -      -      -
escape_haproxy_regex()       Y      Y      Y       -      -      -
haproxy_supports_quic()      Y      Y      Y       -      -      -
FIRST_RUN_FILE               Y      Y      Y       Y      Y      -
DATA_DIR                     Y      -      -       -      -      -
clean command                Y      -      -       -      -      -
start_web_ui()               Y      -      -       -      -      -
```

`*` GitNexus says "Auto certificate generation is not supported" in error message, but the 605-group and snyk DO have `validate_tls_days()` for auto-generated self-signed certs.

---

## Key Differences by Tier

### GitNexus (Tier A) -- 727 lines, 24 functions
**Unique features:**
- `run_gitnexus_analyze()`, `run_gitnexus_clean()`, `run_gitnexus_wiki()`, `start_web_ui()` -- app-specific lifecycle commands
- `DATA_DIR` support with directory validation
- Multi-PID `wait -n "${pids[@]}"` (handles variable number of background processes)
- **Missing**: `validate_tls_days()` -- cannot auto-generate self-signed certs (requires user-provided certs)

### snyk (Tier A-) -- 659 lines, 21 functions
**Identical core infrastructure** to 605-group but with all shared functions.
- Has `validate_tls_days()` (auto self-signed cert generation)
- No app-specific extras like GitNexus

### 605-Group (Tier C) -- 605-606 lines, 22 functions each
**The "gold standard" shared infrastructure.** All have:
- Full TLS with auto-cert generation (`validate_tls_days`)
- HTTP/1.1, HTTP/2, HTTP/3 (QUIC) mode switching
- HAProxy config generation from template with sed substitution
- CORS validation with origin allowlist
- API key auth with min/max length + regex validation
- Graceful shutdown with trap + `shutdown()` function
- `is_true()` helper for boolean env var parsing

### fetch-mcp (Tier B) -- 651 lines, 15 functions
**Older/divergent architecture.** Has unique functions not in others:
- `build_mcp_server_cmd()`, `display_config_summary()`, `generate_client_config_example()`, `validate_fetch_env()`, `validate_directory()`, `is_non_negative_int()`

**Missing from shared infrastructure (12 functions):**
- No TLS/HTTPS support at all
- No HTTP version mode / QUIC/H3
- No `is_true()` helper
- No `shutdown()` / `trap` (no graceful shutdown)
- No `prepare_tls_pem()`, `resolve_listener_protocols()`, `escape_haproxy_regex()`
- No `validate_tls_min_version()`, `validate_tls_days()`
- No min/max API key length validation

### terminal-control (Tier D) -- 250 lines, 7 functions
**Severely behind.** Missing:
- All TLS/HTTPS support
- All HTTP version mode / QUIC/H3
- No HAProxy config generation (no haproxy at all?)
- No trap/shutdown handling
- No `is_true()` helper
- No `escape_haproxy_regex()`, `prepare_tls_pem()`, etc.
- Has only basic: CORS, API_KEY (no length validation), PUID/PGID, port validation, supergateway

### pylint (Tier E) -- 32 lines
**Completely different architecture.** Python-based server, no supergateway, no HAProxy, no shared infrastructure. Only has PUID/PGID constants and a debug mode. All validation delegated to Python server.

---

## Additional Divergences Within 605-Group

| Divergence | Repos Affected | Detail |
|-----------|---------------|--------|
| `gosu` vs `su-exec` | branch-thinking, redis-srv, codegraph use `gosu`; rest use `su-exec` | Different privilege-drop binary |
| MCP_SERVER_ENTRY validation | branch-thinking only | Checks `/app/dist/index.js` exists before launch |
| Dynamic user creation | redis-srv only | Creates `node` user/group at runtime (Python Alpine base) |

---

## Repos BEHIND on Shared Infrastructure

### Critical (should be updated):
1. **fetch-mcp-docker** -- Missing TLS, HTTP mode, QUIC, graceful shutdown, `is_true()`. Appears to be an older codebase that predates the current shared infrastructure.
2. **terminal-control-mcp-docker** -- Missing TLS, HTTP mode, QUIC, HAProxy config gen, graceful shutdown. Only 250 lines; needs full rewrite to match 605-group standard.

### Minor:
3. **GitNexus-docker** -- Missing `validate_tls_days()` (no auto self-signed cert generation). This may be intentional.

### Not applicable:
4. **pylint-mcp-docker** -- Entirely different architecture (Python native). Not comparable.

---

## Recommendation

The **605-group template** (e.g., brave-search-mcp-docker) should be considered the canonical shared entrypoint. To bring all repos to parity:

1. **fetch-mcp-docker**: Rebase onto 605-group template, preserving its unique `build_mcp_server_cmd()`, `display_config_summary()`, `generate_client_config_example()`, `validate_fetch_env()`, and `validate_directory()` functions
2. **terminal-control-mcp-docker**: Rebase onto 605-group template entirely
3. **GitNexus-docker**: Consider adding `validate_tls_days()` for auto self-signed cert support, unless deliberately excluded
4. Standardize `gosu` vs `su-exec` across all repos (pick one)
