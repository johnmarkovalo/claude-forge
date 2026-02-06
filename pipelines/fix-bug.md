# Pipeline: fix-bug

Targeted pipeline for diagnosing and fixing bugs.

## Phases

### 1. analyze
- **Agent:** debugger
- **Input:** User's bug report + error output + relevant code
- **Output:** Root cause analysis with evidence and proposed fix
- **This phase is always required** — never skip diagnosis

### 2. plan
- **Agent:** architect
- **Input:** Debugger's root cause analysis
- **Output:** Fix plan (minimal, targeted — not a rewrite)
- **Skip if:** debugger's proposed fix is simple and self-contained (single file, < 20 lines changed)

### 3. execute
- **Agent:** implementer
- **Input:** Fix plan (or debugger's proposed fix if plan was skipped)
- **Output:** Code changes
- **On failure:** Retry with escalation — feed the error back to debugger for re-analysis

### 4. verify
- **Agent:** tester
- **Input:** Code changes + original bug reproduction steps
- **Output:** Verification that bug is fixed AND no regressions
- **Required checks:**
  - [ ] Original bug no longer reproduces
  - [ ] Related functionality still works
  - [ ] Existing tests still pass

## Loop Limits

| Loop | Max Iterations | On Exceed |
|------|---------------|-----------|
| verify → debugger re-analysis | 2 | Report with full diagnostics |

## Key Difference from build-feature
The first phase uses `debugger` instead of `analyst`. The debugger reproduces the issue first, traces execution, and identifies root cause before any planning happens. This prevents "fix the symptom" patches.
