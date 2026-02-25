# Knowledge Persistence — How Project Knowledge Is Saved

> **Reading order:** File 10 of 10. Previous: [08-reference.md](./08-reference.md)

---

OAC has **four distinct knowledge layers**, each with a different persistence mechanism and trigger model. None are fully automatic — OAC is deliberately human-in-the-loop.

## The Four Layers at a Glance

| Layer | What | Where | Trigger | Persistence | Automated? |
|-------|------|-------|---------|-------------|------------|
| **Project Intelligence** | Your patterns, tech stack, decisions | `.opencode/context/project-intelligence/` | User runs `/add-context` | Git-committed, permanent | No |
| **External Docs Cache** | Library documentation | `.tmp/external-context/` | Agent fetches during approved workflow | 7-day cache, not committed | Semi |
| **Session Context** | Task assembly (paths, constraints) | `.tmp/sessions/` | Agent creates after approval | Ephemeral, deleted after task | Semi |
| **Harvested Knowledge** | Extracted from summaries | `.opencode/context/` | User runs `/context harvest` | Git-committed, permanent | No |

---

## Layer 1: Project Intelligence (Permanent, User-Triggered)

**Location:** [`.opencode/context/project-intelligence/`](../../.opencode/context/project-intelligence/)

The core knowledge about YOUR project — tech stack, patterns, naming conventions, security rules, architectural decisions, and living notes.

### Files

| File | Purpose | Local Path |
|------|---------|------------|
| [`technical-domain.md`](../../.opencode/context/project-intelligence/technical-domain.md) | Tech stack, architecture, code patterns | Priority: critical |
| [`business-domain.md`](../../.opencode/context/project-intelligence/business-domain.md) | Business context, problem domain, users | Priority: high |
| [`business-tech-bridge.md`](../../.opencode/context/project-intelligence/business-tech-bridge.md) | How business needs map to technical solutions | Priority: high |
| [`decisions-log.md`](../../.opencode/context/project-intelligence/decisions-log.md) | Architectural decisions with rationale | Priority: high |
| [`living-notes.md`](../../.opencode/context/project-intelligence/living-notes.md) | Active issues, technical debt, questions | Priority: medium |

### Triggers

| Event | Action | Who Does It |
|-------|--------|-------------|
| First setup | `/add-context` wizard (6 questions, ~5 min) | User runs command |
| Tech stack changes | `/add-context --update` or direct edit | User runs command |
| New architectural decision | Edit `decisions-log.md` | User or agent (with approval) |
| New issues/debt discovered | Edit `living-notes.md` | User or agent (with approval) |
| Business direction shifts | Edit `business-domain.md` | User or agent (with approval) |
| Feature launch | Edit `business-tech-bridge.md` | User or agent (with approval) |

### Governance

| Area | Owner | Review Cadence |
|------|-------|----------------|
| Business domain | Product Owner | Per PR + quarterly |
| Technical domain | Tech Lead | Per PR + quarterly |
| Decisions log | Tech Lead | Per decision |
| Living notes | Whole team | Ongoing |

### Version Tracking

Every file has an HTML frontmatter comment:

```html
<!-- Context: project-intelligence/technical | Priority: critical | Version: 1.3 | Updated: 2026-02-25 -->
```

| Change Type | Version Bump |
|-------------|-------------|
| New file | 1.0 |
| Content addition/update | MINOR (1.1, 1.2) |
| Structure change | MAJOR (2.0, 3.0) |

**Verdict: 100% user-triggered.** Nothing writes to project-intelligence without the user either running `/add-context` or approving an edit.

See: [`project-intelligence.md`](../../.opencode/context/core/standards/project-intelligence.md), [`project-intelligence-management.md`](../../.opencode/context/core/standards/project-intelligence-management.md)

---

## Layer 2: External Library Docs (Cached, Semi-Automatic)

**Location:** `.tmp/external-context/{package}/{topic}.md`

