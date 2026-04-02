# CLAUDE.md - GitNexus-docker

## Project Context

- **What**: Unofficial multi-arch Docker image for GitNexus MCP Server
- **Upstream**: github.com/abhigyanpatwari/GitNexus (PolyForm Noncommercial License)
- **Image**: `mekayelanik/gitnexus-mcp` on Docker Hub
- **Stack**: Node.js, HAProxy (QUIC/H3), Debian Trixie slim
- **Key files**: `DockerfileModifier.sh` (generates Dockerfile), `resources/entrypoint.sh`, `resources/haproxy.cfg.template`
- **Maintainer**: Mohammad Mekayel Anik

---

## Mandatory Rules

1. **Every conversation MUST use MCP tools** for research or verification. Never rely solely on internal knowledge for technical decisions.
2. **Free tools first.** Use paid tools only when free tools fail or produce clearly insufficient results.
3. **context-mode for large output.** Any command producing >20 lines MUST use `ctx_execute` or `ctx_batch_execute`, never raw Bash.
4. **Never call any `jina-free` tool.** All endpoints return 401 Unauthorized (broken config).
5. **Never use `exa-paid`.** Results are identical to `exa-free` — save money.
6. **Perplexity is expensive.** Use ONLY after all cheaper alternatives fail, or when deep reasoning/research is explicitly requested.
7. **Batch operations.** Use `ctx_batch_execute` instead of multiple sequential Bash/tool calls.
8. **Use `github-mcp` tools** for GitHub operations, not `gh` CLI.
9. **Use `ctx_fetch_and_index`** instead of WebFetch for URL content.
10. **Use `docfork`** as first choice for library/framework documentation.

---

## Cost Tiers

```
TIER 0 - FREE (always try first):
  context-mode       -- command execution, indexing, search
  open-web-search    -- web search (Brave), URL fetching, GitHub READMEs
  exa-free           -- web search, code search, deep research, crawling
  docfork            -- library/framework documentation
  github-mcp         -- full GitHub API (issues, PRs, code search, releases)
  branch-thinking    -- complex problem decomposition
  time               -- date/time calculations

TIER 1 - PAID/CHEAP (when free is insufficient):
  tavily             -- fast ranked search, site mapping, extraction
  firecrawl          -- JS-rendered pages, structured extraction, site crawling
  jina-paid          -- URL reading, parallel fetches, academic search

TIER 2 - PAID/EXPENSIVE (last resort, high value only):
  perplexity_ask     -- cheapest perplexity option, AI-synthesized answers
  perplexity_reason  -- step-by-step logic (moderate cost)
  perplexity_research -- deep multi-source investigation (most expensive)

BROKEN - NEVER USE:
  jina-free          -- all endpoints return 401
  exa-paid           -- identical to exa-free, wastes money
```

---

## Decision Trees

### Web Search

```
1. open-web-search > search          (free, Brave backend)
2. exa-free > web_search_exa         (free, semantic search)
3. tavily > tavily_search            (paid/cheap, relevance-scored)
4. perplexity > perplexity_ask       (paid/expensive, ONLY if synthesis needed)
```

### Read a URL / Webpage

```
1. open-web-search > fetchWebContent     (free, static pages)
2. firecrawl > firecrawl_scrape          (paid, JS-rendered / blocked sites)
3. jina-paid > read_url                  (paid, clean markdown extraction)
4. For multiple URLs: jina-paid > parallel_read_url
```

### Library / Framework Documentation

```
1. docfork > search_docs + fetch_doc     (free, purpose-built, versioned)
2. tavily > tavily_skill                 (paid, API doc search with context)
3. Fallback: open-web-search > fetchWebContent on docs URL
```

### Code Examples / Programming Questions

```
1. exa-free > get_code_context_exa       (free, code-focused search)
2. docfork > search_docs                 (free, if it's about a known library)
3. tavily > tavily_search                (paid, broader web)
4. perplexity > perplexity_ask           (paid/expensive, complex synthesis only)
```

### GitHub Operations (Issues, PRs, Releases, Code Search)

