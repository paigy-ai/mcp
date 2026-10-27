---
name: paigy
description: Use Paigy from Codex to notify or call the user, receive their answers, and follow up later.
---

# Paigy in Codex

Use the Paigy MCP tools supplied by this plugin. Do not invoke a Paigy server from a repository checkout or call the Paigy API directly: the plugin-managed MCP is the source of truth for this Codex identity.

## Pairing

- If Paigy says it is unpaired, call its `configure` tool and show the returned code (`user_message`) to the user, then call `configure` again with the returned `device_code` to finish.
- Treat pairing and unpairing as explicit user-authorized actions.
- This plugin identifies the client as `codex`; do not reuse another client identity such as `antigravity`.

## Sending attention

- **Use `contact`** — the one tool for reaching the user, whether you're telling them something or need an answer.
- Tell them something with an `updates` item (`message`, and the `goalIds` it is about); ask with a `questions` item (`question`, its `goalId`, and `options` when you have them). Every Goal named must exist: create it with `manage_goals` first.
- What happens to your work meanwhile:
  - An update asks nothing. It reaches them only when they asked for it, it answers something they said, or its Goal is done; otherwise it is kept as the Goal's progress.
  - A question you can keep working around needs nothing more.
  - `workItBlocks`: you are STOPPED until they answer. It asks for a real phone call; use it only when you are truly blocked.
- If the user asks you to **call** them, set `userExplicitlyRequested: "call"` on that item.
- Paigy picks the channel; your words are sent exactly as written. Keep each question or message brief and natural to hear aloud; it may be spoken.
- Name the same Goal for follow-ups about the same matter, and never re-send a question still waiting there; take back one that no longer matters with `withdrawQuestionIds`. Use separate Goals for independent work.

## Replies and follow-ups

- `contact` returns at once unless you ask it to wait: `contact({ wait: true })` holds one ~45 s window for a response to what you sent, and `contact({})` one for anything addressed to you. While a Call is open, keep receiving window after window; with no open Call, stop when a window comes back empty: the answer reaches you on the Goal. Use `contact({ wait: false })` and `get_goals` when resuming work or checking outstanding items, and acknowledge the events you handled with `contact({ ackEventIds })`. Call `listen` once to check that Paigy can wake this session when an answer arrives, and start the command it gives if it is not listening.
- To follow up later, defer the Goal with `manage_goals` (kind `defer`, `until`); it does not itself send a notification. When you are woken because it is due, read the Goal with `get_goals`, then send the promised follow-up naming the same Goal.
- Honor the user's requested channel and timing. If a scheduled time has passed, report that clearly and ask before sending a late call unless the user explicitly asked for it to be sent even if late.
