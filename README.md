[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/llm-wiki-1?utm_medium=integration&utm_source=button&utm_campaign=llmwiki)

# LLM Wiki on Railway

LLM Wiki is an open-source, AI-maintained personal wiki, based on Andrej Karpathy's LLM wiki idea. You upload papers, notes, PDFs and Office files, then connect Claude, Codex or any MCP client, and the AI writes interlinked wiki pages with footnote citations back to your sources and keeps them current.

## About Hosting LLM Wiki

This template runs LLM Wiki's single-workspace server as one Railway service, built from our GitHub repo at a pinned upstream commit. It contains the Next.js web app, the FastAPI API with the PDF extractor, and the MCP server, behind a small Caddy front. Your files, wiki pages and the SQLite index sit on one volume at `/data`, so they survive redeploys and restarts. Upstream's local mode has no login, so the template locks it: the web app and API need a generated username and password, and the MCP endpoint needs a generated token. There is no database to run and no API key to enter, because the AI runs in your own MCP client.

## Common Use Cases

* A personal research wiki that Claude keeps up to date from the papers and notes you upload
* A shared memory for AI coding and writing agents (Claude Code, Codex, Cursor) over remote MCP
* A nightly Claude routine that reads new sources and folds them into linked, cited wiki pages

## Dependencies for LLM Wiki Hosting

* One Railway service built from `aalfath/llmwiki-railway-template` (web app, API, MCP server and Caddy)
* One Railway volume at `/data` for your files, wiki pages and index
* An MCP client with its own model access (Claude, Claude Code, Codex, Cursor or similar)

### Deployment Dependencies

* LLM Wiki source: https://github.com/lucasastorian/llmwiki (built at commit 4d887e83, 2026-11-09)
* Template repo, Dockerfile and changelog: https://github.com/aalfath/llmwiki-railway-template
* Model Context Protocol: https://modelcontextprotocol.io

### Implementation Details

**After deploy.** Open the service's Variables tab and copy `LLMWIKI_PASSWORD`. Open the public URL and sign in as `admin` with that password. Then open `https://YOUR-DOMAIN/connect`: it shows your MCP URL and the token.

**Connect Claude.** In claude.ai, add a custom connector with the URL `https://YOUR-DOMAIN/mcp/YOUR-MCP-TOKEN`. In Claude Code:

```
claude mcp add --transport http llmwiki https://YOUR-DOMAIN/mcp --header "Authorization: Bearer YOUR-MCP-TOKEN"
```

Then ask Claude to read the guide and build pages from your uploaded sources. Anyone with the MCP token can read and change the wiki, so keep it secret. To revoke it, change `MCP_TOKEN` and redeploy.

**Services and resources.** One service with three processes: the web app, the API (with a Java PDF extractor) and the MCP server, plus Caddy on `PORT`. The health check is `/healthz`. It runs on Railway's Free plan at 0.5 GB RAM and 1 vCPU (a 14-page PDF peaked at about 385 MB in our test). For very large PDFs, give the service 1 GB.

**Optional.** Set `MISTRAL_API_KEY` for better OCR of complex PDFs. Word and PowerPoint files need LibreOffice, which this image leaves out to stay small, so convert them to PDF first. Uploads are limited to 100 MB per file.

**Updates.** Railway shows "update available" when we bump the pinned upstream commit in the template repo. Read `CHANGELOG.md` there, then apply the update from your service. Your data on `/data` is kept, and database migrations run on start.

## Variables

| Variable | Default | What it does |
|---|---|---|
| `LLMWIKI_PASSWORD` | generated, 24 characters | Password for the web app and API (basic auth) |
| `LLMWIKI_USERNAME` | `admin` | Username for the web app and API |
| `MCP_TOKEN` | generated, 40 characters | Token for the `/mcp` endpoint (bearer header or `/mcp/<token>` URL) |
| `PORT` | `8080` | Port Caddy listens on (Railway routes the public domain to it) |

Optional, add them yourself: `MISTRAL_API_KEY` (better PDF OCR).

## Repo layout

* `Dockerfile`: fetches `lucasastorian/llmwiki` at a pinned commit and builds upstream's `docker/local` recipe on digest-pinned base images (`node:22.23.5-bookworm-slim`, `python:3.11.18-slim-bookworm`, `caddy:2.11.9-alpine`, `alpine/git:v2.54.1`).
* `rootfs/usr/local/bin/llmwiki-start`: first-boot workspace setup, migrations, memory and CPU caps read from the cgroup, and a supervisor that exits non-zero when any process stops, so Railway restarts the service.
* `rootfs/etc/caddy/Caddyfile`: basic auth, the MCP token check, `/connect`, `/healthz`, and the loopback Host and Origin rewrites that upstream's local mode requires.

## How updates reach deployers

Railway sends an "update available" notice to everyone who deployed the template when `main` of this repo changes. Each change is listed in [CHANGELOG.md](CHANGELOG.md), breaking changes first.

## Why Deploy LLM Wiki on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying LLM Wiki on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
