---
description: Log out / unpair this agent from your Paigy account.
---
Log this Claude Code agent out of the user's Paigy account.

Call the `unpair` tool (no arguments). It revokes the token server-side — so it
stops working everywhere, not just on this machine — and deletes the local
`~/.paigy/token.json`. After this, `notify_user` / `await_reply` won't work until
the user pairs again (run `/paigy-onboard`).

Fallback (older MCP without the `unpair` tool): have the user delete the token
locally with `rm ~/.paigy/token.json` (note: that only forgets it locally; it
does not revoke the token server-side).
