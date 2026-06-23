# Paigy — Claude Code plugin

A voice inbox for your AI agents. Paigy lets an agent **call/notify you** and
**await your reply** — so a long-running agent can ask, hand off, and resume on
your answer.

This repo is the **Claude Code plugin + marketplace** for Paigy. It wires the
published [`@paigy/mcp`](https://www.npmjs.com/package/@paigy/mcp) server into
Claude Code in one step. (The app + backend live in a separate repo.)

## Install

```
/plugin marketplace add paigy-ai/claude
/plugin install paigy
```

The Paigy MCP connects automatically. The first time an agent uses it while
unpaired, it'll prompt you to pair — run `/paigy-onboard` (opens your browser to
approve).

### Or add the MCP directly

```
claude mcp add paigy -s user -- npx -y @paigy/mcp
```

## License

MIT
