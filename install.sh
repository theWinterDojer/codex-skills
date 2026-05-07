#!/usr/bin/env bash
set -euo pipefail

REPO="theWinterDojer/codex-skills"
ARCHIVE_URL="https://github.com/$REPO/archive/refs/heads/main.tar.gz"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

need_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

find_package_dir() {
  local entry

  for entry in "$TMP_DIR"/*; do
    if [[ -d "$entry" && -x "$entry/simple-codex/wizard.sh" ]]; then
      printf "%s" "$entry"
      return
    fi
  done

  echo "Downloaded archive did not contain simple-codex/wizard.sh." >&2
  exit 1
}

run_wizard() {
  local package_dir="$1"
  shift

  cd "$package_dir/simple-codex"
  if [[ -t 0 ]]; then
    ./wizard.sh "$@"
  elif [[ -r /dev/tty ]]; then
    ./wizard.sh "$@" </dev/tty
  else
    echo "The simple-codex wizard needs an interactive terminal." >&2
    echo "Download the repo and run simple-codex/wizard.sh directly in this environment." >&2
    exit 1
  fi
}

need_command curl
need_command tar

echo "Downloading simple-codex from $REPO@main..."
curl -fsSL "$ARCHIVE_URL" -o "$TMP_DIR/codex-skills.tar.gz"
tar -xzf "$TMP_DIR/codex-skills.tar.gz" -C "$TMP_DIR"

PACKAGE_DIR="$(find_package_dir)"
echo "Launching the interactive simple-codex wizard."
run_wizard "$PACKAGE_DIR" "$@"
