#!/usr/bin/env bash
# Exercises read_paigy_token — the REAL function the hooks source, not a copy of it — against
# every shape ~/.paigy/token.json has had. Writes only to a temp dir; never touches ~/.paigy.
# Run: hooks/token-read.test.sh
set -uo pipefail
export NO_COLOR=1 FORCE_COLOR=0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The thing under test is the shipped code itself — sourcing it (rather than restating the
# read here) is the whole point: a test over a copy would pass while the hooks drifted, which
# is exactly how the 0.22.0 breakage went unnoticed.
. "$HERE/token.sh"
read_token() { read_paigy_token "$1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0

check() { # name, expected, actual
  if [ "$2" = "$3" ]; then echo "  PASS  $1"; pass=$((pass+1));
  else echo "  FAIL  $1 — expected '$2', got '$3'"; fail=$((fail+1)); fi
}

# 1. Keyed map, this agent's slot (the shape that broke it).
echo '{"mcp-agent":{"access_token":"claude-tok","name":"Claude Code"},"codex":{"access_token":"codex-tok"}}' > "$TMP/t.json"
check "keyed map -> own slot" "claude-tok" "$(read_token "$TMP/t.json")"

# 2. Same file, but running as a different agent.
check "keyed map -> honors PAIGY_AGENT" "codex-tok" "$(PAIGY_AGENT=codex read_token "$TMP/t.json")"

# 3. Legacy bare token (pre-0.22.0) — must still work.
echo '{"access_token":"legacy-tok","name":"Claude Code"}' > "$TMP/t.json"
check "legacy bare token" "legacy-tok" "$(read_token "$TMP/t.json")"

# 4. The "*" shared slot.
echo '{"*":{"access_token":"shared-tok"}}' > "$TMP/t.json"
check "shared \"*\" slot" "shared-tok" "$(read_token "$TMP/t.json")"

# 5. THE REGRESSION: a keyed map with no slot for us must yield "" — not "undefined",
#    which sailed past the hooks' [ -n "$TOKEN" ] guard and rang the API with a junk bearer.
echo '{"antigravity":{"access_token":"ag-tok"}}' > "$TMP/t.json"
out=$(read_token "$TMP/t.json")
check "no slot for us -> empty, NOT 'undefined'" "" "$out"
if [ -n "$out" ]; then echo "  FAIL  the -n guard would still pass on '$out'"; fail=$((fail+1)); else echo "  PASS  the -n guard correctly rejects it"; pass=$((pass+1)); fi

# 6. Malformed file must not explode (node exits non-zero -> hook exits 0).
echo '{ not json' > "$TMP/t.json"
check "malformed file -> empty" "" "$(read_token "$TMP/t.json")"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
