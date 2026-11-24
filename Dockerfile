# LLM Wiki (lucasastorian/llmwiki) for Railway: web app, API and MCP server in one
# service, behind Caddy (basic auth for the UI, bearer token for /mcp).
# Upstream publishes no releases or images, so we build its own docker/local recipe
# from a pinned commit. Bump LLMWIKI_COMMIT (and CHANGELOG.md) to update.
ARG LLMWIKI_COMMIT=4d887e8378237fd4042ccd268a731059b6b87f20

FROM alpine/git:v2.54.1@sha256:29cff25811f790b9f72fc266bf8009a5a911714c0e03c31c47339c50909d9aef AS src
ARG LLMWIKI_COMMIT
WORKDIR /src
RUN git init -q . \
 && git remote add origin https://github.com/lucasastorian/llmwiki.git \
 && git fetch -q --depth 1 origin "$LLMWIKI_COMMIT" \
 && git checkout -q FETCH_HEAD \
 && rm -rf .git

FROM node:22.23.5-bookworm-slim@sha256:e9f565d32859f0cbfb52125eafe8be39390f24dac302dc3cdf566e8ba3ab21ee AS web-build
WORKDIR /build/web
COPY --from=src /src/web/package.json /src/web/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY --from=src /src/web/ ./
# Test files fail Next's type check at this commit; they are not part of the app.
# CIRCLE_NODE_TOTAL caps Next's build workers (it starts one per host CPU otherwise).
RUN find src -name '*.test.ts' -delete -o -name '*.test.tsx' -delete
ENV NEXT_PUBLIC_MODE=local \
    NEXT_PUBLIC_API_URL=/api \
    NEXT_TELEMETRY_DISABLED=1 \
    CIRCLE_NODE_TOTAL=2
RUN npm run build

FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 AS caddy

FROM python:3.11.18-slim-bookworm@sha256:a83ba18aef0f865b1a4a611c2cf460fe446f2795673bbb9fe43be570439e3b39
WORKDIR /app
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    MODE=local \
    WORKSPACE_PATH=/data/llmwiki \
    MALLOC_ARENA_MAX=2 \
    NEXT_TELEMETRY_DISABLED=1

# opendataloader-pdf (the local PDF parser) shells out to java.
RUN apt-get update \
 && apt-get install -y --no-install-recommends default-jre-headless \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir uv==0.13.9
COPY --from=src /src/api/requirements.lock ./api/requirements.lock
RUN uv pip install --system --require-hashes -r api/requirements.lock
COPY --from=src /src/mcp/requirements.lock ./mcp/requirements.lock
RUN uv venv /opt/mcp && uv pip install --python /opt/mcp/bin/python --require-hashes -r mcp/requirements.lock

COPY --from=web-build /usr/local/bin/node /usr/local/bin/node
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY --from=src /src/api/ ./api/
# Make the document-processing concurrency configurable (upstream: 4 parallel jobs, each
# PDF one JVM); the start script sets 1 below 900 MB so small plans don't OOM-kill extractions.
RUN sed -i 's/^PROCESS_CONCURRENCY = 4$/PROCESS_CONCURRENCY = max(1, int(os.environ.get("LLMWIKI_PROCESS_CONCURRENCY", "4")))/' api/domain/local_processor.py \
 && grep -q 'LLMWIKI_PROCESS_CONCURRENCY' api/domain/local_processor.py
COPY --from=src /src/mcp/ ./mcp/
COPY --from=src /src/shared/ ./shared/
COPY --from=src /src/llmwiki ./llmwiki
COPY --from=web-build /build/web/.next/standalone /app/web
COPY --from=web-build /build/web/.next/static /app/web/.next/static
COPY --from=web-build /build/web/public /app/web/public
COPY rootfs/ /
RUN chmod +x /usr/local/bin/llmwiki-start

EXPOSE 8080
CMD ["/usr/local/bin/llmwiki-start"]
