# /resume

Continue a task from the last checkpoint.

## Usage
```
/resume                    # Resume most recent active task
/resume forge-20260206-001 # Resume specific task
```

## Behavior

1. Read `~/.claude-forge/SYSTEM.md`
2. Find the most recent checkpoint in `~/.claude-forge/checkpoints/active/`
   - If task ID is specified, load that specific checkpoint
   - If no active checkpoints exist, report "No active tasks to resume"
3. Display: task ID, current state, phase, what's completed, what remains
4. Re-read the outputs from completed phases (from checkpoint `phases_completed`)
5. Continue from the current phase and attempt number
6. Resume normal pipeline execution

## Key Behavior
- Do NOT re-run completed phases
- Re-inject completed phase outputs as context for the current phase
- Continue cost tracking from the checkpoint's `cost_total_usd`
