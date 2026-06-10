---
name: spec-driven-workflow
description: "Use when an AI coding agent should turn a complex or fuzzy request into a bounded implementation workflow: clarify requirements without overwhelming the user, bootstrap local AGENT/SYSTEM_MAP/WIP/ADR docs when missing, draft and self-review a task spec from fresh perspectives, converge it to approval, implement it with the current agent by default, verify the work, and preserve follow-up memory in SYSTEM_MAP/ADR/AGENT or a checklist. Trigger on requests like '走 spec 流程', '先 brainstorm', '先写 spec', '自己审到 approved', '需求比较复杂', '等着验收', or when repository AGENT(S), docs/wip, agent-docs/wip, ADR, SYSTEM_MAP, or local project-memory workflows are involved."
---

# Spec Driven Workflow

## Default Promise

Use this skill to run a complete local engineering loop:

1. Clarify the user's intent with a bounded question budget.
2. Draft or update a local spec.
3. Review the spec from fresh perspectives until actionable findings converge.
4. Get user approval only when the local workflow or risk requires it.
5. Implement with the current agent by default.
6. Verify, summarize, and promote durable memory to the right local document.
7. Pass the final Verification And Memory Gate before responding.

Do not involve another model, tool, or cross-agent handoff unless the user explicitly asks. The normal experience should be: clarify once, then run autonomously until the work is ready for user acceptance.

## Invocation Contract

When this skill is invoked by name or tag, treat that as an explicit request to run this workflow. The user does not need to also say "strictly follow the process".

Invocation examples include `@Spec-Driven Workflow`, `$spec-driven-workflow`, `Spec Driven Workflow`, `Spec Driven Develop`, `走 spec 流程`, `先 brainstorm`, and `先写 spec`.

At the start of the response, state:

- `Mode: spec-driven-workflow`
- `Workflow strictness: strict` or `Workflow strictness: lightweight`

Default to `strict` when the request is complex or fuzzy, asks for implementation, mentions repository workflow docs, or expects the agent to run until acceptance. In strict mode, run bootstrap detection, the Brainstorm Gate, spec convergence when needed, same-agent execution by default, verification, and the Verification And Memory Gate.

Use `lightweight` only when the user explicitly asks for a quick/direct answer, says not to write a spec, asks only a question about the skill, or the task is clearly trivial. If any phase is skipped, say which phase was skipped and why.

## Workflow

### 0. Bootstrap Detection

First determine whether this is a mature repo, partial repo, fresh repo, or loose folder. Read [bootstrap.md](references/bootstrap.md) when any local workflow document may be missing, or when the project is new to agent work.

Detect:

- `AGENTS.md` or `AGENT.md`
- `docs/SYSTEM_MAP.md` or `agent-docs/SYSTEM_MAP.md`
- `docs/wip/` or `agent-docs/wip/`
- `docs/adr/` or `agent-docs/adr/`
- `agent-memory-inbox.html`, `local-notes-checklist.html`, or similar

Never fail only because those files are absent. Use bootstrap or temporary mode.

### 1. Bounded Brainstorm

Before writing a spec in strict mode, complete the Brainstorm Gate. Read [bounded-brainstorm.md](references/bounded-brainstorm.md).

The Brainstorm Gate is non-optional in strict mode. Existing docs, tickets, or project briefs may reduce the number of questions to zero, but they do not remove the need to state the gate result.

At the start of this phase, write one of:

- `Brainstorm Gate: running bounded brainstorm`
- `Brainstorm Gate: no user questions needed; proceeding with stated assumptions`
- `Brainstorm Gate: skipped because <explicit user opt-out or trivial task>`

Only use the no-question path when the available input already covers goal, target user or workflow, constraints, acceptance shape, likely non-goals, and high-risk unknowns. Then list the working assumptions before drafting the spec.

Only skip the gate when the user explicitly asks not to brainstorm, explicitly asks for a quick/direct answer, or the task is clearly trivial. If skipped, say why.

Default limits:

- Ask at most 3 questions per round.
- Use a default total budget of 8 questions; use 12 only for unusually complex work.
- Tell the user the question count and estimated remaining rounds.
- Stop asking once no blocking decisions remain, even if interesting details remain.

### 2. Task Risk And Spec Decision

Classify the work:

- Small: direct implementation is allowed.
- Medium: draft a spec unless the user opts out.
- High risk: draft a spec and converge it before implementation.

High-risk examples include auth, roles, permissions, workflow/state machines, migrations, sync, email/outbox, backup/reset, search semantics, sensitive fields, historical data interpretation, and ADR-bound behavior.

### 3. Spec Convergence

Use the repo's local template when present. Otherwise create a minimal temporary spec. Read [spec-convergence.md](references/spec-convergence.md).

Review rounds must start from a fresh angle instead of only checking the previous diff. Default perspectives:

1. Product and acceptance.
2. Architecture, SYSTEM_MAP, and ADR.
3. Implementation, verification, and file scope.
4. UI and interaction, only when relevant.

After 3 divergent rounds, converge: accept only blocking or high-risk findings, avoid scope expansion, and decide whether the spec is executable.

### 4. Execution Mode

Default to same-agent execution after convergence because the current agent has the richest context. Use a sub-agent only when the user asks, context is exhausted, or a fresh implementation pass has concrete value.

Before implementation:

- Confirm approval status required by local workflow.
- Check for dirty worktree overlap.
- Respect the spec's affected-file scope.
- Stop and update the spec if implementation must exceed scope.

### 5. Verification And Memory

After implementation:

- Run focused verification appropriate to the risk.
- Fill the spec execution summary when a spec exists.
- Promote durable information into SYSTEM_MAP, ADR, or AGENT(S) when it belongs there.
- Put secondary unresolved memory into a local checklist inbox. Read [memory-inbox.md](references/memory-inbox.md).

Before the final response, complete the non-optional Verification And Memory Gate:

- verification run or explicitly skipped with reason
- spec execution summary filled, or no spec existed
- SYSTEM_MAP/ADR/AGENT(S) reviewed for durable updates
- memory inbox reviewed for secondary notes
- final response ready

The final response must include a `Memory handling:` line with one of: `promoted`, `added to inbox`, `none`, or `deferred`, plus the destination or reason. Final response to the user should be an acceptance packet: what changed, verification run, open risks, docs/memory updates, and where to review the result.
