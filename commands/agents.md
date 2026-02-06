# /agents

Manage Claude Forge agents.

## Usage
```
/agents                        # List all agents with status
/agents promote <name>         # Promote staging agent to stable
/agents retire <name>          # Retire an agent
/agents info <name>            # Show agent details and stats
```

## Behavior

### /agents (list)
Read `~/.claude-forge/agents/_registry.json` and display:
```
═══ Forge Agents ═══

Stable (7):
  analyst      opus    2500 avg tokens   12 invocations   —
  architect    opus    3000 avg tokens   10 invocations   —
  implementer  sonnet  4000 avg tokens   15 invocations   —
  reviewer     opus    2000 avg tokens    8 invocations   —
  tester       sonnet  2500 avg tokens   12 invocations   —
  debugger     opus    2000 avg tokens    3 invocations   —
  documenter   haiku   1500 avg tokens    5 invocations   —

Staging (1):
  db-optimizer  opus   — proposed 2026-02-05   2 uses   awaiting promotion

Retired (0):
  (none)
```

### /agents promote <name>
1. Verify agent exists in `~/.claude-forge/agents/staging/`
2. Move file to `~/.claude-forge/agents/stable/`
3. Update `_registry.json`: set status to "stable"
4. Log evolution event

### /agents retire <name>
1. Move file to `~/.claude-forge/agents/retired/`
2. Update `_registry.json`: set status to "retired"
3. Log evolution event
