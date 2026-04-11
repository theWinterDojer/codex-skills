#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="${HOME}/.codex"
REPO_PATH=""
DRY_RUN=0

SKILLS=(
  code-review
  session-init
  execution-ledger
  agent-retrospective
)

GLOBAL_AGENTS_SRC="$SCRIPT_DIR/AGENTS.md"
REPO_AGENTS_SRC="$SCRIPT_DIR/templates/repo-AGENTS.md"

GLOBAL_AGENTS_DEST=""
GLOBAL_AGENTS_STAGED=""
GLOBAL_AGENTS_MERGE=""
REPO_AGENTS_DEST=""
REPO_AGENTS_STAGED=""
REPO_AGENTS_MERGE=""

declare -A SKILL_ACTIONS=()
declare -A SKILL_STATE=()

GLOBAL_ACTION=""
REPO_ACTION=""

usage() {
  cat <<'EOF'
Usage:
  ./wizard.sh [--codex-home PATH] [--repo PATH] [--dry-run]

Options:
  --codex-home PATH  Use a different Codex home directory.
  --repo PATH        Also configure a repository-level AGENTS.md target.
  --dry-run          Preview actions without writing files.
  --help             Show this help message.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --codex-home)
      CODEX_HOME="$2"
      shift 2
      ;;
    --repo)
      REPO_PATH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
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

GLOBAL_AGENTS_DEST="$CODEX_HOME/AGENTS.md"
GLOBAL_AGENTS_STAGED="$CODEX_HOME/AGENTS.simple-codex.md"
GLOBAL_AGENTS_MERGE="$CODEX_HOME/AGENTS.simple-codex.merge.md"
MANIFEST_PATH="$CODEX_HOME/simple-codex-manifest.txt"

if [[ -n "$REPO_PATH" ]]; then
  REPO_AGENTS_DEST="$REPO_PATH/AGENTS.md"
  REPO_AGENTS_STAGED="$REPO_PATH/AGENTS.simple-codex.md"
  REPO_AGENTS_MERGE="$REPO_PATH/AGENTS.simple-codex.merge.md"
fi

pause() {
  printf "Press Enter to continue..."
  read -r _
}

prompt_choice() {
  local prompt="$1"
  local default="$2"
  shift 2
  local valid=("$@")
  local choice=""

  while true; do
    printf "%s [%s]: " "$prompt" "$default" >&2
    read -r choice
    if [[ -z "$choice" ]]; then
      choice="$default"
    fi
    for option in "${valid[@]}"; do
      if [[ "$choice" == "$option" ]]; then
        printf "%s" "$choice"
        return
      fi
    done
    echo "Invalid choice: $choice" >&2
  done
}

show_diff() {
  local left="$1"
  local right="$2"
  if [[ ! -e "$left" || ! -e "$right" ]]; then
    echo "Diff unavailable because one side is missing."
    return
  fi
  diff -u "$left" "$right" || true
}

write_merge_candidate() {
  local existing="$1"
  local baseline="$2"
  local output="$3"
  local title="$4"

  mkdir -p "$(dirname "$output")"
  cat > "$output" <<EOF
# $title
#
# This is a manual review candidate created by simple-codex.
# It is not an auto-merged result. Review it before adopting any section.

## Existing File

$(cat "$existing")

## simple-codex Candidate

$(cat "$baseline")
EOF
}

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

copy_if_needed() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" ]] && cmp -s "$src" "$dest"; then
    echo "unchanged: $dest"
    return
  fi
  cp "$src" "$dest"
  echo "wrote: $dest"
}

copy_dir_if_needed() {
  local src_dir="$1"
  local dest_dir="$2"

  if [[ -e "$dest_dir" ]]; then
    rm -rf "$dest_dir"
  fi
  mkdir -p "$(dirname "$dest_dir")"
  cp -r "$src_dir" "$dest_dir"
  echo "wrote: $dest_dir"
}

