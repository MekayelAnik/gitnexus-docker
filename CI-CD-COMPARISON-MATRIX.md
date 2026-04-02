# CI/CD Comparison Matrix -- All MCP Docker Repos

Generated: 2026-04-01

## Repos Analyzed (18 total, including GitNexus-docker)

| # | Repo | Type |
|---|------|------|
| 1 | GitNexus-docker | NPM |
| 2 | branch-thinking-mcp-docker | NPM |
| 3 | brave-search-mcp-docker | NPM |
| 4 | codegraphcontext-mcp-docker | PyPI |
| 5 | context7-mcp-docker | NPM |
| 6 | db-mcp-server-docker | Legacy |
| 7 | duckduckgo-mcp-docker | NPM |
| 8 | fetch-mcp-docker | Legacy |
| 9 | filesystem-mcp-docker | NPM |
| 10 | firecrawl-mcp-docker | NPM |
| 11 | knowledge-graph-mcp-docker | NPM |
| 12 | perplexity-mcp-docker | NPM |
| 13 | pylint-mcp-docker | Legacy |
| 14 | redis-mcp-server-docker | PyPI |
| 15 | sequential-thinking-mcp-docker | NPM |
| 16 | snyk-mcp-docker | NPM |
| 17 | terminal-control-mcp-docker | Legacy |
| 18 | time-mcp-docker | NPM |

---

## 1. Workflows

| Repo | monitor-npm-releases.yml | reusable-build-versions.yml | reusable-promote-latest.yml | Other |
|------|:---:|:---:|:---:|-------|
| GitNexus-docker | Y | Y | Y | |
| branch-thinking-mcp-docker | Y | Y | Y | |
| brave-search-mcp-docker | Y | Y | Y | |
| codegraphcontext-mcp-docker | Y | Y | Y | |
| context7-mcp-docker | Y | Y | Y | |
| **db-mcp-server-docker** | **N** | **N** | **N** | docker-publish.yml |
| duckduckgo-mcp-docker | Y | Y | Y | |
| **fetch-mcp-docker** | **N** | **N** | **N** | **NO WORKFLOWS** |
| filesystem-mcp-docker | Y | Y | Y | |
| firecrawl-mcp-docker | Y | Y | Y | |
| knowledge-graph-mcp-docker | Y | Y | Y | |
| perplexity-mcp-docker | Y | Y | Y | |
| **pylint-mcp-docker** | **N** | **N** | **N** | **NO WORKFLOWS** |
| redis-mcp-server-docker | Y | Y | Y | |
| sequential-thinking-mcp-docker | Y | Y | Y | |
| snyk-mcp-docker | Y | Y | Y | |
| **terminal-control-mcp-docker** | **N** | **N** | **N** | **NO WORKFLOWS** |
| time-mcp-docker | Y | Y | Y | |

### Monitor Workflow -- Key Values

