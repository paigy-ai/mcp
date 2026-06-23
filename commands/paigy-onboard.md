---
description: Pair this agent with your Paigy account (one-time).
---
Pair this Claude Code agent with the user's Paigy account so the Paigy MCP tools
can reach them.

Run this in the shell:

    npx -y @paigy/mcp paigy-mcp-onboard

It prints a short approval code and opens the user's browser to approve. On
approval it saves a token to `~/.paigy/token.json`; the Paigy MCP tools
(`notify_user`, `await_reply`, `check_replies`, …) then work. Retry whatever you
were doing.
