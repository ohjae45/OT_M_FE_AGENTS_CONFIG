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

CREATED_SEEDS=()
SKIPPED_SEEDS=()
SYNCED_MANAGED=()
DELETED_MANAGED=()

# ---------------------------------------------------------------------------
# Phase 1: Seed files — copy only when target file does not exist
# ---------------------------------------------------------------------------
copy_seed() {
  local src="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    SKIPPED_SEEDS+=("$dest")
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    CREATED_SEEDS+=("$dest")
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
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  SYNCED_MANAGED+=("$dest")
}

sync_managed_dir() {
  local src_dir="$1"
  local dest_dir="$2"

  # Copy/overwrite files from source
  for f in "$src_dir"/*; do
    [ -f "$f" ] || continue
    copy_managed "$f" "$dest_dir/$(basename "$f")"
  done

  # Delete files in target that no longer exist in source
  if [ -d "$dest_dir" ]; then
    for f in "$dest_dir"/*; do
      [ -f "$f" ] || continue
      if [ ! -f "$src_dir/$(basename "$f")" ]; then
        rm "$f"
        DELETED_MANAGED+=("$f")
      fi
    done
  fi
}

sync_managed_dir "$SOURCE_DIR/agent-docs/guides" "$TARGET_DIR/agent-docs/guides"

copy_managed "$SOURCE_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"
copy_managed "$SOURCE_DIR/scripts/sync-agent-config.sh" "$TARGET_DIR/scripts/sync-agent-config.sh"

sync_managed_dir "$SOURCE_DIR/.claude/skills" "$TARGET_DIR/.claude/skills"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Sync Complete ==="

if [ ${#CREATED_SEEDS[@]} -gt 0 ]; then
  echo ""
  echo "[created seed]"
  for f in "${CREATED_SEEDS[@]}"; do
    echo "  + ${f#"$TARGET_DIR/"}"
  done
fi

if [ ${#SKIPPED_SEEDS[@]} -gt 0 ]; then
  echo ""
  echo "[skipped seed]"
  for f in "${SKIPPED_SEEDS[@]}"; do
    echo "  - ${f#"$TARGET_DIR/"} (already exists, not overwritten)"
  done
fi

if [ ${#SYNCED_MANAGED[@]} -gt 0 ]; then
  echo ""
  echo "[synced managed]"
  for f in "${SYNCED_MANAGED[@]}"; do
    echo "  ~ ${f#"$TARGET_DIR/"}"
  done
fi

if [ ${#DELETED_MANAGED[@]} -gt 0 ]; then
  echo ""
  echo "[deleted managed]"
  for f in "${DELETED_MANAGED[@]}"; do
    echo "  x ${f#"$TARGET_DIR/"}"
  done
fi

echo ""
echo "Review changes with 'git diff', then commit and open a PR manually."
