# Reference — Comparison, Installation, Design Principles & Quick Reference

> **Reading order:** File 9 of 10. Previous: [07-customization.md](./07-customization.md) | Next: [09-knowledge-persistence.md](./09-knowledge-persistence.md)

---

## Comparison with Alternatives

| Dimension | OAC | Cursor/Copilot | Aider | Oh My OpenCode |
|-----------|-----|----------------|-------|----------------|
| **Pattern learning** | Built-in context system | None | None | Manual setup |
| **Approval gates** | Always required | Optional (default off) | Auto-executes | Fully autonomous |
| **Agent editability** | Markdown files you edit | Proprietary/baked-in | Limited prompts | Config files |
| **Token efficiency** | MVI (~80% reduction) | Full context loaded | Full context loaded | High token usage |
| **Team standards** | Shared context files | Per-user settings | No team support | Manual config per user |
| **Model choice** | Any model, any provider | Limited options | OpenAI/Claude only | Multiple models |
| **Execution speed** | Sequential with approval | Fast | Fast | Parallel agents |
| **Error recovery** | Human-guided validation | Auto-retry (can loop) | Auto-retry | Self-correcting |
| **Best for** | Production code, teams | Quick prototypes | Solo developers | Power users, complex projects |

### When to Use What

**Use OAC when:**
- You have established coding patterns and want AI to follow them
- You want code that ships without heavy refactoring
- You need approval gates for quality control
- You care about token efficiency and costs
- You work in a team with shared standards

**Use alternatives when:**
- **Cursor/Copilot:** Quick prototypes, don't care about patterns
- **Aider:** Simple file edits, no team coordination needed
- **Oh My OpenCode:** Need fully autonomous execution with parallel agents (speed over control)

