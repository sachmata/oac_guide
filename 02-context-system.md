# The Context System — OAC's Core Innovation

> **Reading order:** File 3 of 9. Previous: [01-agents.md](./01-agents.md) | Next: [03-workflow-engine.md](./03-workflow-engine.md)

---

The context system is OAC's primary differentiator. It's a structured knowledge base that agents load *before* generating code, ensuring output matches your project's patterns from the start.

## Context Resolution (Local-First)

ContextScout resolves the context root location **once at startup** (max 2 glob checks):

```
1. Check local: .opencode/context/core/navigation.md
   |-- Found? --> Use local for everything. Done.
   |-- Not found?
2. Check global: ~/.config/opencode/context/core/navigation.md
   |-- Found? --> Use global for core/ files only.
   |-- Not found? --> Proceed without core context.
```

**Rules:**

| Rule | Detail |
|------|--------|
| Local always wins | If `.opencode/context/core/` exists locally, global is never checked |
| Global fallback is core-only | Only `core/` (universal standards) falls back to global |
| Project intelligence is always local | `project-intelligence/` is project-specific, never loaded from global |
| One-time check | Resolution happens once per session, not per-file |

**Common setups:**

| Setup | Core files from | Project intelligence from |
|-------|----------------|--------------------------|
| Local install (`bash install.sh developer`) | `.opencode/context/core/` | `.opencode/context/project-intelligence/` |
| Global install + `/add-context` | `~/.config/opencode/context/core/` | `.opencode/context/project-intelligence/` |
| Both local and global | `.opencode/context/core/` (local wins) | `.opencode/context/project-intelligence/` |

