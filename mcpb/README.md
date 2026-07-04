# MCPB bundle (for Smithery)

Smithery's current publish model (verified 2026-07, their own docs at
smithery.ai/docs/build/publish) only has two paths:

- **URL** — bring-your-own-hosting, requires Streamable HTTP transport. Not
  us; Paigy only ships as a stdio process.
- **Local (MCPB Bundle)** — for stdio servers. Smithery just distributes a
  pre-built `.mcpb` bundle that clients download and run locally; it does
  **not** build/host anything from a Dockerfile or GitHub repo (older
  blog posts and search results describing a GitHub-connect + Docker build
  flow are describing a since-removed version of the platform).

## Build

```
./build.sh
```

Vendors the real published `@paigy/mcp` package (not an `npx` shim — an MCPB
bundle is meant to be self-contained, no network fetch at runtime) into
`server/node_modules/`, then packs `manifest.json` + `icon.png` + `server/`
into `paigy.mcpb` via the official `@anthropic-ai/mcpb` CLI.

Verified locally (2026-07-03): extracted a packed bundle fresh, ran its entry
point directly with `node`, got a valid MCP `initialize` response and all 9
tools from `tools/list`.

## Publish

```
smithery mcp publish mcpb/paigy.mcpb -n <namespace>/<server-id>
```

Needs an authenticated `smithery` CLI session — this is a manual step, not
automated in CI, since bundle version bumps should be deliberate (`@paigy/mcp`
version is hardcoded in `manifest.json`, kept in sync by hand when it's worth
a fresh Smithery listing update, not on every npm patch release).
