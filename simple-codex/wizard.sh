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
REPO_AGENTS_DEST=""
REPO_AGENTS_STAGED=""

declare -A SKILL_ACTIONS=()
declare -A SKILL_STATE=()
declare -A SKILL_DIFF_FILES=()

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
MANIFEST_PATH="$CODEX_HOME/simple-codex-manifest.txt"

if [[ -n "$REPO_PATH" ]]; then
  REPO_AGENTS_DEST="$REPO_PATH/AGENTS.md"
  REPO_AGENTS_STAGED="$REPO_PATH/AGENTS.simple-codex.md"
fi

pause() {
  printf "Press Enter to continue..."
  read -r _
}

prompt_menu() {
  local prompt="$1"
  local default="$2"
  shift 2
  local options=("$@")
  local choice=""
  local idx

  while true; do
    idx=1
    echo "$prompt" >&2
    for option in "${options[@]}"; do
      echo "$idx. $option" >&2
      idx=$((idx + 1))
    done
    printf "Choose an option: " >&2
    read -r choice
    if [[ -z "$choice" ]]; then
      choice="$default"
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      printf "%s" "$choice"
      return
    fi
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
  local diff_output
  for skill in "${SKILLS[@]}"; do
    dest="$CODEX_HOME/skills/$skill"
    if [[ ! -e "$dest" ]]; then
      SKILL_STATE["$skill"]="missing"
      SKILL_ACTIONS["$skill"]="install"
      SKILL_DIFF_FILES["$skill"]=""
      continue
    fi
    if dirs_match "$SCRIPT_DIR/skills/$skill" "$dest"; then
      SKILL_STATE["$skill"]="same"
      SKILL_ACTIONS["$skill"]="keep"
      SKILL_DIFF_FILES["$skill"]=""
    else
      SKILL_STATE["$skill"]="different"
      SKILL_ACTIONS["$skill"]="keep"
      diff_output="$(
        { diff -qr "$SCRIPT_DIR/skills/$skill" "$dest" 2>/dev/null || true; } \
          | sed "s|$SCRIPT_DIR/skills/$skill/||g; s|$dest/||g" \
          | grep -v 'Zone.Identifier' || true
      )"
      SKILL_DIFF_FILES["$skill"]="$diff_output"
    fi
  done
}

show_intro() {
  echo "simple-codex wizard"
  echo
  echo "This wizard installs simple-codex skills and optional AGENTS.md files."
  echo "Existing AGENTS.md files are preserved unless you choose to replace them."
  echo "Unrelated skills are left alone."
  echo

  local entry
  entry="$(prompt_menu "Choose how to start:" "1" "Install or update" "Preview only (dry-run)" "Cancel")"
  case "$entry" in
    1) ;;
    2) DRY_RUN=1 ;;
    3) exit 0 ;;
  esac
}

show_detection_summary() {
  local global_state="missing"
  local repo_state="not requested"
  local bundled_found=0
  local other_count
  local differing_count=0
  local same_count=0
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
    if [[ "${SKILL_STATE[$skill]}" == "different" ]]; then
      differing_count=$((differing_count + 1))
    fi
    if [[ "${SKILL_STATE[$skill]}" == "same" ]]; then
      same_count=$((same_count + 1))
    fi
  done

  echo "I found your existing Codex setup."
  echo "- Codex home: $CODEX_HOME"

  case "$global_state" in
    found)
      if cmp -s "$GLOBAL_AGENTS_SRC" "$GLOBAL_AGENTS_DEST"; then
        echo "- Your global AGENTS.md already matches the simple-codex baseline."
      else
        echo "- You already have a global AGENTS.md with your own instructions."
      fi
      ;;
    missing)
      echo "- You do not have a global AGENTS.md yet."
      ;;
  esac

  if [[ -n "$REPO_PATH" ]]; then
    echo "- Repo path: $REPO_PATH"
    case "$repo_state" in
      found)
        if cmp -s "$REPO_AGENTS_SRC" "$REPO_AGENTS_DEST"; then
          echo "- This repo already has the simple-codex repo template."
        else
          echo "- This repo already has its own AGENTS.md."
        fi
        ;;
      missing)
        echo "- This repo does not have an AGENTS.md yet."
        ;;
      not\ requested)
        ;;
    esac
  fi

  if [[ "$bundled_found" -eq 0 ]]; then
    echo "- None of the simple-codex bundled skills are installed yet."
  else
    echo "- You already have $bundled_found of ${#SKILLS[@]} simple-codex bundled skill(s) installed."
  fi

  if [[ "$same_count" -gt 0 ]]; then
    echo "- $same_count skill(s) already match the versions from this repo."
  fi

  if [[ "$differing_count" -gt 0 ]]; then
    echo "- $differing_count installed skill(s) use versions that differ from this repo."
  fi

  if [[ "$other_count" -gt 0 ]]; then
    echo "- You also have $other_count other installed skill(s) that simple-codex will leave alone."
  else
    echo "- No unrelated installed skills were found."
  fi
  echo
}

