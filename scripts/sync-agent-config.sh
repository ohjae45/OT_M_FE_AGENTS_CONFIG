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

SEEDS_SKIPPED=()
MANAGED_ADDED=()
MANAGED_MODIFIED=()
MANAGED_UNCHANGED=()
MANAGED_DELETED=()

# ---------------------------------------------------------------------------
# Phase 1: Seed files — copy only when target file does not exist
# ---------------------------------------------------------------------------
copy_seed() {
  local src="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    SEEDS_SKIPPED+=("${dest#"$TARGET_DIR/"}")
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    MANAGED_ADDED+=("${dest#"$TARGET_DIR/"}")
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
  if [ -f "$dest" ]; then
    if cmp -s "$src" "$dest"; then
      MANAGED_UNCHANGED+=("${dest#"$TARGET_DIR/"}")
    else
      MANAGED_MODIFIED+=("${dest#"$TARGET_DIR/"}")
    fi
  else
    MANAGED_ADDED+=("${dest#"$TARGET_DIR/"}")
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
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
        MANAGED_DELETED+=("${f#"$TARGET_DIR/"}")
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
RED=$'\033[0;31m'
RESET=$'\033[0m'

print_section() {
  local icon="$1"
  local label="$2"
  local icon_color="$3"
  shift 3
  local files=("$@")
  if [ ${#files[@]} -gt 0 ]; then
    echo ""
    printf "${icon_color}${icon}${RESET}  %s\n" "$label"
    for f in "${files[@]}"; do
      printf "    - %s\n" "$f"
    done
    echo ""
  fi
}

echo ""
echo "=== Sync Complete ==="
echo ""

print_section "✅"  "Added"                           "" "${MANAGED_ADDED[@]+"${MANAGED_ADDED[@]}"}"
print_section "✏️"   "Modified"                        "" "${MANAGED_MODIFIED[@]+"${MANAGED_MODIFIED[@]}"}"
print_section "❌"  "Deleted"                         "$RED" "${MANAGED_DELETED[@]+"${MANAGED_DELETED[@]}"}"
print_section "·"   "Unchanged"                       "" "${MANAGED_UNCHANGED[@]+"${MANAGED_UNCHANGED[@]}"}"
print_section "⏭️"   "Seed skipped (already exists)"  "" "${SEEDS_SKIPPED[@]+"${SEEDS_SKIPPED[@]}"}"

echo ""
echo "Review changes with 'git diff', then commit and open a PR manually."
