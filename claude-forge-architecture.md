# Claude Forge — Architecture & Design Document

> An improved multi-agent orchestration system for Claude Code with real routing logic, cost controls, validated evolution, and observable state machines.

---

## 1. Core Problems with vibe-claude (and what we fix)

| Problem | Root Cause | Our Fix |
|---|---|---|
| "Agents" are just prompt files | No runtime orchestration | **State machine** with typed transitions |
| Routing is vibes-based | No structured intent classification | **Pattern-matching router** with fallback chain |
| 10x retries = cost bomb | No budget or circuit breakers | **Cost controller** with per-task budgets and model escalation policy |
| Self-evolution is unvalidated | No quality gate on generated agents | **Evolution pipeline** with scoring, A/B testing, and pruning |
| Session state is a markdown file | No structured checkpointing | **Typed checkpoint system** with resumable state |
| No observability | Can't debug routing or failures | **Structured event log** with trace IDs |
| No security boundary | Arbitrary file writes to ~/.claude/ | **Sandbox + review gate** before agent activation |
| Memory is grep over files | No indexing, no relevance ranking | **Indexed memory** with TF-IDF scoring and decay |

---

## 2. System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         CLAUDE FORGE                                │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  User Input: /forge "build a REST API for user management"        │
│       │                                                           │
│       ▼                                                           │
│  ┌────────────────────────────────────────────┐                  │
│  │           INTENT CLASSIFIER                 │                  │
│  │  1. Pattern match against known intents     │                  │
│  │  2. Extract: domain, action, complexity     │                  │
│  │  3. Output: IntentResult + confidence       │                  │
│  └────────────────┬───────────────────────────┘                  │
│                   │                                               │
│       ▼                                                           │
│  ┌────────────────────────────────────────────┐                  │
│  │              COST CONTROLLER                │                  │
│  │  - Check remaining budget                   │                  │
│  │  - Select model tier for this task          │                  │
│  │  - Set max retries based on budget          │                  │
│  └────────────────┬───────────────────────────┘                  │
│                   │                                               │
│       ▼                                                           │
│  ┌────────────────────────────────────────────┐                  │
│  │               ROUTER                        │                  │
│  │  - Map intent → pipeline template           │                  │
│  │  - Select agents for each phase             │                  │
│  │  - Build execution DAG                      │                  │
│  └────────────────┬───────────────────────────┘                  │
│                   │                                               │
│       ▼                                                           │
│  ┌────────────────────────────────────────────┐                  │
│  │          EXECUTION ENGINE                   │                  │
│  │  - State machine per task                   │                  │
│  │  - Checkpoint after each phase              │                  │
│  │  - Retry with escalation policy             │                  │
│  │  - Emit structured events                   │                  │
│  └────────────────┬───────────────────────────┘                  │
│                   │                                               │
│       ▼                                                           │
│  ┌────────────────────────────────────────────┐                  │
│  │          VERIFICATION GATE                  │                  │
│  │  - Run automated checks (lint, test, type)  │                  │
│  │  - Critic agent reviews output              │                  │
│  │  - Evidence-based pass/fail                 │                  │
│  └────────────────┬───────────────────────────┘                  │
│                   │                                               │
│       ▼                                                           │
│  ┌────────────────────────────────────────────┐                  │
│  │         EVOLUTION EVALUATOR                 │                  │
│  │  - Score task execution (cost, retries,     │                  │
│  │    time, quality)                           │                  │
│  │  - Detect capability gaps                   │                  │
│  │  - Propose new agents → staging             │                  │
│  │  - Promote after N successful uses          │                  │
│  └────────────────────────────────────────────┘                  │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. File Structure

