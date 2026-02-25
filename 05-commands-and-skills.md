# Slash Commands & Skills System

> **Reading order:** File 6 of 9. Previous: [04-task-management.md](./04-task-management.md) | Next: [06-permissions-and-data-flow.md](./06-permissions-and-data-flow.md)

---

## Slash Commands

Commands are Markdown files in [`.opencode/command/`](../../.opencode/command/) that define interactive workflows invoked with `/command-name`.

### Command Reference

| Command | File | Purpose |
|---------|------|---------|
| `/add-context` | [`add-context.md`](../../.opencode/command/add-context.md) | Interactive wizard to teach agents your patterns (6 questions, ~5 min) |
| `/commit` | [`commit.md`](../../.opencode/command/commit.md) | Smart git commits with conventional format + emoji |
| `/test` | [`test.md`](../../.opencode/command/test.md) | Run complete testing pipeline (typecheck -> lint -> test) |
| `/optimize` | [`optimize.md`](../../.opencode/command/optimize.md) | Performance, security, and code quality analysis |
| `/context` | [`context.md`](../../.opencode/command/context.md) | Context management (harvest, extract, organize, validate) |
| `/clean` | [`clean.md`](../../.opencode/command/clean.md) | Cleanup operations |
| `/validate-repo` | [`validate-repo.md`](../../.opencode/command/validate-repo.md) | Repository validation |
| `/analyze-patterns` | [`analyze-patterns.md`](../../.opencode/command/analyze-patterns.md) | Pattern analysis |

Additional commands in [`command/openagents/`](../../.opencode/command/openagents/) provide OAC-specific operations.

---

### `/add-context` — Pattern Wizard

The most important command for new users. Creates project intelligence files that teach agents your patterns.

```bash
/add-context                 # Interactive wizard (recommended)
/add-context --update        # Update existing patterns
/add-context --tech-stack    # Add/update tech stack only
/add-context --patterns      # Add/update code patterns only
/add-context --global        # Save to global config (~/.config/opencode/)
```

**Workflow:**
1. Check for external context files in `.tmp/`
2. Detect existing project intelligence
3. Ask 6 questions (~5 min) OR review existing patterns
4. Show full preview before writing
5. Generate/update `technical-domain.md` + `navigation.md`
6. Validate MVI compliance (<200 lines)

**6 Questions:**
1. What's your tech stack?
2. Show an API endpoint example (paste your code)
3. Show a component example (paste your code)
4. What naming conventions?
5. Any code standards?
6. Any security requirements?

See: [`add-context.md`](../../.opencode/command/add-context.md) for the full specification.

---

### `/commit` — Smart Git Commits

Analyzes changes and generates conventional commit messages with emoji:

```bash
/commit                      # Full workflow (lint, build, analyze, commit, push)
/commit "quick message"      # Skip to commit with provided message
```

**Workflow:**
1. Run pre-commit validation (`pnpm lint`, `pnpm build`)
2. Analyze `git status` and `git diff --cached`
3. Generate commit message: `<emoji> <type>: <description>`
4. Execute commit and push

**Commit types:**

| Emoji | Type | Usage |
|-------|------|-------|
| `feat` | New feature | `feat: add user authentication system` |
| `fix` | Bug fix | `fix: resolve memory leak in rendering` |
| `docs` | Documentation | `docs: update API documentation` |
| `refactor` | Code refactoring | `refactor: simplify error handling logic` |
| `test` | Tests | `test: add unit tests for auth flow` |
| `chore` | Tooling/config | `chore: improve developer tooling setup` |
| `perf` | Performance | `perf: optimize database query performance` |
| `style` | Formatting | `style: reorganize component structure` |

See: [`commit.md`](../../.opencode/command/commit.md) for the full emoji reference.

---

### `/context` — Context Management

Manages the context knowledge base with multiple sub-operations:

```bash
/context                     # Quick scan, suggest actions
/context harvest             # Extract knowledge from AI summaries -> permanent context
/context harvest .tmp/       # Harvest from specific directory
/context extract from docs/  # Extract context from docs/code/URLs
/context organize dev/       # Restructure flat files -> function-based folders
/context update for Next.js  # Update context when APIs/frameworks change
/context error for {error}   # Add recurring error to knowledge base
/context create {category}   # Create new context category
/context migrate             # Copy global project-intelligence -> local project
/context map                 # View current context structure
/context validate            # Check integrity, references, file sizes
/context compact {file}      # Minimize verbose file to MVI format
```

**Subagent routing:**

| Operations | Routed To |
|------------|-----------|
| harvest, extract, organize, update, error, create, migrate | ContextOrganizer |
| map, validate | ContextScout |

