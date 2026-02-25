# The Workflow Engine — Stages, Gates & Rules

> **Reading order:** File 4 of 9. Previous: [02-context-system.md](./02-context-system.md) | Next: [04-task-management.md](./04-task-management.md)

---

## Critical Rules (Enforced Across All Agents)

These rules are declared in every agent's definition and override all other considerations:

| Rule | ID | Enforcement |
|------|----|-------------|
| **Approval Gate** | `approval_gate` | Request approval before ANY write/edit/bash/task execution. Read/list ops don't require approval. |
| **Stop on Failure** | `stop_on_failure` | STOP on test fail/build errors — NEVER auto-fix without approval. |
| **Report First** | `report_first` | On fail: REPORT -> PROPOSE FIX -> REQUEST APPROVAL -> FIX (never auto-fix). |
| **Confirm Cleanup** | `confirm_cleanup` | Confirm before deleting session files or cleanup operations. |
| **Incremental Execution** | `incremental_execution` | (OpenCoder only) Implement ONE step at a time, validate each step before proceeding. |

### Execution Priority Tiers

When rules conflict, higher tiers always win:

| Tier | Description | Examples |
|------|-------------|---------|
| **Tier 1** | Safety & Approval Gates | Context loading, approval gates, permission checks |
| **Tier 2** | Core Workflow | Stage progression, delegation routing |
| **Tier 3** | Optimization | Minimal session overhead, context discovery |

**Edge cases:**
- Question needs bash (e.g., `ls`) -> Tier 1 applies (approval required)
- Question is purely informational -> Skip approval
- Context loading vs. speed -> Tier 1 wins (context is mandatory)

---

## OpenAgent Workflow (6 Stages)

Defined in [`agent/core/openagent.md`](../../.opencode/agent/core/openagent.md).

### Two Execution Paths

| Path | Trigger | Approval Required |
|------|---------|-------------------|
| **Conversational** | Pure question, no execution needed | No |
| **Task** | Needs bash/write/edit/task | Yes |

### Stage Diagram

```
Stage 1: Analyze
  Classify request: conversational or task?
      |
      |-- Conversational --> Answer directly (no approval needed)
      |
      |-- Task path:
          |
          v
Stage 1.5: Discover
  ContextScout finds relevant context files
  ExternalScout fetches live docs (if external packages detected)
      |
      v
Stage 2: Approve
  Present plan based on discovered context
  Wait for user confirmation
  (NEVER skip this gate)
      |
      v
Stage 3: Execute
  3.0 LoadContext: Read mandatory context files for task type
  3.1 Route: Delegate to specialist OR execute directly
  3.1b ExecuteParallel: Batch execution (if TaskManager created tasks)
  3.2 Run: Execute with context applied
      |
      v
Stage 4: Validate
  Check quality, verify completeness, test if applicable
  ON FAILURE: STOP -> Report -> Propose fix -> Request approval
      |
      v
Stage 5: Summarize
  Brief for simple tasks, formal for complex
      |
      v
Stage 6: Confirm & Cleanup
  Ask if satisfactory
  Offer to clean .tmp/ session files
```

### Delegation Decision

OpenAgent evaluates delegation criteria before executing:

**Delegate when:**
- 4+ files affected (`scale`)
- Specialized knowledge needed (`expertise`)
- Multi-component review (`review`)
- Multi-step dependencies (`complexity`)
- Fresh perspective needed (`perspective`)
- Edge case testing (`simulation`)
- User explicitly requests it (`user_request`)

**Execute directly when:**
- Single file, simple change
- Straightforward enhancement
- Clear bug fix

---

## OpenCoder Workflow (6 Stages)

Defined in [`agent/core/opencoder.md`](../../.opencode/agent/core/opencoder.md). Adds session management and parallel execution.

### Stage Diagram

