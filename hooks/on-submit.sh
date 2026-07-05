#!/usr/bin/env bash
# Fires when the user submits a new prompt — marks this session as "responded"
# so any armed escalate.sh timer for it cancels instead of firing.
set -euo pipefail
ACTIVITY_DIR="$HOME/.paigy/idle-escalation/activity"
mkdir -p "$ACTIVITY_DIR"

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || SID="unknown"

touch "$ACTIVITY_DIR/$SID"
exit 0