Live documentation fetched from external libraries via [Context7 API](https://context7.com). Cached to avoid re-fetching on every task.

### How It Works

```
User mentions external library (e.g., "set up Drizzle")
  |
  v
Agent detects external package during approved workflow
  |
  v
ExternalScout checks cache (.tmp/external-context/.manifest.json)
  |
  +-- Cache hit (<7 days old) --> Return cached file paths
  |
  +-- Cache miss --> Fetch from Context7 API
                     Filter to relevant sections
                     Write to .tmp/external-context/{package}/{topic}.md
                     Update .manifest.json
                     Return file paths
```

### Triggers

| Event | Action | Who Does It |
|-------|--------|-------------|
| User mentions external library | ExternalScout fetches docs | Agent auto-delegates (within approved workflow) |
| Cache hit (<7 days) | Skip fetch, return cached paths | ExternalScout checks automatically |
| Cache stale (>7 days) | Re-fetch from Context7 | ExternalScout on next request |
| Cleanup | Delete `.tmp/external-context/{package}/` | User confirms |

### File Format

Each cached file has a metadata header:

```markdown
---
source: Context7 API
library: Drizzle ORM
package: drizzle-orm
topic: modular-schemas
fetched: 2026-02-25T14:30:22Z
official_docs: https://orm.drizzle.team
---

# Modular Schemas in Drizzle ORM
[Filtered documentation content...]
```

### Downstream Flow

```
ExternalScout persists to disk
  --> Main agent references paths in session context.md
    --> TaskManager includes in subtask JSONs as external_context
      --> CoderAgent reads files (no re-fetching)
```

**Verdict: Semi-automatic.** Fetching and caching happen automatically *within an already-approved workflow*. Cleanup requires user confirmation. Files are never git-committed.

See: [`external-context-management.md`](../../.opencode/context/core/workflows/external-context-management.md), [`external-context-integration.md`](../../.opencode/context/core/workflows/external-context-integration.md)

---

## Layer 3: Session Context (Ephemeral, Agent-Created)

**Location:** `.tmp/sessions/{session-id}/context.md`

A temporary assembly of discovered context paths, references, external docs, constraints, and exit criteria. Created by OpenCoder for complex tasks. Lives only for the duration of a task.

### How It Works

```
User approves plan (Stage 2)
  |
  v
OpenCoder creates session (Stage 3: Init Session)
  .tmp/sessions/2026-02-25-user-auth/
    context.md          <-- Single source of truth
    .manifest.json      <-- Tracks all session files
  |
  v
All downstream agents read from context.md
  (TaskManager, CoderAgent, TestEngineer, etc.)
  |
  v
Task completes
  |
  v
Agent asks: "Clean up session files?"
  --> User confirms --> Session deleted
```

### Triggers

| Event | Action | Who Does It |
|-------|--------|-------------|
| Complex task approved | Create `context.md` | Agent creates (after user approval) |
| Task progresses | Update `last_activity` in manifest | Agent updates automatically |
| Task completes | Ask "Clean up session files?" | User confirms cleanup |
| Stale session (>24h) | Can be auto-removed | Script-based (not currently automated) |

### What context.md Contains

```markdown
# Task Context: User Authentication
Session ID: 2026-02-25-user-auth
Status: in_progress

## Context Files (Standards to Follow)
- .opencode/context/core/standards/code-quality.md
- .opencode/context/core/standards/security-patterns.md

## Reference Files (Source Material)
- src/middleware/auth.ts

## External Context Fetched
- .tmp/external-context/better-auth/setup.md

## Components, Constraints, Exit Criteria
...
```

**Key insight:** Sessions don't create new knowledge — they *assemble* existing knowledge (context paths, references, constraints) into a single file that downstream agents can read.

**Verdict: Agent-created, user-destroyed.** Created automatically as part of the approved workflow. Cleanup always requires user confirmation.

See: [`session-management.md`](../../.opencode/context/core/workflows/session-management.md)

---

## Layer 4: Context Harvesting (Permanent, User-Triggered)

**Location:** `.opencode/context/` (permanent, extracted from `.tmp/` or workspace summaries)

The mechanism for converting ephemeral knowledge (AI summaries, session notes, external docs) into permanent, structured context files.

### How It Works

```
AI summaries accumulate in workspace
  (*OVERVIEW.md, *SUMMARY.md, SESSION-*.md, .tmp/ files)
  |
  v
User runs: /context harvest
  |
  v
System scans for harvestable files
  |
  v
Shows what was found + proposed extraction:
  "Found 3 summary files:
    [A] CONTEXT-SYSTEM-OVERVIEW.md (4.2 KB)
    [B] SESSION-auth-work.md (1.8 KB)
    [C] .tmp/NOTES.md (800 bytes)

   Select items to harvest (A B C or 'all'):"
  |
  v
User selects items
  |
  v
System extracts knowledge --> permanent context files
  (concepts/ examples/ guides/ lookup/ errors/)
  |
  v
System asks: Archive or delete source files?
  --> User confirms
```

### Triggers

| Event | Action | Who Does It |
|-------|--------|-------------|
| AI summaries accumulate | `/context harvest` | User runs command |
| External docs need permanence | `/context harvest .tmp/` | User runs command |
| Context needs reorganization | `/context organize` | User runs command |
| Framework/API changes | `/context update for Next.js 15` | User runs command |
| Recurring error pattern | `/context error for "hooks error"` | User runs command |

### Extraction Targets

Content is classified and routed to the appropriate directory:

| Content Type | Destination |
|-------------|-------------|
| Design decisions | `concepts/` |
| Solutions/patterns | `examples/` |
| Workflows/how-to | `guides/` |
| Reference data | `lookup/` |
| Errors encountered | `errors/` |

### Safety

- Letter-based approval UI (`A B C` or `all`) — never auto-harvest
- Source files archived to `.tmp/archive/harvested/{date}/` by default
- Option to delete permanently (with confirmation)
- All extracted files follow MVI (<200 lines)

**Verdict: 100% user-triggered.** Detection of harvestable files is automatic, but extraction and cleanup always require explicit user selection and confirmation.

See: [`context-system.md`](../../.opencode/context/core/context-system.md), [`harvest.md`](../../.opencode/context/core/context-system/operations/harvest.md)

---

## The Key Design Insight

**OAC has no background automation for knowledge persistence.** There are no file watchers, no git hooks, no cron jobs, no post-commit scripts that automatically update context.

This is deliberate:

1. **Permanent knowledge** (project-intelligence, harvested context) is always user-triggered
2. **Ephemeral knowledge** (sessions, external cache) is agent-managed within approved workflows
3. **Nothing persists to git without explicit user action**

The governance guidelines in [`project-intelligence.md`](../../.opencode/context/core/standards/project-intelligence.md) define trigger-action pairs (e.g., "Business direction shifts -> Update `business-domain.md`"), but these are **responsibilities for humans**, not automated hooks.

### Why No Automation?

| Concern | OAC's Answer |
|---------|-------------|
| What if context drifts from reality? | Human review cadence (per PR + quarterly) |
| What if someone forgets to update? | `living-notes.md` captures debt; `/context validate` checks integrity |
| What about external library updates? | ExternalScout re-fetches when cache expires (7 days) |
| What about session knowledge loss? | `/context harvest` extracts before cleanup |

The trade-off is intentional: **control and accuracy over convenience**. Automated context updates risk introducing stale or incorrect patterns that agents would then propagate across all generated code.

---

## Further Reading

- **Previous:** [08-reference.md](./08-reference.md) — Comparison, installation, quick reference
- **Project intelligence standard:** [`project-intelligence.md`](../../.opencode/context/core/standards/project-intelligence.md)
- **Management guide:** [`project-intelligence-management.md`](../../.opencode/context/core/standards/project-intelligence-management.md)
- **Session management:** [`session-management.md`](../../.opencode/context/core/workflows/session-management.md)
- **External context management:** [`external-context-management.md`](../../.opencode/context/core/workflows/external-context-management.md)
- **External context integration:** [`external-context-integration.md`](../../.opencode/context/core/workflows/external-context-integration.md)
- **Harvest workflow:** [`harvest.md`](../../.opencode/context/core/context-system/operations/harvest.md)
- **Context system spec:** [`context-system.md`](../../.opencode/context/core/context-system.md)
