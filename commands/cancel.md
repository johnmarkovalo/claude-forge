# /cancel

Stop the current Forge task.

## Usage
```
/cancel
```

## Behavior
1. Set current task state to `stopped`
2. Save checkpoint (do NOT delete)
3. Report: what was completed, what was in progress, cost so far
4. The task can be resumed later with `/resume`
