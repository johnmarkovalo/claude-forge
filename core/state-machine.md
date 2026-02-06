# Task State Machine

## States

| State | Description | Next States |
|-------|-------------|-------------|
| `created` | Task ID generated, checkpoint initialized | `classifying` |
| `classifying` | Running intent classifier | `routing`, `awaiting_clarification` |
| `awaiting_clarification` | Confidence too low, asked user for more info | `classifying` |
| `routing` | Mapping intent to pipeline + agents | `executing` |
| `executing` | Running a pipeline phase | `verifying`, `retrying`, `stopped` |
| `retrying` | Phase failed, preparing retry with changes | `executing`, `escalating`, `stopped` |
| `escalating` | Upgrading model tier for retry | `executing`, `stopped` |
| `verifying` | Running verification checks | `completed`, `retrying` |
| `completed` | All phases done, verified | (terminal) |
| `failed` | Max retries exceeded or circuit breaker tripped | (terminal) |
| `stopped` | User cancelled or budget exceeded | (terminal) |

## Transitions

```
created → classifying
  Action: Generate task ID, read configs, create checkpoint

classifying → routing
  Condition: confidence >= 0.6
  Action: Record intent in checkpoint

classifying → awaiting_clarification
  Condition: confidence < 0.6
  Action: Present clarification questions to user

awaiting_clarification → classifying
  Condition: User provides more info
  Action: Re-classify with additional context

routing → executing
  Action: Select pipeline, assign agents, record in checkpoint

executing → verifying
  Condition: Current phase completed successfully
  Action: Record phase output, advance to next phase or verify

executing → retrying
  Condition: Phase failed, retries remaining, budget available
  Action: Log failure, determine retry strategy

executing → stopped
  Condition: Budget exceeded or user cancelled
  Action: Save state for possible /resume

retrying → executing
  Condition: Same model tier retry (attempts 1-2)
  Action: Adjust strategy, re-run phase

retrying → escalating
  Condition: Attempts >= escalation threshold
  Action: Select higher model tier

retrying → stopped
  Condition: Circuit breaker tripped (3 consecutive failures)
  Action: Report full diagnostics, save checkpoint

escalating → executing
  Action: Re-run phase with upgraded model

escalating → stopped
  Condition: Already at highest tier (Opus) and max retries reached
  Action: Report failure, save checkpoint for manual intervention

verifying → completed
  Condition: All checks pass
  Action: Move checkpoint to completed, evaluate evolution, save memory

verifying → retrying
  Condition: Verification failed
  Action: Feed verification results back into execution phase
```

## Checkpoint Updates

Update the checkpoint file at EVERY state transition. The checkpoint must always reflect the current state so `/resume` works from any point.

Fields to update on each transition:
- `state`: Current state name
- `updated_at`: Current timestamp
- `current_phase`: Active pipeline phase
- `attempt`: Current attempt number
- `cost_total_usd`: Running cost total

## Cancel Handling

When user runs `/cancel` during execution:
1. Set state to `stopped`
2. Record which phase was in progress
3. Save checkpoint (do NOT delete it)
4. Report: what was completed, what was in progress, estimated cost so far
