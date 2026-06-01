# Compatibility

## Skill Shape

Each skill is a directory containing:

```text
SKILL.md
references/   optional
scripts/      optional
agents/       optional agent-specific metadata
```

`SKILL.md` is the portable core. Other files are loaded or executed only when the agent chooses to use them.

## Codex

Install to:

```text
~/.codex/skills/<skill-name>/
```

Codex can use `agents/openai.yaml` for UI metadata. The skill still works if that file is absent.

## Claude Code

Install to:

```text
~/.claude/skills/<skill-name>/
```

Claude Code primarily needs `SKILL.md` and support files. It can ignore `agents/openai.yaml`.

## Other Agents

Other agents can use the same folders if they support a `SKILL.md`-style instruction bundle, or they can read the folder directly as local instructions.

## Portability Rules

- Keep `SKILL.md` platform-neutral.
- Keep agent-specific metadata optional.
- Avoid absolute user paths.
- Prefer scripts that run from the skill directory or accept explicit paths.
- Document external CLI dependencies inside the skill.