| Repo | Pipeline Name | NPM_PACKAGE | DOCKERHUB_REPO fallback |
|------|--------------|-------------|------------------------|
| GitNexus-docker | GitNexus MCP NPM Build Pipeline | gitnexus | mekayelanik/gitnexus-mcp |
| branch-thinking-mcp-docker | Branch Thinking MCP NPM Build Pipeline | branch-thinking-mcp | mekayelanik/branch-thinking-mcp |
| brave-search-mcp-docker | Brave Search MCP NPM Build Pipeline | @brave/brave-search-mcp-server | mekayelanik/brave-search-mcp |
| codegraphcontext-mcp-docker | CodeGraphContext MCP PyPI Build Pipeline | (PyPI-based, no NPM_PACKAGE) | mekayelanik/codegraphcontext-mcp |
| context7-mcp-docker | Context7 MCP NPM Build Pipeline | @upstash/context7-mcp | mekayelanik/context7-mcp |
| duckduckgo-mcp-docker | DuckDuckGo MCP NPM Build Pipeline | @oevortex/ddg_search | mekayelanik/duckduckgo-mcp |
| filesystem-mcp-docker | Filesystem MCP NPM Build Pipeline | @modelcontextprotocol/server-filesystem | mekayelanik/filesystem-mcp |
| firecrawl-mcp-docker | Firecrawl MCP NPM Build Pipeline | firecrawl-mcp | mekayelanik/firecrawl-mcp |
| knowledge-graph-mcp-docker | Knowledge Graph MCP NPM Build Pipeline | mcp-knowledge-graph | mekayelanik/knowledge-graph-mcp |
| perplexity-mcp-docker | Perplexity MCP NPM Build Pipeline | @perplexity-ai/mcp-server | mekayelanik/perplexity-mcp |
| redis-mcp-server-docker | Redis MCP PyPI Build Pipeline | (PyPI-based, no NPM_PACKAGE) | mekayelanik/redis-mcp-server |
| sequential-thinking-mcp-docker | Sequential Thinking MCP NPM Build Pipeline | @modelcontextprotocol/server-sequential-thinking | mekayelanik/sequential-thinking-mcp |
| snyk-mcp-docker | Snyk MCP NPM Build Pipeline | snyk | mekayelanik/snyk-mcp |
| time-mcp-docker | Time MCP NPM Build Pipeline | time-mcp | mekayelanik/time-mcp |

### Monitor Workflow -- Job Structure (standard template)

All 14 repos with monitor-npm-releases.yml share the same job structure:
1. **check-pipeline** -- Compare NPM/PyPI latest against stored state
2. **preflight** -- Checkout, validate workflow YAML, run preflight shell tests
3. **fetch-releases** -- Normalize dispatch inputs, collect stable versions
4. **build-versions** -- Calls reusable-build-versions.yml
5. **promote-latest** -- Calls reusable-promote-latest.yml
6. **update-state** -- Checkout state branch, write and push state

PyPI variants (codegraphcontext, redis) say "Compare PyPI latest" and "Fetch and filter PyPI releases" but otherwise identical structure.

---

## 2. GitHub Actions (.github/actions/)

Standard set (6 actions): `preflight-shell-tests`, `promote-latest`, `registry-login`, `registry-sync`, `resolve-build-profile`, `setup-build-env`

| Repo | preflight-shell-tests | promote-latest | registry-login | registry-sync | resolve-build-profile | setup-build-env |
|------|:---:|:---:|:---:|:---:|:---:|:---:|
| GitNexus-docker | Y | Y | Y | Y | Y | Y |
| branch-thinking-mcp-docker | Y | Y | Y | Y | Y | Y |
| brave-search-mcp-docker | Y | Y | Y | Y | Y | Y |
| codegraphcontext-mcp-docker | Y | Y | Y | Y | Y | Y |
| context7-mcp-docker | Y | Y | Y | Y | Y | Y |
| **db-mcp-server-docker** | **N** | **N** | Y | Y | **N** | **N** |
| duckduckgo-mcp-docker | Y | Y | Y | Y | Y | Y |
| **fetch-mcp-docker** | **N** | **N** | **N** | **N** | **N** | **N** |
| filesystem-mcp-docker | Y | Y | Y | Y | Y | Y |
| firecrawl-mcp-docker | Y | Y | Y | Y | Y | Y |
| knowledge-graph-mcp-docker | Y | Y | Y | Y | Y | Y |
| perplexity-mcp-docker | Y | Y | Y | Y | Y | Y |
| **pylint-mcp-docker** | **N** | **N** | **N** | **N** | **N** | **N** |
| redis-mcp-server-docker | Y | Y | Y | Y | Y | Y |
| sequential-thinking-mcp-docker | Y | Y | Y | Y | Y | Y |
| snyk-mcp-docker | Y | Y | Y | Y | Y | Y |
| **terminal-control-mcp-docker** | **N** | **N** | **N** | **N** | **N** | **N** |
| time-mcp-docker | Y | Y | Y | Y | Y | Y |

