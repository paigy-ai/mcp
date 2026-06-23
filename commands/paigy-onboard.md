---
description: Pair this agent with your Paigy account (one-time).
---
Pair this Claude Code agent with the user's Paigy account so the Paigy MCP tools
(`notify_user`, `await_reply`, `check_replies`, …) can reach them. Do it
in-context with the `pair` tool — no shell step needed:

1. Call the `pair` tool with **no arguments**. It opens the user's browser and
   returns `{ verification_uri_complete, user_code, device_code }`.
2. Show the user `verification_uri_complete` and `user_code`, and ask them to
   open it (if the browser didn't) and tap **Approve** — telling them to verify
   the on-screen code matches `user_code`.
3. Once they say they've approved, call `pair` again passing that `device_code`
   to finish. It saves the token to `~/.paigy/token.json`. If it returns
   `{ status: "pending" }`, they haven't approved yet — call again with the same
   `device_code` to keep waiting.

Then retry whatever you were doing.

Fallback (older MCP without the `pair` tool): have the user run
`npx -y @paigy/mcp paigy-mcp-onboard` in their shell and approve in the browser.
