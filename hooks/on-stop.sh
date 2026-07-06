#!/usr/bin/env bash
# Fires on every Claude Code turn end. Arms two independent timers:
#   escalate.sh (10 min)   — has the user responded at all, how much is pending.
#   quick-check.sh (2 min) — has the user ALREADY replied to something no agent
#     has engaged with yet (unacknowledged) — a narrower, faster check for the
#     "they did their part, the agent just hasn't looked" case.
# Never blocks: backgrounds both immediately so the Stop event returns fast.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || SID="unknown"
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$CWD" ] || CWD="$PWD"

nohup "$HERE/escalate.sh" "$SID" "$CWD" >/dev/null 2>&1 &
disown 2>/dev/null || true
nohup "$HERE/quick-check.sh" "$SID" "$CWD" >/dev/null 2>&1 &
disown 2>/dev/null || true
exit 0
