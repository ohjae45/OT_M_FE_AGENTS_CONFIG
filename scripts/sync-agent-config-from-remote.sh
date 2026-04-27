#!/usr/bin/env bash
# Clones COMMON_AGENT_CONFIG and syncs files into this project.
# Usage: bash scripts/sync-agent-config-from-remote.sh
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
copy_seed "$SOURCE_DIR/scripts/sync-agent-config-from-remote.sh" "$TARGET_DIR/scripts/sync-agent-config-from-remote.sh"

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

for f in "$SOURCE_DIR"/ai-guides/*; do
  [ -f "$f" ] || continue
  copy_managed "$f" "$TARGET_DIR/docs/ai-guides/$(basename "$f")"
done

copy_managed "$SOURCE_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"

for f in "$SOURCE_DIR"/.claude/skills/*; do
  [ -f "$f" ] || continue
  copy_managed "$f" "$TARGET_DIR/.claude/skills/$(basename "$f")"
done

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

echo ""
echo "Review changes with 'git diff', then commit and open a PR manually."
