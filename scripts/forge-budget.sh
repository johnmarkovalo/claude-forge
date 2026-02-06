#!/usr/bin/env bash
set -euo pipefail

FORGE_HOME="${HOME}/.claude-forge"
EVENTS_LOG="${FORGE_HOME}/logs/events.jsonl"
COST_POLICY="${FORGE_HOME}/core/cost-policy.json"

# ─────────────────────────────────────────────────────────
# Usage
# ─────────────────────────────────────────────────────────

usage() {
    echo "Usage: forge-budget.sh [command]"
    echo ""
    echo "Commands:"
    echo "  summary          Today's cost summary (default)"
    echo "  task <id>        Cost breakdown for a specific task"
    echo "  agents [days]    Cost by agent (default: 7 days)"
    echo "  failures [days]  Show recent failures (default: 7 days)"
    echo "  trace <task-id>  Full event trace for a task"
    echo ""
}

# ─────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────

today_start() {
    date -u +%Y-%m-%dT00:00:00Z
}

days_ago() {
    local days=$1
    date -u -d "${days} days ago" +%Y-%m-%dT00:00:00Z 2>/dev/null || \
    date -u -v-${days}d +%Y-%m-%dT00:00:00Z 2>/dev/null || \
    echo "1970-01-01T00:00:00Z"
}

# ─────────────────────────────────────────────────────────
# Commands
# ─────────────────────────────────────────────────────────

cmd_summary() {
    if [ ! -f "$EVENTS_LOG" ] || [ ! -s "$EVENTS_LOG" ]; then
        echo "No events logged yet. Run /forge to get started."
        return 0
    fi

    local today
    today=$(today_start)
    local daily_cap
    daily_cap=$(jq -r '.budget.daily_cap_usd' "$COST_POLICY" 2>/dev/null || echo "50.00")

    echo "═══ Forge Budget ═══"
    echo ""

    # Today's total cost
    local today_cost
    today_cost=$(jq -r "select(.ts >= \"${today}\") | select(.event == \"phase_completed\") | .cost_usd // 0" "$EVENTS_LOG" 2>/dev/null | \
        awk '{sum += $1} END {printf "%.2f", sum}')
    today_cost=${today_cost:-0.00}

    echo "Today: \$${today_cost} / \$${daily_cap} daily cap"
    echo ""

    # Active tasks
    echo "Active tasks:"
    local active_dir="${FORGE_HOME}/checkpoints/active"
    if [ -d "$active_dir" ] && [ "$(ls -A "$active_dir" 2>/dev/null)" ]; then
        for f in "$active_dir"/*.json; do
            local task_id state cost budget
            task_id=$(jq -r '.task_id' "$f" 2>/dev/null)
            state=$(jq -r '.state' "$f" 2>/dev/null)
            cost=$(jq -r '.cost_total_usd // 0' "$f" 2>/dev/null)
            budget=$(jq -r '.cost_budget_usd // 0' "$f" 2>/dev/null)
            printf "  %-24s  %-12s  \$%.2f / \$%.2f\n" "$task_id" "$state" "$cost" "$budget"
        done
    else
        echo "  (none)"
    fi

    echo ""

    # Recent completed
    echo "Recent completed:"
    local completed_dir="${FORGE_HOME}/checkpoints/completed"
    if [ -d "$completed_dir" ] && [ "$(ls -A "$completed_dir" 2>/dev/null)" ]; then
        ls -t "$completed_dir"/*.json 2>/dev/null | head -5 | while read -r f; do
            local task_id cost
            task_id=$(jq -r '.task_id' "$f" 2>/dev/null)
            cost=$(jq -r '.cost_total_usd // 0' "$f" 2>/dev/null)
            printf "  %-24s  \$%.2f  ✅\n" "$task_id" "$cost"
        done
    else
        echo "  (none)"
    fi
}

cmd_task() {
    local task_id="${1:-}"
    if [ -z "$task_id" ]; then
        echo "Usage: forge-budget.sh task <task-id>"
        return 1
    fi

    echo "═══ Task: ${task_id} ═══"
    echo ""

    # Check active
    local checkpoint="${FORGE_HOME}/checkpoints/active/${task_id}.json"
    if [ ! -f "$checkpoint" ]; then
        checkpoint="${FORGE_HOME}/checkpoints/completed/${task_id}.json"
    fi

    if [ -f "$checkpoint" ]; then
        jq -r '
            "State: \(.state)",
            "Pipeline: \(.pipeline)",
            "Cost: $\(.cost_total_usd // 0) / $\(.cost_budget_usd // 0)",
            "",
            "Phases:",
            (.phases_completed | to_entries[] | "  \(.key): $\(.value.cost_usd // 0) (\(.value.agent))")
        ' "$checkpoint" 2>/dev/null
    else
        echo "Task not found in checkpoints."
    fi
}

cmd_agents() {
    local days="${1:-7}"
    local since
    since=$(days_ago "$days")

    echo "═══ Agent Costs (${days}d) ═══"
    echo ""

    if [ ! -f "$EVENTS_LOG" ] || [ ! -s "$EVENTS_LOG" ]; then
        echo "No events logged yet."
        return 0
    fi

    jq -r "select(.ts >= \"${since}\") | select(.event == \"agent_invocation\") | \"\(.agent) \(.est_cost_usd // 0)\"" "$EVENTS_LOG" 2>/dev/null | \
        awk '{cost[$1] += $2; count[$1]++} END {for (a in cost) printf "  %-16s  $%.2f  (%d invocations)\n", a, cost[a], count[a]}' | \
        sort -t'$' -k2 -rn

    if [ $? -ne 0 ] || [ -z "$(jq -r "select(.ts >= \"${since}\") | select(.event == \"agent_invocation\")" "$EVENTS_LOG" 2>/dev/null)" ]; then
        echo "  No agent invocations in the last ${days} days."
    fi
}

cmd_failures() {
    local days="${1:-7}"
    local since
    since=$(days_ago "$days")

    echo "═══ Failures (${days}d) ═══"
    echo ""

    if [ ! -f "$EVENTS_LOG" ] || [ ! -s "$EVENTS_LOG" ]; then
        echo "No events logged yet."
        return 0
    fi

    jq -r "select(.ts >= \"${since}\") | select(.event == \"phase_failed\") | \"\(.ts) \(.task_id) \(.phase) attempt=\(.attempt) reason=\(.reason)\"" "$EVENTS_LOG" 2>/dev/null || \
        echo "  No failures in the last ${days} days."
}

cmd_trace() {
    local task_id="${1:-}"
    if [ -z "$task_id" ]; then
        echo "Usage: forge-budget.sh trace <task-id>"
        return 1
    fi

    echo "═══ Trace: ${task_id} ═══"
    echo ""

    if [ ! -f "$EVENTS_LOG" ]; then
        echo "No events logged yet."
        return 0
    fi

    jq -r "select(.task_id == \"${task_id}\") | \"\(.ts)  \(.event)  \(del(.ts, .event, .task_id, .trace_id) | to_entries | map(\"\(.key)=\(.value)\") | join(\" \"))\"" "$EVENTS_LOG" 2>/dev/null || \
        echo "  No events found for ${task_id}."
}

# ─────────────────────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────────────────────

case "${1:-summary}" in
    summary)   cmd_summary ;;
    task)      cmd_task "${2:-}" ;;
    agents)    cmd_agents "${2:-7}" ;;
    failures)  cmd_failures "${2:-7}" ;;
    trace)     cmd_trace "${2:-}" ;;
    -h|--help) usage ;;
    *)         echo "Unknown command: $1"; usage; exit 1 ;;
esac
