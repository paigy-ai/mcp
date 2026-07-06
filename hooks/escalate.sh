#!/usr/bin/env bash
# Armed by on-stop.sh on EVERY turn end. Sleeps 10 min, then checks whether the
# user has responded AND how much is actually pending — using dedicated
# non-claiming endpoints so this never consumes replies/requests meant for the
# real agent session's own check_replies/await_reply.
#
# No content heuristic on arming: this arms on every stop, blocking or not
# (accepted tradeoff). 0 pending = skip entirely.
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
COUNT=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).count||0)}catch{console.log(0)}})" 2>/dev/null) || COUNT=0
UNACK=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).unacknowledged||0)}catch{console.log(0)}})" 2>/dev/null) || UNACK=0
[ "$((COUNT + UNACK))" -gt 0 ] || exit 0

# Try the real call path first: pulls the oldest call-eligible pending item forward
# to ring now and marks every other one coalesced, so the bot drains them into that
# one call (call-coalescing-design.md's "Idle-escalation integration") instead of
# reading a bundled digest with no pause between unrelated items. If nothing is
# call-eligible (escalated:false — everything pending is banner/inbox-level, or it's
# purely unacknowledged replies/requests with nothing to ring about), fall through
# to a plain text reminder below.
ESCALATE_RESULT=$(curl -sS -X POST "$BACKEND_URL/api/pending/escalate-call" -H "authorization: Bearer $TOKEN" 2>/dev/null) || ESCALATE_RESULT=""
ESCALATED=$(echo "$ESCALATE_RESULT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).escalated===true?'1':'0')}catch{console.log('0')}})" 2>/dev/null) || ESCALATED="0"
[ "$ESCALATED" = "1" ] && exit 0

# Fallback: a plain banner/text reminder — never "call" here, since anything
# call-eligible already went through escalate-call above. Real titles of what's
# actually pending, not just a bare count (confirmed by real user feedback: a bare
# "N things waiting" call was useless without saying what).
ITEMS_JSON=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.stringify(JSON.parse(d).items||[]))}catch{console.log('[]')}})" 2>/dev/null) || ITEMS_JSON="[]"
UNACK_ITEMS_JSON=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.stringify(JSON.parse(d).unacknowledgedItems||[]))}catch{console.log('[]')}})" 2>/dev/null) || UNACK_ITEMS_JSON="[]"

PROJECT_NAME=$(basename "$CWD")
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

curl -sS -X POST "$BACKEND_URL/api/notify" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d "$(node -e '
    const [unackStr, project, itemsJson, unackItemsJson, nowIso] = process.argv.slice(1);
    const unack = Number(unackStr);
    const items = JSON.parse(itemsJson);
    const unackItems = JSON.parse(unackItemsJson);

    const allItems = [...items, ...unackItems].sort((a, b) => a.createdAt.localeCompare(b.createdAt));
    const allTitles = allItems.map((i) => i.title);

    let title;
    if (allTitles.length === 0) {
      title = "Claude Code needs you in " + project;
    } else if (allTitles.length === 1) {
      title = allTitles[0];
    } else {
      title = allTitles[0] + " (+" + (allTitles.length - 1) + " more)";
    }

    const description = allTitles.length > 1 ? allTitles.slice() : [];
    if (unack > 0) {
      description.push("Reopen the session to pick up your reply — nothing else will.");
    }
    if (description.length === 0 && allTitles.length === 1) {
      description.push("In " + project + ".");
    }
    if (description.length === 0) {
      description.push("Waiting on you for at least 10 minutes, but could not retrieve what it is about.");
    }

    console.log(JSON.stringify({ context: { title, description }, select: "text", urgency: "banner", createdAt: nowIso }));
  ' "$UNACK" "$PROJECT_NAME" "$ITEMS_JSON" "$UNACK_ITEMS_JSON" "$NOW_ISO")" \
  >/dev/null 2>&1 || true
