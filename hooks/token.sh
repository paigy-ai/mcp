#!/usr/bin/env bash
# Shared token read, sourced by escalate.sh and quick-check.sh and exercised directly by
# token-read.test.sh. It lives here because it USED to live in both hooks separately: when
# @paigy/mcp 0.22.0 re-shaped ~/.paigy/token.json, both copies silently broke and nobody
# noticed until a user asked why Claude Code had gone quiet. One copy, one test.

# Echo THIS agent's Paigy access token from the given token.json path, or "" if there
# isn't one. Usage: TOKEN=$(read_paigy_token "$TOKEN_FILE") || exit 0
#
# token.json holds ONE SLOT PER SESSION, keyed by AGENT_NAME — the SDK's single
# derivation: PAIGY_AGENT if set, else `session:<id>` off the http.ts SESSION_ID chain
# (CLAUDE_CODE_SESSION_ID / CODEX_THREAD_ID / a per-workspace cwd hash). We ASK the SDK
# for that slot (`paigy-slot`) instead of hardcoding a default here: a baked-in
# 'mcp-agent' drifts from the real slot the instant the chain changes and silently reads
# the wrong identity — the very splinter the one-derivation rule exists to prevent. Reads
# every shape the file has had: a bare token (pre-0.22.0), our slot, then "*" (pre-keying).
#
# Echoes "" — never the string "undefined" — when there's nothing for us. That matters:
# `console.log(undefined)` prints a NON-EMPTY string, which sails straight past a
# `[ -n "$TOKEN" ]` guard and rings the API with `Bearer undefined`. That's precisely how
# the 0.22.0 breakage hid: the guard that existed to catch "not paired" never fired.
# THIS session's slot, from the ONE derivation. Its own function so the test can override
# it deterministically instead of spawning npx (and so there is still exactly one place the
# slot comes from). An explicit PAIGY_AGENT short-circuits the spawn — paigy-slot would only
# echo it back.
paigy_slot() { npx -y -p @paigy/mcp@latest paigy-slot 2>/dev/null; }

read_paigy_token() {
  local slot="${PAIGY_AGENT:-$(paigy_slot)}"
  node -e "
    const f = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
    const slot = process.argv[2] || '';
    console.log(f.access_token ?? (slot && f[slot]?.access_token) ?? f['*']?.access_token ?? '');
  " "$1" "$slot" 2>/dev/null
}
