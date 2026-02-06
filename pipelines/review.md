# Pipeline: review

Standalone code review — no implementation, just assessment.

## Phases

### 1. review
- **Agent:** reviewer
- **Input:** Files to review (from user, staged changes, or specified paths)
- **Output:** Full review with findings categorized by severity

## Notes
- This is a single-phase pipeline
- No implementation or fixes are applied
- If the user wants fixes, they should run `/forge fix ...` after reviewing findings
