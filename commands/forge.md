# /forge

Execute a full Claude Forge pipeline.

## Usage
```
/forge <task description>
```

## Behavior

1. Read `~/.claude-forge/SYSTEM.md` — this is your operating manual for this task
2. Follow the complete pipeline: classify → route → execute → verify
3. Checkpoint after every phase
4. Report results with cost estimate

## Examples
```
/forge add a password reset endpoint to the auth API
/forge fix the N+1 query in the dashboard controller
/forge refactor the payment module to use the strategy pattern
/forge create a user management CRUD with soft deletes
```

## Important
- Read SYSTEM.md FIRST before doing anything
- Always classify before acting
- Never skip verification for moderate+ complexity
- Checkpoint after every phase
