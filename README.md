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
claude mcp add paigy -s user -- npx -y @paigy/mcp@latest
```

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
later**. Set `urgency:"alert"` so it rings through as a banner (vs `"inbox"`
silent or `"call"` to ring the phone).

## License

MIT
