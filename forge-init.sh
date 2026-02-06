#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# Claude Forge — Installer
# Sets up the multi-agent orchestration system for Claude Code
# ─────────────────────────────────────────────────────────

FORGE_HOME="${HOME}/.claude-forge"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[forge]${NC} $1"; }
ok()    { echo -e "${GREEN}[forge]${NC} $1"; }
warn()  { echo -e "${YELLOW}[forge]${NC} $1"; }
err()   { echo -e "${RED}[forge]${NC} $1"; }

# ─────────────────────────────────────────────────────────
# Pre-flight checks
# ─────────────────────────────────────────────────────────

if ! command -v claude &> /dev/null; then
    warn "Claude Code CLI not found in PATH."
    warn "Install it first: https://docs.anthropic.com/en/docs/claude-code"
    warn "Continuing anyway — you can still set up the files."
fi

# ─────────────────────────────────────────────────────────
# Backup existing config
# ─────────────────────────────────────────────────────────

if [ -d "$FORGE_HOME" ]; then
    BACKUP="${FORGE_HOME}.backup-$(date +%Y%m%d%H%M%S)"
    warn "Existing ~/.claude-forge found. Backing up to ${BACKUP}"
    mv "$FORGE_HOME" "$BACKUP"
fi

# ─────────────────────────────────────────────────────────
# Install
# ─────────────────────────────────────────────────────────

info "Installing Claude Forge to ${FORGE_HOME}..."

# Copy everything except this script and git metadata
mkdir -p "$FORGE_HOME"
rsync -a --exclude='.git' --exclude='forge-init.sh' --exclude='README.md' --exclude='LICENSE' "${SCRIPT_DIR}/" "${FORGE_HOME}/"

# Create runtime directories (not in repo)
mkdir -p "${FORGE_HOME}/agents/staging"
mkdir -p "${FORGE_HOME}/agents/retired"
mkdir -p "${FORGE_HOME}/pipelines/custom"
mkdir -p "${FORGE_HOME}/memory/lessons"
mkdir -p "${FORGE_HOME}/memory/patterns"
mkdir -p "${FORGE_HOME}/memory/decisions"
mkdir -p "${FORGE_HOME}/memory/context"
mkdir -p "${FORGE_HOME}/checkpoints/active"
mkdir -p "${FORGE_HOME}/checkpoints/completed"
mkdir -p "${FORGE_HOME}/logs"

# Initialize empty logs
touch "${FORGE_HOME}/logs/events.jsonl"
touch "${FORGE_HOME}/logs/evolution.jsonl"

# Initialize memory index
echo '{"terms":{},"last_rebuilt":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","total_entries":0}' > "${FORGE_HOME}/memory/index.json"

# Make scripts executable
chmod +x "${FORGE_HOME}/scripts/"*.sh

ok "Files installed to ${FORGE_HOME}"

# ─────────────────────────────────────────────────────────
# Integrate with Claude Code
# ─────────────────────────────────────────────────────────

info "Integrating with Claude Code..."

# Ensure ~/.claude exists
mkdir -p "${CLAUDE_DIR}"
mkdir -p "${CLAUDE_DIR}/commands"

# Symlink slash commands into Claude's command directory
for cmd_file in "${FORGE_HOME}/commands/"*.md; do
    cmd_name=$(basename "$cmd_file")
    target="${CLAUDE_DIR}/commands/${cmd_name}"
    if [ -L "$target" ]; then
        rm "$target"
    elif [ -f "$target" ]; then
        warn "Existing command ${cmd_name} found — skipping (remove manually to use Forge's version)"
        continue
    fi
    ln -s "$cmd_file" "$target"
    ok "  Linked command: ${cmd_name%.md}"
done

# ─────────────────────────────────────────────────────────
# Inject into CLAUDE.md
# ─────────────────────────────────────────────────────────

CLAUDE_MD="${CLAUDE_DIR}/CLAUDE.md"
FORGE_MARKER="# --- CLAUDE FORGE ---"

inject_forge_reference() {
    local target_file="$1"

    # Check if already injected
    if [ -f "$target_file" ] && grep -q "$FORGE_MARKER" "$target_file"; then
        info "Forge reference already in ${target_file} — updating..."
        # Remove old injection (between markers)
        sed -i "/${FORGE_MARKER}/,/# --- END CLAUDE FORGE ---/d" "$target_file"
    fi

    cat >> "$target_file" << 'INJECT'

# --- CLAUDE FORGE ---
# Multi-agent orchestration system. Read this on every /forge, /plan, /review, /resume command.
# SYSTEM PROMPT: ~/.claude-forge/SYSTEM.md
# COST POLICY: ~/.claude-forge/core/cost-policy.json
# ROUTING: ~/.claude-forge/core/routes.json
# AGENT REGISTRY: ~/.claude-forge/agents/_registry.json

When the user runs any /forge command, read ~/.claude-forge/SYSTEM.md first before proceeding.
When the user runs /budget, run ~/.claude-forge/scripts/forge-budget.sh
When the user runs /agents, read ~/.claude-forge/agents/_registry.json and list agents with their status.
When the user runs /memory, run ~/.claude-forge/scripts/forge-memory.sh with the provided arguments.
# --- END CLAUDE FORGE ---
INJECT

    ok "  Injected Forge reference into ${target_file}"
}

# Global CLAUDE.md
inject_forge_reference "$CLAUDE_MD"

# ─────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Claude Forge installed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Installation:  ${FORGE_HOME}"
echo "  Commands:      ${CLAUDE_DIR}/commands/ (symlinked)"
echo "  Config:        ${FORGE_HOME}/forge.json"
echo ""
echo "  Usage:"
echo "    /forge <task>     Full pipeline (classify → route → execute → verify)"
echo "    /plan <task>      Plan only (no execution)"
echo "    /review           Code review"
echo "    /resume           Continue from checkpoint"
echo "    /budget           Cost tracking"
echo "    /agents           Manage agents"
echo ""
echo "  Optional: Add to your project's CLAUDE.md:"
echo "    echo 'Read ~/.claude-forge/SYSTEM.md for orchestration commands.' >> ./CLAUDE.md"
echo ""
echo -e "  ${YELLOW}First run: /forge hello — to verify everything works.${NC}"
echo ""
