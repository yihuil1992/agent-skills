#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
skills_root="$repo_root/skills"

if [[ ! -d "$skills_root" ]]; then
  echo "Missing skills directory: $skills_root" >&2
  exit 1
fi

shopt -s nullglob
skill_dirs=("$skills_root"/*)
if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  echo "No skill directories found." >&2
  exit 1
fi

for skill_dir in "${skill_dirs[@]}"; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  skill_md="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then
    echo "Missing SKILL.md in $skill_name" >&2
    exit 1
  fi

  if ! grep -Eq '^---[[:space:]]*$' "$skill_md"; then
    echo "Missing YAML frontmatter fence in $skill_md" >&2
    exit 1
  fi

  if ! grep -Eq "^name:[[:space:]]*$skill_name[[:space:]]*$" "$skill_md"; then
    echo "Frontmatter name must match folder name in $skill_md" >&2
    exit 1
  fi

  if ! grep -Eq '^description:[[:space:]].+' "$skill_md"; then
    echo "Missing description in $skill_md" >&2
    exit 1
  fi

  if grep -Eq '\[TODO|TODO:' "$skill_md"; then
    echo "Placeholder TODO remains in $skill_md" >&2
    exit 1
  fi

  while IFS= read -r -d '' sh_script; do
    bash -n "$sh_script"
  done < <(find "$skill_dir" -type f -name '*.sh' -print0)

  echo "Valid: $skill_name"
done

echo "All skills valid."

