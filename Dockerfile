FROM node:20-alpine
# Paigy's MCP server ships on npm, not in this repo (repo = docs + plugin
# marketplace manifest + MCPB bundle build). Glama builds this Dockerfile to
# start the server and run its introspection check, so this just launches
# the published package.
ENTRYPOINT ["npx", "-y", "@paigy/mcp@latest"]
