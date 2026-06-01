---
name: pr-land
description: "Land GitHub pull requests after they are ready. Use when an AI coding agent is asked to wait for CI/checks, confirm review state, merge a PR, delete the PR branch, switch back to main/master/base branch, and pull the latest changes after merge. Also use for requests like 'merge this PR after CI', 'land the current PR', 'ship this branch', 'merge and clean up', or Chinese requests that ask to merge after CI and clean up branches."
---

# PR Land

## Overview

Land a ready GitHub PR with guardrails: resolve the current PR, wait for checks, block on draft/requested-changes states, merge, clean up the branch, then return to the base branch and fast-forward pull.

Use the agent's normal "publish PR" workflow first when the user still needs local changes committed, pushed, or a PR opened. Use this skill after a PR exists.

## Workflow

1. Resolve context.
   - Run `git status -sb`, `git branch --show-current`, and `gh pr view --json number,title,url,headRefName,headRefOid,baseRefName,isDraft,reviewDecision,mergeStateStatus`.
   - Before any commit or landing action, inspect staged paths and unstage anything that matches `.gitignore` rules, including files nested inside ignored directories. Prefer `git check-ignore --no-index` so force-added ignored files are caught.
   - If no PR is found for the current branch, ask for a PR number or URL.
   - If the worktree still has uncommitted changes after unstaging ignored paths, stop before merge cleanup unless the user explicitly says they are unrelated and should be left alone.

2. Gate before merge.
   - Stop if the PR is a draft.
   - Stop if `reviewDecision` is `CHANGES_REQUESTED`.
   - Stop if `reviewDecision` is `REVIEW_REQUIRED` unless the user explicitly wants to try merging anyway.
   - If the local checked-out branch is the PR branch, ensure local `HEAD` equals `headRefOid`; otherwise ask whether to push/reconcile first.

3. Wait for CI.
   - Prefer the bundled script from this skill directory.
   - Windows PowerShell:
     ```powershell
     & .\scripts\land-pr.ps1 -Yes
     ```
   - macOS / Linux:
     ```bash
     ./scripts/land-pr.sh --yes
     ```
   - Use `-Pr 123` or `-Pr https://github.com/OWNER/REPO/pull/123` when landing a PR that is not the current branch.
   - In Bash, use `--pr 123` or `--pr https://github.com/OWNER/REPO/pull/123`.
   - Use `-MergeMethod merge`, `-MergeMethod squash`, or `-MergeMethod rebase` when the user specifies a merge strategy. Default to `squash`.
   - In Bash, use `--merge-method merge`, `--merge-method squash`, or `--merge-method rebase`.
   - Use `-RequiredOnly` when the user only wants required checks to gate the merge.
   - In Bash, use `--required-only`.

4. Merge and clean up.
   - The script first unstages ignored files, then merges with `gh pr merge --<method> --delete-branch`, checks out the PR base branch, pulls with `git pull --ff-only origin <base>`, and deletes the matching local PR branch only when it matches the PR head SHA.
   - If the script cannot safely delete the local branch, report the reason and leave it in place.

5. Finish with the concrete result.
   - Include PR number/title, merge method, final branch, whether remote/local branch cleanup happened, and whether `git pull --ff-only` succeeded.

## Manual Fallback

Use this sequence when the script is unavailable or needs adaptation:

```powershell
gh pr checks --watch --fail-fast --interval 30
gh pr view --json number,title,url,headRefName,headRefOid,baseRefName,isDraft,reviewDecision,mergeStateStatus
gh pr merge <number> --squash --delete-branch
git checkout <baseRefName>
git pull --ff-only origin <baseRefName>
git branch -D <headRefName>
```

Before `git branch -D`, verify the local branch exists and its SHA equals the PR `headRefOid`.
