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
# THE VERSION THE MANIFEST NAMES, not `@latest`. The release runs this seconds after publishing
# @paigy/mcp, and the registry serves the old `latest` for a while after a publish — so the
# bundle vendored the PREVIOUS version, the release's check refused it ("bundle vendored X,
# expected Y"), and 0.40.9, 0.40.10 and 0.40.11 all shipped to npm with no bundle behind them.
# An exact version that is not served yet fails outright rather than resolving to the old one,
# so wait for it: the same backoff the release uses for its own registry check.
VERSION=$(node -p "require('./manifest.json').version")
(cd server && npm init -y >/dev/null)
delay=2
for attempt in 1 2 3 4 5 6; do
  (cd server && npm install --prefer-online "@paigy/mcp@$VERSION") && break
  [ "$attempt" = 6 ] && { echo "✗ @paigy/mcp@$VERSION is still not installable from the registry" >&2; exit 1; }
  echo "… @paigy/mcp@$VERSION not installable yet (attempt $attempt), retrying in ${delay}s" >&2
  sleep "$delay"; delay=$((delay * 2))
done

npx --yes @anthropic-ai/mcpb validate manifest.json
npx --yes @anthropic-ai/mcpb pack . paigy.mcpb

echo "Built: $(pwd)/paigy.mcpb"
echo "Publish with: smithery mcp publish mcpb/paigy.mcpb -n <namespace>/<server-id>"
