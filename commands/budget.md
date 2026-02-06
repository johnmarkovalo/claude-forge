# /budget

Show cost tracking and budget status.

## Usage
```
/budget                    # Show today's summary
/budget task <id>          # Show specific task costs
/budget agents             # Show cost by agent
```

## Behavior

1. Run `~/.claude-forge/scripts/forge-budget.sh` with the appropriate arguments
2. Parse and display the output
3. Show warnings if approaching limits

## Output Format
```
═══ Forge Budget ═══

Today:        $12.40 / $50.00 daily cap (24.8%)
Active task:  $0.30 / $3.00 (moderate) — forge-20260206-001

Recent tasks:
  forge-20260206-001  moderate  $0.30   (in progress)
  forge-20260205-003  complex   $4.20   ✅
  forge-20260205-002  simple    $0.45   ✅
  forge-20260205-001  trivial   $0.12   ✅

Top agents by cost (7d):
  architect    $8.40  (28 invocations)
  implementer  $6.20  (34 invocations)
  reviewer     $4.10  (15 invocations)
```