```
1. github-mcp tools                      (free, 44 tools, full API)
   Never use `gh` CLI when github-mcp is available.
```

### GitHub README

```
1. open-web-search > fetchGithubReadme   (free, purpose-built)
```

### Deep Research / Multi-Source Synthesis

```
1. exa-free > deep_researcher_start + deep_researcher_check  (free)
2. tavily > tavily_research              (paid/cheap)
3. perplexity > perplexity_research      (paid/EXPENSIVE, last resort)
```

### Structured Data Extraction from Websites

```
1. firecrawl > firecrawl_extract         (paid, JSON schema support)
2. firecrawl > firecrawl_scrape          (paid, with jsonOptions.schema)
```

### Site Discovery / Mapping

```
1. firecrawl > firecrawl_map             (paid, discover all URLs on a site)
2. tavily > tavily_map                   (paid, site structure with depth control)
```

### Academic Papers

```
1. jina-paid > search_arxiv              (paid, arXiv focused)
2. exa-free > web_search_exa             (free, broader academic)
3. perplexity > perplexity_reason        (paid/expensive, for analysis)
```

### Running Commands with Large Output

```
1. ctx_batch_execute                     (multiple commands + auto-search)
2. ctx_execute                           (single command, any language)
3. ctx_execute_file                      (process large files without loading)
   NEVER use raw Bash for output >20 lines.
```

### Remember / Recall Across Sessions

```
1. knowledge-graph-* > aim_memory_store / aim_memory_search
2. Claude's built-in memory system (MEMORY.md)
```

---

## Provider Rules

### context-mode (FREE) -- Context Window Protection

- **Primary tool**: `ctx_batch_execute` -- runs multiple commands + searches in ONE call
- **Follow-ups**: `ctx_search` -- search previously indexed content
- **Large files**: `ctx_execute_file` -- processes files without loading to context
- **URL fetching**: `ctx_fetch_and_index` -- fetch + index + searchable (replaces WebFetch)
- **Indexing**: `ctx_index` -- index docs/knowledge for later search
- Always use instead of Bash for commands producing >20 lines

### open-web-search (FREE) -- Web Search & Fetching

- `search` -- first-choice web search (Brave engine, multi-engine capable)
- `fetchGithubReadme` -- first choice for any GitHub repo README
- `fetchWebContent` -- first choice for reading any URL (static pages)
- `fetchCsdnArticle` / `fetchJuejinArticle` / `fetchLinuxDoArticle` -- only for content on those specific platforms

### exa-free (FREE) -- Semantic Search & Code

- `web_search_exa` -- semantic web search (describe the ideal page, not keywords)
- `get_code_context_exa` -- code-specific search (API usage, library examples)
- `crawling_exa` -- extract full page content from known URLs (batch capable)
- `deep_researcher_start` + `deep_researcher_check` -- free multi-source research agent
- Never use exa-paid (identical results)

### docfork (FREE) -- Library Documentation

- Two-step workflow: `search_docs` (find) then `fetch_doc` (read full page)
- Use exact `owner/repo` format for library param (e.g., `vercel/next.js`)
- First choice for any library/framework/API documentation question

### github-mcp (FREE) -- GitHub API

- 44 tools covering: repos, issues, PRs, code search, releases, branches, tags, file contents
- Use `search_code` for finding code patterns across GitHub
- Use `list_pull_requests` / `pull_request_read` for PR reviews
- Use `create_pull_request` for PR creation
- Prefer over `gh` CLI in all cases

### branch-thinking (FREE) -- Problem Decomposition

- Use `branch-thinking` when working through complex multi-step problems
- Free, no reason not to use it for architectural decisions

### time (FREE) -- Date/Time Utilities

- `current_time`, `convert_time`, `relative_time`, `get_timestamp`, `days_in_month`, `get_week_year`

### firecrawl (PAID/CHEAP) -- Advanced Web Scraping