---

## 3. GitHub Scripts (.github/scripts/)

Standard set (9 scripts): `check-existing-tags.sh`, `fetch-releases.sh`, `lib-retry.sh`, `normalize-dispatch-inputs.sh`, `preflight-shell-tests.sh`, `registry-sync.sh`, `test-api-key-validation.sh`, `test-registry-sync.sh`, `test-runtime-behavior.sh`

| Repo | Full 9-script set | Extra scripts | Notes |
|------|:---:|------|-------|
| GitNexus-docker | Y | | |
| branch-thinking-mcp-docker | Y | | |
| brave-search-mcp-docker | Y | | |
| codegraphcontext-mcp-docker | Y | fetch-releases-pypi.sh | PyPI variant |
| context7-mcp-docker | Y | | |
| **db-mcp-server-docker** | **Partial** | | Only: check-existing-tags.sh, lib-retry.sh |
| duckduckgo-mcp-docker | Y | | |
| **fetch-mcp-docker** | **N** | | **NO SCRIPTS DIR** |
| filesystem-mcp-docker | Y | | |
| firecrawl-mcp-docker | Y | | |
| knowledge-graph-mcp-docker | Y | | |
| perplexity-mcp-docker | Y | | |
| **pylint-mcp-docker** | **N** | | **NO SCRIPTS DIR** |
| redis-mcp-server-docker | Y | fetch-releases-pypi.sh | PyPI variant |
| sequential-thinking-mcp-docker | Y | | |
| snyk-mcp-docker | Y | | |
| **terminal-control-mcp-docker** | **N** | | **NO SCRIPTS DIR** |
| time-mcp-docker | Y | | |

Note: No repo has `npm-version-filter.sh` (previously existed in GitNexus-docker, now removed).

---

## 4. .gitignore

| Repo | Has .gitignore | Notes |
|------|:---:|-------|
| GitNexus-docker | Y | Standard + `build_data`, `example/`, `.buildx-cache`, `.git` |
| branch-thinking-mcp-docker | Y | Standard + `resources/build-timestamp.txt` |
| brave-search-mcp-docker | Y | Standard |
| codegraphcontext-mcp-docker | Y | Standard + `resources/build-timestamp.txt` |
| context7-mcp-docker | Y | Standard + `build_data`, `example/`, `.buildx-cache`, `.git` |
| **db-mcp-server-docker** | **N** | **MISSING** |
| duckduckgo-mcp-docker | Y | Standard |
| fetch-mcp-docker | Y | Standard |
| filesystem-mcp-docker | Y | Standard + `resources/build-timestamp.txt` |
| firecrawl-mcp-docker | Y | Standard |
| knowledge-graph-mcp-docker | Y | Standard + `resources/build-timestamp.txt` |
| perplexity-mcp-docker | Y | Standard |
| pylint-mcp-docker | Y | **STALE: references `Dockerfile.ispyagentdvr` and `/DockerfileModifier.sh`** |
| redis-mcp-server-docker | Y | Standard + `build_data`, `example/`, `.buildx-cache`, `.git` |
| sequential-thinking-mcp-docker | Y | Standard + `resources/build-timestamp.txt` |
| snyk-mcp-docker | Y | Standard |
| terminal-control-mcp-docker | Y | **STALE: references `Dockerfile.ispyagentdvr` and `/DockerfileModifier.sh`** |
| time-mcp-docker | Y | Standard + `resources/build-timestamp.txt` |

"Standard" = `build_logs`, `resources/build_data`, `resources/build-timestamp`, `resources/tag`, `Dockerfile.<name>`, `/.vs`, `/Dockerfile.<name>`, `/Dockerfile`

---

## 5. CREDITS.md / NOTICE / LICENSE

