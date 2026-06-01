# Agent Skills

Portable skills for AI coding agents.

This repo publishes self-contained `SKILL.md` folders that can be installed into Codex, Claude Code, GitHub Copilot agent skills, and other harnesses that understand the Agent Skills layout.

## Skills

| Skill | Purpose |
|---|---|
| `spec-driven-workflow` | Clarify fuzzy requests, draft and self-review a bounded spec, implement, verify, and preserve local project memory. |
| `pr-land` | Wait for CI, gate on PR readiness, merge a GitHub PR, delete branches, and return to the base branch. |

## Install From GitHub

If your environment supports the `skills` CLI:

```bash
npx skills add https://github.com/yihuil1992/agent-skills --skill spec-driven-workflow
npx skills add https://github.com/yihuil1992/agent-skills --skill pr-land
```

You can also install from this repository manually. The `dist/` directory contains ready-to-copy layouts for common harnesses.

### Codex / Generic Agents

Project-local:

```bash
cp -R dist/agents/.agents your-project/
```

User-wide:

```bash
mkdir -p ~/.agents/skills
cp -R dist/agents/.agents/skills/* ~/.agents/skills/
```

### Claude Code

Project-local:

```bash
cp -R dist/claude/.claude your-project/
```

User-wide:

```bash
mkdir -p ~/.claude/skills
cp -R dist/claude/.claude/skills/* ~/.claude/skills/
```

### GitHub Copilot Agent Skills

Project-local:

```bash
cp -R dist/github/.github your-project/
```

## Install With Scripts

Windows PowerShell:

```powershell
.\scripts\install-skill.ps1 -Skill spec-driven-workflow -Target codex
.\scripts\install-skill.ps1 -Skill pr-land -Target codex
.\scripts\install-skill.ps1 -Skill spec-driven-workflow -Target claude
.\scripts\install-skill.ps1 -Skill pr-land -Target claude
```

macOS / Linux:

```bash
./scripts/install-skill.sh --skill spec-driven-workflow --target codex
./scripts/install-skill.sh --skill pr-land --target codex
./scripts/install-skill.sh --skill spec-driven-workflow --target claude
./scripts/install-skill.sh --skill pr-land --target claude
```

## Repository Layout

```text
skills/    source of truth for each skill
dist/      generated provider layouts for direct copying
scripts/   install, build, and validation helpers
docs/      compatibility notes
```

Author changes in `skills/`, then rebuild `dist/`.

## Build And Validate

Windows PowerShell:

```powershell
.\scripts\build-dist.ps1
.\scripts\validate-skills.ps1
```

macOS / Linux:

```bash
./scripts/build-dist.sh
./scripts/validate-skills.sh
```

Validation checks frontmatter, required files, obvious placeholder text, and bundled script syntax.

## Compatibility

See [docs/compatibility.md](docs/compatibility.md).

