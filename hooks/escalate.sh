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

# Two distinct things can need attention: the agent's own still-unanswered
# questions (count/items), and replies/requests the USER already sent that no
# agent has picked up yet (unacknowledged/unacknowledgedItems) — e.g. they
# answered via the app, but this Claude Code session already stopped and
# nothing else will notice, so they need to know to reopen it. Both come from
# the same non-claiming endpoint, so this never consumes anything meant for
# the real agent session's own check_replies/await_reply.
COUNT=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).count||0)}catch{console.log(0)}})" 2>/dev/null) || COUNT=0
UNACK=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).unacknowledged||0)}catch{console.log(0)}})" 2>/dev/null) || UNACK=0
[ "$((COUNT + UNACK))" -gt 0 ] || exit 0

# Real titles of what's actually pending — the whole point of the escalation is
# telling the user WHAT needs them and WHAT decision it needs, not just "something
# is pending" (confirmed by real user feedback: a bare "N things waiting" call was
# useless without saying what).
ITEMS_JSON=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.stringify(JSON.parse(d).items||[]))}catch{console.log('[]')}})" 2>/dev/null) || ITEMS_JSON="[]"
UNACK_ITEMS_JSON=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.stringify(JSON.parse(d).unacknowledgedItems||[]))}catch{console.log('[]')}})" 2>/dev/null) || UNACK_ITEMS_JSON="[]"

PROJECT_NAME=$(basename "$CWD")
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

curl -sS -X POST "$BACKEND_URL/api/notify" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d "$(node -e '
    const [countStr, unackStr, project, itemsJson, unackItemsJson, armedAtStr, nowIso] = process.argv.slice(1);
    const count = Number(countStr);
    const unack = Number(unackStr);
    const items = JSON.parse(itemsJson);
    const unackItems = JSON.parse(unackItemsJson);
    const armedAt = Number(armedAtStr);

    // Merge both kinds of item (still-pending questions, unpicked-up replies)
    // oldest-first — a bare count is never enough on its own (confirmed by real
    // user feedback twice now): the title must lead with the actual thing, not
    // just how many there are.
    const allItems = [...items, ...unackItems].sort((a, b) => a.createdAt.localeCompare(b.createdAt));
    const allTitles = allItems.map((i) => i.title);

    // Urgency scales with what is actually blocked: multiple things, or the
    // oldest one being stale a while, escalate to a call; a single fresh one
    // gets a banner instead of ringing the phone outright.
    const allTimes = allItems.map((i) => new Date(i.createdAt).getTime() / 1000);
    const oldestAgeMin = allTimes.length > 0 ? (armedAt - Math.min(...allTimes)) / 60 : 0;
    const total = count + unack;
    const urgency = total >= 2 || oldestAgeMin >= 20 ? "call" : "banner";

    let title;
    if (allTitles.length === 0) {
      title = "Claude Code needs you in " + project;
    } else if (allTitles.length === 1) {
      title = allTitles[0];
    } else {
      title = allTitles[0] + " (+" + (allTitles.length - 1) + " more)";
    }

    // Full list as its own chunks so the user can ask to expand any one —
    // skipped when there is exactly one, since the title already is it.
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

    console.log(JSON.stringify({ context: { title, description }, select: "text", urgency, createdAt: nowIso }));
  ' "$COUNT" "$UNACK" "$PROJECT_NAME" "$ITEMS_JSON" "$UNACK_ITEMS_JSON" "$ARMED_AT" "$NOW_ISO")" \
  >/dev/null 2>&1 || true
