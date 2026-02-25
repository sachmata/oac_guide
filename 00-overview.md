# OpenAgents Control (OAC) — Overview & Architecture

> **Reading order:** This is file 1 of 9. Start here, then proceed to [01-agents.md](./01-agents.md).

---

## What It Is

[OpenAgents Control](https://github.com/darrenhinde/OpenAgentsControl) (OAC) is an **AI agent orchestration framework** built on top of [OpenCode](https://opencode.ai). It provides a structured, plan-first development workflow where AI agents learn *your* coding patterns and generate matching code — with human approval gates at every step.

**Key premise:** Most AI coding tools produce generic code that requires heavy refactoring. OAC solves this by loading project-specific context (your patterns, naming conventions, security rules) *before* generating any code.

| Attribute | Value |
|-----------|-------|
| License | [MIT](https://github.com/darrenhinde/OpenAgentsControl/blob/main/LICENSE) |
| Stars | 2.2k+ |
| Current version | [v0.7.1](https://github.com/darrenhinde/OpenAgentsControl/releases/tag/v0.7.1) |
| Repository | [github.com/darrenhinde/OpenAgentsControl](https://github.com/darrenhinde/OpenAgentsControl) |
| Built on | [OpenCode CLI](https://opencode.ai/docs) |
| Language support | TypeScript, Python, Go, Rust, any language |
| Model support | Claude, GPT, Gemini, local models (model-agnostic) |

---

## Architecture Overview

The framework is organized into five interconnected subsystems, all living under `.opencode/`:

```
.opencode/
├── agent/                  # Agent definitions (markdown-as-code)
│   ├── core/               # Primary orchestrator agents
│   │   ├── openagent.md    # General-purpose agent (start here)
│   │   └── opencoder.md    # Production development specialist
│   └── subagents/          # Specialist workers
│       ├── core/           # ContextScout, ExternalScout, TaskManager, DocWriter
│       ├── code/           # CoderAgent, TestEngineer, CodeReviewer, BuildAgent
│       ├── development/    # FrontendSpecialist, DevOpsSpecialist
│       └── system-builder/ # ContextOrganizer
├── context/                # Knowledge base (the "secret weapon")
│   ├── core/               # Universal standards, workflows, task-management
│   ├── project-intelligence/ # YOUR project patterns (tech stack, naming, security)
│   ├── project/            # Project-level context
│   ├── development/        # Software development patterns
│   └── ui/                 # Design & UX patterns
├── command/                # Slash commands (/commit, /add-context, /test, etc.)
├── skills/                 # Reusable capabilities (task-management CLI, Context7 API)
├── tool/                   # Custom tools (env loader)
└── package.json            # Dependencies (@opencode-ai/plugin)
```

### Subsystem Relationships

```
User Request
    │
    ▼
┌─────────────────────────────────────────────────┐
│  Primary Agent (OpenAgent or OpenCoder)          │
│  .opencode/agent/core/                           │
│                                                  │
│  Reads: .opencode/context/ (via ContextScout)    │
│  Uses:  .opencode/command/ (slash commands)       │
│  Loads: .opencode/skills/ (on demand)             │
│                                                  │
│  Delegates to: .opencode/agent/subagents/         │
│  Temp files:   .tmp/sessions/, .tmp/tasks/        │
└─────────────────────────────────────────────────┘
```

Each subsystem is **plain Markdown + JSON** — no compilation, no build step, no vendor lock-in. You edit text files to change behavior.

---

## Key Concepts at a Glance

| Concept | What It Means |
|---------|---------------|
| **Agents** | Markdown files that define AI behavior, permissions, and workflows |
| **Context** | Structured knowledge base of standards, patterns, and project intelligence |
| **MVI** | Minimal Viable Information — context files kept <200 lines for token efficiency |
| **Approval Gates** | AI proposes, human approves before any execution |
| **ContextScout** | Read-only subagent that discovers relevant context files |
| **ExternalScout** | Subagent that fetches live library docs via [Context7 API](https://context7.com) |
| **TaskManager** | Decomposes complex features into atomic JSON subtasks with dependencies |
| **Parallel Batches** | Independent subtasks execute simultaneously; dependent ones wait |

---

## Further Reading

- **Next:** [01-agents.md](./01-agents.md) — Agent hierarchy and definition format
- **GitHub README:** [OpenAgentsControl README](https://github.com/darrenhinde/OpenAgentsControl/blob/main/README.md)
- **Context System Guide:** [CONTEXT_SYSTEM_GUIDE.md](https://github.com/darrenhinde/OpenAgentsControl/blob/main/CONTEXT_SYSTEM_GUIDE.md)
- **Roadmap:** [Project Board](https://github.com/darrenhinde/OpenAgentsControl/projects)
- **Changelog:** [CHANGELOG.md](https://github.com/darrenhinde/OpenAgentsControl/blob/main/CHANGELOG.md)
- **OpenCode Docs:** [opencode.ai/docs](https://opencode.ai/docs)
