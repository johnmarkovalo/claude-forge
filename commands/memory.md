# /memory

Manage Claude Forge's knowledge memory.

## Usage
```
/memory search <query>     # Search memories by keyword
/memory stats              # Show memory statistics
/memory save <type> <title> # Manually save a memory
/memory prune              # Remove stale/low-value memories
```

## Behavior

### /memory search <query>
Run `~/.claude-forge/scripts/forge-memory.sh search "<query>"`
Display matching memories ranked by relevance.

### /memory stats
Run `~/.claude-forge/scripts/forge-memory.sh stats`
```
═══ Forge Memory ═══

Total entries: 47
  Lessons:    18
  Patterns:   12
  Decisions:   9
  Context:     8

Top tags: laravel (12), api (10), auth (8), database (7), react (5)
Stale (>90d unused): 3
Last indexed: 2026-02-06T15:00:00Z
```

### /memory save <type> <title>
Create a memory entry from the current conversation context.
Types: `lesson`, `pattern`, `decision`, `context`

### /memory prune
Archive memories with `usefulness_score < 0.1`
Report how many archived.
