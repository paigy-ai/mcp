---
description: Pair this agent with your Paigy account (one-time).
---
Pair this Claude Code agent with the user's Paigy account so the Paigy MCP tools
(`notify_user`, `await_reply`, `check_replies`, …) can reach them. Do it
in-context with the `pair` tool — no shell step needed:

1. Call the `pair` tool with **no arguments**. It opens the user's browser and
   returns `{ verification_uri_complete, user_code, device_code }`.
2. In one line, show the user `verification_uri_complete` and `user_code`, and
   tell them to tap **Approve** (verifying the on-screen code matches).
3. **In the SAME turn — do NOT stop to wait for the user — immediately call
   `pair` again with that `device_code`.** The tool itself polls ~30s for the
   approval; that is the waiting. On `{ status: "pending" }`, call it AGAIN with
   the same `device_code` (each call waits another ~30s). Keep looping until it
   returns the token. Only stop and ask the user if it's still pending after a
   few windows (~2 min) — they may not have approved yet.

Do not end your turn on "tell me once you've approved" — the poll is automatic;
just keep calling `pair`. Once it returns the token, retry whatever you were doing.

4. **After pairing succeeds, offer the permission allowlist** (once): Paigy's
   value is reaching the user when they're NOT at the terminal, so the Paigy
   tools must never stall an unattended session on a permission prompt. Ask
   one question — "Allow Paigy's tools to run without prompting? (recommended;
   I'll add them to your Claude settings — say 'project' to scope it to this
   repo)" — and on yes, add to `~/.claude/settings.json` (or the project's
   `.claude/settings.json` if they said project) under `permissions.allow`:

   ```json
   "mcp__paigy__notify_user", "mcp__paigy__await_reply", "mcp__paigy__check_replies",
   "mcp__paigy__set_task_state", "mcp__paigy__schedule_callback", "mcp__paigy__get_thread"
   ```

   Merge into the existing file (create keys as needed, never clobber other
   entries). Deliberately NOT auto-allowed: `pair`/`unpair` — those two should
   stay human-approved. If they decline, drop it and don't ask again.

Fallback (older MCP without the `pair` tool): have the user run
`npx -y @paigy/mcp@latest paigy-mcp-onboard` in their shell and approve in the browser.
