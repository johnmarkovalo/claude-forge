# Claude Forge

<h3 align="center">Structure over vibes. Evidence over assertions. Budgets over hope.</h3>

<p align="center">
  <strong>A multi-agent orchestration system for Claude Code with structured routing, cost controls, validated evolution, and observable state machines.</strong>
</p>

<p align="center">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://claude.ai"><img src="https://img.shields.io/badge/Claude-Code-blueviolet" alt="Claude Code"></a>
  <a href="#"><img src="https://img.shields.io/badge/v1.0.0-Opus%204.6-orange" alt="v1.0.0"></a>
  <a href="#agents"><img src="https://img.shields.io/badge/Agents-7-blue" alt="7 Agents"></a>
  <a href="#pipelines"><img src="https://img.shields.io/badge/Pipelines-5-green" alt="5 Pipelines"></a>
  <a href="#commands"><img src="https://img.shields.io/badge/Commands-8-brightgreen" alt="8 Commands"></a>
</p>

---

## What Happens When You Type `/forge`

```
You: "/forge add a password reset endpoint to the auth API"

Claude Forge:
  Phase 0  Setup        Generate task ID, load config, search memory
  Phase 1  Classify     domain=auth, action=create, complexity=moderate, confidence=0.91
  Phase 2  Route        pipeline=build-feature, skip=[document], budget=$3.00
  Phase 3  Execute
     ├─ analyst    (Opus)   → requirements, risks, relevant code
     ├─ architect  (Opus)   → implementation plan, file list, contracts
     ├─ implementer(Sonnet) → code changes
     └─ tester     (Sonnet) → run tests, paste actual output
  Phase 4  Verify       Evidence-based — ran it, tested it, proved it
  Phase 5  Complete     Checkpoint saved, memory updated, cost: $1.24

Every phase checkpointed. Every dollar tracked. Every claim proven.
```

---

## Why Claude Forge?

| Problem | What Typically Happens | What Forge Does |
|---------|----------------------|-----------------|
| Routing is unstructured | Claude guesses what to do | **Pattern-matching router** with 13 rules and fallback chain |
| Retries are a cost bomb | Blind retries, same approach | **5 meaningful retries** with model escalation policy |
| "Done" means nothing | "Should work" / "Looks correct" | **Evidence-based verification** — run it, test it, paste the output |
| Evolution is unvalidated | Auto-generated agents go straight to production | **Staged evolution** — staging, probation, then promotion |
| Sessions are lost | Context runs out, work disappears | **JSON checkpoints** after every phase, resumable with `/resume` |
| No cost visibility | No idea what you're spending | **Per-task budgets**, daily caps, per-agent cost tracking |
| No observability | Can't debug why routing failed | **Structured JSONL event log** with trace IDs |
| Memory is grep over files | No indexing, no relevance | **Indexed memory** with TF-IDF scoring and decay |

---

## Quick Start

```bash
# Clone the repo
git clone https://github.com/YOUR_USER/claude-forge.git ~/.claude-forge-src

# Copy system files
mkdir -p ~/.claude-forge
cp -r ~/.claude-forge-src/{core,agents,pipelines,commands,scripts,forge.json,SYSTEM.md} ~/.claude-forge/

# Create runtime directories
mkdir -p ~/.claude-forge/{agents/staging,agents/retired,memory,checkpoints/active,checkpoints/completed,logs}

# Make scripts executable
chmod +x ~/.claude-forge/scripts/*.sh

# Register slash commands with Claude Code
mkdir -p ~/.claude/commands
for f in ~/.claude-forge/commands/*.md; do ln -sf "$f" ~/.claude/commands/; done
```

Then open Claude Code in any project:

```bash
/forge add user authentication with JWT tokens
```

That's it. The system classifies, routes, executes, verifies, and reports.

---

## Commands

| Command | What It Does | Cost |
|---------|-------------|------|
| `/forge <task>` | Full pipeline: classify, route, execute, verify | Variable |
| `/plan <task>` | Classify + plan only — review approach before committing | Low |
| `/review [path]` | Standalone code review on files or staged changes | Low |
| `/resume [id]` | Continue from last checkpoint (survives session loss) | Variable |
| `/budget` | Today's cost summary, active tasks, budget remaining | Free |
| `/agents` | List and manage agents (stable, staging, retired) | Free |
| `/memory <cmd>` | Search or manage the knowledge store | Free |
| `/cancel` | Stop the current task | Free |

