#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
skills_root="$repo_root/skills"
dist_root="$repo_root/dist"

if [[ ! -d "$skills_root" ]]; then
  echo "Missing skills directory: $skills_root" >&2
  exit 1
fi

rm -rf -- "$dist_root"

for layout in agents:.agents/skills claude:.claude/skills github:.github/skills; do
  name="${layout%%:*}"
  path="${layout#*:}"
  target_root="$dist_root/$name/$path"
  mkdir -p "$target_root"
  for skill_dir in "$skills_root"/*; do
    [[ -d "$skill_dir" ]] || continue
    cp -R -- "$skill_dir" "$target_root/"
  done
done

chmod +x \
  "$dist_root/agents/.agents/skills/pr-land/scripts/land-pr.sh" \
  "$dist_root/claude/.claude/skills/pr-land/scripts/land-pr.sh" \
  "$dist_root/github/.github/skills/pr-land/scripts/land-pr.sh"

echo "Built dist layouts in $dist_root"