```
~/.claude-forge/
├── forge.json                    # Global config (budgets, defaults, model preferences)
├── SYSTEM.md                     # Master system prompt (loaded by Claude Code)
│
├── core/                         # Core orchestration logic (shell + prompt hybrids)
│   ├── router.md                 # Routing rules as structured prompt
│   ├── classifier.md             # Intent classification prompt
│   ├── cost-policy.json          # Model tier rules, budget limits
│   └── state-machine.md          # Task lifecycle definition
│
├── agents/                       # Agent prompt templates
│   ├── _registry.json            # Agent registry with metadata
│   ├── stable/                   # Production agents (validated)
│   │   ├── analyst.md
│   │   ├── architect.md
│   │   ├── implementer.md
│   │   ├── reviewer.md
│   │   ├── tester.md
│   │   ├── debugger.md
│   │   └── documenter.md
│   ├── staging/                  # Evolved agents (probationary)
│   │   └── *.md
│   └── retired/                  # Agents that failed validation
│       └── *.md
│
├── pipelines/                    # Execution pipeline templates
│   ├── _registry.json            # Pipeline registry
│   ├── build-feature.md          # Standard feature build
│   ├── fix-bug.md                # Bug fix flow
│   ├── refactor.md               # Refactoring flow
│   ├── review.md                 # Code review flow
│   ├── spike.md                  # Research/exploration
│   └── custom/                   # User-defined pipelines
│       └── *.md
│
├── commands/                     # Slash commands
│   ├── forge.md                  # /forge — main entry point
│   ├── plan.md                   # /plan — planning only
│   ├── review.md                 # /review — review only
│   ├── resume.md                 # /resume — continue from checkpoint
│   ├── budget.md                 # /budget — show cost status
│   ├── evolve.md                 # /evolve — manual evolution trigger
│   └── agents.md                 # /agents — list/manage agents
│
├── memory/                       # Indexed knowledge store
│   ├── index.json                # Search index (terms → file refs)
│   ├── lessons/                  # Failure → solution records
│   │   └── *.json
│   ├── patterns/                 # Reusable patterns
│   │   └── *.json
│   ├── decisions/                # Architecture decision records
│   │   └── *.json
│   └── context/                  # Project-specific context
│       └── *.json
│
├── checkpoints/                  # Task state persistence
│   ├── active/                   # Currently in-progress tasks
│   │   └── {task-id}.json
│   └── completed/                # Finished tasks (for evolution scoring)
│       └── {task-id}.json
│
├── logs/                         # Structured event logs
│   ├── events.jsonl              # Append-only event stream
│   └── evolution.jsonl           # Evolution-specific events
│
└── scripts/                      # Helper scripts
    ├── forge-init.sh             # First-time setup
    ├── forge-budget.sh           # Budget reporting
    ├── forge-memory.sh           # Memory indexing/search
    ├── forge-prune.sh            # Clean old checkpoints/logs
    └── forge-export.sh           # Export config for team sharing
```

---

## 4. Intent Classifier

The classifier replaces vibes-based routing with structured intent extraction.

### classifier.md (Prompt Template)

```markdown
# Intent Classifier

Analyze the user's request and extract structured intent.

## Output Format (JSON only)

{
  "domain": "api|ui|database|auth|testing|devops|refactor|docs|debug|other",
  "action": "create|modify|fix|delete|review|analyze|optimize|migrate",
  "complexity": "trivial|simple|moderate|complex|architectural",
  "entities": ["<specific things mentioned: files, endpoints, components>"],
  "constraints": ["<any mentioned constraints: timeline, tech, compatibility>"],
  "ambiguity": "none|low|medium|high",
  "clarification_needed": ["<questions to ask if ambiguity is high>"],
  "confidence": 0.0-1.0
}

## Complexity Heuristics

- **trivial**: Single file change, config update, typo fix
- **simple**: Single component/endpoint, well-defined scope
- **moderate**: Multiple files, some design decisions needed
- **complex**: Cross-cutting concerns, multiple components, testing strategy needed
- **architectural**: System-wide changes, new patterns, migration paths

## Rules

- If confidence < 0.6, set ambiguity to "high" and provide clarification questions
- Always extract entities even if incomplete
- Domain can be multiple (comma-separated) for cross-cutting tasks
```

### Routing Table

The router maps `(domain, action, complexity)` to a pipeline + agent set:

