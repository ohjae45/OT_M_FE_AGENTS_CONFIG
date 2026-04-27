#!/usr/bin/env bash
# Clones COMMON_AGENT_CONFIG and syncs files into this project.
# Usage: bash scripts/sync-agent-config.sh
#        (run from project root)
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — update REMOTE_REPO when the repo URL changes
# ---------------------------------------------------------------------------
REMOTE_REPO="git@github.com:woic-ej/COMMON_AGENT_CONFIG.git"
REMOTE_BRANCH="main"

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
TARGET_DIR="$(pwd)"
TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Cloning COMMON_AGENT_CONFIG (--depth 1)..."
git clone --depth 1 --branch "$REMOTE_BRANCH" "$REMOTE_REPO" "$TMP_DIR/config" --quiet
SOURCE_DIR="$TMP_DIR/config"

# Each entry: "<icon> <relative-path>"
CHANGE_LOG=()

# ---------------------------------------------------------------------------
# Phase 1: Seed files — copy only when target file does not exist
# ---------------------------------------------------------------------------
copy_seed() {
  local src="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    CHANGE_LOG+=("  ⏭️  ${dest#"$TARGET_DIR/"}")
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    CHANGE_LOG+=("  ✅  ${dest#"$TARGET_DIR/"}")
  fi
}

copy_seed "$SOURCE_DIR/templates/AGENTS.md" "$TARGET_DIR/AGENTS.md"
copy_seed "$SOURCE_DIR/templates/CLAUDE.md"  "$TARGET_DIR/CLAUDE.md"

# ---------------------------------------------------------------------------
# Phase 2: Managed files — always overwrite
# ---------------------------------------------------------------------------
copy_managed() {
  local src="$1"
  local dest="$2"
  local icon
  if [ -f "$dest" ]; then
    if cmp -s "$src" "$dest"; then
      icon="  ·  "
    else
      icon="  ✏️  "
    fi
  else
    icon="  ✅  "
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  CHANGE_LOG+=("$icon${dest#"$TARGET_DIR/"}")
}

sync_managed_dir() {
  local src_dir="$1"
  local dest_dir="$2"

  for f in "$src_dir"/*; do
    [ -f "$f" ] || continue
    copy_managed "$f" "$dest_dir/$(basename "$f")"
  done

  if [ -d "$dest_dir" ]; then
    for f in "$dest_dir"/*; do
      [ -f "$f" ] || continue
      if [ ! -f "$src_dir/$(basename "$f")" ]; then
        rm "$f"
        CHANGE_LOG+=("  🗑️  ${f#"$TARGET_DIR/"}")
      fi
    done
  fi
}

sync_managed_dir "$SOURCE_DIR/agent-docs/guides" "$TARGET_DIR/agent-docs/guides"

copy_managed "$SOURCE_DIR/.claude/settings.json"           "$TARGET_DIR/.claude/settings.json"
copy_managed "$SOURCE_DIR/scripts/sync-agent-config.sh"    "$TARGET_DIR/scripts/sync-agent-config.sh"

sync_managed_dir "$SOURCE_DIR/.claude/skills" "$TARGET_DIR/.claude/skills"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Sync Complete ==="
echo ""
echo "  ✅  added"
echo "  ✏️  modified"
echo "  🗑️  deleted"
echo "  ·   unchanged"
echo "  ⏭️  seed skipped (already exists)"
echo ""

for entry in "${CHANGE_LOG[@]}"; do
  echo "$entry"
done

echo ""
echo "Review changes with 'git diff', then commit and open a PR manually."
