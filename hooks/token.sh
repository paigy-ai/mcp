#!/usr/bin/env bash
# Shared token read, sourced by escalate.sh and quick-check.sh and exercised directly by
# token-read.test.sh. It lives here because it USED to live in both hooks separately: when
# @paigy/mcp 0.22.0 re-shaped ~/.paigy/token.json, both copies silently broke and nobody
# noticed until a user asked why Claude Code had gone quiet. One copy, one test.

# Echo THIS agent's Paigy access token from the given token.json path, or "" if there
# isn't one. Usage: TOKEN=$(read_paigy_token "$TOKEN_FILE") || exit 0
#
# token.json holds ONE SLOT PER AGENT keyed by PAIGY_AGENT (>= 0.22.0), so pairing one
# agent can't clobber another's. Reads every shape the file has ever had: a bare token
# (pre-0.22.0), our own slot, then "*" (the pre-keying shared slot).
#
# Echoes "" — never the string "undefined" — when there's nothing for us. That matters:
# `console.log(undefined)` prints a NON-EMPTY string, which sails straight past a
# `[ -n "$TOKEN" ]` guard and rings the API with `Bearer undefined`. That's precisely how
# the 0.22.0 breakage hid: the guard that existed to catch "not paired" never fired.
read_paigy_token() {
  node -e "
    const f = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
    const agent = process.env.PAIGY_AGENT || 'mcp-agent';
    console.log(f.access_token ?? f[agent]?.access_token ?? f['*']?.access_token ?? '');
  " "$1" 2>/dev/null
}