- `firecrawl_scrape` -- single URL, JS rendering, fastest paid option
- `firecrawl_crawl` + `firecrawl_check_crawl_status` -- multi-page (async, poll for results)
- `firecrawl_map` -- discover all URLs on a site before scraping
- `firecrawl_extract` -- structured data with JSON schema + LLM
- `firecrawl_search` -- web search when URL is unknown
- `firecrawl_agent` + `firecrawl_agent_status` -- autonomous research (expensive, async)
- `firecrawl_browser_*` -- browser automation (create/execute/delete/list)
- Use ONLY when free tools fail (JS-rendered content, anti-bot, structured extraction)

### tavily (PAID/CHEAP) -- Fast Search & Extraction

- `tavily_search` -- ranked web search with relevance scores (basic/advanced/fast depth)
- `tavily_extract` -- pull content from known URLs (supports tables, LinkedIn)
- `tavily_crawl` -- bulk extraction from related pages
- `tavily_map` -- discover site structure (depth/breadth control)
- `tavily_research` -- multi-source research agent (rate limited: 20 req/min)
- `tavily_skill` -- API/library documentation search with project context

### jina-paid (PAID/CHEAP) -- URL Reading & Academic Search

- `read_url` -- clean markdown from any URL (good quality)
- `parallel_read_url` -- batch URL reading (up to 5 URLs)
- `search_web` -- Google-backed web search
- `search_arxiv` -- arXiv paper search
- `search_images` -- image search
- `sort_by_relevance` -- rerank results by query relevance
- `classify_text` -- text classification with custom labels

### perplexity (PAID/EXPENSIVE) -- AI-Powered Research

**Cost hierarchy (cheapest to most expensive):**
1. `perplexity_search` -- simple ranked results, no AI synthesis
2. `perplexity_ask` -- AI-synthesized answer (Sonar Pro, cheapest AI option)
3. `perplexity_reason` -- step-by-step reasoning (Sonar Reasoning Pro)
4. `perplexity_research` -- deep multi-source investigation (Sonar Deep Research, 30+ sec)

**Rules:**
- NEVER use for simple web lookups -- use Brave/exa-free instead
- NEVER use `perplexity_research` without trying `exa-free > deep_researcher` and `tavily_research` first
- If you must use perplexity, start with `perplexity_ask` (cheapest)
- Only escalate to `perplexity_reason` for logic/math/analysis
- Only use `perplexity_research` when explicitly requested or when cheaper research agents produce garbage
- When using `perplexity_ask`, set `search_context_size: "low"` unless broad context is needed

---

## Anti-Patterns

- **DO NOT** use Bash for commands producing >20 lines. Use `ctx_execute` or `ctx_batch_execute`.
- **DO NOT** use `exa-paid`. Use `exa-free` (identical results).
- **DO NOT** call any `jina-free` tool (all broken, 401 errors).
- **DO NOT** use `perplexity_search` for simple lookups. Use Brave or exa-free.
- **DO NOT** use `perplexity_research` without trying free/cheap research tools first.
- **DO NOT** use WebFetch. Use `ctx_fetch_and_index` instead.
- **DO NOT** dump raw large output into context window. Always use context-mode.
- **DO NOT** use `gh` CLI when `github-mcp` tools are available.
- **DO NOT** make multiple sequential tool calls when `ctx_batch_execute` can batch them.
- **DO NOT** use `firecrawl_agent` for simple page reads. Use `firecrawl_scrape`.
- **DO NOT** skip tool usage. Every conversation must verify facts with MCP tools.

---

## Workflow Examples

### Investigating a Docker build issue
```
1. ctx_batch_execute  -- run docker build, capture logs, auto-index
2. ctx_search         -- search indexed logs for error patterns
3. exa-free > get_code_context_exa  -- find similar issues/solutions
4. docfork > search_docs  -- check official Docker docs
```

### Researching a new dependency
```
1. open-web-search > fetchGithubReadme  -- read the repo README
2. docfork > search_docs  -- find official docs
3. exa-free > web_search_exa  -- find blog posts/tutorials
4. Only if complex: tavily > tavily_research
```

### Updating CI/CD pipeline
```
1. github-mcp > list_pull_requests  -- check recent PRs
2. github-mcp > get_file_contents  -- read workflow files
3. ctx_execute  -- validate YAML/config changes
4. docfork > search_docs  -- check GitHub Actions docs
```
