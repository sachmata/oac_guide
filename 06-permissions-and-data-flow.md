# Permissions & End-to-End Data Flow

> **Reading order:** File 7 of 9. Previous: [05-commands-and-skills.md](./05-commands-and-skills.md) | Next: [07-customization.md](./07-customization.md)

---

## Permission Model

Every agent has explicit permission declarations in its YAML frontmatter. Permissions are scoped by tool type and matched with glob patterns.

### Permission Levels

| Level | Meaning | User Prompt |
|-------|---------|-------------|
| `"allow"` | Silent execution | No |
| `"ask"` | Requires user approval | Yes |
| `"deny"` | Blocked entirely, cannot be overridden | N/A |

### Example: OpenAgent Permissions

From [`agent/core/openagent.md`](../../.opencode/agent/core/openagent.md):

```yaml
permission:
  bash:
    "*": "ask"              # Default: ask user before running any command
    "rm -rf *": "ask"       # Destructive: ask
    "rm -rf /*": "deny"     # System-wide delete: absolute deny
    "sudo *": "deny"        # Privilege escalation: deny
    "> /dev/*": "deny"      # Device writes: deny
  edit:
    "**/*.env*": "deny"     # Never edit environment files
    "**/*.key": "deny"      # Never edit key files
    "**/*.secret": "deny"   # Never edit secret files
    "node_modules/**": "deny" # Never edit dependencies
    ".git/**": "deny"       # Never edit git internals
```

### Example: ContextScout Permissions (Most Restricted)

From [`agent/subagents/core/contextscout.md`](../../.opencode/agent/subagents/core/contextscout.md):

```yaml
permission:
  read:
    "*": "allow"            # Can read anything
  grep:
    "*": "allow"            # Can search anything
  glob:
    "*": "allow"            # Can glob anything
  bash:
    "*": "deny"             # Cannot run any commands
  edit:
    "*": "deny"             # Cannot edit anything
  write:
    "*": "deny"             # Cannot write anything
  task:
    "*": "deny"             # Cannot delegate to anyone
```

### Example: CoderAgent Permissions (Scoped)

From [`agent/subagents/code/coder-agent.md`](../../.opencode/agent/subagents/code/coder-agent.md):

```yaml
permission:
  bash:
    "*": "deny"                                                    # Default: deny
    "bash .opencode/skills/task-management/router.sh complete*": "allow"  # Can mark tasks complete
    "bash .opencode/skills/task-management/router.sh status*": "allow"   # Can check status
  edit:
    "**/*.env*": "deny"     # Standard secret protection
    "**/*.key": "deny"
    "node_modules/**": "deny"
    ".git/**": "deny"
  task:
    contextscout: "allow"   # Can discover context
    externalscout: "allow"  # Can fetch external docs
    TestEngineer: "allow"   # Can delegate to test engineer
```

### Permission Design Principles

1. **Least privilege:** Subagents get only the permissions they need
2. **Secret protection:** `.env`, `.key`, `.secret` files are universally denied
3. **Infrastructure protection:** `node_modules/`, `.git/` are universally denied
4. **Delegation scoping:** Subagents can only delegate to explicitly allowed agents
5. **Bash scoping:** Subagents get specific command patterns, not wildcard access

---

## End-to-End Data Flow

Here's the complete data flow for a typical complex feature request through OpenCoder:

