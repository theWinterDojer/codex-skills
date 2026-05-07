#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="${HOME}/.codex"
REPO_PATH=""
FORCE=0

SKILLS=(
  code-review
  session-init
  execution-ledger
  agent-retrospective
)

usage() {
  cat <<'EOF'
Usage:
  ./install.sh [--codex-home PATH] [--repo PATH] [--force]

Options:
  --codex-home PATH  Install into a different Codex home directory.
  --repo PATH        Also scaffold a repo-local AGENTS.md in the target repo.
  --force            Replace simple-codex-managed targets when they differ.
  --help             Show this help message.
EOF
}

require_value() {
  local option="$1"
  local value="${2:-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    echo "$option requires a path value." >&2
    usage >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --codex-home)
      require_value "$1" "${2:-}"
      CODEX_HOME="$2"
      shift 2
      ;;
    --repo)
      require_value "$1" "${2:-}"
      REPO_PATH="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

MANIFEST_PATH="$CODEX_HOME/simple-codex-manifest.txt"
GLOBAL_AGENTS_PATH="$CODEX_HOME/AGENTS.md"
STAGED_AGENTS_PATH="$CODEX_HOME/AGENTS.simple-codex.md"

mkdir -p "$CODEX_HOME/skills"

dirs_match() {
  local left="$1"
  local right="$2"

  if [[ ! -d "$left" || ! -d "$right" ]]; then
    return 1
  fi

  if diff -qr "$left" "$right" >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

install_skill_dir() {
  local skill_name="$1"
  local src_dir="$SCRIPT_DIR/skills/$skill_name"
  local dest_dir="$CODEX_HOME/skills/$skill_name"

  if [[ -e "$dest_dir" ]]; then
    if dirs_match "$src_dir" "$dest_dir"; then
      echo "unchanged skill: $skill_name"
      return
    fi
    if [[ "$FORCE" -ne 1 ]]; then
      echo "kept existing skill: $skill_name"
      return
    fi
    rm -rf "$dest_dir"
  fi

  cp -r "$src_dir" "$dest_dir"
  echo "installed skill: $skill_name"
}

install_global_agents() {
  local src="$SCRIPT_DIR/AGENTS.md"

  if [[ ! -e "$GLOBAL_AGENTS_PATH" ]]; then
    cp "$src" "$GLOBAL_AGENTS_PATH"
    echo "installed global baseline: $GLOBAL_AGENTS_PATH"
    return
  fi

  if cmp -s "$src" "$GLOBAL_AGENTS_PATH"; then
    echo "unchanged global baseline: $GLOBAL_AGENTS_PATH"
    return
  fi

  if [[ "$FORCE" -eq 1 ]]; then
    cp "$src" "$GLOBAL_AGENTS_PATH"
    echo "replaced global baseline: $GLOBAL_AGENTS_PATH"
    return
  fi

  if [[ -e "$STAGED_AGENTS_PATH" ]] && cmp -s "$src" "$STAGED_AGENTS_PATH"; then
    echo "existing staged baseline preserved: $STAGED_AGENTS_PATH"
    return
  fi

  cp "$src" "$STAGED_AGENTS_PATH"
  echo "kept existing global baseline: $GLOBAL_AGENTS_PATH"
  echo "staged simple-codex baseline at: $STAGED_AGENTS_PATH"
}

install_repo_agents() {
  local src="$SCRIPT_DIR/templates/repo-AGENTS.md"
  local dest="$REPO_PATH/AGENTS.md"
  local staged="$REPO_PATH/AGENTS.simple-codex.md"

  if [[ ! -d "$REPO_PATH" ]]; then
    echo "repo path does not exist: $REPO_PATH" >&2
    exit 1
  fi

  if [[ ! -e "$dest" ]]; then
    cp "$src" "$dest"
    echo "installed repo baseline: $dest"
    return
  fi

  if cmp -s "$src" "$dest"; then
    echo "unchanged repo baseline: $dest"
    return
  fi

  if [[ "$FORCE" -eq 1 ]]; then
    cp "$src" "$dest"
    echo "replaced repo baseline: $dest"
    return
  fi

  cp "$src" "$staged"
  echo "kept existing repo baseline: $dest"
  echo "staged simple-codex repo baseline at: $staged"
}

write_manifest() {
  {
    echo "simple-codex"
    echo "codex_home=$CODEX_HOME"
    echo "global_agents=$GLOBAL_AGENTS_PATH"
    if [[ -e "$STAGED_AGENTS_PATH" ]]; then
      echo "staged_global_agents=$STAGED_AGENTS_PATH"
    fi
    if [[ -n "$REPO_PATH" ]]; then
      echo "repo_path=$REPO_PATH"
      if [[ -e "$REPO_PATH/AGENTS.simple-codex.md" ]]; then
        echo "staged_repo_agents=$REPO_PATH/AGENTS.simple-codex.md"
      else
        echo "repo_agents=$REPO_PATH/AGENTS.md"
      fi
    fi
    for skill in "${SKILLS[@]}"; do
      echo "skill=$skill"
    done
  } > "$MANIFEST_PATH"

  echo "wrote manifest: $MANIFEST_PATH"
}

install_global_agents

for skill in "${SKILLS[@]}"; do
  install_skill_dir "$skill"
done

if [[ -n "$REPO_PATH" ]]; then
  install_repo_agents
fi

write_manifest

echo "simple-codex install complete"
