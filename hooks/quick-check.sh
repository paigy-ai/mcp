#!/usr/bin/env bash
# Armed by on-stop.sh alongside escalate.sh, on EVERY turn end — but wakes much
# sooner (2 min vs 10) and checks a narrower thing: did the user already reply/
# request something that no agent has engaged with yet (unacknowledged)? That's
# different from "the user hasn't answered at all" (escalate.sh's job) — an
# unacknowledged reply means they already did their part; if the agent's session
# has genuinely stopped, nothing else will notice unless told to reopen it.
#
# This does NOT replace escalate.sh's 10-min check — both fire from every stop;
# if the same items are still unacknowledged at 10 min, escalate.sh's own
# fallback covers them too. A repeated nudge for something genuinely still
# unaddressed is expected, not a bug.
set -euo pipefail

SESSION_ID="${1:?session_id required}"
CWD="${2:-unknown project}"
ARMED_AT=$(date +%s)
ACTIVITY_FILE="$HOME/.paigy/idle-escalation/activity/${SESSION_ID}"
TOKEN_FILE="$HOME/.paigy/token.json"
BACKEND_URL="${PAIGY_BACKEND_URL:-https://paigy.ai}"

sleep 120

if [ -f "$ACTIVITY_FILE" ]; then
  ACTIVITY_AT=$(stat -f %m "$ACTIVITY_FILE" 2>/dev/null || stat -c %Y "$ACTIVITY_FILE" 2>/dev/null || echo 0)
  if [ "$ACTIVITY_AT" -ge "$ARMED_AT" ]; then
    exit 0
  fi
fi

[ -f "$TOKEN_FILE" ] || exit 0
TOKEN=$(node -e "console.log(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).access_token)" "$TOKEN_FILE" 2>/dev/null) || exit 0
[ -n "$TOKEN" ] || exit 0

SUMMARY=$(curl -sS -X GET "$BACKEND_URL/api/pending/summary" -H "authorization: Bearer $TOKEN" 2>/dev/null) || exit 0
UNACK=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).unacknowledged||0)}catch{console.log(0)}})" 2>/dev/null) || UNACK=0
[ "$UNACK" -gt 0 ] || exit 0

UNACK_ITEMS_JSON=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.stringify(JSON.parse(d).unacknowledgedItems||[]))}catch{console.log('[]')}})" 2>/dev/null) || UNACK_ITEMS_JSON="[]"
PROJECT_NAME=$(basename "$CWD")
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

curl -sS -X POST "$BACKEND_URL/api/notify" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d "$(node -e '
    const [project, unackItemsJson, nowIso] = process.argv.slice(1);
    const unackItems = JSON.parse(unackItemsJson);
    const titles = unackItems.map((i) => i.title);

    const title = titles.length === 1
      ? titles[0]
      : titles.length > 1
        ? titles[0] + " (+" + (titles.length - 1) + " more)"
        : "You replied in " + project + ", but nothing has picked it up yet";

    const description = titles.length > 1 ? titles.slice() : [];
    description.push("Reopen the session to pick this up — nothing else will after 2 minutes like this.");

    console.log(JSON.stringify({ context: { title, description }, select: "text", urgency: "banner", createdAt: nowIso }));
  ' "$PROJECT_NAME" "$UNACK_ITEMS_JSON" "$NOW_ISO")" \
  >/dev/null 2>&1 || true