```
User: "Create a user authentication system"
  |
  v
OpenCoder (Stage 1: Discover)
  |
  +-- Delegates to ContextScout
  |     Reads navigation.md --> Finds:
  |       [Critical] core/standards/code-quality.md
  |       [Critical] core/standards/security-patterns.md
  |       [Critical] project-intelligence/technical-domain.md
  |       [ExternalScout Recommendation] "Better Auth" not found internally
  |
  +-- Delegates to ExternalScout (external libs detected)
  |     Fetches live docs via Context7 API
  |     Writes to .tmp/external-context/better-auth/setup.md
  |     Returns: file locations + summary
  |
  v
OpenCoder (Stage 2: Propose)
  |
  |  Presents lightweight plan:
  |    What: JWT-based auth with refresh tokens
  |    Components: Auth service, JWT middleware, login endpoint
  |    Approach: Delegate to TaskManager
  |    Context discovered: [list of paths]
  |    External docs: Better Auth setup
  |
  |  --> User approves
  |
  v
OpenCoder (Stage 3: Init Session)
  |
  |  Creates: .tmp/sessions/2026-02-25-user-auth/context.md
  |    Contains:
  |      - Current request (verbatim)
  |      - Context files (standards to follow)
  |      - Reference files (source material)
  |      - External docs fetched
  |      - Components, constraints, exit criteria
  |
  v
OpenCoder (Stage 4: Plan)
  |
  +-- Delegates to TaskManager
  |     Reads: session context.md
  |     Creates: .tmp/tasks/user-auth/
  |       task.json
  |       subtask_01.json (parallel: true, no deps)
  |       subtask_02.json (parallel: true, no deps)
  |       subtask_03.json (depends_on: [01, 02])
  |       subtask_04.json (depends_on: [03])
  |
  |  --> User confirms task plan
  |
  v
OpenCoder (Stage 5: Execute)
  |
  |  Batch 1 (parallel):
  |  +-- Delegates subtask_01 to CoderAgent
  |  |     1. Calls ContextScout (discovers standards)
  |  |     2. Reads context_files from subtask JSON
  |  |     3. Reads reference_files
  |  |     4. Implements deliverables
  |  |     5. Runs Self-Review Loop
  |  |     6. Marks complete via router.sh
  |  |
  |  +-- Delegates subtask_02 to CoderAgent (simultaneously)
  |        (same workflow as above)
  |
  |  --> Verify batch complete: router.sh status user-auth
  |
  |  Batch 2 (sequential):
  |  +-- Delegates subtask_03 to CoderAgent
  |        (depends on 01+02 being complete)
  |
  |  Batch 3 (sequential):
  |  +-- Delegates subtask_04 to CoderAgent
  |        (depends on 03 being complete)
  |
  v
OpenCoder (Stage 6: Validate & Handoff)
  |
  +-- Suggests TestEngineer for tests
  +-- Suggests CodeReviewer for security review
  +-- Summarizes what was built
  +-- Asks user to clean up .tmp/ files
```

### File System Artifacts

After a complete feature implementation, the `.tmp/` directory contains:

```
.tmp/
├── sessions/
│   └── 2026-02-25-user-auth/
│       └── context.md              # Session context (single source of truth)
├── tasks/
│   └── user-auth/
│       ├── task.json               # Feature metadata
│       ├── subtask_01.json         # Completed subtask
│       ├── subtask_02.json         # Completed subtask
│       ├── subtask_03.json         # Completed subtask
│       └── subtask_04.json         # Completed subtask
└── external-context/
    └── better-auth/
        └── setup.md                # Cached external docs
```

All `.tmp/` files are ephemeral. The agent asks for confirmation before cleanup.

---

## Context Flow Summary

```
                    ContextScout
                   (read-only discovery)
                         |
                         v
    .opencode/context/  --->  context file paths
         |                         |
         |                         v
         |                  Session context.md
         |                  (single source of truth)
         |                         |
         |              +----------+----------+
         |              |          |          |
         v              v          v          v
    Standards      TaskManager  CoderAgent  TestEngineer
    (loaded by       (reads      (reads      (reads
     all agents)     context.md)  context.md)  context.md)
```

**Key principle:** ContextScout discovers paths. The orchestrator persists them into `context.md`. All downstream agents read from `context.md`. No re-discovery needed.

---

## Further Reading

- **Next:** [07-customization.md](./07-customization.md) — Customization points
- **OpenAgent permissions:** [`agent/core/openagent.md`](../../.opencode/agent/core/openagent.md) (lines 6-18)
- **OpenCoder permissions:** [`agent/core/opencoder.md`](../../.opencode/agent/core/opencoder.md) (lines 6-22)
- **ContextScout permissions:** [`agent/subagents/core/contextscout.md`](../../.opencode/agent/subagents/core/contextscout.md) (lines 5-19)
- **Session management workflow:** [`workflows/session-management.md`](../../.opencode/context/core/workflows/session-management.md)