```json
{
  "routes": [
    {
      "match": { "action": "fix", "domain": "any" },
      "pipeline": "fix-bug",
      "agents": {
        "analyze": "debugger",
        "plan": "architect",
        "execute": "implementer",
        "verify": "tester"
      }
    },
    {
      "match": { "action": "create", "complexity": ["complex", "architectural"] },
      "pipeline": "build-feature",
      "agents": {
        "analyze": "analyst",
        "plan": "architect",
        "execute": "implementer",
        "review": "reviewer",
        "verify": "tester",
        "document": "documenter"
      }
    },
    {
      "match": { "action": "create", "complexity": ["trivial", "simple"] },
      "pipeline": "build-feature",
      "skip_phases": ["analyze", "review"],
      "agents": {
        "plan": "architect",
        "execute": "implementer",
        "verify": "tester"
      }
    },
    {
      "match": { "action": "review" },
      "pipeline": "review",
      "agents": {
        "review": "reviewer"
      }
    },
    {
      "match": { "action": "optimize", "domain": "database" },
      "pipeline": "refactor",
      "agents": {
        "analyze": "analyst",
        "plan": "architect",
        "execute": "implementer",
        "verify": "tester"
      },
      "prefer_evolved": ["db-optimizer"]
    }
  ],
  "fallback": {
    "pipeline": "build-feature",
    "agents": {
      "analyze": "analyst",
      "plan": "architect",
      "execute": "implementer",
      "verify": "tester"
    }
  }
}
```

Key improvement: **`prefer_evolved`** — the router checks staging agents first, falls back to stable if the evolved agent hasn't been promoted yet.

---

## 5. Agent Registry & Tiering

### _registry.json

```json
{
  "agents": {
    "analyst": {
      "file": "stable/analyst.md",
      "tier": "heavy",
      "model": "opus",
      "capabilities": ["root-cause-analysis", "requirement-extraction", "risk-assessment"],
      "avg_tokens": 2500,
      "success_rate": null
    },
    "architect": {
      "file": "stable/architect.md",
      "tier": "heavy",
      "model": "opus",
      "capabilities": ["system-design", "api-design", "schema-design", "trade-off-analysis"],
      "avg_tokens": 3000,
      "success_rate": null
    },
    "implementer": {
      "file": "stable/implementer.md",
      "tier": "standard",
      "model": "sonnet",
      "capabilities": ["code-generation", "refactoring", "integration"],
      "avg_tokens": 4000,
      "success_rate": null
    },
    "reviewer": {
      "file": "stable/reviewer.md",
      "tier": "heavy",
      "model": "opus",
      "capabilities": ["code-review", "security-audit", "performance-review"],
      "avg_tokens": 2000,
      "success_rate": null
    },
    "tester": {
      "file": "stable/tester.md",
      "tier": "standard",
      "model": "sonnet",
      "capabilities": ["test-generation", "test-execution", "edge-case-analysis"],
      "avg_tokens": 2500,
      "success_rate": null
    },
    "debugger": {
      "file": "stable/debugger.md",
      "tier": "heavy",
      "model": "opus",
      "capabilities": ["debugging", "stack-trace-analysis", "reproduction"],
      "avg_tokens": 2000,
      "success_rate": null
    },
    "documenter": {
      "file": "stable/documenter.md",
      "tier": "light",
      "model": "haiku",
      "capabilities": ["documentation", "readme", "api-docs", "comments"],
      "avg_tokens": 1500,
      "success_rate": null
    }
  },
  "tier_models": {
    "heavy": "claude-opus-4-5-20250514",
    "standard": "claude-sonnet-4-5-20250514",
    "light": "claude-haiku-4-5-20250514"
  }
}
```

### Model Escalation Policy

Instead of always using Opus, we start at the appropriate tier and escalate on failure:

```
Attempt 1-2: Assigned tier (e.g., Sonnet for implementer)
Attempt 3:   Escalate one tier (Sonnet → Opus)
Attempt 4:   Opus + expanded context (include analyzer output)
Attempt 5:   Opus + different strategy (router picks alternative pipeline)
After 5:     Stop. Report failure with diagnostics. Ask user.
```

Maximum 5 attempts, not 10. Each escalation is meaningful, not just "try again."

---

## 6. Cost Controller

### cost-policy.json

```json
{
  "budget": {
    "per_task_default_usd": 2.00,
    "per_task_max_usd": 10.00,
    "daily_cap_usd": 50.00,
    "warning_threshold_pct": 75
  },
  "model_costs_per_1k_tokens": {
    "claude-opus-4-5-20250514":   { "input": 0.015, "output": 0.075 },
    "claude-sonnet-4-5-20250514": { "input": 0.003, "output": 0.015 },
    "claude-haiku-4-5-20250514":  { "input": 0.0008, "output": 0.004 }
  },
  "escalation_rules": {
    "max_retries": 5,
    "escalate_after": 2,
    "cooldown_between_retries_sec": 3,
    "circuit_breaker": {
      "consecutive_failures": 3,
      "action": "stop_and_report"
    }
  },
  "complexity_budgets": {
    "trivial":        { "max_usd": 0.50,  "max_retries": 2 },
    "simple":         { "max_usd": 1.00,  "max_retries": 3 },
    "moderate":       { "max_usd": 3.00,  "max_retries": 4 },
    "complex":        { "max_usd": 7.00,  "max_retries": 5 },
    "architectural":  { "max_usd": 10.00, "max_retries": 5 }
  }
}
```