count_other_skills() {
  local count=0
  local skill_dir="$CODEX_HOME/skills"
  if [[ ! -d "$skill_dir" ]]; then
    echo 0
    return
  fi
  while IFS= read -r entry; do
    local name
    name="$(basename "$entry")"
    local bundled=0
    for skill in "${SKILLS[@]}"; do
      if [[ "$name" == "$skill" ]]; then
        bundled=1
        break
      fi
    done
    if [[ "$bundled" -eq 0 ]]; then
      count=$((count + 1))
    fi
  done < <(find "$skill_dir" -mindepth 1 -maxdepth 1 -type d | sort)
  echo "$count"
}

detect_skills() {
  local dest
  for skill in "${SKILLS[@]}"; do
    dest="$CODEX_HOME/skills/$skill"
    if [[ ! -e "$dest" ]]; then
      SKILL_STATE["$skill"]="missing"
      SKILL_ACTIONS["$skill"]="install"
      continue
    fi
    if dirs_match "$SCRIPT_DIR/skills/$skill" "$dest"; then
      SKILL_STATE["$skill"]="same"
      SKILL_ACTIONS["$skill"]="keep"
    else
      SKILL_STATE["$skill"]="conflict"
      SKILL_ACTIONS["$skill"]="keep"
    fi
  done
}

show_intro() {
  echo "simple-codex wizard"
  echo
  echo "This wizard only manages simple-codex assets."
  echo "- It can install bundled skills."
  echo "- It can install or stage global and repo AGENTS.md files."
  echo "- It does not remove unrelated skills."
  echo "- It does not overwrite existing baselines without confirmation."
  echo

  local entry
  entry="$(prompt_choice "Continue, dry-run, or cancel? (c/d/x)" "c" "c" "d" "x")"
  case "$entry" in
    c) ;;
    d) DRY_RUN=1 ;;
    x) exit 0 ;;
  esac
}

show_detection_summary() {
  local global_state="missing"
  local repo_state="not requested"
  local bundled_found=0
  local other_count
  local skill

  [[ -e "$GLOBAL_AGENTS_DEST" ]] && global_state="found"
  if [[ -n "$REPO_PATH" ]]; then
    if [[ -e "$REPO_AGENTS_DEST" ]]; then
      repo_state="found"
    else
      repo_state="missing"
    fi
  fi

  detect_skills
  other_count="$(count_other_skills)"
  for skill in "${SKILLS[@]}"; do
    if [[ "${SKILL_STATE[$skill]}" != "missing" ]]; then
      bundled_found=$((bundled_found + 1))
    fi
  done

  echo "Detected environment"
  echo "- Codex home: $CODEX_HOME"
  echo "- Global AGENTS.md: $global_state"
  if [[ -n "$REPO_PATH" ]]; then
    echo "- Repo path: $REPO_PATH"
  fi
  echo "- Repo AGENTS.md: $repo_state"
  echo "- Bundled skills already present: $bundled_found/${#SKILLS[@]}"
  echo "- Other skills present: $other_count"
  echo
}

choose_global_action() {
  local choice
  if [[ ! -e "$GLOBAL_AGENTS_DEST" ]]; then
    choice="$(prompt_choice "No global AGENTS.md found. Install simple-codex baseline? (i/s)" "i" "i" "s")"
    if [[ "$choice" == "i" ]]; then
      GLOBAL_ACTION="install"
    else
      GLOBAL_ACTION="skip"
    fi
    return
  fi

  if cmp -s "$GLOBAL_AGENTS_SRC" "$GLOBAL_AGENTS_DEST"; then
    GLOBAL_ACTION="keep"
    echo "Global AGENTS.md already matches the simple-codex baseline."
    return
  fi

  while true; do
    echo "Existing global AGENTS.md found."
    choice="$(prompt_choice "Choose global baseline action: keep+stage (k), diff (d), review candidate (m), replace (r), skip (s)" "k" "k" "d" "m" "r" "s")"
    case "$choice" in
      k) GLOBAL_ACTION="stage"; return ;;
      d) show_diff "$GLOBAL_AGENTS_DEST" "$GLOBAL_AGENTS_SRC"; pause ;;
      m) GLOBAL_ACTION="merge"; return ;;
      r) GLOBAL_ACTION="replace"; return ;;
      s) GLOBAL_ACTION="skip"; return ;;
    esac
  done
}