### Real Examples

```bash
# Simple — fast path, skips analysis and review
/forge fix the typo in the login error message

# Moderate — runs full pipeline minus documentation
/forge add pagination to the users API with cursor-based navigation

# Complex — full pipeline with all phases
/forge refactor the payment module to use the strategy pattern

# Plan first, execute later
/plan migrate the database from MySQL to PostgreSQL
# Review the plan, then:
/forge migrate the database from MySQL to PostgreSQL

# Code review
/review src/controllers/
/review                          # reviews staged git changes

# Resume after session loss
/resume                          # most recent active task
/resume forge-20260207-001       # specific task

# Cost tracking
/budget
```

---

## How Routing Works

Every request is classified before any work begins:

```
/forge "optimize the dashboard database queries"
         │
         ▼
  ┌─────────────────────────────────────────────┐
  │  INTENT CLASSIFIER                          │
  │  domain: database                           │
  │  action: optimize                           │
  │  complexity: moderate                       │
  │  confidence: 0.88                           │
  └─────────────┬───────────────────────────────┘
                │
                ▼
  ┌─────────────────────────────────────────────┐
  │  ROUTER (routes.json)                       │
  │  Match: action=optimize, domain=database    │
  │  Pipeline: refactor                         │
  │  Agents: analyst → architect → implementer  │
  │          → tester → reviewer                │
  │  Prefer evolved: db-optimizer (if staged)   │
  └─────────────┬───────────────────────────────┘
                │
                ▼
  ┌─────────────────────────────────────────────┐
  │  COST CONTROLLER                            │
  │  Budget: $3.00 (moderate)                   │
  │  Max retries: 4                             │
  │  Daily remaining: $37.60 / $50.00           │
  └─────────────────────────────────────────────┘
```

### Complexity-Based Routing

Different complexity levels take different paths through the pipeline:

| Complexity | Phases Run | Budget | Max Retries |
|------------|-----------|--------|-------------|
| **Trivial** | plan → execute | $0.50 | 2 |
| **Simple** | plan → execute → verify | $1.00 | 3 |
| **Moderate** | analyze → plan → execute → verify | $3.00 | 4 |
| **Complex** | analyze → plan → execute → verify → review → document | $7.00 | 5 |
| **Architectural** | All phases + user approval on plan | $10.00 | 5 |

If confidence is below 0.6, the system asks clarifying questions before proceeding.

---

## Agents

7 specialized agents with clear role boundaries:

```
┌────────────────────────────────────────────────────────┐
│                    AGENT HIERARCHY                     │
├────────────────────────────────────────────────────────┤
│                                                        │
│  OPUS TIER (Heavy — reasoning-intensive)               │
│  ├─ analyst     → Requirements, risks, codebase scan   │
│  ├─ architect   → System design, planning, trade-offs  │
│  ├─ reviewer    → Code review, security, performance   │
│  └─ debugger    → Root cause analysis, reproduction    │
│                                                        │
│  SONNET TIER (Standard — execution tasks)              │
│  ├─ implementer → Code generation, refactoring         │
│  └─ tester      → Verification with pasted evidence    │
│                                                        │
│  HAIKU TIER (Light — low-complexity output)             │
│  └─ documenter  → Docs, READMEs, inline comments       │
│                                                        │
└────────────────────────────────────────────────────────┘
```

Each agent has:
- **Defined scope** — what it does and what it must NOT do
- **Structured output** — JSON-compatible, not free prose
- **Quality bar** — specific criteria for "done"
- **Escalation triggers** — when to fail and retry

The implementer follows the architect's plan without redesigning. The tester pastes actual output, never assertions. The reviewer references specific `file:line` for every finding.

---

## Pipelines

5 execution templates, selected by the router based on intent:

### build-feature (default)

```
analyze (analyst)  →  plan (architect)  →  execute (implementer)
                                                │
                                           verify (tester)
                                           ┌────┘     │
                                           │    max 2  │
                                           │   loops   │
                                           ▼          ▼
                                      execute    review (reviewer)
                                                      │
                                                      ▼
                                                document (documenter)
```

### fix-bug

