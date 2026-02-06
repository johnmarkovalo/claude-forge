#!/usr/bin/env bash
set -euo pipefail

FORGE_HOME="${HOME}/.claude-forge"
OUTPUT="${1:-forge-export.tar.gz}"

echo "Exporting Forge config (excluding personal memory and checkpoints)..."

tar -czf "$OUTPUT" \
    -C "$FORGE_HOME" \
    --exclude='memory/lessons/*' \
    --exclude='memory/patterns/*' \
    --exclude='memory/decisions/*' \
    --exclude='memory/context/*' \
    --exclude='memory/index.json' \
    --exclude='memory/.archived' \
    --exclude='checkpoints/active/*' \
    --exclude='checkpoints/completed/*' \
    --exclude='logs/*' \
    --exclude='agents/staging/*' \
    --exclude='agents/retired/*' \
    . 2>/dev/null

echo "Exported to: ${OUTPUT}"
echo ""
echo "Includes: core config, stable agents, pipelines, commands, scripts"
echo "Excludes: memory, checkpoints, logs, staging/retired agents"
echo ""
echo "To import on another machine:"
echo "  mkdir -p ~/.claude-forge && tar -xzf ${OUTPUT} -C ~/.forge"
echo "  ~/.claude-forge/scripts/forge-init.sh  # Re-link commands"
