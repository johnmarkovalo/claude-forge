#!/usr/bin/env bash
set -euo pipefail

FORGE_HOME="${HOME}/.claude-forge"

usage() {
    echo "Usage: forge-prune.sh [command]"
    echo ""
    echo "Commands:"
    echo "  checkpoints [days]  Remove completed checkpoints older than N days (default: 30)"
    echo "  logs [days]         Trim event logs older than N days (default: 90)"
    echo "  all [days]          Prune everything (default: 30 for checkpoints, 90 for logs)"
    echo ""
}

cmd_checkpoints() {
    local days="${1:-30}"
    local dir="${FORGE_HOME}/checkpoints/completed"
    echo "Pruning completed checkpoints older than ${days} days..."

    if [ ! -d "$dir" ]; then
        echo "  No completed checkpoints directory."
        return 0
    fi

    local count=0
    find "$dir" -name "*.json" -type f -mtime +"$days" 2>/dev/null | while read -r f; do
        rm "$f"
        count=$((count + 1))
        echo "  Removed: $(basename "$f")"
    done
    echo "Removed ${count} old checkpoints."
}

cmd_logs() {
    local days="${1:-90}"
    local cutoff
    cutoff=$(date -u -d "${days} days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
             date -u -v-${days}d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")

    if [ -z "$cutoff" ]; then
        echo "Could not compute cutoff date."
        return 1
    fi

    for log in events.jsonl evolution.jsonl; do
        local logfile="${FORGE_HOME}/logs/${log}"
        if [ -f "$logfile" ]; then
            local before after
            before=$(wc -l < "$logfile")
            jq -c "select(.ts >= \"${cutoff}\")" "$logfile" > "${logfile}.tmp" && mv "${logfile}.tmp" "$logfile"
            after=$(wc -l < "$logfile")
            echo "  ${log}: removed $((before - after)) old entries (kept ${after})"
        fi
    done
}

cmd_all() {
    local cp_days="${1:-30}"
    local log_days="${2:-90}"
    cmd_checkpoints "$cp_days"
    echo ""
    cmd_logs "$log_days"
    echo ""

    # Also prune memory
    "${FORGE_HOME}/scripts/forge-memory.sh" prune
}

case "${1:-}" in
    checkpoints)  cmd_checkpoints "${2:-30}" ;;
    logs)         cmd_logs "${2:-90}" ;;
    all)          cmd_all "${2:-30}" "${3:-90}" ;;
    -h|--help)    usage ;;
    "")           usage ;;
    *)            echo "Unknown command: $1"; usage; exit 1 ;;
esac