choose_repo_action() {
  local choice
  if [[ -z "$REPO_PATH" ]]; then
    REPO_ACTION="skip"
    return
  fi
  if [[ ! -d "$REPO_PATH" ]]; then
    echo "Repo path does not exist: $REPO_PATH" >&2
    exit 1
  fi
  if [[ ! -e "$REPO_AGENTS_DEST" ]]; then
    choice="$(prompt_choice "No repo AGENTS.md found. Install repo template? (i/s)" "i" "i" "s")"
    if [[ "$choice" == "i" ]]; then
      REPO_ACTION="install"
    else
      REPO_ACTION="skip"
    fi
    return
  fi

  if cmp -s "$REPO_AGENTS_SRC" "$REPO_AGENTS_DEST"; then
    REPO_ACTION="keep"
    echo "Repo AGENTS.md already matches the simple-codex repo template."
    return
  fi

  while true; do
    echo "Existing repo AGENTS.md found."
    choice="$(prompt_choice "Choose repo baseline action: keep+stage (k), diff (d), review candidate (m), replace (r), skip (s)" "k" "k" "d" "m" "r" "s")"
    case "$choice" in
      k) REPO_ACTION="stage"; return ;;
      d) show_diff "$REPO_AGENTS_DEST" "$REPO_AGENTS_SRC"; pause ;;
      m) REPO_ACTION="merge"; return ;;
      r) REPO_ACTION="replace"; return ;;
      s) REPO_ACTION="skip"; return ;;
    esac
  done
}

review_skill_conflict() {
  local skill="$1"
  local choice
  while true; do
    echo "Existing bundled skill conflict: $skill"
    choice="$(prompt_choice "Choose action: keep (k), diff (d), replace (r), skip decision (s)" "k" "k" "d" "r" "s")"
    case "$choice" in
      k) SKILL_ACTIONS["$skill"]="keep"; return ;;
      d) show_diff "$CODEX_HOME/skills/$skill/SKILL.md" "$SCRIPT_DIR/skills/$skill/SKILL.md"; pause ;;
      r) SKILL_ACTIONS["$skill"]="replace"; return ;;
      s) SKILL_ACTIONS["$skill"]="keep"; return ;;
    esac
  done
}

choose_skill_actions() {
  local skill
  local conflicts=0

  echo "Bundled skill plan"
  for skill in "${SKILLS[@]}"; do
    echo "- $skill: state=${SKILL_STATE[$skill]} recommended=${SKILL_ACTIONS[$skill]}"
    if [[ "${SKILL_STATE[$skill]}" == "conflict" ]]; then
      conflicts=$((conflicts + 1))
    fi
  done
  echo

  if [[ "$conflicts" -eq 0 ]]; then
    return
  fi

  local choice
  choice="$(prompt_choice "Accept recommended actions, review conflicts, replace all conflicts, keep all conflicts, or cancel? (a/v/r/k/x)" "a" "a" "v" "r" "k" "x")"
  case "$choice" in
    a) return ;;
    v)
      for skill in "${SKILLS[@]}"; do
        if [[ "${SKILL_STATE[$skill]}" == "conflict" ]]; then
          review_skill_conflict "$skill"
        fi
      done
      ;;
    r)
      for skill in "${SKILLS[@]}"; do
        if [[ "${SKILL_STATE[$skill]}" == "conflict" ]]; then
          SKILL_ACTIONS["$skill"]="replace"
        fi
      done
      ;;
    k)
      for skill in "${SKILLS[@]}"; do
        if [[ "${SKILL_STATE[$skill]}" == "conflict" ]]; then
          SKILL_ACTIONS["$skill"]="keep"
        fi
      done
      ;;
    x)
      exit 0
      ;;
  esac
}

