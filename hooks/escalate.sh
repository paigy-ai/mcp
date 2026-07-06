#!/usr/bin/env bash
# Armed by on-stop.sh on EVERY turn end. Sleeps 10 min, then checks whether the
# user has responded AND how much is actually pending — using a dedicated
# non-claiming endpoint (/api/pending/summary) so this never consumes
# replies/requests meant for the real agent session's own check_replies/await_reply.
#
# No content heuristic on arming: this arms on every stop, blocking or not
# (accepted tradeoff) — the urgency chosen at escalation time is what scales with
# how much is actually blocked. 0 pending = skip entirely.
set -euo pipefail

SESSION_ID="${1:?session_id required}"
CWD="${2:-unknown project}"
ARMED_AT=$(date +%s)
ACTIVITY_FILE="$HOME/.paigy/idle-escalation/activity/${SESSION_ID}"
TOKEN_FILE="$HOME/.paigy/token.json"
BACKEND_URL="${PAIGY_BACKEND_URL:-https://paigy.ai}"

sleep 600

# If the user submitted a prompt after we armed, the activity file's mtime
# will be newer than ARMED_AT — they responded, nothing to do.
if [ -f "$ACTIVITY_FILE" ]; then
  ACTIVITY_AT=$(stat -f %m "$ACTIVITY_FILE" 2>/dev/null || stat -c %Y "$ACTIVITY_FILE" 2>/dev/null || echo 0)
  if [ "$ACTIVITY_AT" -ge "$ARMED_AT" ]; then
    exit 0
  fi
fi

# No token = not paired = nothing we can do.
[ -f "$TOKEN_FILE" ] || exit 0
TOKEN=$(node -e "console.log(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).access_token)" "$TOKEN_FILE" 2>/dev/null) || exit 0
[ -n "$TOKEN" ] || exit 0

SUMMARY=$(curl -sS -X GET "$BACKEND_URL/api/pending/summary" -H "authorization: Bearer $TOKEN" 2>/dev/null) || exit 0

# Nothing actually pending (answered through another path, or wasn't blocking) — skip.
COUNT=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).count||0)}catch{console.log(0)}})" 2>/dev/null) || COUNT=0
[ "$COUNT" -gt 0 ] || exit 0

OLDEST=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).oldestCreatedAt||'')}catch{console.log('')}})" 2>/dev/null) || OLDEST=""
# Real titles of what's actually pending — the whole point of the escalation is
# telling the user WHAT needs them and WHAT decision it needs, not just "something
# is pending" (confirmed by real user feedback: a bare "N things waiting" call was
# useless without saying what).
ITEMS_JSON=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.stringify(JSON.parse(d).items||[]))}catch{console.log('[]')}})" 2>/dev/null) || ITEMS_JSON="[]"

# Urgency scales with what's actually blocked: multiple pending things, or the
# oldest one being stale a while, escalate to a call; a single fresh one gets a
# banner instead of ringing the phone outright.
URGENCY="banner"
if [ "$COUNT" -ge 2 ]; then
  URGENCY="call"
elif [ -n "$OLDEST" ]; then
  OLDEST_EPOCH=$(node -e "console.log(Math.floor(new Date(process.argv[1]).getTime()/1000))" "$OLDEST" 2>/dev/null) || OLDEST_EPOCH=0
  AGE_MIN=$(( (ARMED_AT - OLDEST_EPOCH) / 60 ))
  if [ "$AGE_MIN" -ge 20 ]; then
    URGENCY="call"
  fi
fi

PROJECT_NAME=$(basename "$CWD")
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

curl -sS -X POST "$BACKEND_URL/api/notify" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d "$(node -e '
    const [count, project, urgency, itemsJson] = [process.argv[1], process.argv[2], process.argv[3], process.argv[4]];
    const items = JSON.parse(itemsJson);
    const title = count > 1
      ? "Claude Code has " + count + " things waiting on you in " + project
      : "Claude Code needs you in " + project;
    // Each pending item description as its own chunk so the user can ask to expand it.
    const description = items.length > 0
      ? items.map(i => i.title)
      : ["Waiting on you for at least 10 minutes, but could not retrieve what it is about."];
    console.log(JSON.stringify({
      context: { title, description },
      select: "text",
      urgency,
      createdAt: process.argv[5],
    }));
  ' "$COUNT" "$PROJECT_NAME" "$URGENCY" "$ITEMS_JSON" "$NOW_ISO")" \
  >/dev/null 2>&1 || true
