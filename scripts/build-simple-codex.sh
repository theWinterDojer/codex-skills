#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$REPO_ROOT/simple-codex"
SKILLS_DIR="$PACKAGE_DIR/skills"

SKILLS=(
  code-review
  session-init
  execution-ledger
  agent-retrospective
)

mkdir -p "$SKILLS_DIR"

cp "$REPO_ROOT/AGENTS.md" "$PACKAGE_DIR/AGENTS.md"

for skill in "${SKILLS[@]}"; do
  rm -rf "$SKILLS_DIR/$skill"
  cp -r "$REPO_ROOT/$skill" "$SKILLS_DIR/$skill"
done

find "$PACKAGE_DIR" -type f -name '*:Zone.Identifier' -delete

echo "simple-codex package refreshed"
