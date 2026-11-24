#!/bin/sh
# Paigy Antigravity SessionStart hook.
# Fast, zero-network, and exits 0 whatever happens.
# Silent when harness-spawned (its pump already delivers) or when this machine has no local
# pairing token (hosted OAuth sessions do not run a local listener).
if [ -n "${PAIGY_HARNESS:-}" ] || [ ! -f "${HOME}/.paigy/token.json" ]; then
  printf '{}\n'
  exit 0
fi

cat <<'EOF'
{"injectSteps":[{"systemMessage":{"systemMessage":"Paigy: call contact({ wait: false }) once to pick up any waiting work. If you are using the local @paigy/mcp server (not hosted OAuth), call the listen tool and run its command with run_command (IsDaemon: true) so answers wake you."}}]}
EOF
exit 0
