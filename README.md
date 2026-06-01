# Agent Skills

Portable skills for AI coding agents.

This repository stores skill folders that can be copied into agent-specific skill directories such as Codex skills or Claude Code skills. Each skill is self-contained and starts with a `SKILL.md` file. Optional support files live next to it under folders such as `references/`, `scripts/`, and `agents/`.

## Skills

| Skill | Purpose |
|---|---|
| `spec-driven-workflow` | Clarify fuzzy requests, draft and self-review a bounded spec, implement, verify, and preserve local project memory. |
| `pr-land` | Wait for CI, gate on PR readiness, merge a GitHub PR, delete branches, and return to the base branch. |

## Install

Copy one skill folder into your agent's skill directory.

### Windows PowerShell

Codex:

```powershell
.\scripts\install-skill.ps1 -Skill spec-driven-workflow -Target codex
.\scripts\install-skill.ps1 -Skill pr-land -Target codex
```

Claude Code:

```powershell
.\scripts\install-skill.ps1 -Skill spec-driven-workflow -Target claude
.\scripts\install-skill.ps1 -Skill pr-land -Target claude
```

### macOS / Linux

Codex:

```bash
./scripts/install-skill.sh --skill spec-driven-workflow --target codex
./scripts/install-skill.sh --skill pr-land --target codex
```

Claude Code:

```bash
./scripts/install-skill.sh --skill spec-driven-workflow --target claude
./scripts/install-skill.sh --skill pr-land --target claude
```

You can also copy manually:

```text
skills/<skill-name>/ -> ~/.codex/skills/<skill-name>/
skills/<skill-name>/ -> ~/.claude/skills/<skill-name>/
```

Agent-specific metadata such as `agents/openai.yaml` is harmless for agents that ignore it.

## Validate

Windows PowerShell:

```powershell
.\scripts\validate-skills.ps1
```

macOS / Linux:

```bash
./scripts/validate-skills.sh
```

Validation checks frontmatter, required files, obvious placeholder text, and bundled script syntax.

## Compatibility

See [docs/compatibility.md](docs/compatibility.md).