```
analyze (debugger)  →  plan (architect)  →  execute (implementer)  →  verify (tester)
   reproduce              optional             fix + test               confirm fix
   trace execution        skip if simple       errors → debugger        no regressions
```

### refactor

```
analyze (analyst)  →  plan (architect)  →  execute (implementer)  →  verify (tester)  →  review (reviewer)
   current state        each step leaves       step-by-step            behavior unchanged     assess improvement
   pain points          system working         test after each         performance same+      quality gate
```

### spike
```
analyze (analyst)  →  done
   research + recommendations, no code changes
```

### review
```
review (reviewer)  →  done
   standalone code review with severity categories
```

---

## Cost Controls

Every task has a budget. Every phase has a cost estimate. Every dollar is tracked.

### Budget Policy

```json
{
  "per_task_default": "$2.00",
  "per_task_max":     "$10.00",
  "daily_cap":        "$50.00",
  "warning_at":       "75%"
}
```

### Model Escalation (Not Blind Retries)

```
Attempt 1-2: Assigned tier (e.g., Sonnet for implementer)
Attempt 3:   Escalate one tier (Sonnet → Opus)
Attempt 4:   Opus + expanded context
Attempt 5:   Opus + alternative strategy
After 5:     STOP. Report failure with diagnostics. Ask user.
```

Each retry **must change something** — model, strategy, or context. No blind retries.

### Circuit Breaker

3 consecutive failures on the same phase → stop and report. Don't burn budget on a dead end.

### Tracking

```bash
/budget
```

```
═══ Forge Budget ═══

Today: $12.40 / $50.00 daily cap

Active tasks:
  forge-20260207-001     executing     $0.30 / $3.00

Recent completed:
  forge-20260207-000     $1.24  ✅
  forge-20260206-003     $0.48  ✅
```

---

## State Machine & Checkpoints

Every task moves through a 9-state machine with checkpointing after every transition:

```
CREATED → CLASSIFYING → ROUTING → EXECUTING → VERIFYING → COMPLETED
                                      │              │
                                      ▼              ▼
                                   RETRYING        FAILED
                                      │
                                      ▼
                                   ESCALATING
                                      │
                              ┌───────┴───────┐
                              ▼               ▼
                          EXECUTING        STOPPED
```

### Checkpoint Format

After every phase, state is written to `~/.claude-forge/checkpoints/active/{task-id}.json`:

```json
{
  "task_id": "forge-20260207-001",
  "state": "executing",
  "pipeline": "build-feature",
  "current_phase": "execute",
  "phases_completed": {
    "analyze": { "agent": "analyst", "cost_usd": 0.12 },
    "plan":    { "agent": "architect", "cost_usd": 0.18 }
  },
  "phases_remaining": ["execute", "verify"],
  "attempt": 1,
  "cost_total_usd": 0.30,
  "cost_budget_usd": 3.00,
  "files_created": [],
  "files_modified": []
}
```

Lost your session? `/resume` picks up exactly where you left off. No re-running completed phases.

---

## Memory System

Claude Forge remembers what worked and what didn't — across tasks and sessions.

```
┌────────────────────────────────────────────────┐
│              MEMORY SYSTEM                     │
├────────────────────────────────────────────────┤
│                                                │
│  AUTO-RECALL (on task start)                   │
│  ├─ Extract keywords from request              │
│  ├─ Search indexed memory (TF-IDF scored)      │
│  └─ Inject top 3 relevant memories into context │
│                                                │
│  AUTO-SAVE (on task complete)                  │
│  ├─ Succeeded after retries  → save as lesson  │
│  ├─ New pattern used         → save as pattern │
│  ├─ Architecture decision    → save as decision│
│  └─ New project domain       → save as context │
│                                                │
│  DECAY & PRUNING                               │
│  ├─ 90 days unused → usefulness score halved   │
│  ├─ Score < 0.1    → auto-archived             │
│  └─ 80% tag overlap → merge, don't duplicate   │
│                                                │
└────────────────────────────────────────────────┘
```

```bash
/memory search "rate limiting"
/memory stats
```

---

## Self-Evolution

When the system detects it's struggling in a domain, it proposes a specialized agent — but never deploys one automatically.

### How It Works

