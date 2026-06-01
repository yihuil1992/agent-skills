# Bounded Brainstorm

Use this before drafting a spec for complex, fuzzy, or hard-to-verbalize requirements.

## Goal

Help the user make the few decisions that actually shape the work, without turning discovery into an endless questionnaire. The desired user experience is:

```text
Describe the idea -> answer bounded questions -> discuss hard choices -> wait for acceptance.
```

## First Response

Do not immediately ask a long list of questions. First restate:

- understood goal
- known requirements
- likely non-goals
- possible user path
- uncertainty list
- risk or disagreement areas

Then ask only the highest-value questions.

## Question Budget

Default budget:

- 3 questions per round
- 8 total questions
- 12 total only for unusually complex or high-risk work
- 1 follow-up per answered question unless a blocking contradiction appears

Every question round must start with progress:

```markdown
Clarification progress: round 1, questions 1-3 of 8. I expect 1-2 more rounds.
```

## Triage Uncertainty

Classify each uncertainty:

- **Blocking**: cannot write a coherent spec without it.
- **High-impact**: affects architecture, data, permissions, major UX, or irreversible cost.
- **Preference**: affects polish or behavior but can use a recommended default.
- **Implementation detail**: choose from project conventions without asking.

Ask only Blocking and a small number of High-impact questions. Convert Preference and Implementation Detail to assumptions.

## Question Format

Keep questions easy to answer:

```markdown
1. [Blocking] Question?
   Why it matters: ...
   Recommended default: ...
```

When useful, offer 2-3 choices, but always allow a free-form answer. Invite the user to say:

```text
use the default
not sure, discuss
defer
```

## Discussion Mode

When the user is unsure, do not add new questions immediately. Compare options:

```markdown
Option A
Best when:
Tradeoff:
Future change cost:

Option B
Best when:
Tradeoff:
Future change cost:

Recommendation:
Conservative default:
```

Record the decision:

```markdown
### Decision Log
- Decision:
- Reason:
- Confidence: high | medium | low
- Revisit trigger:
```

Low-confidence decisions can proceed if they are reversible or can be isolated.

## Stop Asking

Stop clarification when any is true:

- question budget is exhausted
- one full round finds no Blocking questions
- remaining questions can use defaults
- user says "先这样", "just run", or equivalent

Then produce:

- working assumptions
- deferred questions
- accepted risks
- spec-ready summary

If a Blocking decision remains, mark the task blocked instead of guessing.

## During Later Review

Spec review may discover new uncertainty. Do not reopen brainstorming unless the uncertainty is Blocking or changes the target, data model, permission/security posture, or user-visible workflow. Otherwise choose a conservative default and write it into the spec.