### Budget Tracking

Every agent invocation logs estimated cost:

```json
// appended to logs/events.jsonl
{
  "event": "agent_invocation",
  "task_id": "forge-20260206-001",
  "trace_id": "tr-abc123",
  "agent": "implementer",
  "model": "claude-sonnet-4-5-20250514",
  "phase": "execute",
  "attempt": 1,
  "est_input_tokens": 3200,
  "est_output_tokens": 4800,
  "est_cost_usd": 0.082,
  "cumulative_task_cost_usd": 0.234,
  "timestamp": "2026-02-06T14:30:00Z"
}
```

The `/budget` command reads this log and reports:

```
Task forge-20260206-001: $0.23 / $3.00 budget (moderate)
Today: $12.40 / $50.00 daily cap
Top cost agents: architect ($4.20), implementer ($3.80), reviewer ($2.10)
```

---

## 7. Task State Machine

Every `/forge` task follows a typed state machine with checkpointing.

### States

```
CREATED → CLASSIFYING → ROUTING → EXECUTING → VERIFYING → COMPLETED
                                      │              │
                                      ▼              ▼
                                   RETRYING      FAILED
                                      │
                                      ▼
                                   ESCALATING
                                      │
                              ┌───────┴───────┐
                              ▼               ▼
                          EXECUTING      STOPPED
```

### Checkpoint Schema

```json
{
  "task_id": "forge-20260206-001",
  "created_at": "2026-02-06T14:25:00Z",
  "updated_at": "2026-02-06T14:32:00Z",
  "state": "executing",
  "input": {
    "raw": "build a REST API for user management",
    "intent": {
      "domain": "api",
      "action": "create",
      "complexity": "moderate",
      "entities": ["REST API", "user management", "CRUD"],
      "confidence": 0.92
    }
  },
  "pipeline": "build-feature",
  "phase": "execute",
  "phases_completed": {
    "analyze": {
      "agent": "analyst",
      "model": "opus",
      "output_ref": "phases/analyze.md",
      "cost_usd": 0.12,
      "duration_sec": 8
    },
    "plan": {
      "agent": "architect",
      "model": "opus",
      "output_ref": "phases/plan.md",
      "cost_usd": 0.18,
      "duration_sec": 12
    }
  },
  "phases_remaining": ["execute", "verify"],
  "attempts": [
    {
      "phase": "execute",
      "attempt": 1,
      "agent": "implementer",
      "model": "sonnet",
      "status": "in_progress"
    }
  ],
  "cost_total_usd": 0.30,
  "cost_budget_usd": 3.00,
  "files_created": [],
  "files_modified": [],
  "memory_refs": ["lessons/api-auth-pattern-001.json"]
}
```

### Resume Flow (`/resume`)

```
1. Read latest checkpoint from checkpoints/active/
2. Display: "Resuming task {id} from phase {phase}, attempt {n}"
3. Reload phase outputs from phases_completed
4. Re-inject relevant context into agent prompt
5. Continue from current phase
```

No markdown work documents. Structured JSON checkpoints that can be reliably parsed.

---

## 8. Execution Pipelines

### Pipeline Definition Format

