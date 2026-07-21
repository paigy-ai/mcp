---
name: paigy
description: Use Paigy from Codex to notify or call the user, receive scoped replies, and manage callbacks.
---

# Paigy in Codex

Use the Paigy MCP tools supplied by this plugin. Do not invoke a Paigy server from a repository checkout or call the Paigy API directly: the plugin-managed MCP is the source of truth for this Codex identity.

## Pairing

- If Paigy says it is unpaired, call its `pair` tool and show the returned approval link/code to the user.
- Treat pairing and unpairing as explicit user-authorized actions.
- This plugin identifies the client as `codex`; do not reuse another client identity such as `antigravity`.

## Sending attention

- **Use `contact`** — the one tool for reaching the user, whether you're telling them something or need an answer. (If your session still shows `notify_user` instead, the MCP hasn't refreshed yet — same fields, use it the same way.)
- Two fields: `ask` — plain prose, what you need to tell the user or find out from them — and `waiting` — what happens to your work meanwhile:
  - `"none"`: you're just informing them.
  - `"soft"`: you'd like an answer but can keep working.
  - `"hard"`: you are STOPPED until they answer. This reaches them urgently and escalates to a real phone call if unanswered.
- If the user asks you to **call** them, send `waiting: "hard"` and say so in the ask (e.g. "You asked me to call: …").
- Paigy's broker picks the channel, phrasing, and answer format — that is its job, not yours. Keep the ask brief and natural to hear aloud; it may be spoken.
- Use the returned `threadId` for follow-ups about the same matter. A follow-up on an existing thread supersedes its pending items; use separate threads for independent work.

## Replies and callbacks

- Use `await_reply` for a notification just sent; use `check_replies` when resuming work or checking outstanding items.
- A `schedule_callback` records an obligation; it does not itself send a notification. When the callback is due, use `check_replies`, then send the promised follow-up on the same `threadId`.
- Honor the user's requested channel and timing. If a scheduled time has passed, report that clearly and ask before sending a late call unless the user explicitly asked for it to be sent even if late.
