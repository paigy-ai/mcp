#!/usr/bin/env bash
# Builds paigy.mcpb — the MCPB bundle for Smithery's "Local (MCPB Bundle)"
# publish path (Smithery has no GitHub/Docker build flow for stdio servers
# despite what older docs/blog posts describe — it just distributes a
# pre-built bundle that clients run locally, see mcpb/README.md).
#
# Vendors the ACTUAL published @paigy/mcp package + its dependencies — an
# MCPB bundle is meant to be self-contained (no network fetch at runtime),
# so this does NOT shell out to npx.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf server paigy.mcpb
mkdir -p server
(cd server && npm init -y >/dev/null && npm install @paigy/mcp@latest)

npx --yes @anthropic-ai/mcpb validate manifest.json
npx --yes @anthropic-ai/mcpb pack . paigy.mcpb

echo "Built: $(pwd)/paigy.mcpb"
echo "Publish with: smithery mcp publish mcpb/paigy.mcpb -n <namespace>/<server-id>"