| Repo | LICENSE | CREDITS.md | NOTICE |
|------|:---:|:---:|:---:|
| GitNexus-docker | Y | Y | N |
| branch-thinking-mcp-docker | Y | Y | N |
| brave-search-mcp-docker | Y | Y | N |
| codegraphcontext-mcp-docker | Y | Y | N |
| context7-mcp-docker | Y | Y | N |
| db-mcp-server-docker | Y | **N** | N |
| duckduckgo-mcp-docker | Y | Y | N |
| fetch-mcp-docker | Y | Y | N |
| filesystem-mcp-docker | Y | Y | N |
| firecrawl-mcp-docker | Y | Y | N |
| knowledge-graph-mcp-docker | Y | Y | N |
| perplexity-mcp-docker | Y | Y | N |
| pylint-mcp-docker | Y | Y | N |
| **redis-mcp-server-docker** | **N** | **N** | **N** |
| sequential-thinking-mcp-docker | Y | Y | N |
| snyk-mcp-docker | Y | N | Y |
| terminal-control-mcp-docker | Y | Y | N |
| time-mcp-docker | Y | Y | N |

---

## 6. CERTIFICATE_SETUP_GUIDE.md

Only 3 repos have it:
- **GitNexus-docker** -- Y
- **context7-mcp-docker** -- Y
- **snyk-mcp-docker** -- Y
- All other 15 repos -- **N**

---

## 7. docker-compose.yml (in repo root)

Only 1 repo has it:
- **snyk-mcp-docker** -- Y
- All other 17 repos -- **N**

---

## FLAGGED ISSUES

### Severely Behind (no modern CI/CD pipeline)

| Repo | Issue | Severity |
|------|-------|----------|
| **fetch-mcp-docker** | No workflows, no actions, no scripts -- entirely missing CI/CD | CRITICAL |
| **pylint-mcp-docker** | No workflows, no actions, no scripts -- entirely missing CI/CD | CRITICAL |
| **terminal-control-mcp-docker** | No workflows, no actions, no scripts -- entirely missing CI/CD | CRITICAL |
| **db-mcp-server-docker** | Has legacy `docker-publish.yml` instead of the standard 3-workflow setup; only 2 actions and 2 scripts | HIGH |

### Stale / Wrong Values

| Repo | Issue | Severity |
|------|-------|----------|
| **pylint-mcp-docker** | .gitignore references `Dockerfile.ispyagentdvr` and `/Dockerfile.ispyagentdvr-docker` -- clearly copy-pasted from iSpy project | MEDIUM |
| **terminal-control-mcp-docker** | .gitignore references `Dockerfile.ispyagentdvr` and `/DockerfileModifier.sh` -- same copy-paste issue | MEDIUM |
| **codegraphcontext-mcp-docker** | Monitor workflow says "Compare NPM latest" but is titled "PyPI Build Pipeline" -- cosmetic mismatch in step names | LOW |

### Missing Files

| Repo | Missing | Severity |
|------|---------|----------|
| **db-mcp-server-docker** | .gitignore, CREDITS.md | MEDIUM |
| **redis-mcp-server-docker** | LICENSE, CREDITS.md | HIGH |
| **snyk-mcp-docker** | CREDITS.md (has NOTICE instead -- intentional?) | LOW |
| 15 repos | CERTIFICATE_SETUP_GUIDE.md (only GitNexus, context7, snyk have it) | LOW (only needed for HTTPS/HAProxy repos) |
| 17 repos | docker-compose.yml (only snyk has it) | LOW (optional convenience file) |

### Consistency Notes

- **PyPI repos** (codegraphcontext, redis) have an extra `fetch-releases-pypi.sh` script -- expected divergence.
- **All 14 modern repos** share identical job structure in monitor-npm-releases.yml with 6 jobs.
- **All 14 modern repos** share the same 6 composite actions.
- **No repo** has `npm-version-filter.sh` (appears to have been globally removed).
- **GITHUB_REPO** is not set as an env var in any monitor workflow -- repos rely on `vars.DOCKERHUB_REPO` and `github.repository` context. No stale GITHUB_REPO references found.
