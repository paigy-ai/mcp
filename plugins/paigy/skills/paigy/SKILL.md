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

- **Always use `notify_user`** — never the bare `notify` tool. (Field incident 2026-07-21: a greeting sent via `notify` landed as a silent inbox item while the user waited for a call.)
- **Prefer the simplified form**: pass `ask` (plain prose: what you need to tell the user, or find out from them) plus `urgencyHint` and `blocking`. Paigy's broker picks the channel, answer shape, and phrasing — that is its job, not yours.
- `urgencyHint`: `"now"` when you are stopped or the moment is time-sensitive; `"soon"` when you want an answer but can keep working; `"whenever"` for FYIs. Set `blocking: true` whenever real work is stalled behind the answer — unanswered blocking asks escalate to a real phone call automatically.
- If the user asks you to **call** them, that is explicit: use `notify_user` with `urgency: "call"` directly.
- Keep anything that may be spoken brief and natural to hear aloud.
- Use the returned `threadId` for follow-ups about the same matter. A follow-up on an existing thread supersedes its pending items; use separate threads for independent work.

## Replies and callbacks

- Use `await_reply` for a notification just sent; use `check_replies` when resuming work or checking outstanding items.
- A `schedule_callback` records an obligation; it does not itself send a notification. When the callback is due, use `check_replies`, then send the promised follow-up on the same `threadId`.
- Honor the user's requested channel and timing. If a scheduled time has passed, report that clearly and ask before sending a late call unless the user explicitly asked for it to be sent even if late.