```markdown
# Pipeline: build-feature

## Phases

### 1. analyze (parallel-safe: true)
- **Agent**: analyst
- **Input**: user request + codebase context
- **Output**: requirements, risks, related code references
- **Skip if**: complexity is trivial

### 2. plan
- **Agent**: architect
- **Input**: analyst output + user request
- **Output**: implementation plan with file list, approach, and decision rationale
- **Approval**: auto (unless complexity is architectural → ask user)

### 3. execute
- **Agent**: implementer
- **Input**: plan output
- **Output**: code changes (files created/modified)
- **Parallel**: split by independent file groups if plan allows

### 4. verify
- **Agent**: tester
- **Input**: code changes + plan
- **Checks**:
  - [ ] Code runs without errors
  - [ ] Tests pass (if tests exist or were generated)
  - [ ] Linting passes
  - [ ] Type checking passes (if applicable)
- **Evidence required**: actual command output, not assertions

### 5. review (skip if: complexity < moderate)
- **Agent**: reviewer
- **Input**: code changes + plan + verify results
- **Output**: pass/fail with specific issues
- **On fail**: return to execute phase with review feedback

### 6. document (skip if: complexity < complex)
- **Agent**: documenter
- **Input**: code changes + plan
- **Output**: updated docs, README changes, inline comments
```

### Pipeline Execution Rules

1. **Phases are sequential by default** unless marked `parallel-safe`
2. **Skip conditions** are evaluated at runtime based on intent classification
3. **Review failures** loop back to execute (max 2 review loops, then stop)
4. **Each phase produces a typed output** stored in the checkpoint
5. **User approval gates** can be inserted at any phase via config

---

## 9. Evolution Pipeline

The key architectural improvement: evolution is a staged pipeline, not fire-and-forget.

### Evolution Lifecycle

```
DETECTION → PROPOSAL → STAGING → PROBATION → PROMOTION (or RETIREMENT)
```

### Stage 1: Detection

After each task completion, the evaluator scores execution quality:

```json
{
  "task_id": "forge-20260206-001",
  "scores": {
    "cost_efficiency": 0.7,
    "retry_count": 2,
    "total_attempts": 3,
    "verification_pass_rate": 0.8,
    "time_to_complete_sec": 45,
    "user_satisfaction": null
  },
  "gaps_detected": [
    {
      "type": "repeated_failure",
      "domain": "database",
      "pattern": "query optimization",
      "frequency": 3,
      "avg_retries": 2.5
    }
  ]
}
```

### Gap Detection Rules

| Signal | Threshold | Action |
|---|---|---|
| Same domain fails 3+ times | retries > 2 avg | Propose specialized agent |
| Same pattern succeeds but is slow | cost > 2x budget | Propose optimized prompt |
| New domain encountered | no matching agent capability | Propose domain agent |
| User frequently overrides a phase | override_count > 3 | Propose pipeline adjustment |

### Stage 2: Proposal

The system generates a candidate agent and writes it to `agents/staging/`:

```json
{
  "proposed_agent": "db-optimizer",
  "reason": "3 database optimization tasks averaged 2.5 retries with generic analyst",
  "based_on": "analyst",
  "specializations": [
    "PostgreSQL query plan analysis",
    "Index recommendation",
    "N+1 query detection"
  ],
  "file": "staging/db-optimizer.md",
  "created_at": "2026-02-06T15:00:00Z",
  "status": "staging"
}
```

### Stage 3: Probation

Staging agents are used when the router's `prefer_evolved` matches, but:

- They run **alongside** the stable agent (shadow mode for first 2 uses)
- Their output is **compared** against the stable agent's output
- Metrics are tracked per-agent in the registry

### Stage 4: Promotion or Retirement

```
After 5 successful uses with better metrics than stable:
  → Move to agents/stable/, update registry

After 3 uses with worse metrics than stable:
  → Move to agents/retired/, log reason

After 30 days with < 3 uses:
  → Move to agents/retired/ (unused)
```

### Evolution Safety

- **Staging agents cannot modify system files** — they only produce output
- **Promotion requires explicit user confirmation** via `/agents promote <name>`
- **Auto-promotion** can be enabled in config but is off by default
- **All evolution events are logged** to `logs/evolution.jsonl`

---

## 10. Memory System

### Indexed Storage (No External Dependencies)

Each memory entry is a JSON file with metadata for indexing:

```json
{
  "id": "lesson-20260206-001",
  "type": "lesson",
  "title": "Laravel API rate limiting with Redis",
  "tags": ["laravel", "api", "rate-limiting", "redis"],
  "content": "When implementing rate limiting on Laravel 11 APIs...",
  "context": {
    "project": "acme-api",
    "domain": "api",
    "stack": ["laravel", "redis"]
  },
  "source_task": "forge-20260205-003",
  "created_at": "2026-02-05T16:00:00Z",
  "last_accessed": "2026-02-06T14:00:00Z",
  "access_count": 3,
  "usefulness_score": 0.85
}
```

