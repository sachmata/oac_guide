# Task Management — Decomposition, JSON Schema & Parallel Execution

> **Reading order:** File 5 of 9. Previous: [03-workflow-engine.md](./03-workflow-engine.md) | Next: [05-commands-and-skills.md](./05-commands-and-skills.md)

---

For complex features (4+ files, >60min), [TaskManager](../../.opencode/agent/subagents/core/task-manager.md) decomposes work into atomic JSON subtasks with dependency tracking and parallel execution support.

## Task Structure

```
.tmp/tasks/{feature-slug}/
├── task.json              # Feature-level metadata
├── subtask_01.json        # Atomic subtask definitions
├── subtask_02.json
├── subtask_03.json
└── ...

.tmp/tasks/completed/      # Archived completed features
└── {feature-slug}/
```

---

## task.json Schema

The feature-level metadata file:

```json
{
  "id": "user-auth",
  "name": "User Authentication System",
  "status": "active",
  "objective": "Implement JWT-based authentication with refresh tokens (max 200 chars)",
  "context_files": [".opencode/context/core/standards/code-quality.md"],
  "reference_files": ["src/middleware/auth.ts"],
  "exit_criteria": ["All tests passing", "JWT tokens signed with RS256"],
  "subtask_count": 5,
  "completed_count": 0,
  "created_at": "2026-02-25T10:00:00Z",
  "completed_at": null
}
```

**Key distinction:** `context_files` = standards to follow (conventions, patterns, security rules). `reference_files` = source code to study (existing project files). **Never mix them.**

---

## subtask_NN.json Schema

Each atomic subtask:

```json
{
  "id": "user-auth-02",
  "seq": "02",
  "title": "Implement JWT service with token generation and validation",
  "status": "pending",
  "depends_on": ["01"],
  "parallel": false,
  "suggested_agent": "CoderAgent",
  "context_files": [".opencode/context/core/standards/code-quality.md"],
  "reference_files": ["src/config/jwt.config.ts"],
  "acceptance_criteria": [
    "JWT tokens signed with RS256 algorithm",
    "Access tokens expire in 15 minutes",
    "Token validation includes signature and expiry checks"
  ],
  "deliverables": ["src/auth/jwt.service.ts", "src/auth/jwt.service.test.ts"],
  "started_at": null,
  "completed_at": null,
  "completion_summary": null
}
```

### Status Flow

```
pending --> in_progress --> completed
                |
                +--> blocked (issue found, cannot proceed)
```

| Status | Meaning |
|--------|---------|
| `pending` | Initial state, waiting for dependencies |
| `in_progress` | Working agent picked up the task |
| `completed` | TaskManager verified completion |
| `blocked` | Issue found, cannot proceed |

### Agent Field Semantics

| Field | Set By | Meaning |
|-------|--------|---------|
| `suggested_agent` | TaskManager (during planning) | Recommendation for which agent should execute |
| `agent_id` | Working agent (when starting) | Tracks who is actually working on the task |

---

## Enhanced Schema (v2.0)

The enhanced schema adds optional fields for domain modeling, prioritization, and architectural tracking. All fields are **backward compatible** — existing task files work without changes.

### Line-Number Precision

For large context files (>100 lines), point agents to exact sections:

```json
"context_files": [
  {
    "path": ".opencode/context/core/standards/code-quality.md",
    "lines": "53-95",
    "reason": "Pure function patterns for service layer"
  },
  {
    "path": ".opencode/context/core/standards/security-patterns.md",
    "lines": "120-145,200-220",
    "reason": "JWT validation and token refresh patterns"
  }
]
```

Both formats are valid and can be mixed in the same array:
- **String format:** `".opencode/context/file.md"` — read entire file
- **Object format:** `{"path": "...", "lines": "10-50", "reason": "..."}` — read specific lines

### Optional DDD Fields

| Field | Source | Purpose |
|-------|--------|---------|
| `bounded_context` | ArchitectureAnalyzer | DDD bounded context (e.g., "authentication") |
| `module` | ArchitectureAnalyzer | Module/package name (e.g., "@app/auth") |
| `vertical_slice` | StoryMapper | Feature slice identifier (e.g., "user-login") |
| `contracts` | ContractManager | API/interface contracts |
| `related_adrs` | ADRManager | Architectural Decision Records |
| `rice_score` | PrioritizationEngine | RICE prioritization score |
| `wsjf_score` | PrioritizationEngine | WSJF prioritization score |
| `release_slice` | PrioritizationEngine | Release identifier (e.g., "v1.0.0") |

See: [`task-manager.md`](../../.opencode/agent/subagents/core/task-manager.md) for the full enhanced schema specification.

---

## CLI Integration

The [task-management skill](../../.opencode/skills/task-management/SKILL.md) provides a CLI for tracking progress:

