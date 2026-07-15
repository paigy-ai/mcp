#!/usr/bin/env bash
# Exercises the exact token read now used by escalate.sh / quick-check.sh against every
# shape ~/.paigy/token.json has had. Writes only to a temp dir — never touches ~/.paigy.
set -uo pipefail
export NO_COLOR=1 FORCE_COLOR=0
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0

# The read under test — kept byte-identical to the hooks.
read_token() {
  node -e "
    const f = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
    const agent = process.env.PAIGY_AGENT || 'mcp-agent';
    console.log(f.access_token ?? f[agent]?.access_token ?? f['*']?.access_token ?? '');
  " "$1" 2>/dev/null
}

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