show_summary() {
  local skill
  echo
  echo "Planned actions"
  echo "- Global AGENTS.md: $GLOBAL_ACTION"
  if [[ -n "$REPO_PATH" ]]; then
    echo "- Repo AGENTS.md: $REPO_ACTION"
  fi
  for skill in "${SKILLS[@]}"; do
    echo "- Skill $skill: ${SKILL_ACTIONS[$skill]}"
  done
  echo "- Manifest: $MANIFEST_PATH"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "- Mode: dry-run"
  fi
  echo
}

apply_global_action() {
  case "$GLOBAL_ACTION" in
    install|replace)
      copy_if_needed "$GLOBAL_AGENTS_SRC" "$GLOBAL_AGENTS_DEST"
      ;;
    stage)
      copy_if_needed "$GLOBAL_AGENTS_SRC" "$GLOBAL_AGENTS_STAGED"
      ;;
    merge)
      write_merge_candidate "$GLOBAL_AGENTS_DEST" "$GLOBAL_AGENTS_SRC" "$GLOBAL_AGENTS_MERGE" "Global AGENTS Review Candidate"
      echo "wrote: $GLOBAL_AGENTS_MERGE"
      ;;
    keep|skip)
      ;;
  esac
}

apply_repo_action() {
  case "$REPO_ACTION" in
    install|replace)
      copy_if_needed "$REPO_AGENTS_SRC" "$REPO_AGENTS_DEST"
      ;;
    stage)
      copy_if_needed "$REPO_AGENTS_SRC" "$REPO_AGENTS_STAGED"
      ;;
    merge)
      write_merge_candidate "$REPO_AGENTS_DEST" "$REPO_AGENTS_SRC" "$REPO_AGENTS_MERGE" "Repo AGENTS Review Candidate"
      echo "wrote: $REPO_AGENTS_MERGE"
      ;;
    keep|skip)
      ;;
  esac
}

apply_skill_actions() {
  local skill
  for skill in "${SKILLS[@]}"; do
    case "${SKILL_ACTIONS[$skill]}" in
      install|replace)
        copy_dir_if_needed "$SCRIPT_DIR/skills/$skill" "$CODEX_HOME/skills/$skill"
        ;;
      keep)
        ;;
    esac
  done
}

write_manifest() {
  mkdir -p "$(dirname "$MANIFEST_PATH")"
  {
    echo "simple-codex"
    echo "codex_home=$CODEX_HOME"
    echo "mode=wizard"
    echo "dry_run=$DRY_RUN"
    echo "global_action=$GLOBAL_ACTION"
    if [[ -n "$REPO_PATH" ]]; then
      echo "repo_path=$REPO_PATH"
      echo "repo_action=$REPO_ACTION"
    fi
    for skill in "${SKILLS[@]}"; do
      echo "skill_${skill}=${SKILL_ACTIONS[$skill]}"
    done
  } > "$MANIFEST_PATH"
  echo "wrote: $MANIFEST_PATH"
}

apply_actions() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Dry-run only. No files were written."
    return
  fi

  mkdir -p "$CODEX_HOME/skills"
  apply_global_action
  if [[ -n "$REPO_PATH" ]]; then
    apply_repo_action
  fi
  apply_skill_actions
  write_manifest
  echo "simple-codex wizard apply complete"
}

show_intro
show_detection_summary
choose_global_action
choose_repo_action
choose_skill_actions
show_summary

FINAL_CHOICE="$(prompt_choice "Apply these actions, go back, or cancel? (a/b/x)" "x" "a" "b" "x")"
case "$FINAL_CHOICE" in
  a)
    apply_actions
    ;;
  b)
    choose_global_action
    choose_repo_action
    choose_skill_actions
    show_summary
    FINAL_CHOICE="$(prompt_choice "Apply these actions or cancel? (a/x)" "x" "a" "x")"
    if [[ "$FINAL_CHOICE" == "a" ]]; then
      apply_actions
    fi
    ;;
  x)
    echo "Cancelled."
    ;;
esac
