#!/usr/bin/env bash
set -euo pipefail

pr=""
merge_method="squash"
timeout_minutes=60
poll_seconds=30
required_only=0
skip_review_gate=0
keep_remote_branch=0
keep_local_branch=0
no_pull=0
yes=0

usage() {
  cat <<'EOF'
Usage: land-pr.sh [--pr PR_OR_URL] [--merge-method merge|squash|rebase] [--timeout-minutes N] [--poll-seconds N] [--required-only] [--skip-review-gate] [--keep-remote-branch] [--keep-local-branch] [--no-pull] [--yes]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)
      pr="${2:-}"
      shift 2
      ;;
    --merge-method)
      merge_method="${2:-}"
      shift 2
      ;;
    --timeout-minutes)
      timeout_minutes="${2:-}"
      shift 2
      ;;
    --poll-seconds)
      poll_seconds="${2:-}"
      shift 2
      ;;
    --required-only)
      required_only=1
      shift
      ;;
    --skip-review-gate)
      skip_review_gate=1
      shift
      ;;
    --keep-remote-branch)
      keep_remote_branch=1
      shift
      ;;
    --keep-local-branch)
      keep_local_branch=1
      shift
      ;;
    --no-pull)
      no_pull=1
      shift
      ;;
    --yes)
      yes=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$merge_method" in
  merge|squash|rebase) ;;
  *)
    echo "Invalid --merge-method: $merge_method" >&2
    exit 2
    ;;
esac

command -v git >/dev/null
command -v gh >/dev/null
command -v python3 >/dev/null

run() {
  echo "> $*"
  "$@"
}

capture() {
  "$@"
}

json_get() {
  local expr="$1"
  python3 -c 'import json,sys; data=json.load(sys.stdin); value=eval(sys.argv[1], {}, {"data": data}); print("" if value is None else value)' "$expr"
}

local_branch_exists() {
  git show-ref --verify --quiet "refs/heads/$1"
}

ref_sha() {
  git rev-parse "$1"
}

unstage_ignored_paths() {
  local staged
  staged="$(git diff --cached --name-only)"
  [[ -n "$staged" ]] || return 0

  local ignored=()
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    if git check-ignore --quiet --no-index -- "$path"; then
      ignored+=("$path")
    else
      status=$?
      if [[ "$status" -ne 1 ]]; then
        echo "git check-ignore failed with exit code $status for path: $path" >&2
        exit 1
      fi
    fi
  done <<< "$staged"

  if [[ ${#ignored[@]} -gt 0 ]]; then
    echo "Unstaging ignored path(s):"
    printf -- '- %s\n' "${ignored[@]}"
    run git restore --staged -- "${ignored[@]}"
  fi
}

wait_for_checks() {
  local selector="$1"
  local deadline="$2"
  local args=(pr checks "$selector" --json bucket,name,state,link,workflow)
  if [[ "$required_only" -eq 1 ]]; then
    args+=(--required)
  fi

  while true; do
    local raw
    set +e
    raw="$(gh "${args[@]}" 2>&1)"
    local exit_code=$?
    set -e
    if [[ "$exit_code" -ne 0 && "$exit_code" -ne 8 ]]; then
      echo "$raw" >&2
      exit "$exit_code"
    fi

    if [[ -z "$raw" ]]; then
      echo "No CI checks reported for PR $selector."
      return 0
    fi

    local status
    status="$(CHECKS_JSON="$raw" python3 - <<'PY'
import json, os
data = json.loads(os.environ["CHECKS_JSON"])
if not data:
    print("empty")
    raise SystemExit
failed = [c for c in data if c.get("bucket") in ("fail", "cancel")]
pending = [c for c in data if c.get("bucket") == "pending"]
if failed:
    print("failed")
    for c in failed:
        print(f"- {c.get('name')}: {c.get('state')} {c.get('link') or ''}")
elif pending:
    print("pending")
    print(len(pending))
    for c in pending:
        print(f"- {c.get('name')}: {c.get('state')}")
else:
    print("passed")
PY
)"
    local first_line
    first_line="$(printf '%s\n' "$status" | sed -n '1p')"

    case "$first_line" in
      empty)
        echo "No CI checks reported for PR $selector."
        return 0
        ;;
      failed)
        echo "CI did not pass:" >&2
        printf '%s\n' "$status" | sed '1d' >&2
        exit 1
        ;;
      passed)
        echo "CI checks passed for PR $selector."
        return 0
        ;;
      pending)
        if [[ "$(date +%s)" -ge "$deadline" ]]; then
          echo "Timed out after $timeout_minutes minute(s) waiting for CI:" >&2
          printf '%s\n' "$status" | sed '1,2d' >&2
          exit 1
        fi
        local count
        count="$(printf '%s\n' "$status" | sed -n '2p')"
        echo "Waiting for $count pending check(s). Next poll in ${poll_seconds}s."
        sleep "$poll_seconds"
        ;;
      *)
        echo "Unexpected CI parser output: $status" >&2
        exit 1
        ;;
    esac
  done
}