choose_global_action() {
  local choice
  if [[ ! -e "$GLOBAL_AGENTS_DEST" ]]; then
    choice="$(prompt_menu "No global AGENTS.md found. What would you like to do?" "1" "Install the simple-codex global baseline" "Skip global baseline setup")"
    if [[ "$choice" == "1" ]]; then
      GLOBAL_ACTION="install"
    else
      GLOBAL_ACTION="skip"
    fi
    return
  fi

  if cmp -s "$GLOBAL_AGENTS_SRC" "$GLOBAL_AGENTS_DEST"; then
    GLOBAL_ACTION="keep"
    echo "Your global AGENTS.md is already aligned, so no change is needed there."
    return
  fi

  while true; do
    echo "Global AGENTS.md already exists."
    choice="$(prompt_menu "Replace it with the simple-codex default AGENTS.md?" "1" "No, keep current and save the simple-codex default beside it" "Yes, replace it" "Show what changed" "Skip")"
    case "$choice" in
      1) GLOBAL_ACTION="stage"; return ;;
      2) GLOBAL_ACTION="replace"; return ;;
      3) show_diff "$GLOBAL_AGENTS_DEST" "$GLOBAL_AGENTS_SRC"; pause ;;
      4) GLOBAL_ACTION="skip"; return ;;
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
    choice="$(prompt_menu "No repo AGENTS.md found. What would you like to do?" "1" "Install the simple-codex repo template" "Skip repo baseline setup")"
    if [[ "$choice" == "1" ]]; then
      REPO_ACTION="install"
    else
      REPO_ACTION="skip"
    fi
    return
  fi

  if cmp -s "$REPO_AGENTS_SRC" "$REPO_AGENTS_DEST"; then
    REPO_ACTION="keep"
    echo "This repo AGENTS.md is already aligned, so no change is needed there."
    return
  fi

  while true; do
    echo "Repo AGENTS.md already exists."
    choice="$(prompt_menu "Replace it with the simple-codex repo AGENTS.md template?" "1" "No, keep current and save the simple-codex template beside it" "Yes, replace it" "Show what changed" "Skip")"
    case "$choice" in
      1) REPO_ACTION="stage"; return ;;
      2) REPO_ACTION="replace"; return ;;
      3) show_diff "$REPO_AGENTS_DEST" "$REPO_AGENTS_SRC"; pause ;;
      4) REPO_ACTION="skip"; return ;;
    esac
  done
}

review_skill_conflict() {
  local skill="$1"
  local choice
  while true; do
    echo
    echo "$skill"
    echo "Your installed version differs from the version in this repo."
    echo "Only this skill will be affected by the choice you make here."
    if [[ -n "${SKILL_DIFF_FILES[$skill]}" ]]; then
      echo "Changed files:"
      printf '%s\n' "${SKILL_DIFF_FILES[$skill]}" | sed 's/^/- /'
    else
      echo "Changed files:"
      echo "- bundled skill contents differ"
    fi
    choice="$(prompt_menu "Choose how to handle this skill:" "1" "Show detailed differences" "Replace with the version from this repo" "Keep installed version")"
    case "$choice" in
      1)
        diff -ru "$CODEX_HOME/skills/$skill" "$SCRIPT_DIR/skills/$skill" || true
        pause
        ;;
      2) SKILL_ACTIONS["$skill"]="replace"; return ;;
      3) SKILL_ACTIONS["$skill"]="keep"; return ;;
    esac
  done
}

show_differing_skill_diffs() {
  local skill

  for skill in "${SKILLS[@]}"; do
    if [[ "${SKILL_STATE[$skill]}" == "different" ]]; then
      echo
      echo "$skill"
      echo "----------------------------------------"
      if [[ -n "${SKILL_DIFF_FILES[$skill]}" ]]; then
        echo "Changed files:"
        printf '%s\n' "${SKILL_DIFF_FILES[$skill]}" | sed 's/^/- /'
        echo
      fi
      diff -ru "$CODEX_HOME/skills/$skill" "$SCRIPT_DIR/skills/$skill" || true
    fi
  done
}