See: [OpenCode config docs](https://opencode.ai/docs/config/) for how configs merge.

---

## Context Categories

| Directory | Purpose | Loaded When | Local File |
|-----------|---------|-------------|------------|
| `core/standards/` | Code quality, test coverage, documentation, security | Every code/test/doc task | [`code-quality.md`](../../.opencode/context/core/standards/code-quality.md) |
| `core/workflows/` | Code review, delegation, session management, design iteration | Review/delegation tasks | [`code-review.md`](../../.opencode/context/core/workflows/code-review.md) |
| `core/task-management/` | Task schema, splitting guides, managing tasks | TaskManager operations | [`navigation.md`](../../.opencode/context/core/task-management/) |
| `core/context-system/` | MVI standards, structure, templates | Context management | [`context-system.md`](../../.opencode/context/core/context-system.md) |
| `project-intelligence/` | YOUR tech stack, patterns, naming, security | Every task (via ContextScout) | [`technical-domain.md`](../../.opencode/context/project-intelligence/technical-domain.md) |
| `development/` | Language/framework-specific patterns | Development tasks | [`navigation.md`](../../.opencode/context/development/) |
| `ui/` | Design system, component patterns | UI tasks | [`navigation.md`](../../.opencode/context/ui/) |

### Mandatory Context Loading

The framework enforces context loading based on task type. This is **not optional**:

| Task Type | Required Context File |
|-----------|-----------------------|
| Write/edit code | `core/standards/code-quality.md` |
| Write/edit docs | `core/standards/documentation.md` |
| Write/edit tests | `core/standards/test-coverage.md` |
| Code review | `core/workflows/code-review.md` |
| Delegate to subagent | `core/workflows/task-delegation-basics.md` |
| Bash-only | No context required |

---

## MVI Principle (Minimal Viable Information)

Every context file follows MVI to maximize token efficiency:

| Element | Guideline |
|---------|-----------|
| Core concept | 1-3 sentences |
| Key points | 3-5 bullets |
| Minimal example | 5-10 lines of code |
| Reference link | To full docs |
| File size | **<200 lines** (scannable in <30 seconds) |

**Why MVI matters:** Loading 750 tokens of focused context beats loading 8,000 tokens of everything. OAC claims ~80% token reduction compared to loading entire codebase context.

**Traditional approach:**
- Loads entire codebase context
- Large token overhead per request
- Slow responses, high costs

**OAC approach:**
- Loads only relevant patterns
- Context files <200 lines (quick to load)
- Lazy loading (agents load what they need)
- 80% of tasks use isolation context (minimal overhead)

See: [`context-system.md`](../../.opencode/context/core/context-system.md) for the full MVI specification.

---

## Navigation Files

Every directory has a `navigation.md` that acts as a routing table (~200-300 tokens). ContextScout follows these files top-down to discover relevant context.

**Example** — [`context/navigation.md`](../../.opencode/context/navigation.md):

```markdown
# Context Navigation

## Quick Routes

| Task | Path |
|------|------|
| **Write code** | `core/standards/code-quality.md` |
| **Write tests** | `core/standards/test-coverage.md` |
| **Write docs** | `core/standards/documentation.md` |
| **Review code** | `core/workflows/code-review.md` |
| **Delegate task** | `core/workflows/task-delegation-basics.md` |

## By Category

**core/** - Standards, workflows, patterns --> `core/navigation.md`
**development/** - All development --> `development/navigation.md`
**ui/** - Design & UX --> `ui/navigation.md`
```

### Two Organizational Patterns

| Pattern | Use When | Example |
|---------|----------|---------|
| **Function-Based** | Repository-specific context | `concepts/`, `examples/`, `guides/`, `lookup/`, `errors/` |
| **Concern-Based** | Multi-technology development | `frontend/react/`, `backend/api-patterns/`, `data/sql-patterns/` |

---

## Project Intelligence

Project intelligence is the mechanism for teaching agents YOUR patterns. It lives in `.opencode/context/project-intelligence/` and is always local (never loaded from global).

### Files

| File | Purpose | Local Path |
|------|---------|------------|
| [`technical-domain.md`](../../.opencode/context/project-intelligence/technical-domain.md) | Tech stack, architecture, code patterns | `project-intelligence/technical-domain.md` |
| [`business-domain.md`](../../.opencode/context/project-intelligence/business-domain.md) | Business context, domain model | `project-intelligence/business-domain.md` |
| [`business-tech-bridge.md`](../../.opencode/context/project-intelligence/business-tech-bridge.md) | How business needs map to technical solutions | `project-intelligence/business-tech-bridge.md` |
| [`decisions-log.md`](../../.opencode/context/project-intelligence/decisions-log.md) | Architectural decision history | `project-intelligence/decisions-log.md` |
| [`living-notes.md`](../../.opencode/context/project-intelligence/living-notes.md) | Evolving notes and observations | `project-intelligence/living-notes.md` |
| [`navigation.md`](../../.opencode/context/project-intelligence/navigation.md) | Navigation for project intelligence | `project-intelligence/navigation.md` |

### Creating Project Intelligence

The `/add-context` command runs a 6-question wizard (~5 minutes):

1. **Tech stack** — Framework, language, database, styling
2. **API pattern** — Paste your actual endpoint code
3. **Component pattern** — Paste your actual component code
4. **Naming conventions** — Files, components, functions, database
5. **Code standards** — TypeScript strict, Zod validation, etc.
6. **Security requirements** — Input validation, parameterized queries, etc.

The result is a `technical-domain.md` file marked `Priority: critical` that agents load before every code generation task.

```bash
/add-context                 # Interactive wizard (recommended)
/add-context --update        # Update existing patterns
/add-context --tech-stack    # Add/update tech stack only
/add-context --patterns      # Add/update code patterns only
/add-context --global        # Save to global config instead of project
```

See: [`command/add-context.md`](../../.opencode/command/add-context.md) for the full wizard specification.

---

## ContextScout — How Discovery Works

[ContextScout](../../.opencode/agent/subagents/core/contextscout.md) is a **read-only** subagent that discovers relevant context files. It:

1. **Resolves core location** (once) — local or global fallback
2. **Understands intent** — What is the user trying to do?
3. **Follows navigation** — Reads `navigation.md` files top-down
4. **Returns ranked files** — Priority order: Critical > High > Medium

**Response format:**

```markdown
# Context Files Found

## Critical Priority
**File**: `.opencode/context/core/standards/code-quality.md`
**Contains**: Modular, functional code patterns, naming conventions

## High Priority
**File**: `.opencode/context/project-intelligence/technical-domain.md`
**Contains**: Project tech stack, API patterns, component patterns

## ExternalScout Recommendation
The framework **Better Auth** has no internal context coverage.
--> Invoke ExternalScout to fetch live docs
```

**Key constraints:**
- Can only `read`, `grep`, `glob` — cannot write, edit, bash, or delegate
- Must verify every file path exists before recommending it
- Suggests ExternalScout when a library has no internal coverage

---

## ExternalScout — Live Documentation

[ExternalScout](../../.opencode/agent/subagents/core/externalscout.md) fetches current documentation for external libraries via the [Context7 API](https://context7.com). This prevents agents from relying on outdated training data.

**Workflow:**
1. **Check cache** — `.tmp/external-context/` (skip if <7 days old)
2. **Detect library** — Match against [library registry](../../.opencode/skills/context7/)
3. **Fetch docs** — Context7 API (primary) or official docs (fallback)
4. **Filter** — Extract only relevant sections
5. **Persist** — Write to `.tmp/external-context/{package}/{topic}.md`
6. **Return** — File locations + brief summary

**Supported libraries:** React, Next.js, Drizzle, Prisma, TanStack Query/Router, Better Auth, Tailwind CSS, shadcn/ui, Zod, Vitest, Playwright, Cloudflare Workers, and more.

See: [`skills/context7/SKILL.md`](../../.opencode/skills/context7/SKILL.md) for the Context7 API reference.

---

## For Teams: Repeatable Patterns

Store team patterns in `.opencode/context/project-intelligence/`. Commit to repo. Everyone uses the same standards:

```bash
# Team lead adds patterns once
/add-context

# Commit to repo
git add .opencode/context/
git commit -m "Add team coding standards"
git push

# All team members now use same patterns automatically
# New developers inherit standards on day 1
```

---

## Further Reading

- **Next:** [03-workflow-engine.md](./03-workflow-engine.md) — Workflow engine
- **Context system spec:** [`context-system.md`](../../.opencode/context/core/context-system.md)
- **Essential patterns:** [`essential-patterns.md`](../../.opencode/context/core/essential-patterns.md)
- **Code quality standards:** [`code-quality.md`](../../.opencode/context/core/standards/code-quality.md)
- **Security patterns:** [`security-patterns.md`](../../.opencode/context/core/standards/security-patterns.md)
- **Upstream context guide:** [CONTEXT_SYSTEM_GUIDE.md](https://github.com/darrenhinde/OpenAgentsControl/blob/main/CONTEXT_SYSTEM_GUIDE.md)
