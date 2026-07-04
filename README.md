# Paigy — MCP server

A voice inbox for your AI agents. When an agent needs your input — mid-task,
blocked, or done with something long-running — Paigy can text, push, ring
your phone with a banner, or **place an actual phone call** and read the
question aloud, so you can just talk back instead of babysitting a terminal.
Built for anyone running long agent sessions who wants to walk away and still
get pulled back in the moment a decision is needed.

A standard MCP server (stdio, TypeScript) — no client-specific code anywhere,
verified over the raw protocol against a non-Claude client identity. Works
with **any** MCP-compatible agent, including local-model setups (Cline,
Continue.dev, Zed, Goose, mcphost, anything running against Ollama/LM
Studio/llama.cpp). This repo also happens to be the **Claude Code plugin +
marketplace** for it — one of several ways in, not the only one. (The app +
backend live in a separate repo.)

## Install

**Claude Code** (plugin — easiest path on Claude):
```
/plugin marketplace add paigy-ai/mcp
/plugin install paigy
```
Connects automatically; the first time an agent uses it while unpaired, it'll
prompt you to pair — run `/paigy-onboard` (opens your browser to approve).

**Codex CLI:**
```
codex mcp add paigy --env PAIGY_AGENT=codex -- npx -y @paigy/mcp@latest
```

**Gemini CLI:**
```
gemini mcp add -s user -e PAIGY_AGENT=gemini paigy npx -y @paigy/mcp@latest
```

**Any other MCP client** (Cline, Continue.dev, Zed, Cursor, or a CLI that
takes the standard MCP JSON config directly) — most GUI clients take this in
their MCP settings (Cline: `cline_mcp_settings.json`; Continue:
`~/.continue/config.json`):
```json
{
  "mcpServers": {
    "paigy": {
      "command": "npx",
      "args": ["-y", "@paigy/mcp@latest"],
      "env": { "PAIGY_AGENT": "local" }
    }
  }
}
```

Then pair your phone, whichever client you used:
```
npx -y -p @paigy/mcp@latest paigy-mcp-onboard
```
Approve on your phone, then sign in at [paigy.ai](https://paigy.ai) to start
receiving messages.

> Heads-up for smaller/local models: the tool descriptions ask the agent to
> pick between a few answer shapes (confirm, options, free text) based on
> context — Claude follows this reliably; smaller local models may be less
> consistent about it. Free text always works as a fallback.

## Choosing how the user answers

`notify_user` should ask in the shape that's fastest to answer — don't leave a
decision as free text. Pick with `select` (and `options`):

| You need… | Use | Answer comes back as |
|---|---|---|
| **Yes/No or Approve/Deny** | `select:"confirm"` (`confirmStyle:"approve"` for Approve/Deny) | `{kind:"confirm", approved}` |
| **Pick one of several** | `options` + `select:"one"` | `{kind:"option", optionId}` |
| **Pick several** | `options` + `select:"many"` | `{kind:"multi", optionIds}` |
| **Rank / order a subset** | `options` + `select:"rank"` | `{kind:"ranked", optionIds}` |
| **A visual choice** | options with an `html` or `image` preview | one of the above |
| **An open-ended reply** | no options | `{kind:"text", text}` |

`confirm` is **answerable straight from the banner** (Yes/No or Approve/Deny
buttons). Other paiges get banner actions **See Options · Hear them · Remind me
later**.

`urgency` is a *request*, not a guarantee — the user's account settings can
cap it lower. Four levels, low to high: `"inbox"` (silent, sits in the inbox),
`"push"` (a quiet passive notification, no sound), `"banner"` (a
time-sensitive lock-screen banner with sound), `"call"` (rings the phone —
use only when you genuinely need the user in the moment).

If you're about to start something long-running or blocking — the kind of
thing where the user would otherwise sit and wait on you — mention **once**,
in passing, that you can text or call them when it's done or if you hit a
blocker. Don't offer it for quick tasks, and don't repeat the offer once
they've answered.

## License

MIT
