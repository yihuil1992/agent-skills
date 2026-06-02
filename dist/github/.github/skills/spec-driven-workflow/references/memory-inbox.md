# Memory Inbox

Use this to preserve useful secondary project memory that is not yet ready for SYSTEM_MAP, ADR, AGENT(S), or the current spec.

## Purpose

The memory inbox is a checklist for "maybe the agent should remember this later" notes. It is not authoritative. Authoritative memory belongs in:

- SYSTEM_MAP for current architecture, commands, routes, states, permissions, and module responsibilities
- ADR for durable decisions that future agents may accidentally reverse
- AGENT(S) for operating instructions and repository workflow rules
- WIP spec for task-specific decisions, evidence, and follow-ups

## File

Prefer one of:

```text
agent-docs/agent-memory-inbox.html
docs/agent-memory-inbox.html
agent-docs/local-notes-checklist.html
.agent-session/memory-inbox.html
```

Use the repo's existing convention. Prefer `agent-docs/` for local-only memory in new bootstraps.

## What To Add

Add entries for:

- user preferences not yet hard rules
- small pitfalls discovered during work
- potential follow-ups that are not part of current acceptance
- undecided design ideas
- reminders the user may want to review between runs
- context that did not fit SYSTEM_MAP/ADR/spec

Do not add:

- architecture decisions that clearly need ADR
- current API, permission, state machine, or data-contract changes that need SYSTEM_MAP/ADR
- one-off execution evidence
- ordinary task TODOs that belong in the spec or issue tracker

## Entry Shape

Keep entries short and structured:

```html
<li>
  <label><input type="checkbox"> Short title</label>
  <div class="meta">
    <strong>Note:</strong> ...
    <strong>Source task:</strong> ...
    <strong>Suggested destination:</strong> SYSTEM_MAP | ADR | AGENT | spec | unsure
    <strong>Added:</strong> YYYY-MM-DD
  </div>
</li>
```

## Minimal HTML Template

Use this for new inboxes:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Agent Memory Inbox</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 900px; margin: 32px auto; line-height: 1.5; }
    h1 { font-size: 24px; }
    li { margin: 14px 0; }
    .meta { margin-left: 28px; color: #444; font-size: 14px; }
    .handled { opacity: .65; }
  </style>
</head>
<body>
  <h1>Agent Memory Inbox</h1>
  <p>Checklist for notes that may later be promoted to SYSTEM_MAP, ADR, AGENT(S), or a task spec.</p>
  <h2>Open</h2>
  <ul>
  </ul>
  <h2>Handled</h2>
  <ul>
  </ul>
</body>
</html>
```

## Start Of Run

At startup:

- read checked items
- process at most 5 checked items per run
- decide per item: promote to SYSTEM_MAP, ADR, AGENT(S), fold into current spec, keep, discard, or ask one bounded clarification
- move handled items to the Handled section

Unchecked items are background only; do not force them into the current task.

## End Of Run

After execution summary and before the final response, classify unresolved notes:

- promoted to SYSTEM_MAP/ADR/AGENT
- added to memory inbox
- left in spec follow-up
- discarded as one-off

Do not dump every thought into the inbox. Add only items with plausible future value.

This end-of-run review is required even when no inbox exists yet. If no inbox exists and no secondary memory exists, report:

```text
Memory handling: none - no secondary memory to preserve
```

If an inbox should exist but is missing, create it only when there is a secondary note worth preserving or the local workflow already expects an inbox. Otherwise do not create an empty file just for ceremony.

## Cleanup

Avoid turning the inbox into a second SYSTEM_MAP:

- summarize rather than load old unchecked items over 30 days
- recommend archiving or deleting items ignored across 3 runs
- keep each entry short
- promote durable facts quickly
