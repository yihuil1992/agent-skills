# Bootstrap Detection

Use this reference when a project does not already have a complete local agent workflow, or when the repo is new to this skill.

## Detect Mode

Classify the workspace before assuming any docs exist:

- **Mature repo**: has AGENT(S), SYSTEM_MAP, WIP specs, and ADRs.
- **Partial repo**: has code, but missing some or all workflow docs.
- **Fresh repo**: empty or newly initialized project.
- **Loose folder**: not a git repo or not obviously a project root.

Useful checks:

```powershell
git rev-parse --show-toplevel
git branch --show-current
git status --short
git log --oneline -10
```

If `git rev-parse` fails, do not initialize git unless the user asks.

## Mature Repo Startup

Read, when present:

- `AGENTS.md` or `AGENT.md`
- `docs/SYSTEM_MAP.md` or `agent-docs/SYSTEM_MAP.md`
- `docs/wip/README.md` or `agent-docs/wip/README.md`
- `docs/wip/_template.md` or `agent-docs/wip/_template.md`
- relevant ADR files, or the ADR index first
- active WIP specs that do not end with `.done.md`
- memory inbox checklist

Summarize branch, dirty state, active specs, and any startup blockers before substantive work.

Stop for user confirmation when:

- multiple approved specs are waiting and execution order matters
- dirty worktree changes overlap the requested task
- recent commits touch the same files as the task
- local docs require user approval before implementation

## Partial Repo Bootstrap

If workflow docs are absent but the user wants durable workflow support, create the smallest useful local structure:

```text
AGENTS.md
agent-docs/SYSTEM_MAP.md
agent-docs/adr/README.md
agent-docs/wip/README.md
agent-docs/wip/_template.md
agent-docs/agent-memory-inbox.html
```

Prefer `agent-docs/` for local-only agent memory unless the project already uses `docs/` for the workflow.

Ask only one bootstrap question if needed:

```text
Should I create local workflow docs for this project, or keep this run temporary?
```

Default to temporary mode when the user is unsure.

## Fresh Repo Bootstrap

For an empty or brand-new project, ask at most 3 initial questions:

1. What kind of project is this?
2. Should I create code first, local workflow docs first, or both?
3. Should agent workflow docs be local-only by default?

Use a minimal SYSTEM_MAP skeleton:

```markdown
# System Map

## Purpose
TBD

## Architecture
TBD

## Commands
TBD

## Constraints
TBD

## Open Questions
-
```

Avoid building a heavy process before there is enough project shape to justify it.

## Temporary Mode

Use temporary mode when the user does not want project files yet, the folder is not clearly a repo, or the task is exploratory.

Temporary artifacts may live under:

```text
.agent-session/
  spec.md
  review.md
  memory-inbox.html
```

Do not commit or stage temporary artifacts unless explicitly requested.
