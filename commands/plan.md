# /plan

Run only the classification and planning phases — no execution.

## Usage
```
/plan <task description>
```

## Behavior

1. Read `~/.claude-forge/SYSTEM.md`
2. Classify the intent
3. Route to a pipeline
4. Run the analyze phase (if applicable)
5. Run the plan phase
6. Present the plan to the user — do NOT execute

## Use Cases
- Review the approach before committing
- Get a cost/complexity estimate
- Discuss trade-offs before building
- Architecture planning sessions

## Output
Present the architect's plan and ask: "Ready to execute? Run `/forge` with the same task to proceed."
