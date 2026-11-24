# Changelog

## 2026-11-24: first release

- LLM Wiki at upstream commit `4d887e8378237fd4042ccd268a731059b6b87f20` (2026-11-09; upstream publishes no releases or images).
- One service: web app, API, MCP server and Caddy; data on a `/data` volume.
- Generated `LLMWIKI_PASSWORD` (basic auth for the web app and API) and `MCP_TOKEN` (MCP endpoint).
- Base images: `node:22.23.5-bookworm-slim`, `python:3.11.18-slim-bookworm`, `caddy:2.11.9-alpine`, `alpine/git:v2.54.1`, all pinned by digest.