### Search Index (index.json)

Built by `forge-memory.sh` after each write:

```json
{
  "terms": {
    "laravel": ["lesson-20260206-001", "pattern-20260201-003"],
    "rate-limiting": ["lesson-20260206-001"],
    "redis": ["lesson-20260206-001", "decision-20260203-001"],
    "api": ["lesson-20260206-001", "pattern-20260201-003", "context-20260204-001"]
  },
  "last_rebuilt": "2026-02-06T15:00:00Z",
  "total_entries": 47
}
```

### Retrieval Algorithm

```
1. Extract keywords from current task intent
2. Look up terms in index.json → candidate set
3. Score candidates:
   - Term overlap (TF-IDF style)   × 0.4
   - Recency (exponential decay)   × 0.3
   - Access count / usefulness      × 0.2
   - Domain match                   × 0.1
4. Return top 3 memories, inject into agent context
```

### Auto-Save Rules

| Trigger | Memory Type | Condition |
|---|---|---|
| Task succeeded after retry | `lesson` | retries > 1 |
| New tech/pattern used | `pattern` | agent introduced unfamiliar approach |
| Architecture decision made | `decision` | architect agent produced trade-off analysis |
| New project detected | `context` | no existing context for this directory |

### Deduplication

Before saving, compute tag overlap with existing memories of same type. If overlap > 80%, merge instead of creating new entry.

### Decay & Pruning

- Memories not accessed in 90 days get `usefulness_score` reduced by 50%
- Memories with `usefulness_score < 0.1` are auto-archived
- `/forge prune-memory` runs manual cleanup

---

## 11. Observability & Event Log

### Event Schema

All events are appended to `logs/events.jsonl`:

```json
{"ts":"2026-02-06T14:25:00Z","event":"task_created","task_id":"forge-20260206-001","input":"build REST API..."}
{"ts":"2026-02-06T14:25:01Z","event":"intent_classified","task_id":"forge-20260206-001","intent":{"domain":"api","action":"create","complexity":"moderate","confidence":0.92}}
{"ts":"2026-02-06T14:25:01Z","event":"route_selected","task_id":"forge-20260206-001","pipeline":"build-feature","agents":{"analyze":"analyst","plan":"architect","execute":"implementer","verify":"tester"}}
{"ts":"2026-02-06T14:25:02Z","event":"phase_started","task_id":"forge-20260206-001","phase":"analyze","agent":"analyst","model":"opus"}
{"ts":"2026-02-06T14:25:10Z","event":"phase_completed","task_id":"forge-20260206-001","phase":"analyze","duration_sec":8,"cost_usd":0.12}
{"ts":"2026-02-06T14:25:30Z","event":"phase_failed","task_id":"forge-20260206-001","phase":"execute","attempt":1,"reason":"type_error","will_retry":true}
{"ts":"2026-02-06T14:25:31Z","event":"model_escalated","task_id":"forge-20260206-001","from":"sonnet","to":"opus","reason":"2_consecutive_failures"}
{"ts":"2026-02-06T14:26:00Z","event":"task_completed","task_id":"forge-20260206-001","total_cost_usd":1.24,"total_duration_sec":60,"retries":1}
```

### Queryable via Script

```bash
# Show all failures today
forge-budget.sh failures --today

# Show cost breakdown by agent
forge-budget.sh cost-by-agent --last 7d

# Show evolution events
forge-budget.sh evolution --last 30d

# Trace a specific task
forge-budget.sh trace forge-20260206-001
```

---

## 12. Security Model

### File Access Boundaries

```
WRITE-ALLOWED:
  ~/.claude-forge/agents/staging/*        # Evolved agents (probationary only)
  ~/.claude-forge/memory/*                # Memory entries
  ~/.claude-forge/checkpoints/*           # Task state
  ~/.claude-forge/logs/*                  # Event logs
  ./  (project directory)          # Actual code output

WRITE-BLOCKED (without explicit user confirmation):
  ~/.claude-forge/agents/stable/*         # Production agents
  ~/.claude-forge/core/*                  # System configuration
  ~/.claude-forge/pipelines/*             # Pipeline definitions
  ~/.claude-forge/SYSTEM.md               # Master prompt
  ~/.claude-forge/forge.json              # Global config

NEVER-WRITE:
  ~/.claude/                       # Don't touch Claude Code's own config
  ~/.*                             # No dotfile modifications outside ~/.claude-forge/
```

