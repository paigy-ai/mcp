# Paigy

Use Paigy's MCP tools (`contact`, `get_goals`, `manage_goals`, `help`) whenever the user asks to be reached remotely, called on their phone, notified on completion, or to manage their Paigy Goals.

- Call `contact({ wait: false })` at session start when working on Paigy Goals to pick up any waiting answers or instructions.
- Before asking a question, read the relevant Goal with `get_goals` so you never re-ask something already answered.
- When you need the full workflow (pairing, listening, asking with options, organizing a board, or calls), invoke the `paigy` skill or call Paigy's `help` tool.