choose_differing_skill_actions() {
  local choice
  local skill

  while true; do
    choice="$(prompt_menu "Choose how to handle your installed simple-codex skills:" "1" "Show what changed" "Replace differing skills with the versions from this repo" "Keep installed versions" "Review each differing skill" "Cancel")"
    case "$choice" in
      1)
        show_differing_skill_diffs
        pause
        ;;
      2)
        for skill in "${SKILLS[@]}"; do
          if [[ "${SKILL_STATE[$skill]}" == "different" ]]; then
            SKILL_ACTIONS["$skill"]="replace"
          fi
        done
        return
        ;;
      3)
        for skill in "${SKILLS[@]}"; do
          if [[ "${SKILL_STATE[$skill]}" == "different" ]]; then
            SKILL_ACTIONS["$skill"]="keep"
          fi
        done
        return
        ;;
      4)
        for skill in "${SKILLS[@]}"; do
          if [[ "${SKILL_STATE[$skill]}" == "different" ]]; then
            review_skill_conflict "$skill"
          fi
        done
        return
        ;;
      5)
        exit 0
        ;;
    esac
  done
}

choose_skill_actions() {
  local skill
  local differing=0
  local missing=0

  echo "Installed simple-codex skills"
  for skill in "${SKILLS[@]}"; do
    case "${SKILL_STATE[$skill]}" in
      same)
        echo "- $skill: already matches the version from this repo"
        ;;
      different)
        echo "- $skill: installed, but differs from the version in this repo"
        ;;
      missing)
        echo "- $skill: not installed yet"
        ;;
    esac
    if [[ "${SKILL_STATE[$skill]}" == "different" ]]; then
      differing=$((differing + 1))
    fi
    if [[ "${SKILL_STATE[$skill]}" == "missing" ]]; then
      missing=$((missing + 1))
    fi
  done
  echo

  if [[ "$differing" -eq 0 ]]; then
    if [[ "$missing" -gt 0 ]]; then
      echo
      echo "simple-codex can install the missing bundled skills."
    else
      echo
      echo "Your installed simple-codex skills already match the versions from this repo."
    fi
    return
  fi

  echo
  echo "You already have $differing simple-codex skill(s) installed with versions that differ from this repo."
  if [[ "$missing" -gt 0 ]]; then
    echo "Missing bundled skills will still be installed unless you cancel."
  fi
  echo

  choose_differing_skill_actions
}

show_summary() {
  local skill
  local replace_skills=()
  local install_skills=()
  echo

  for skill in "${SKILLS[@]}"; do
    case "${SKILL_ACTIONS[$skill]}" in
      replace) replace_skills+=("$skill") ;;
      install) install_skills+=("$skill") ;;
    esac
  done

  echo "Here is what I am about to do:"

  case "$GLOBAL_ACTION" in
    keep)
      echo "- Leave your global AGENTS.md unchanged"
      ;;
    install)
      echo "- Install the simple-codex global AGENTS.md"
      ;;
    stage)
      echo "- Leave your global AGENTS.md unchanged and stage the simple-codex version beside it"
      ;;
    replace)
      echo "- Replace your global AGENTS.md with the simple-codex version"
      ;;
    skip)
      echo "- Skip global AGENTS.md changes"
      ;;
  esac

  if [[ -n "$REPO_PATH" ]]; then
    case "$REPO_ACTION" in
      keep)
        echo "- Leave this repo AGENTS.md unchanged"
        ;;
      install)
        echo "- Install the simple-codex repo AGENTS.md template"
        ;;
      stage)
        echo "- Leave this repo AGENTS.md unchanged and stage the simple-codex version beside it"
        ;;
      replace)
        echo "- Replace this repo AGENTS.md with the simple-codex template"
        ;;
      skip)
        echo "- Skip repo AGENTS.md changes"
        ;;
    esac
  fi

  if [[ "${#install_skills[@]}" -gt 0 ]]; then
    echo "- Install these missing skills:"
    for skill in "${install_skills[@]}"; do
      echo "  - $skill"
    done
  fi

  if [[ "${#replace_skills[@]}" -gt 0 ]]; then
    echo "- Replace these installed skills with the versions from this repo:"
    for skill in "${replace_skills[@]}"; do
      echo "  - $skill"
    done
  fi

  if [[ "${#install_skills[@]}" -eq 0 && "${#replace_skills[@]}" -eq 0 ]]; then
    echo "- Leave your installed simple-codex skills unchanged"
  fi

  echo "- Leave all unrelated installed skills unchanged"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "- Preview manifest target: $MANIFEST_PATH"
    echo "- Mode: dry-run"
    echo "- No files will be written"
  else
    echo "- Write the install manifest to: $MANIFEST_PATH"
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

FINAL_CHOICE="$(prompt_menu "What would you like to do next?" "3" "Apply these actions" "Go back and adjust choices" "Cancel")"
case "$FINAL_CHOICE" in
  1)
    apply_actions
    ;;
  2)
    choose_global_action
    choose_repo_action
    choose_skill_actions
    show_summary
    FINAL_CHOICE="$(prompt_menu "What would you like to do next?" "2" "Apply these actions" "Cancel")"
    if [[ "$FINAL_CHOICE" == "1" ]]; then
      apply_actions
    fi
    ;;
  3)
    echo "Cancelled."
    ;;
esac
