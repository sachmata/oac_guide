# Agents — Hierarchy, Roles & Definition Format

> **Reading order:** File 2 of 9. Previous: [00-overview.md](./00-overview.md) | Next: [02-context-system.md](./02-context-system.md)

---

## Primary Agents (User-Facing)

These are the agents you invoke directly. They orchestrate work and delegate to subagents.

| Agent | File | Purpose | Temperature |
|-------|------|---------|-------------|
| **OpenAgent** | [`agent/core/openagent.md`](../../.opencode/agent/core/openagent.md) | Universal agent — questions, tasks, workflow coordination | 0.2 |
| **OpenCoder** | [`agent/core/opencoder.md`](../../.opencode/agent/core/opencoder.md) | Complex coding, multi-file refactoring, production features | 0.1 |

### OpenAgent

The general-purpose entry point. Handles everything from answering questions to delegating complex work. Follows a 6-stage workflow:

**Analyze -> Discover -> Approve -> Execute -> Validate -> Summarize**

Best for: first-time users, simple features, questions, documentation, analysis.

```bash
opencode --agent OpenAgent
> "Create a user authentication system"
> "How do I implement authentication in Next.js?"
> "Explain the architecture of this codebase"
```

### OpenCoder

The production development specialist. Adds session management (`context.md` files), TaskManager integration, and parallel batch execution. Follows a more rigorous 6-stage workflow:

**Discover -> Propose -> Init Session -> Plan -> Execute (Parallel Batches) -> Validate & Handoff**

Best for: production code, complex features, multi-file refactoring, team development.

```bash
opencode --agent OpenCoder
> "Create a user authentication system"
> "Refactor this codebase to use dependency injection"
> "Add real-time notifications with WebSockets"
```

See [03-workflow-engine.md](./03-workflow-engine.md) for detailed workflow descriptions.

---

## Subagents (Auto-Delegated)

Subagents are never invoked directly by the user. The orchestrator agents delegate to them via the `task()` tool. Each has tightly scoped permissions.

### Core Subagents

| Subagent | File | Role | Key Constraint |
|----------|------|------|----------------|
| **ContextScout** | [`subagents/core/contextscout.md`](../../.opencode/agent/subagents/core/contextscout.md) | Discovers relevant context files from `.opencode/context/` | **Read-only** — cannot write, edit, or run bash |
| **ExternalScout** | [`subagents/core/externalscout.md`](../../.opencode/agent/subagents/core/externalscout.md) | Fetches live docs for external libraries via [Context7 API](https://context7.com) | Writes only to `.tmp/external-context/` |
| **TaskManager** | [`subagents/core/task-manager.md`](../../.opencode/agent/subagents/core/task-manager.md) | Breaks complex features into atomic JSON subtasks | Creates `.tmp/tasks/{feature}/` structure |
| **DocWriter** | [`subagents/core/documentation.md`](../../.opencode/agent/subagents/core/documentation.md) | Documentation generation | Follows [documentation standards](../../.opencode/context/core/standards/documentation.md) |

### Code Subagents

| Subagent | File | Role |
|----------|------|------|
| **CoderAgent** | [`subagents/code/coder-agent.md`](../../.opencode/agent/subagents/code/coder-agent.md) | Executes individual coding subtasks with mandatory self-review |
| **TestEngineer** | [`subagents/code/test-engineer.md`](../../.opencode/agent/subagents/code/test-engineer.md) | Test authoring and TDD |
| **CodeReviewer** | [`subagents/code/reviewer.md`](../../.opencode/agent/subagents/code/reviewer.md) | Code review and security analysis |
| **BuildAgent** | [`subagents/code/build-agent.md`](../../.opencode/agent/subagents/code/build-agent.md) | Type checking and build validation |

### Development Subagents

| Subagent | File | Role |
|----------|------|------|
| **FrontendSpecialist** | [`subagents/development/frontend-specialist.md`](../../.opencode/agent/subagents/development/frontend-specialist.md) | UI design (4-stage: Layout -> Theme -> Animation -> Implementation) |
| **DevOpsSpecialist** | [`subagents/development/devops-specialist.md`](../../.opencode/agent/subagents/development/devops-specialist.md) | CI/CD, infrastructure as code |

### System Builder Subagents

| Subagent | File | Role |
|----------|------|------|
| **ContextOrganizer** | [`subagents/system-builder/context-organizer.md`](../../.opencode/agent/subagents/system-builder/context-organizer.md) | Manages context files (harvest, extract, organize) |

---

## Agent Definition Format

Every agent is a **Markdown file with YAML frontmatter**. This is the entire configuration — no compilation, no vendor lock-in:

```yaml
---
name: OpenAgent
description: "Universal agent for answering queries, executing tasks..."
mode: primary          # "primary" = user-facing, "subagent" = delegated
temperature: 0.2       # Lower = more deterministic
permission:
  bash:
    "*": "ask"         # Default: ask user before running
    "rm -rf /*": "deny" # Absolute deny
    "sudo *": "deny"
  edit:
    "**/*.env*": "deny" # Never edit secrets
    "**/*.key": "deny"
    "node_modules/**": "deny"
    ".git/**": "deny"
  task:
    contextscout: "allow"  # Can delegate to ContextScout
    "*": "deny"            # Cannot delegate to unlisted agents
---

# Agent instructions follow in Markdown + XML...

<critical_rules priority="absolute" enforcement="strict">
  <rule id="approval_gate">...</rule>
  <rule id="stop_on_failure">...</rule>
</critical_rules>

<workflow>
  <stage id="1" name="Analyze">...</stage>
  <stage id="2" name="Approve">...</stage>
  ...
</workflow>
```

### Key Design Insight

Agents are **editable text files**. You can change any agent's behavior by editing its markdown — add project rules, change workflows, customize constraints. This is fundamentally different from tools like Cursor/Copilot where behavior is baked into proprietary code.

### Permission Levels

| Level | Meaning |
|-------|---------|
| `"allow"` | Silent execution, no user prompt |
| `"ask"` | Requires user approval before execution |
| `"deny"` | Blocked entirely, cannot be overridden |

### Delegation Syntax

Orchestrator agents delegate to subagents via the `task()` tool:

```javascript
task(
  subagent_type="ContextScout",
  description="Find coding standards for auth feature",
  prompt="Discover context files related to authentication..."
)
```

---

## Agent Selection Guide

| Scenario | Agent | Why |
|----------|-------|-----|
| First time using OAC | OpenAgent | Simpler workflow, good for learning |
| Simple feature (1-3 files) | OpenAgent | Direct execution, no session overhead |
| Complex feature (4+ files) | OpenCoder | Session management, TaskManager, parallel execution |
| Multi-file refactoring | OpenCoder | Incremental execution with validation |
| Questions / analysis | OpenAgent | Conversational path, no approval needed |
| Production deployment | OpenCoder | Full validation pipeline |

---

## Further Reading

- **Next:** [02-context-system.md](./02-context-system.md) — The context system
- **Agent files:** [`.opencode/agent/`](../../.opencode/agent/)
- **OpenCode agent docs:** [opencode.ai/docs](https://opencode.ai/docs)
- **Upstream agent definitions:** [github.com/darrenhinde/OpenAgentsControl/.opencode](https://github.com/darrenhinde/OpenAgentsControl/tree/main/.opencode)
