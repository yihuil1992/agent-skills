# Spec Convergence And Execution

Use this after bounded brainstorming or when the user asks to draft/review/approve a spec.

## Spec Contents

Prefer the repository's `_template.md`. If no template exists, include:

- Goal
- Background / context
- Clarifications / decision log
- Affected files
- Data or interface contract
- Existing pattern to follow
- Out of scope
- Constraints / business rules
- Test-first requirement, when relevant
- Acceptance checks
- Baseline verification
- Completion evidence
- Review rounds
- Execution summary

The spec must be self-contained enough that an executing agent does not rely on chat memory.

## Writing Rules

- Keep file scope tight.
- State non-goals explicitly.
- List hard business rules separately from preferences.
- For frontend/backend sync, list fields, validation, state names, dates, permissions, and API contracts that must match.
- Reference ADRs and SYSTEM_MAP sections for constraints that should not be simplified away.
- Put uncertain but nonblocking choices into assumptions or follow-ups.
- Avoid filling specs with irrelevant history.

## Divergent Review Rounds

Run review rounds as fresh perspectives. Each round reviews the whole spec, not only the previous changes.

Default rounds:

1. **Product and acceptance**: user-visible goal, success criteria, edge cases, failure states, ambiguity.
2. **Architecture and ADR**: module boundaries, SYSTEM_MAP, ADRs, data ownership, permissions, state machines.
3. **Implementation and verification**: affected files, existing patterns, migrations, fixtures, tests, rollback, build/check commands.
4. **UI and interaction**: only for UI work; loading, empty, error, responsive, accessibility, design-system reuse, screenshot checks.

Review format:

```markdown
### Round N Review - Perspective

#### New Actionable Findings
- [P1/P2/P3] ...

#### Non-blocking Suggestions
- ...

#### Questions / Human Decisions
- ...

#### Approval Recommendation
Status: NEEDS_CHANGE | APPROVE
```

Severity:

- P1: blocks safe implementation or risks data/security correctness.
- P2: likely behavioral bug, missing acceptance coverage, or scope conflict.
- P3: clarity, maintainability, or useful polish.

## Finding Merge

After each review, merge findings:

- new finding
- duplicate
- already covered
- resolved by existing text
- non-blocking
- requires human decision

Only edit for actionable findings. Add a spec update summary:

```markdown
### Round N Spec Update Summary
- Clarified ...
- Added ...
- Marked ... as out of scope
- Deferred ...
```

Do not expand scope casually. If a required fix needs new files or behavior, update Affected Files and explain why.

## Convergence Phase

After 3 divergent rounds, begin convergence. Default maximum:

```text
divergent rounds: 3
convergence rounds: 2
max rounds: 5
```

In convergence:

- accept only P1/P2 or execution-blocking findings
- reject pure preference churn
- avoid new scope unless required for correctness
- decide if the spec is executable rather than perfect

If max rounds are exhausted and P1/P2 remains, stop with:

```text
BLOCKED: requires user decision
```

## Approval Criteria

Approve when:

- latest round has no new actionable P1/P2 findings
- all prior P1/P2 findings are resolved, downgraded with reason, or converted to user decisions
- affected files are explicit enough
- out-of-scope is explicit enough
- acceptance checks are executable
- verification evidence is defined
- AGENT(S), SYSTEM_MAP, and ADR hard constraints are respected
- implementation does not require guessing business semantics

If local workflow requires user approval, set status to `READY_FOR_USER_APPROVAL` and ask. Otherwise mark the spec approved and proceed.

## Execution Mode

Default: current agent executes. It has the full clarification and review context.

Use sub-agent execution only when:

- user asks for it
- context is too full
- implementation is mechanical and fully scoped
- a fresh execution pass materially reduces risk

If a sub-agent executes, the main agent still owns final review, verification, and memory promotion.

## Implementation Rules

Before editing:

- check dirty worktree overlap
- read relevant files
- respect affected-file scope
- pause and update spec if new required scope appears

During implementation:

- prefer existing local patterns
- keep changes scoped
- add tests proportional to risk
- do not alter local workflow docs unless the spec or user requires it

After implementation:

- run focused verification
- fill execution summary
- record deviations
- rename spec to `.done.md` only when local workflow says completion is ready

## Verification And Memory Gate

This gate is non-optional. Complete it immediately before the final response, even for small tasks and even when there is no memory to add.

Checklist:

- Verification run, or explicitly skipped with reason.
- Spec execution summary filled, or no spec existed.
- SYSTEM_MAP reviewed for durable architecture, command, route, state, permission, or module-responsibility updates.
- ADR reviewed for durable decisions that future agents may accidentally reverse.
- AGENT(S) reviewed for operating rules or workflow instructions.
- Memory inbox reviewed for secondary notes that are useful but not authoritative.
- Final response includes a `Memory handling:` line.

Allowed `Memory handling:` values:

```text
Memory handling: promoted to SYSTEM_MAP/ADR/AGENT(S) - <path or summary>
Memory handling: added to inbox - <path or summary>
Memory handling: none - no durable or secondary memory from this run
Memory handling: deferred - <reason or user decision needed>
```

If memory was added, mention the file path. If memory was not added, say why. This explicit line is the visible closeout check that prevents memory work from being skipped.

Final user response should be an acceptance packet, not a process dump.
