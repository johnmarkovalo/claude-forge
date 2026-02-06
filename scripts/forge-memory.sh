#!/usr/bin/env bash
set -euo pipefail

FORGE_HOME="${HOME}/.claude-forge"
MEMORY_DIR="${FORGE_HOME}/memory"
INDEX_FILE="${MEMORY_DIR}/index.json"

usage() {
    echo "Usage: forge-memory.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  search <query>       Search memories by keyword"
    echo "  stats                Show memory statistics"
    echo "  rebuild-index        Rebuild the search index"
    echo "  save <file>          Index a new memory file"
    echo "  prune                Archive stale memories"
    echo ""
}

# ─────────────────────────────────────────────────────────
# Search
# ─────────────────────────────────────────────────────────

cmd_search() {
    local query="${1:-}"
    if [ -z "$query" ]; then
        echo "Usage: forge-memory.sh search <query>"
        return 1
    fi

    if [ ! -f "$INDEX_FILE" ]; then
        echo "No memory index found. Run: forge-memory.sh rebuild-index"
        return 1
    fi

    # Split query into terms and search index
    local terms
    terms=$(echo "$query" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '\n')

    echo "═══ Memory Search: ${query} ═══"
    echo ""

    local found=0
    local -A scores

    for term in $terms; do
        # Look up term in index
        local matches
        matches=$(jq -r ".terms[\"${term}\"][]? // empty" "$INDEX_FILE" 2>/dev/null)
        for match in $matches; do
            scores[$match]=$(( ${scores[$match]:-0} + 1 ))
            found=1
        done
    done

    if [ $found -eq 0 ]; then
        echo "No memories found for: ${query}"
        echo "Try broader terms or check: forge-memory.sh stats"
        return 0
    fi

    # Sort by score (number of matching terms) and display top results
    for id in "${!scores[@]}"; do
        echo "${scores[$id]} ${id}"
    done | sort -rn | head -5 | while read -r score id; do
        # Find the actual file
        local file
        file=$(find "$MEMORY_DIR" -name "${id}.json" -type f 2>/dev/null | head -1)
        if [ -n "$file" ] && [ -f "$file" ]; then
            local title type tags
            title=$(jq -r '.title // "Untitled"' "$file")
            type=$(jq -r '.type // "unknown"' "$file")
            tags=$(jq -r '.tags // [] | join(", ")' "$file")
            echo "  [${type}] ${title}"
            echo "    Tags: ${tags}"
            echo "    File: ${file}"
            echo "    Relevance: ${score} term matches"
            echo ""

            # Update access count
            jq ".access_count += 1 | .last_accessed = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
        fi
    done
}

# ─────────────────────────────────────────────────────────
# Stats
# ─────────────────────────────────────────────────────────

cmd_stats() {
    echo "═══ Forge Memory ═══"
    echo ""

    local total=0
    for type in lessons patterns decisions context; do
        local dir="${MEMORY_DIR}/${type}"
        local count=0
        if [ -d "$dir" ]; then
            count=$(find "$dir" -name "*.json" -type f 2>/dev/null | wc -l)
        fi
        printf "  %-12s %d\n" "${type}:" "$count"
        total=$((total + count))
    done
    echo "  ────────────────"
    printf "  %-12s %d\n" "Total:" "$total"
    echo ""

    # Top tags
    if [ -f "$INDEX_FILE" ]; then
        echo "Top tags:"
        jq -r '.terms | to_entries | map({key: .key, count: (.value | length)}) | sort_by(-.count) | .[0:10] | .[] | "  \(.key) (\(.count))"' "$INDEX_FILE" 2>/dev/null || echo "  (index empty)"
        echo ""

        local last_indexed
        last_indexed=$(jq -r '.last_rebuilt // "never"' "$INDEX_FILE")
        echo "Last indexed: ${last_indexed}"
    fi

    # Stale count
    local stale=0
    local ninety_days_ago
    ninety_days_ago=$(date -u -d "90 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-90d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
    if [ -n "$ninety_days_ago" ]; then
        stale=$(find "$MEMORY_DIR" -name "*.json" -type f -exec jq -r "select(.last_accessed < \"${ninety_days_ago}\" or .last_accessed == null) | .id" {} \; 2>/dev/null | wc -l)
        echo "Stale (>90d unused): ${stale}"
    fi
}

# ─────────────────────────────────────────────────────────
# Rebuild Index
# ─────────────────────────────────────────────────────────

cmd_rebuild_index() {
    echo "Rebuilding memory index..."

    local tmp_index="/tmp/forge-index-$$.json"
    echo '{"terms":{}}' > "$tmp_index"

    local count=0
    find "$MEMORY_DIR" -name "*.json" -not -name "index.json" -type f 2>/dev/null | while read -r file; do
        local id
        id=$(jq -r '.id // empty' "$file" 2>/dev/null)
        if [ -z "$id" ]; then continue; fi

        # Extract tags
        local tags
        tags=$(jq -r '.tags[]? // empty' "$file" 2>/dev/null)
        for tag in $tags; do
            tag=$(echo "$tag" | tr '[:upper:]' '[:lower:]')
            # Add to index using jq
            jq --arg term "$tag" --arg id "$id" '.terms[$term] = ((.terms[$term] // []) + [$id] | unique)' "$tmp_index" > "${tmp_index}.new" && mv "${tmp_index}.new" "$tmp_index"
        done
        count=$((count + 1))
    done

    # Add metadata
    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson total "$count" \
        '.last_rebuilt = $ts | .total_entries = $total' "$tmp_index" > "$INDEX_FILE"
    rm -f "$tmp_index"

    echo "Indexed ${count} entries."
}

# ─────────────────────────────────────────────────────────
# Prune
# ─────────────────────────────────────────────────────────

cmd_prune() {
    echo "Pruning stale memories..."

    local archived=0
    local archive_dir="${MEMORY_DIR}/.archived"
    mkdir -p "$archive_dir"

    find "$MEMORY_DIR" -name "*.json" -not -name "index.json" -not -path "*/.archived/*" -type f 2>/dev/null | while read -r file; do
        local score
        score=$(jq -r '.usefulness_score // 1.0' "$file" 2>/dev/null)
        # Use awk for float comparison
        if echo "$score" | awk '{exit ($1 < 0.1) ? 0 : 1}'; then
            mv "$file" "$archive_dir/"
            archived=$((archived + 1))
            echo "  Archived: $(basename "$file")"
        fi
    done

    echo "Archived ${archived} stale memories."
    echo "Run 'forge-memory.sh rebuild-index' to update the index."
}

# ─────────────────────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────────────────────

case "${1:-}" in
    search)        cmd_search "${2:-}" ;;
    stats)         cmd_stats ;;
    rebuild-index) cmd_rebuild_index ;;
    prune)         cmd_prune ;;
    -h|--help)     usage ;;
    "")            usage ;;
    *)             echo "Unknown command: $1"; usage; exit 1 ;;
esac