See: [`context.md`](../../.opencode/command/context.md) for the full specification.

---

### `/test` — Testing Pipeline

Runs the complete testing pipeline:

```bash
/test
```

**Steps:**
1. `pnpm type:check` — Type errors
2. `pnpm lint` — Linting errors
3. `pnpm test` — Unit/integration tests
4. Report failures
5. Fix and repeat until all pass

See: [`test.md`](../../.opencode/command/test.md).

---

### `/optimize` — Code Optimization

Analyzes code for performance, security, and potential issues:

```bash
/optimize                    # Analyze current context (open files, recent changes)
/optimize src/auth/          # Analyze specific directory
/optimize src/api/route.ts   # Analyze specific file
```

**Analysis areas:**
- Algorithmic efficiency (O(n^2) patterns, redundant calculations)
- Memory management (leaks, excessive allocations)
- I/O optimization (missing caching, blocking operations)
- Security vulnerabilities (injection, XSS, exposed secrets)
- Edge cases (null handling, race conditions)
- Maintainability (duplication, complexity, coupling)

See: [`optimize.md`](../../.opencode/command/optimize.md).

---

## Command Definition Format

Commands are Markdown files with YAML frontmatter:

```yaml
---
description: Create well-formatted commits with conventional commit messages
tags: [git, commit, conventional]
dependencies:
  - subagent:context-organizer    # Optional: requires specific subagent
  - context:core/standards/...    # Optional: requires specific context
---

# Command Title

Instructions for the agent when this command is invoked...
```

The `$ARGUMENTS` variable contains any arguments passed after the command name.

---

## Skills System

Skills are reusable capabilities that agents can load on demand. They live in [`.opencode/skills/`](../../.opencode/skills/).

### Task Management Skill

| Attribute | Value |
|-----------|-------|
| Location | [`.opencode/skills/task-management/`](../../.opencode/skills/task-management/) |
| Entry point | `router.sh` -> `scripts/task-cli.ts` |
| Purpose | CLI for tracking subtask status, dependencies, completion |
| Spec | [`SKILL.md`](../../.opencode/skills/task-management/SKILL.md) |

**Architecture:**
```
.opencode/skills/task-management/
├── SKILL.md                  # Skill documentation
├── router.sh                 # CLI router (entry point)
└── scripts/
    └── task-cli.ts           # TypeScript CLI implementation
```

**Commands:** `status`, `next`, `parallel`, `deps`, `blocked`, `complete`, `validate`, `help`

See: [04-task-management.md](./04-task-management.md) for detailed CLI usage.

---

### Context7 Skill

| Attribute | Value |
|-----------|-------|
| Location | [`.opencode/skills/context7/`](../../.opencode/skills/context7/) |
| Purpose | Fetch live documentation from the [Context7 API](https://context7.com) |
| Spec | [`SKILL.md`](../../.opencode/skills/context7/SKILL.md) |
| API key | Not required for basic usage (rate-limited) |

**Workflow:**

```bash
# Step 1: Search for library ID
curl -s "https://context7.com/api/v2/libs/search?libraryName=react&query=hooks" \
  | jq '.results[0].id'
# Returns: "/websites/react_dev_reference"

# Step 2: Fetch documentation
curl -s "https://context7.com/api/v2/context?libraryId=/websites/react_dev_reference&query=useState&type=txt"
```

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `libraryName` | Yes (search) | Library name (e.g., "react", "nextjs") |
| `libraryId` | Yes (context) | Library ID from search results |
| `query` | Yes | Topic to search for |
| `type` | No | Response format: `json` (default) or `txt` |

**Supported libraries:** React, Next.js, Drizzle, Prisma, Better Auth, NextAuth.js, Clerk, TanStack Query/Router, Cloudflare Workers, AWS Lambda, Vercel, shadcn/ui, Radix UI, Tailwind CSS, Zustand, Jotai, Zod, React Hook Form, Vitest, Playwright.

**Tips:**
- Use `type=txt` for more readable output
- Use `jq` to filter JSON responses
- Be specific with `query` for better relevance
- URL-encode spaces with `+` or `%20`

See: [Context7 website](https://context7.com) for the full API documentation.

---

## Further Reading

- **Next:** [06-permissions-and-data-flow.md](./06-permissions-and-data-flow.md) — Permissions and data flow
- **Command directory:** [`.opencode/command/`](../../.opencode/command/)
- **Skills directory:** [`.opencode/skills/`](../../.opencode/skills/)
- **OpenCode CLI docs:** [opencode.ai/docs](https://opencode.ai/docs)
