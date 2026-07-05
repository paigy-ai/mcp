#!/usr/bin/env bash
# Fires on every Claude Code turn end. Arms a 10-min idle-escalation timer —
# see escalate.sh for what happens when it wakes. Never blocks: backgrounds
# immediately so the Stop event returns fast.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || SID="unknown"
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$CWD" ] || CWD="$PWD"

nohup "$HERE/escalate.sh" "$SID" "$CWD" >/dev/null 2>&1 &
disown 2>/dev/null || true
exit 0