```bash
# Show all task statuses
bash .opencode/skills/task-management/router.sh status

# Show status for specific feature
bash .opencode/skills/task-management/router.sh status user-auth

# Show next eligible tasks (dependencies satisfied)
bash .opencode/skills/task-management/router.sh next

# Show parallelizable tasks ready to run
bash .opencode/skills/task-management/router.sh parallel

# Show dependency tree for a specific subtask
bash .opencode/skills/task-management/router.sh deps user-auth 07

# Show blocked tasks and why
bash .opencode/skills/task-management/router.sh blocked

# Mark subtask complete with summary
bash .opencode/skills/task-management/router.sh complete user-auth 01 "Implemented JWT auth"

# Validate JSON files and dependencies
bash .opencode/skills/task-management/router.sh validate
```

### Validation Rules

The `validate` command checks:

- **Task-level:** task.json exists, ID matches slug, subtask count matches files
- **Subtask-level:** IDs prefixed with feature name, unique sequences, valid status values
- **Dependencies:** All `depends_on` references exist, no circular dependencies, acyclic graph

---

## Parallel Execution Model

Tasks are grouped into dependency-ordered batches:

```
Batch 1: [01, 02, 03]  <-- parallel: true, no dependencies
Batch 2: [04]           <-- depends on 01+02+03
Batch 3: [05]           <-- depends on 04
```

### Execution Rules

| Rule | Detail |
|------|--------|
| **Within a batch** | All tasks start simultaneously |
| **Between batches** | Wait for entire previous batch to complete |
| **Parallel flag** | Only tasks with `parallel: true` AND no inter-dependencies run together |
| **Status checking** | Use `router.sh status` to verify batch completion |
| **Never proceed** | Don't start Batch N+1 until Batch N is 100% complete |

### Execution Strategy Decision

| Batch Size | Strategy | How |
|------------|----------|-----|
| 1-4 parallel tasks | **Direct execution** | OpenCoder delegates directly to CoderAgents |
| 5+ parallel tasks | **BatchExecutor** | OpenCoder delegates to BatchExecutor, which manages CoderAgents |

### Example: Direct Execution (1-4 tasks)

```javascript
// All three start at the same time
task(subagent_type="CoderAgent", description="Task 01", prompt="...subtask_01.json...")
task(subagent_type="CoderAgent", description="Task 02", prompt="...subtask_02.json...")
task(subagent_type="CoderAgent", description="Task 03", prompt="...subtask_03.json...")

// Wait for all to complete, then verify:
// bash .opencode/skills/task-management/router.sh status user-auth
```

### Example: Full Batch Execution

```
Task breakdown:
  Task 1: Write component A (parallel: true, no deps)
  Task 2: Write component B (parallel: true, no deps)
  Task 3: Write component C (parallel: true, no deps)
  Task 4: Write tests (parallel: false, depends on 1+2+3)
  Task 5: Integration (parallel: false, depends on 4)

Execution:
  Batch 1 (Parallel): Delegate Task 1, 2, 3 simultaneously
    - All three CoderAgents work at the same time
    - Wait for all three to complete
  Batch 2 (Sequential): Delegate Task 4 (tests)
    - Only starts after 1+2+3 are done
  Batch 3 (Sequential): Delegate Task 5 (integration)
    - Only starts after Task 4 is done
```

**Benefits:** 50-70% time savings for multi-component features.

---

## Quality Standards

| Standard | Guideline |
|----------|-----------|
| Atomic tasks | Each completable in 1-2 hours |
| Clear objectives | Single, measurable outcome per task |
| Explicit deliverables | Specific files or endpoints |
| Binary acceptance | Pass/fail criteria only |
| Parallel identification | Mark isolated tasks as `parallel: true` |
| Context references | Reference paths, don't embed content |
| Summary length | Max 200 characters for `completion_summary` |

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Features | kebab-case | `auth-system`, `user-dashboard` |
| Tasks | kebab-case descriptions | `implement-jwt-service` |
| Sequences | 2-digit zero-padded | `01`, `02`, `03` |
| Files | `subtask_{seq}.json` | `subtask_01.json` |

---

## Further Reading

- **Next:** [05-commands-and-skills.md](./05-commands-and-skills.md) — Commands and skills
- **TaskManager definition:** [`task-manager.md`](../../.opencode/agent/subagents/core/task-manager.md)
- **Task management skill:** [`skills/task-management/SKILL.md`](../../.opencode/skills/task-management/SKILL.md)
- **Task splitting guide:** [`.opencode/context/core/task-management/`](../../.opencode/context/core/task-management/)
- **Feature breakdown workflow:** [`workflows/feature-breakdown.md`](../../.opencode/context/core/workflows/feature-breakdown.md)