```
Task completes → Evaluate execution quality
                     │
                     ├─ Domain required > 2 retries?        → Capability gap
                     ├─ Same pattern failed 3+ times?       → Specialized agent needed
                     └─ User frequently overrides a phase?  → Pipeline adjustment needed
                     │
                     ▼
              Propose staging agent
              Write to agents/staging/
              Notify user:

[EVOLUTION] Proposed new agent: db-optimizer
  Reason: Database optimization tasks averaged 2.5 retries
  File: ~/.claude-forge/agents/staging/db-optimizer.md
  Promote with: /agents promote db-optimizer
```

### Evolution Lifecycle

```
DETECTION → PROPOSAL → STAGING → PROBATION → PROMOTION (or RETIREMENT)
```

| Stage | What Happens |
|-------|-------------|
| **Staging** | Agent written to `agents/staging/`, never to stable |
| **Probation** | Used alongside stable agent, metrics compared |
| **Promotion** | After 5 successful uses with better metrics → `/agents promote <name>` |
| **Retirement** | 3 consecutive failures or 30 days unused → moved to `agents/retired/` |

**Auto-promotion is off by default.** Only you decide what goes to production.

---

## Observability

Every event is appended to `~/.claude-forge/logs/events.jsonl`:

```json
{"ts":"...","event":"task_created","task_id":"forge-20260207-001","input":"add password reset..."}
{"ts":"...","event":"intent_classified","task_id":"forge-20260207-001","intent":{"domain":"auth","action":"create","complexity":"moderate"}}
{"ts":"...","event":"phase_started","task_id":"forge-20260207-001","phase":"analyze","agent":"analyst","model":"opus"}
{"ts":"...","event":"phase_completed","task_id":"forge-20260207-001","phase":"analyze","duration_sec":8,"cost_usd":0.12}
{"ts":"...","event":"model_escalated","task_id":"forge-20260207-001","from":"sonnet","to":"opus","reason":"2_consecutive_failures"}
{"ts":"...","event":"task_completed","task_id":"forge-20260207-001","total_cost_usd":1.24,"retries":1}
```

Query with the budget script:

```bash
~/.claude-forge/scripts/forge-budget.sh summary          # today's costs
~/.claude-forge/scripts/forge-budget.sh task <id>         # per-task breakdown
~/.claude-forge/scripts/forge-budget.sh agents 7          # cost by agent (7 days)
~/.claude-forge/scripts/forge-budget.sh failures 7        # recent failures
~/.claude-forge/scripts/forge-budget.sh trace <task-id>   # full event trace
```

---

## Evidence-Based Completion

Nothing is "done" without proof.

Every tester and reviewer agent must paste actual output:

```
## Verification

✓ Executed: npm run dev
  Output: Server running on localhost:3000

✓ Tests: npm test
  Result: 47 passed, 0 failed

✓ Features verified:
  - Password reset endpoint: src/controllers/auth.ts:142
  - Email service integration: src/services/email.ts:28
  - Token expiration: src/middleware/auth.ts:55
```

**Forbidden:**
- ~~"Should work"~~ → Must test it
- ~~"I think it's done"~~ → Must prove it
- ~~"Looks correct"~~ → Must run it

---

## Configuration

### Global Settings

Edit `~/.claude-forge/forge.json`:

```json
{
  "version": "1.0.0",
  "defaults": {
    "pipeline": "build-feature",
    "model_tier": "standard",
    "auto_verify": true,
    "auto_memory": true,
    "auto_evolve_propose": true,
    "auto_evolve_promote": false,
    "checkpoint_on_phase": true
  },
  "display": {
    "show_cost_after_task": true,
    "show_memory_matches": true,
    "show_phase_transitions": true,
    "verbose_events": false
  }
}
```

### Cost Policy

Edit `~/.claude-forge/core/cost-policy.json` for budgets, model pricing, and escalation rules.

### Routing Rules

Edit `~/.claude-forge/core/routes.json` to customize intent-to-pipeline mapping.

### Project-Level Integration

Optionally add to your project's `CLAUDE.md` for stack-aware routing:

```markdown
Read ~/.claude-forge/SYSTEM.md for orchestration commands.

## Project Context
- Stack: Node.js, Express, PostgreSQL
- Test runner: jest
- Linter: eslint
```

---

## Security Model

