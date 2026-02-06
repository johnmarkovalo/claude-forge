# Pipeline: refactor

For optimization, cleanup, and restructuring without changing behavior.

## Phases

### 1. analyze
- **Agent:** analyst
- **Input:** User request + target code
- **Output:** Current state assessment, pain points, dependencies, blast radius

### 2. plan
- **Agent:** architect
- **Input:** Analysis output
- **Output:** Refactoring strategy with ordered steps, ensuring each step keeps the system working
- **Key constraint:** Every intermediate step must leave the codebase in a working state

### 3. execute
- **Agent:** implementer
- **Input:** Refactoring plan
- **Output:** Code changes, applied step by step
- **Rule:** Run tests after each step. If tests break, fix before proceeding.

### 4. verify
- **Agent:** tester
- **Input:** All code changes
- **Output:** Confirmation that behavior is unchanged
- **Required checks:**
  - [ ] All existing tests pass
  - [ ] No behavioral changes (same inputs → same outputs)
  - [ ] Performance is same or better (if applicable)

### 5. review
- **Agent:** reviewer
- **Input:** Changes + verification results
- **Output:** Assessment of whether the refactoring actually improved things
