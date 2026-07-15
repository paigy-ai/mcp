#!/usr/bin/env bash
# Armed by on-stop.sh alongside escalate.sh, on EVERY turn end — but wakes much
# sooner (2 min vs 10) and checks a narrower thing: did the user already reply/
# request something that no agent has engaged with yet (unacknowledged)? That's
# different from "the user hasn't answered at all" (escalate.sh's job) — an
# unacknowledged reply means they already did their part; the agent's own
# session just hasn't looked yet.
#
# Tries to actually wake an agent first, on a three-rung ladder (#26):
#   1. `claude -p --resume $SESSION_ID --fork-session` — the stopped session's
#      FULL context, forked into a NEW session id. Forking sidesteps the reason
#      plain --resume was rejected: resuming would inject a fake "user" turn
#      into a transcript the user might be actively looking at (or typing in) —
#      a real double-writer risk. A fork writes nothing to the original.
#   2. A headless FRESH `claude -p` (fork failed: session file gone, old CLI) —
#      no history, but it CAN check_replies, engage/set_task_state, and post a
#      natural acknowledgment via notify_user.
#   3. Notify the human directly (claude not on PATH / both spawns failed) —
#      the old behavior, kept as the safety net.
# Rungs 1–2 read as a normal message from the agent, not a system nudge.
#
# This does NOT replace escalate.sh's 10-min check — both fire from every stop;
# if the same items are still unacknowledged at 10 min, escalate.sh's own
# fallback covers them too. A repeated nudge for something genuinely still
# unaddressed is expected, not a bug.
set -euo pipefail

# See escalate.sh for why: a user shell with FORCE_COLOR set globally makes
# `node -e "console.log(...)"` wrap output in ANSI codes even when piped,
# corrupting every numeric/JSON parse below.
export NO_COLOR=1
export FORCE_COLOR=0

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hooks/token.sh
. "$HERE/token.sh"

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
TOKEN=$(read_paigy_token "$TOKEN_FILE") || exit 0
[ -n "$TOKEN" ] || exit 0

SUMMARY=$(curl -sS -X GET "$BACKEND_URL/api/pending/summary" -H "authorization: Bearer $TOKEN" 2>/dev/null) || exit 0
UNACK=$(echo "$SUMMARY" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).unacknowledged||0)}catch{console.log(0)}})" 2>/dev/null) || UNACK=0
[ "$UNACK" -gt 0 ] || exit 0

PAIGY_TOOLS="mcp__paigy__check_replies,mcp__paigy__get_thread,mcp__paigy__set_task_state,mcp__paigy__notify_user,mcp__paigy__await_reply,mcp__paigy__schedule_callback"

# Rung 1: fork the stopped session — full context, no writes to the original
# transcript. --fork-session mints a new session id, so the user's own session
# stays untouched even if they reopen it mid-run.
if command -v claude >/dev/null 2>&1; then
  if (cd "$CWD" 2>/dev/null && claude -p --resume "$SESSION_ID" --fork-session \
      --allowedTools="$PAIGY_TOOLS" \
      "You are a fork of this stopped session, woken because the user replied or sent a request that nothing has engaged with. Call check_replies via the paigy MCP now and handle what it returns using the full context above: continue the work, or reply via notify_user on the item's threadId. If a request carries a contextThreadId or a threadId not in this conversation, call get_thread on it first and treat the transcript as prior conversation." \
      >/dev/null 2>&1); then
    exit 0
  fi

  # Rung 2: fresh headless session (fork failed — session file gone, old CLI),
  # scoped to just the tools it needs to catch up and act.
  if (cd "$CWD" 2>/dev/null && claude -p \
      --allowedTools="$PAIGY_TOOLS" \
      "Call check_replies via the paigy MCP now. If a request carries a contextThreadId, or lands on a threadId from a conversation you don't have, call get_thread on it FIRST and treat the transcript as prior conversation you were part of — then continue it for real. For every other reply/request no agent has engaged with yet: call set_task_state on it, then post a brief, natural acknowledgment via notify_user on its threadId — e.g. \"I see a stale notification about X, sorry I missed it — starting on it now.\" Beyond what get_thread gives you, don't pretend to have context you don't." \
      >/dev/null 2>&1); then
    exit 0
  fi
fi

# Fallback: the agent couldn't be woken (claude not on PATH, resume failed,
# timed out) — notify the human directly so they know to reopen it themselves.
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
