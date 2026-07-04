FROM node:20-alpine
# Paigy's MCP server ships on npm, not in this repo — this repo is the Claude
# Code plugin/marketplace wrapper + docs. Smithery needs a Docker image to run
# the stdio server it hosts, so this just launches the published package.
ENTRYPOINT ["npx", "-y", "@paigy/mcp@latest"]
