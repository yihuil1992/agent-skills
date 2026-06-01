#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/install-skill.sh --skill <spec-driven-workflow|pr-land> --target <codex|claude> [--destination-root DIR] [--force]
EOF
}

skill=""
target=""
destination_root=""
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill)
      skill="${2:-}"
      shift 2
      ;;
    --target)
      target="${2:-}"
      shift 2
      ;;
    --destination-root)
      destination_root="${2:-}"
      shift 2
      ;;
    --force)
      force=1
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

case "$skill" in
  spec-driven-workflow|pr-land) ;;
  *)
    echo "Invalid or missing --skill: $skill" >&2
    usage >&2
    exit 2
    ;;
esac

case "$target" in
  codex|claude) ;;
  *)
    echo "Invalid or missing --target: $target" >&2
    usage >&2
    exit 2
    ;;
esac

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
source_dir="$repo_root/skills/$skill"

if [[ ! -d "$source_dir" ]]; then
  echo "Skill not found: $source_dir" >&2
  exit 1
fi

if [[ -z "$destination_root" ]]; then
  case "$target" in
    codex) destination_root="$HOME/.codex/skills" ;;
    claude) destination_root="$HOME/.claude/skills" ;;
  esac
fi

destination="$destination_root/$skill"
if [[ -e "$destination" && "$force" -ne 1 ]]; then
  echo "Destination already exists: $destination. Re-run with --force to replace it." >&2
  exit 1
fi

mkdir -p "$destination_root"
rm -rf -- "$destination"
cp -R -- "$source_dir" "$destination"
echo "Installed $skill to $destination"