### Agent Sandboxing

- Staging agents run with **read-only** access to system config
- Agent prompts cannot include `bash` execution directives
- All agent outputs are **strings** — they propose changes, the execution engine applies them
- No agent can invoke another agent directly — only the router/engine can

### Review Gates

```
Evolution proposal     → logged, user notified via /agents list
Agent promotion        → requires /agents promote <name>
Pipeline modification  → requires manual file edit
Config changes         → requires manual file edit
```

---

## 13. Commands

| Command | Description | Cost |
|---|---|---|
| `/forge <task>` | Full pipeline: classify → route → execute → verify | Variable |
| `/plan <task>` | Classify + architect only (no execution) | Low |
| `/review [files]` | Code review on specified files or staged changes | Low |
| `/resume` | Continue from last checkpoint | Variable |
| `/budget` | Show cost tracking: task, daily, per-agent | Free |
| `/agents` | List agents (stable, staging, retired) with stats | Free |
| `/agents promote <name>` | Promote staging agent to stable | Free |
| `/agents retire <name>` | Retire an agent | Free |
| `/memory search <query>` | Search memory index | Free |
| `/memory stats` | Show memory counts, top tags, staleness | Free |
| `/forge prune` | Clean old checkpoints, logs, stale memory | Free |
| `/forge export` | Export config for team sharing (excludes memory) | Free |

---

## 14. Key Design Decisions

### Why not a real programming language for orchestration?

Claude Code's extensibility is prompt-based. We work within that constraint but add structure:
- JSON configs for machine-readable rules (routing, costs, registry)
- Shell scripts for operations that need filesystem interaction
- Markdown prompts for agent behavior (what Claude Code actually reads)

The hybrid approach gives us **structured data where we need precision** (routing, budgets, state) and **natural language where we need flexibility** (agent behavior, pipeline descriptions).

### Why 5 retries instead of 10?

Each retry should be **meaningfully different** (escalated model, different strategy, expanded context). Blind retries waste money. 5 attempts with escalation policy cover: original tier (2), escalated tier (2), alternative strategy (1). If that doesn't work, the problem needs human input.

### Why staged evolution instead of immediate deployment?

Unvalidated prompt generation is the biggest risk in vibe-claude. A bad evolved agent can poison routing for every future task in that domain. The staging → probation → promotion pipeline ensures evolved agents earn their place through measured performance.

### Why JSON checkpoints instead of markdown work files?

Markdown is human-readable but machine-unparseable in edge cases. JSON checkpoints are:
- Reliably parseable for resume
- Diffable for debugging
- Queryable for metrics
- Compact for storage

The `/resume` command renders checkpoint state as human-readable output — best of both worlds.

---

## 15. Migration from vibe-claude

```bash
# 1. Install forge
git clone <repo> ~/.claude-forge-src
~/.claude-forge-src/scripts/forge-init.sh

# 2. Import existing vibe agents (optional)
~/.claude-forge-src/scripts/migrate-vibe.sh ~/.claude/agents/ ~/.claude-forge/agents/staging/
# All imported agents go to staging — they must earn promotion

# 3. Import memory (optional)
~/.claude-forge-src/scripts/migrate-memory.sh ~/.claude/.vibe/memory/ ~/.claude-forge/memory/

# 4. Add to Claude Code
# In your project's CLAUDE.md or ~/.claude/CLAUDE.md:
# Include: ~/.claude-forge/SYSTEM.md
```

---

## 16. What This Doesn't Solve

Transparency about limitations:

- **Still prompt-dependent**: Quality of output depends on Claude's ability to follow complex instructions. Structured routing helps but doesn't guarantee execution quality.
- **Cost estimation is approximate**: Token counts are estimated, not measured from API responses (Claude Code doesn't expose this).
- **No true parallelism**: Claude Code executes sequentially. "Parallel" phases are batched instructions, not concurrent processes.
- **Evolution is slow**: Meaningful evolution requires enough task volume to detect patterns (minimum ~10-20 tasks in a domain).
- **Memory search is keyword-based**: Without embeddings, semantic search is limited. TF-IDF scoring is a pragmatic middle ground.
