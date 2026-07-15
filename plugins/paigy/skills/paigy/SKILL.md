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

- Prefer `notify` for new messages; use the returned `threadId` for follow-ups about the same matter.
- Use `urgency: "call"` only when the user explicitly asks for a test call or when work is genuinely blocked and time-sensitive.
- Keep call titles and descriptions brief and natural to hear aloud.
- Sending a follow-up on an existing thread supersedes its pending items. Use separate threads for independent work.

## Replies and callbacks

- Use `await_reply` for a notification just sent; use `check_replies` when resuming work or checking outstanding items.
- A `schedule_callback` records an obligation; it does not itself send a notification. When the callback is due, use `check_replies`, then send the promised follow-up on the same `threadId`.
- Honor the user's requested channel and timing. If a scheduled time has passed, report that clearly and ask before sending a late call unless the user explicitly asked for it to be sent even if late.
