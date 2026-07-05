---
description: Pair this agent with your Paigy account (one-time).
---
Pair this Claude Code agent with the user's Paigy account so the Paigy MCP tools
(`notify_user`, `await_reply`, `check_replies`, …) can reach them. Do it
in-context with the `pair` tool — no shell step needed:

1. Call the `pair` tool with **no arguments**. It attempts to open the user's
   browser and returns `{ verification_uri_complete, user_code, device_code }`.
   That attempt can silently fail in headless/remote environments — always show
   the link regardless of whether it opened.
2. In one line, show the user `verification_uri_complete` and `user_code`, and
   tell them to tap **Approve** (verifying the on-screen code matches). If the
   browser didn't open on its own, they can go to `verification_uri_complete`
   manually and enter `user_code` there.
3. **In the SAME turn — do NOT stop to wait for the user — immediately call
   `pair` again with that `device_code`.** The tool itself polls ~90s for the
   approval; that is the waiting. On `{ status: "pending" }`, call it AGAIN with
   the same `device_code` (each call waits another ~90s). Keep looping until it
   returns the token. Only stop and ask the user if it's still pending after a
   couple windows (~3 min) — they may not have approved yet.

Do not end your turn on "tell me once you've approved" — the poll is automatic;
just keep calling `pair`. Once it returns the token, retry whatever you were doing.

Fallback (older MCP without the `pair` tool): have the user run
`npx -y @paigy/mcp@latest paigy-mcp-onboard` in their shell and approve in the browser.