repo_root="$(git rev-parse --show-toplevel)"
current_branch="$(git branch --show-current)"
unstage_ignored_paths

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree has uncommitted changes. Commit, stash, or confirm a narrower cleanup before landing the PR." >&2
  exit 1
fi

view_args=(pr view)
if [[ -n "$pr" ]]; then
  view_args+=("$pr")
fi
view_args+=(--json number,title,url,headRefName,headRefOid,baseRefName,isDraft,reviewDecision,mergeStateStatus)
pr_json="$(gh "${view_args[@]}")"

selector="$(printf '%s' "$pr_json" | json_get 'data["number"]')"
title="$(printf '%s' "$pr_json" | json_get 'data["title"]')"
url="$(printf '%s' "$pr_json" | json_get 'data["url"]')"
head_branch="$(printf '%s' "$pr_json" | json_get 'data["headRefName"]')"
head_oid="$(printf '%s' "$pr_json" | json_get 'data["headRefOid"]')"
base_branch="$(printf '%s' "$pr_json" | json_get 'data["baseRefName"]')"
is_draft="$(printf '%s' "$pr_json" | json_get 'data["isDraft"]')"
review_decision="$(printf '%s' "$pr_json" | json_get 'data["reviewDecision"]')"

echo "PR #$selector: $title"
echo "$url"
echo "Head: $head_branch ($head_oid)"
echo "Base: $base_branch"
echo "Merge method: $merge_method"

if [[ "$is_draft" == "True" || "$is_draft" == "true" ]]; then
  echo "PR #$selector is still a draft." >&2
  exit 1
fi

if [[ "$skip_review_gate" -ne 1 ]]; then
  if [[ "$review_decision" == "CHANGES_REQUESTED" ]]; then
    echo "PR #$selector has requested changes." >&2
    exit 1
  fi
  if [[ "$review_decision" == "REVIEW_REQUIRED" ]]; then
    echo "PR #$selector still requires review approval." >&2
    exit 1
  fi
fi

branch_to_delete="$head_branch"
local_branch_matches_pr_head=0
if local_branch_exists "$head_branch"; then
  local_head="$(ref_sha "$head_branch")"
  if [[ "$local_head" == "$head_oid" ]]; then
    local_branch_matches_pr_head=1
  elif [[ "$current_branch" == "$head_branch" ]]; then
    echo "Local branch '$head_branch' is at $local_head, but the PR head is $head_oid. Push, pull, or reconcile before landing." >&2
    exit 1
  else
    echo "Warning: local branch '$head_branch' does not match the PR head; local branch cleanup will be skipped." >&2
  fi
fi

if [[ "$yes" -ne 1 ]]; then
  echo "Dry run only. Re-run with --yes to wait for checks, merge, and clean up."
  exit 0
fi

deadline=$(( $(date +%s) + timeout_minutes * 60 ))
wait_for_checks "$selector" "$deadline"

merge_args=(pr merge "$selector" "--$merge_method")
if [[ "$keep_remote_branch" -ne 1 ]]; then
  merge_args+=(--delete-branch)
fi
run gh "${merge_args[@]}"

run git fetch origin "$base_branch"
if local_branch_exists "$base_branch"; then
  run git checkout "$base_branch"
else
  run git checkout -b "$base_branch" "origin/$base_branch"
fi

if [[ "$no_pull" -ne 1 ]]; then
  run git pull --ff-only origin "$base_branch"
fi

if [[ "$keep_local_branch" -ne 1 && "$branch_to_delete" != "$base_branch" ]] && local_branch_exists "$branch_to_delete"; then
  if [[ "$local_branch_matches_pr_head" -eq 1 ]]; then
    run git branch -D "$branch_to_delete"
  else
    echo "Warning: skipped local branch deletion for '$branch_to_delete' because it did not match the PR head SHA." >&2
  fi
fi

echo "Landed PR #$selector and returned to $base_branch in $repo_root."
