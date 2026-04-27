#!/usr/bin/env bash
# Clones COMMON_AGENT_CONFIG and syncs files into this project.
# Shared skill sources live in agent-docs/skills and are generated into
# agent-specific locations during sync.
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

  # If a source directory is absent in an older config checkout, do not delete
  # existing target files just because the source path cannot be read.
  [ -d "$src_dir" ] || return 0

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

extract_codex_description() {
  local src="$1"

  # Codex only indexes SKILL.md frontmatter before loading the body, so keep a
  # concise description derived from the shared source Description section.
  awk '
    /^## Description[[:space:]]*$/ { in_description=1; next }
    in_description && /^## / { exit }
    in_description && NF {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      print
    }
  ' "$src" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/[[:space:]]$//'
}

write_codex_skill() {
  local src="$1"
  local dest="$2"
  local skill_name
  local description
  local generated

  skill_name="$(basename "$src" .md)"
  description="$(extract_codex_description "$src")"
  generated="$TMP_DIR/${skill_name}-SKILL.md"

  if [ -z "$description" ]; then
    description="Common agent workflow for ${skill_name}. Use when the user asks for this skill."
  fi

  # Codex requires SKILL.md frontmatter, while the shared source stays
  # agent-neutral markdown for Claude and future agents.
  {
    printf '%s\n' '---'
    printf 'name: %s\n' "$skill_name"
    printf '%s\n' 'description: >'
    printf '  %s\n' "$description"
    printf '%s\n\n' '---'
    printf '<!-- Generated from agent-docs/skills/%s.md by scripts/sync-agent-config.sh. Edit the source file instead. -->\n\n' "$skill_name"
    cat "$src"
  } > "$generated"

  copy_managed "$generated" "$dest"
}

sync_codex_skills() {
  local src_dir="$1"
  local dest_root="$2"
  local src
  local skill_name
  local skill_dir
  local skill_file

  # Codex repo-local skills use .agents/skills/<name>/SKILL.md, so generate a
  # directory per shared skill source instead of copying the markdown directly.
  [ -d "$src_dir" ] || return 0

  for src in "$src_dir"/*.md; do
    [ -f "$src" ] || continue
    skill_name="$(basename "$src" .md)"
    write_codex_skill "$src" "$dest_root/$skill_name/SKILL.md"
  done

  if [ -d "$dest_root" ]; then
    for skill_dir in "$dest_root"/*; do
      [ -d "$skill_dir" ] || continue
      skill_name="$(basename "$skill_dir")"
      skill_file="$skill_dir/SKILL.md"

      # Only delete stale Codex skills that this sync script previously
      # generated. Target repos can keep their own custom .agents/skills.
      if [ ! -f "$src_dir/$skill_name.md" ] &&
        [ -f "$skill_file" ] &&
        grep -q 'Generated from agent-docs/skills/' "$skill_file"; then
        rm -rf "$skill_dir"
        MANAGED_DELETED+=("${skill_dir#"$TARGET_DIR/"}")
      fi
    done
  fi
}

sync_managed_dir "$SOURCE_DIR/agent-docs/guides" "$TARGET_DIR/agent-docs/guides"
sync_managed_dir "$SOURCE_DIR/agent-docs/skills" "$TARGET_DIR/agent-docs/skills"

copy_managed "$SOURCE_DIR/.claude/settings.json"           "$TARGET_DIR/.claude/settings.json"
copy_managed "$SOURCE_DIR/scripts/sync-agent-config.sh"    "$TARGET_DIR/scripts/sync-agent-config.sh"

# Claude reads plain markdown skills, so copy the shared source as a managed
# output rather than keeping duplicate files in COMMON_AGENT_CONFIG.
sync_managed_dir "$SOURCE_DIR/agent-docs/skills" "$TARGET_DIR/.claude/skills"

# Codex reads SKILL.md folders, so generate Codex-specific wrappers at sync
# time from the same shared source.
sync_codex_skills "$SOURCE_DIR/agent-docs/skills" "$TARGET_DIR/.agents/skills"

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

print_section "⏭️"   "Seed skipped (already exists)"  "" "${SEEDS_SKIPPED[@]+"${SEEDS_SKIPPED[@]}"}"
print_section "💤"  "Unchanged"                       "" "${MANAGED_UNCHANGED[@]+"${MANAGED_UNCHANGED[@]}"}"
print_section "✅"  "Added"                           "" "${MANAGED_ADDED[@]+"${MANAGED_ADDED[@]}"}"
print_section "✏️"   "Modified"                        "" "${MANAGED_MODIFIED[@]+"${MANAGED_MODIFIED[@]}"}"
print_section "❌"  "Deleted"                         "$RED" "${MANAGED_DELETED[@]+"${MANAGED_DELETED[@]}"}"

echo ""
echo "Review changes with 'git diff', then commit and open a PR manually."
