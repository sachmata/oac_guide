# Customization — Editing Agents, Patterns, Commands & Skills

> **Reading order:** File 8 of 9. Previous: [06-permissions-and-data-flow.md](./06-permissions-and-data-flow.md) | Next: [08-reference.md](./08-reference.md)

---

Everything in OAC is editable text. No compilation, no vendor lock-in. This page covers all customization points.

## 1. Edit Agent Behavior

Agents are Markdown files. Edit them directly to change behavior, add constraints, or customize workflows.

```bash
# Edit the general-purpose agent
nano .opencode/agent/core/openagent.md

# Edit the production development agent
nano .opencode/agent/core/opencoder.md

# Edit a subagent
nano .opencode/agent/subagents/code/coder-agent.md
```

### Change Model Per Agent

Edit the YAML frontmatter to specify a different model:

```yaml
---
name: OpenCoder
description: "Development specialist"
model: anthropic/claude-sonnet-4-5  # Change this line
temperature: 0.1
---
```

Browse available models at [models.dev](https://models.dev/?search=open) or run `opencode models`.

**Use cases:**
- Faster agents (ContextScout) on cheaper models (Haiku/Flash)
- Complex agents (OpenCoder) on smarter models (Opus/GPT-5)
- Testing different models for different task types

### Add Project-Specific Rules

Add rules directly to the agent's markdown body:

```markdown
<critical_rules>
  <rule id="my_project_rule">
    Always use Drizzle ORM for database queries.
    Never use raw SQL.
  </rule>
</critical_rules>
```

### Modify Permissions

Edit the `permission` block in frontmatter:

```yaml
permission:
  bash:
    "docker *": "allow"     # Allow Docker commands without asking
    "kubectl *": "ask"      # Ask before Kubernetes commands
  edit:
    "src/generated/**": "deny"  # Never edit generated files
```

---

## 2. Add Project Patterns

### Via Wizard (Recommended)

```bash
/add-context                 # Interactive 6-question wizard
/add-context --update        # Update existing patterns
```

This creates/updates [`project-intelligence/technical-domain.md`](../../.opencode/context/project-intelligence/technical-domain.md).

### Via Direct Edit

```bash
nano .opencode/context/project-intelligence/technical-domain.md
```

**Template structure:**

```markdown
<!-- Context: project-intelligence/technical | Priority: critical | Version: 1.0 | Updated: 2026-02-25 -->

# Technical Domain

## Primary Stack
| Layer | Technology | Version | Rationale |
|-------|-----------|---------|-----------|
| Framework | React 19 | 19.x | Component model |
| Language | TypeScript | 5.x | Type safety |

## Code Patterns
### API Endpoint
```typescript
// Your actual API pattern here
```

### Component
```typescript
// Your actual component pattern here
```

## Naming Conventions
| Type | Convention | Example |
|------|-----------|---------|
| Files | kebab-case | `user-profile.tsx` |
| Components | PascalCase | `UserProfile` |

## Code Standards
- TypeScript strict mode
- Zod validation at boundaries

## Security Requirements
- Validate all user input
- Use parameterized queries
```

**Rules:**
- Must include HTML frontmatter comment (first line)
- Must be <200 lines (MVI compliance)
- Must include "Codebase References" section
- Priority should be `critical` for tech stack patterns

---

## 3. Add Context Categories

Create new directories under `.opencode/context/` with a `navigation.md`. ContextScout discovers them automatically.

```bash
# Create a new category
mkdir -p .opencode/context/my-category

# Add navigation file
cat > .opencode/context/my-category/navigation.md << 'EOF'
# My Category Navigation

## Quick Routes
| Task | Path |
|------|------|
| **Pattern A** | `pattern-a.md` |
| **Pattern B** | `pattern-b.md` |
EOF

# Add content files
nano .opencode/context/my-category/pattern-a.md
```

**Update the root navigation** to include your new category:

Edit [`.opencode/context/navigation.md`](../../.opencode/context/navigation.md) and add your category to the structure and routes.

---

## 4. Add Custom Commands

Create a new `.md` file in [`.opencode/command/`](../../.opencode/command/):

```bash
nano .opencode/command/my-command.md
```

**Template:**

```yaml
---
description: Brief description of what this command does
tags: [optional, tags]
dependencies:
  - subagent:context-organizer    # Optional: requires specific subagent
  - context:core/standards/...    # Optional: requires specific context
---

# My Command

Instructions for the agent when `/my-command` is invoked.

The `$ARGUMENTS` variable contains any arguments passed after the command name.

## Workflow

1. Step one...
2. Step two...
3. Step three...
```

**Invoke with:**
```bash
/my-command
/my-command some arguments
```

---

## 5. Add Custom Skills

Create a directory under [`.opencode/skills/`](../../.opencode/skills/) with a `SKILL.md`:

```bash
mkdir -p .opencode/skills/my-skill
nano .opencode/skills/my-skill/SKILL.md
```

**Template:**

```yaml
---
name: my-skill
description: What this skill does
version: 1.0.0
type: skill
category: development
tags:
  - relevant
  - tags
---

# My Skill

## Overview
What this skill provides...

## How to Use Me
Usage instructions...

## Examples
Working examples...
```

Skills can include scripts, templates, and other resources alongside the `SKILL.md`.

**Reference in agent definitions:**

```yaml
permission:
  skill:
    "my-skill": "allow"
```

---

## 6. Add Custom Tools

Create a directory under [`.opencode/tool/`](../../.opencode/tool/):

```bash
mkdir -p .opencode/tool/my-tool
nano .opencode/tool/my-tool/index.ts
```

Tools are TypeScript files that extend the agent's capabilities. See the existing [`tool/env/index.ts`](../../.opencode/tool/env/index.ts) for an example.

---

## 7. Customize for Teams

### Share Patterns via Git

```bash
# Add project intelligence to version control
git add .opencode/context/project-intelligence/
git commit -m "Add team coding standards"
git push

# New team members get patterns automatically
git clone <repo>
# Agents now use team patterns
```

### Local vs Global

| Location | Scope | Use Case |
|----------|-------|----------|
| `.opencode/` (project root) | Project-specific | Team standards, committed to git |
| `~/.config/opencode/` | Personal defaults | Cross-project preferences |

Local always overrides global. Use `/context migrate` to copy global patterns to a local project.

### Per-Project Overrides

Different projects can have completely different patterns:

```
project-a/.opencode/context/project-intelligence/
  technical-domain.md  # Next.js + TypeScript + PostgreSQL

project-b/.opencode/context/project-intelligence/
  technical-domain.md  # FastAPI + Python + MongoDB
```

---

## Customization Checklist

| What | Where | How |
|------|-------|-----|
| Agent behavior | `.opencode/agent/core/*.md` | Edit markdown body |
| Agent model | `.opencode/agent/core/*.md` | Edit `model:` in frontmatter |
| Agent permissions | `.opencode/agent/core/*.md` | Edit `permission:` in frontmatter |
| Project patterns | `.opencode/context/project-intelligence/` | `/add-context` or direct edit |
| Universal standards | `.opencode/context/core/standards/` | Direct edit |
| Workflows | `.opencode/context/core/workflows/` | Direct edit |
| Slash commands | `.opencode/command/*.md` | Create new or edit existing |
| Skills | `.opencode/skills/*/SKILL.md` | Create new directory + SKILL.md |
| Tools | `.opencode/tool/*/index.ts` | Create new directory + index.ts |

---

## Further Reading

- **Next:** [08-reference.md](./08-reference.md) — Comparison, installation, design principles, quick reference
- **Agent files:** [`.opencode/agent/`](../../.opencode/agent/)
- **Context files:** [`.opencode/context/`](../../.opencode/context/)
- **Command files:** [`.opencode/command/`](../../.opencode/command/)
- **OpenCode config docs:** [opencode.ai/docs/config](https://opencode.ai/docs/config/)
- **Upstream contributing guide:** [CONTRIBUTING.md](https://github.com/darrenhinde/OpenAgentsControl/blob/main/docs/contributing/CONTRIBUTING.md)
