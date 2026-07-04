# Paigy — Claude Code plugin

A voice inbox for your AI agents. When an agent needs your input — mid-task,
blocked, or done with something long-running — Paigy can text, push, ring
your phone with a banner, or **place an actual phone call** and read the
question aloud, so you can just talk back instead of babysitting a terminal.
Built for anyone running long agent sessions who wants to walk away and still
get pulled back in the moment a decision is needed.

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