```
WRITE-ALLOWED:
  ~/.claude-forge/agents/staging/*     # Evolved agents (probationary)
  ~/.claude-forge/memory/*             # Memory entries
  ~/.claude-forge/checkpoints/*        # Task state
  ~/.claude-forge/logs/*               # Event logs
  ./ (your project directory)          # Actual code output

WRITE-BLOCKED (user confirmation required):
  ~/.claude-forge/agents/stable/*      # Production agents
  ~/.claude-forge/core/*               # System configuration
  ~/.claude-forge/pipelines/*          # Pipeline definitions
  ~/.claude-forge/SYSTEM.md            # Master prompt

NEVER-WRITE:
  ~/.claude/                           # Claude Code's own config
```

Staging agents run with read-only access to system config. No agent can invoke another agent directly — only the router can.

---

## File Structure

```
claude-forge/
├── forge.json                 # Global config (defaults, display)
├── SYSTEM.md                  # Master system prompt
├── CLAUDE.md                  # Project instructions
│
├── core/                      # Orchestration logic
│   ├── classifier.md          # Intent classification prompt
│   ├── state-machine.md       # 9-state task lifecycle
│   ├── cost-policy.json       # Budgets, model pricing, escalation
│   └── routes.json            # 13 routing rules (intent → pipeline)
│
├── agents/                    # Agent prompt templates
│   ├── _registry.json         # Agent metadata, tiers, capabilities
│   └── stable/                # 7 production agents
│       ├── analyst.md         # Requirements + risks (Opus)
│       ├── architect.md       # Design + planning (Opus)
│       ├── implementer.md     # Code execution (Sonnet)
│       ├── reviewer.md        # Code review (Opus)
│       ├── tester.md          # Verification (Sonnet)
│       ├── debugger.md        # Root cause analysis (Opus)
│       └── documenter.md      # Documentation (Haiku)
│
├── pipelines/                 # Execution templates
│   ├── _registry.json         # Pipeline metadata
│   ├── build-feature.md       # Full feature workflow (6 phases)
│   ├── fix-bug.md             # Bug fix flow (4 phases)
│   ├── refactor.md            # Refactoring flow (5 phases)
│   ├── review.md              # Code review (1 phase)
│   └── spike.md               # Research/exploration (1 phase)
│
├── commands/                  # Slash command definitions
│   ├── forge.md               # /forge — full pipeline
│   ├── plan.md                # /plan — classify + plan
│   ├── review.md              # /review — code review
│   ├── resume.md              # /resume — continue from checkpoint
│   ├── budget.md              # /budget — cost tracking
│   ├── cancel.md              # /cancel — stop task
│   ├── memory.md              # /memory — knowledge store
│   └── agents.md              # /agents — agent management
│
├── scripts/                   # Shell helpers
│   ├── forge-budget.sh        # Budget reporting (jq-based)
│   ├── forge-memory.sh        # Memory indexing and search
│   ├── forge-prune.sh         # Clean old checkpoints/logs
│   └── forge-export.sh        # Export config for team sharing
│
└── Runtime directories (created during install):
    ├── agents/staging/        # Evolved agents (probationary)
    ├── agents/retired/        # Failed agents
    ├── memory/                # Indexed knowledge store
    ├── checkpoints/active/    # In-progress task state
    ├── checkpoints/completed/ # Finished task state
    └── logs/                  # events.jsonl + evolution.jsonl
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      CLAUDE FORGE                        │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  /forge "your task"                                      │
│         │                                                │
│         ▼                                                │
│  ┌──────────────────────────────────────────┐            │
│  │  INTENT CLASSIFIER                       │            │
│  │  Extract: domain, action, complexity     │            │
│  │  Output: intent + confidence score       │            │
│  └──────────────┬───────────────────────────┘            │
│                 │                                        │
│         ▼                                                │
│  ┌──────────────────────────────────────────┐            │
│  │  COST CONTROLLER                         │            │
│  │  Check budget → select model tier        │            │
│  │  Set max retries from complexity         │            │
│  └──────────────┬───────────────────────────┘            │
│                 │                                        │
│         ▼                                                │
│  ┌──────────────────────────────────────────┐            │
│  │  ROUTER                                  │            │
│  │  Map intent → pipeline + agents          │            │
│  │  13 rules + fallback chain               │            │
│  └──────────────┬───────────────────────────┘            │
│                 │                                        │
│         ▼                                                │
│  ┌──────────────────────────────────────────┐            │
│  │  EXECUTION ENGINE                        │            │
│  │  State machine with 9 typed states       │            │
│  │  Checkpoint after every phase            │            │
│  │  Escalate on failure (max 5 attempts)    │            │
│  └──────────────┬───────────────────────────┘            │
│                 │                                        │
│         ▼                                                │
│  ┌──────────────────────────────────────────┐            │
│  │  VERIFICATION GATE                       │            │
│  │  Run tests, lint, type check             │            │
│  │  Evidence-based pass/fail                │            │
│  └──────────────┬───────────────────────────┘            │
│                 │                                        │
│         ▼                                                │
│  ┌──────────────────────────────────────────┐            │
│  │  EVOLUTION EVALUATOR                     │            │
│  │  Score execution quality                 │            │
│  │  Detect capability gaps                  │            │
│  │  Propose staging agents (never auto-deploy)│          │
│  └──────────────────────────────────────────┘            │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- `jq` installed (`brew install jq` / `apt install jq` / `choco install jq`)
- Bash 4+ (macOS: `brew install bash`)

---

## FAQ

<details>
<summary><strong>Do I need to configure anything per-project?</strong></summary>

No. The slash commands are global — they work in any project directory. Optionally, you can add stack context to your project's `CLAUDE.md` so the classifier makes better routing decisions.

</details>

<details>
<summary><strong>What if a task fails after 5 retries?</strong></summary>

The system stops, reports full diagnostics (what was tried, what failed, which models were used), and asks for your guidance. It does not keep burning budget on a dead end.

</details>

<details>
<summary><strong>Can I customize agents?</strong></summary>

Yes. Agent prompts are markdown files in `~/.claude-forge/agents/stable/`. Edit them directly, or create new agents in `agents/staging/` and promote them with `/agents promote <name>` after they prove themselves.

</details>

<details>
<summary><strong>Is the cost tracking accurate?</strong></summary>

It's an estimate. Claude Code doesn't expose token counts, so costs are calculated from average tokens per agent (tracked in the registry) and model rates. Reported as estimates, not actuals.

</details>

<details>
<summary><strong>What happens when I lose my session?</strong></summary>

Every phase writes a JSON checkpoint. Run `/resume` in a new session and it picks up exactly where you left off — completed phases are not re-run, their outputs are re-injected as context.

</details>

<details>
<summary><strong>Can I add my own pipelines?</strong></summary>

Yes. Create a markdown file in `~/.claude-forge/pipelines/` following the existing format (structured phase headers with agent assignments, skip conditions, and loop limits), then add a route in `core/routes.json` that points to it.

</details>

<details>
<summary><strong>What does this NOT solve?</strong></summary>

- **Still prompt-dependent** — quality depends on Claude following instructions; structured routing helps but doesn't guarantee execution quality
- **Cost estimation is approximate** — token counts are estimated, not measured
- **No true parallelism** — Claude Code executes sequentially; "parallel" phases are batched instructions
- **Evolution is slow** — meaningful evolution needs 10-20+ tasks in a domain to detect patterns
- **Memory search is keyword-based** — TF-IDF scoring, not semantic embeddings

</details>

---

## Design Decisions

### Why prompt-based orchestration?

Claude Code's extensibility is prompt-based. We work within that constraint but add structure: JSON for machine-readable rules (routing, costs, state), shell scripts for filesystem operations, and markdown for agent behavior. Structured data where we need precision, natural language where we need flexibility.

### Why 5 retries, not 10?

Each retry should be meaningfully different. 5 attempts covers: original tier (2), escalated tier (2), alternative strategy (1). If that doesn't work, the problem needs human input — not more money thrown at the same approach.

### Why staged evolution?

An unvalidated generated agent can poison routing for every future task in that domain. The staging → probation → promotion pipeline ensures evolved agents earn their place through measured performance, not hope.

### Why JSON checkpoints?

Markdown is human-readable but unreliably parseable. JSON checkpoints are reliably parseable for resume, diffable for debugging, queryable for metrics, and compact for storage. `/resume` renders them as human-readable output.

---

---

## License

MIT