```
Stage 1: Discover (read-only, no files created)
  Call ContextScout to discover relevant project context
  Call ExternalScout for external packages (if detected)
  Check for install scripts
  Output: mental model + list of context file paths
      |
      v
Stage 2: Propose (lightweight summary, no files created)
  Present summary to user:
    What: 1-2 sentence description
    Components: list of functional units
    Approach: direct execution | delegate to TaskManager
    Context discovered: paths from ContextScout
    External docs: ExternalScout fetches needed
  Wait for approval
      |
      v
Stage 3: Init Session (first file writes, only after approval)
  Create: .tmp/sessions/{YYYY-MM-DD}-{task-slug}/
  Read: code-quality standards (MANDATORY)
  Write: context.md (single source of truth for all downstream agents)
    Contains: request, context files, reference files, external docs,
              components, constraints, exit criteria
      |
      v
Stage 4: Plan (TaskManager creates task JSONs)
  Decision: Do we need TaskManager?
    Simple (1-3 files, <30min) --> Skip, execute directly in Stage 5
    Complex (4+ files, >60min) --> Delegate to TaskManager
  TaskManager creates: .tmp/tasks/{feature}/task.json + subtask_NN.json
  Present task plan to user for confirmation
      |
      v
Stage 5: Execute (parallel batch execution)
  5.0 Analyze task structure, build dependency graph
  5.1 Group into batches by dependency satisfaction
  5.2 Execute one batch at a time:
      - 1-4 parallel tasks: Direct delegation to CoderAgents
      - 5+ parallel tasks: Delegate to BatchExecutor
      - Single/sequential: Direct delegation
  5.3 Integrate batches, verify cross-batch dependencies
      |
      v
Stage 6: Validate & Handoff
  Run full system integration tests
  Suggest TestEngineer or CodeReviewer if not already run
  Summarize what was built
  Ask user to clean up .tmp/ session and task files
```

### Session Context File

The `context.md` file created in Stage 3 is the **single source of truth** for all downstream agents:

```markdown
# Task Context: User Authentication

Session ID: 2026-02-25-user-auth
Created: 2026-02-25T10:00:00Z
Status: in_progress

## Current Request
Create a user authentication system with JWT tokens

## Context Files (Standards to Follow)
- .opencode/context/core/standards/code-quality.md
- .opencode/context/core/standards/security-patterns.md

## Reference Files (Source Material to Look At)
- src/middleware/auth.ts
- package.json

## External Docs Fetched
- Better Auth: setup and configuration

## Components
- Auth service, JWT middleware, login endpoint

## Constraints
- Must use existing database schema

## Exit Criteria
- [ ] JWT tokens signed with RS256
- [ ] Login/logout endpoints working
- [ ] Tests passing
```

This file is what TaskManager, CoderAgent, TestEngineer, and CodeReviewer all read.

---

## CoderAgent Self-Review Loop

Before signaling completion, [CoderAgent](../../.opencode/agent/subagents/code/coder-agent.md) runs a **mandatory 4-check self-review**:

| Check | What It Verifies |
|-------|------------------|
| **Type & Import Validation** | Mismatched signatures, missing imports/exports, circular deps |
| **Anti-Pattern Scan** | `console.log`, `TODO`/`FIXME`, hardcoded secrets, missing error handling, `any` types |
| **Acceptance Criteria** | Every criterion from the subtask JSON is met |
| **ExternalScout Verification** | Usage matches documented API (if external libs used) |

**Output format:**
```
Self-Review: OK Types clean | OK Imports verified | OK No debug artifacts | OK All acceptance criteria met | OK External libs verified
```

If ANY check fails, the agent fixes the issue before signaling completion.

---

## Further Reading

- **Next:** [04-task-management.md](./04-task-management.md) — Task management system
- **OpenAgent definition:** [`agent/core/openagent.md`](../../.opencode/agent/core/openagent.md)
- **OpenCoder definition:** [`agent/core/opencoder.md`](../../.opencode/agent/core/opencoder.md)
- **CoderAgent definition:** [`agent/subagents/code/coder-agent.md`](../../.opencode/agent/subagents/code/coder-agent.md)
- **Code review workflow:** [`workflows/code-review.md`](../../.opencode/context/core/workflows/code-review.md)
- **Delegation workflow:** [`workflows/task-delegation-basics.md`](../../.opencode/context/core/workflows/task-delegation-basics.md)
- **Session management:** [`workflows/session-management.md`](../../.opencode/context/core/workflows/session-management.md)
