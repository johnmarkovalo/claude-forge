# Pipeline: build-feature

The default pipeline for creating or modifying features.

## Phases

### 1. analyze
- **Agent:** analyst
- **Input:** User request + codebase context
- **Output:** Requirements, risks, relevant code, constraints
- **Skip if:** complexity is `trivial` or `simple`

### 2. plan
- **Agent:** architect
- **Input:** Analyst output (if available) + user request
- **Output:** Implementation plan with steps, contracts, constraints
- **Approval gate:** If complexity is `architectural`, present plan to user and wait for confirmation before proceeding.

### 3. execute
- **Agent:** implementer
- **Input:** Architect plan
- **Output:** Code changes (files created/modified)
- **On failure:** Retry with escalation policy

### 4. verify
- **Agent:** tester
- **Input:** Code changes + plan verification criteria
- **Output:** Test results with evidence
- **Skip if:** complexity is `trivial`
- **On failure:** Return to execute phase with failure details (max 2 verify→execute loops)

### 5. review
- **Agent:** reviewer
- **Input:** Code changes + plan + verification results
- **Output:** Pass/fail with findings
- **Skip if:** complexity is `trivial`, `simple`, or `moderate`
- **On FAIL verdict:** Return to execute phase with review feedback (max 1 review loop)

### 6. document
- **Agent:** documenter
- **Input:** Code changes + plan
- **Output:** Documentation updates
- **Skip if:** complexity is `trivial`, `simple`, or `moderate`

## Loop Limits

| Loop | Max Iterations | On Exceed |
|------|---------------|-----------|
| verify → execute | 2 | Report failure, ask user |
| review → execute | 1 | Report review findings, proceed with notes |

## Phase Dependencies

```
analyze ──→ plan ──→ execute ──→ verify ──→ review ──→ document
                        ↑           │         │
                        └───────────┘         │
                        ↑                     │
                        └─────────────────────┘
```