See: [Detailed comparison discussion](https://github.com/darrenhinde/OpenAgentsControl/discussions/116)

---

## Installation

### Prerequisites

- [OpenCode CLI](https://opencode.ai/docs) (free, open-source)
- Bash 3.2+ (macOS default works)
- Git

### Quick Install (Developer Profile)

```bash
# One command — installs locally in .opencode/
curl -fsSL https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/main/install.sh | bash -s developer
```

### Interactive Install

```bash
curl -fsSL https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/main/install.sh -o install.sh
bash install.sh
```

### Keep Updated

```bash
curl -fsSL https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/main/update.sh | bash
```

Use `--install-dir PATH` for custom locations.

### Installation in This Project (MAUI)

This monorepo has OAC installed locally (developer profile). The local installation means:
- All context is project-specific and git-committable
- Team members get the same patterns automatically
- Global fallback is never checked (local wins)

**Project-specific adaptations** are in [`AGENTS.md`](../../AGENTS.md):
- PNPM-only package management (never npm/yarn)
- Moonrepo task orchestration (`pnpm moon run :build`)
- React 19 + React Router v7 + Module Federation
- Tailwind CSS v4 + shadcn/ui (New York style)
- URQL (GraphQL) + Hasura + Auth.js (OIDC)
- Fish shell awareness

### Local vs Global Install

| Setup | Location | Best For |
|-------|----------|----------|
| Local (recommended) | `.opencode/` in project root | Teams, git-committed patterns |
| Global | `~/.config/opencode/` | Personal defaults across projects |
| Both | Local overrides global | Project-specific + personal fallback |

See: [OpenCode config docs](https://opencode.ai/docs/config/) for how configs merge.

### Claude Code Plugin (BETA)

OAC is also available as a Claude Code plugin:

```bash
/plugin marketplace add darrenhinde/OpenAgentsControl
/plugin install oac
/oac:setup --core
```

See: [Plugin README](https://github.com/darrenhinde/OpenAgentsControl/blob/main/plugins/claude-code/README.md)

---

## Key Design Principles

### 1. Markdown-as-Code
Agents, commands, context — everything is editable Markdown. No compilation, no build step, no vendor lock-in. Change behavior by editing text files.

### 2. Context-Before-Code
Agents must load relevant standards before writing any code. This is enforced at the framework level via `@critical_context_requirement`, not optional.

### 3. Human-in-the-Loop
Approval gates at every execution boundary. The AI proposes, the human approves. No "oh no, what did the AI just do?" moments.

### 4. Token Efficiency (MVI)
Context files are kept under 200 lines. Navigation files are ~200-300 tokens. Only relevant context is loaded per task. Claims ~80% token reduction vs. loading entire codebase.

### 5. Separation of Standards and Source
`context_files` (standards to follow) are never mixed with `reference_files` (code to study). This prevents agents from confusing conventions with implementations.

### 6. Parallel-Aware Task Decomposition
Tasks are tagged with `parallel: true/false` and `depends_on` arrays, enabling batch execution with dependency ordering. 50-70% time savings for multi-component features.

### 7. Self-Review Before Handoff
CoderAgent runs a mandatory 4-check self-review (types, imports, anti-patterns, acceptance criteria) before signaling completion.

### 8. Stateless Subagents
Subagents don't assume prior context. Everything they need is passed via the session context file or inline in the delegation prompt. No hidden state.

### 9. Local-First Resolution
Local context always wins over global. Project intelligence is always local. Resolution happens once at startup. Maximum 2 glob checks.

### 10. Least Privilege Permissions
Each subagent gets only the permissions it needs. ContextScout is read-only. CoderAgent can only run specific bash commands. Secret files are universally denied.

---

## Quick Reference

### Start an Agent

```bash
opencode --agent OpenAgent     # General purpose
opencode --agent OpenCoder     # Production development
```

### Essential Commands

```bash
/add-context                   # Teach agents your patterns (~5 min)
/add-context --update          # Update patterns
/commit                        # Smart git commit
/test                          # Run test pipeline
/optimize src/                 # Analyze code
/context harvest               # Clean up summaries
/context validate              # Check integrity
/context map                   # View structure
/context migrate               # Global -> local
```

### Task Management CLI

```bash
bash .opencode/skills/task-management/router.sh status        # All statuses
bash .opencode/skills/task-management/router.sh next          # Next eligible
bash .opencode/skills/task-management/router.sh parallel      # Parallelizable
bash .opencode/skills/task-management/router.sh blocked       # What's stuck
bash .opencode/skills/task-management/router.sh complete <f> <s> "msg"  # Mark done
bash .opencode/skills/task-management/router.sh validate      # Check integrity
```

### Key File Locations

| What | Path |
|------|------|
| Primary agents | `.opencode/agent/core/` |
| Subagents | `.opencode/agent/subagents/` |
| Context root | `.opencode/context/` |
| Navigation index | `.opencode/context/navigation.md` |
| Core standards | `.opencode/context/core/standards/` |
| Core workflows | `.opencode/context/core/workflows/` |
| Project intelligence | `.opencode/context/project-intelligence/` |
| Slash commands | `.opencode/command/` |
| Skills | `.opencode/skills/` |
| Tools | `.opencode/tool/` |
| Task files (temp) | `.tmp/tasks/` |
| Session files (temp) | `.tmp/sessions/` |
| External docs cache | `.tmp/external-context/` |

### Context Loading Cheat Sheet

| Task Type | Load This Context File |
|-----------|-----------------------|
| Write/edit code | `core/standards/code-quality.md` |
| Write/edit docs | `core/standards/documentation.md` |
| Write/edit tests | `core/standards/test-coverage.md` |
| Code review | `core/workflows/code-review.md` |
| Delegate to subagent | `core/workflows/task-delegation-basics.md` |
| Security work | `core/standards/security-patterns.md` |
| UI/frontend | `ui/` + `core/workflows/design-iteration-overview.md` |
| Bash-only | No context required |

---

## Links & Resources

### Project Links

| Resource | URL |
|----------|-----|
| GitHub Repository | [github.com/darrenhinde/OpenAgentsControl](https://github.com/darrenhinde/OpenAgentsControl) |
| Releases | [Releases page](https://github.com/darrenhinde/OpenAgentsControl/releases) |
| Issues | [Issues](https://github.com/darrenhinde/OpenAgentsControl/issues) |
| Discussions | [Discussions](https://github.com/darrenhinde/OpenAgentsControl/discussions) |
| Project Board / Roadmap | [Projects](https://github.com/darrenhinde/OpenAgentsControl/projects) |
| Changelog | [CHANGELOG.md](https://github.com/darrenhinde/OpenAgentsControl/blob/main/CHANGELOG.md) |
| Compatibility | [COMPATIBILITY.md](https://github.com/darrenhinde/OpenAgentsControl/blob/main/COMPATIBILITY.md) |
| Contributing | [CONTRIBUTING.md](https://github.com/darrenhinde/OpenAgentsControl/blob/main/docs/contributing/CONTRIBUTING.md) |
| Code of Conduct | [CODE_OF_CONDUCT.md](https://github.com/darrenhinde/OpenAgentsControl/blob/main/docs/contributing/CODE_OF_CONDUCT.md) |

### Documentation

| Resource | URL |
|----------|-----|
| OpenCode CLI Docs | [opencode.ai/docs](https://opencode.ai/docs) |
| OpenCode Config | [opencode.ai/docs/config](https://opencode.ai/docs/config/) |
| Context System Guide | [CONTEXT_SYSTEM_GUIDE.md](https://github.com/darrenhinde/OpenAgentsControl/blob/main/CONTEXT_SYSTEM_GUIDE.md) |
| Context7 API | [context7.com](https://context7.com) |
| Available Models | [models.dev](https://models.dev/?search=open) |

### Community

| Resource | URL |
|----------|-----|
| Community Forum | [nextsystems.ai](https://nextsystems.ai) |
| YouTube | [DarrenBuildsAI](https://youtube.com/@DarrenBuildsAI) |
| X / Twitter | [@DarrenBuildsAI](https://x.com/DarrenBuildsAI) |
| Support | [Buy Me A Coffee](https://buymeacoffee.com/darrenhinde) |

### Local File References

| Resource | Path |
|----------|------|
| Project AGENTS.md | [`AGENTS.md`](../../AGENTS.md) |
| OpenAgent definition | [`.opencode/agent/core/openagent.md`](../../.opencode/agent/core/openagent.md) |
| OpenCoder definition | [`.opencode/agent/core/opencoder.md`](../../.opencode/agent/core/opencoder.md) |
| Context navigation | [`.opencode/context/navigation.md`](../../.opencode/context/navigation.md) |
| Code quality standards | [`.opencode/context/core/standards/code-quality.md`](../../.opencode/context/core/standards/code-quality.md) |
| Essential patterns | [`.opencode/context/core/essential-patterns.md`](../../.opencode/context/core/essential-patterns.md) |
| Context system spec | [`.opencode/context/core/context-system.md`](../../.opencode/context/core/context-system.md) |
| Task management skill | [`.opencode/skills/task-management/SKILL.md`](../../.opencode/skills/task-management/SKILL.md) |
| Context7 skill | [`.opencode/skills/context7/SKILL.md`](../../.opencode/skills/context7/SKILL.md) |

---

## Guide Index

| # | File | Topics |
|---|------|--------|
| 0 | [00-overview.md](./00-overview.md) | What OAC is, architecture, directory structure |
| 1 | [01-agents.md](./01-agents.md) | Agent hierarchy, primary agents, subagents, definition format |
| 2 | [02-context-system.md](./02-context-system.md) | Context resolution, categories, MVI, navigation, project intelligence |
| 3 | [03-workflow-engine.md](./03-workflow-engine.md) | OpenAgent & OpenCoder workflows, critical rules, self-review |
| 4 | [04-task-management.md](./04-task-management.md) | Task decomposition, JSON schema, CLI, parallel execution |
| 5 | [05-commands-and-skills.md](./05-commands-and-skills.md) | Slash commands, Context7 skill, task-management skill |
| 6 | [06-permissions-and-data-flow.md](./06-permissions-and-data-flow.md) | Permission model, end-to-end data flow diagram |
| 7 | [07-customization.md](./07-customization.md) | Editing agents, adding patterns, custom commands/skills |
| 8 | [08-reference.md](./08-reference.md) | Comparison, installation, design principles, quick reference |
| 9 | [09-knowledge-persistence.md](./09-knowledge-persistence.md) | Four knowledge layers, persistence triggers, automation model |
