#!/usr/bin/env bash
# Clones OT_M_FE_AGENTS_CONFIG and syncs files into this project.
# Shared skai-* skill sources live in agent-docs/skills and are generated
# into agent-specific locations during sync.
# Usage: bash scripts/sync-agent-config.sh
#        (run from project root)
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — update REMOTE_REPO when the repo URL changes
# ---------------------------------------------------------------------------
REMOTE_REPO="https://github.com/skaiworldwide/OT_M_FE_AGENTS_CONFIG.git"
REMOTE_BRANCH="main"

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
TARGET_DIR="$(pwd)"
TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Cloning OT_M_FE_AGENTS_CONFIG (--depth 1)..."
git clone --depth 1 --branch "$REMOTE_BRANCH" "$REMOTE_REPO" "$TMP_DIR/config" --quiet
SOURCE_DIR="$TMP_DIR/config"

SEEDS_SKIPPED=()
MANAGED_ADDED=()
MANAGED_MODIFIED=()
MANAGED_UNCHANGED=()
MANAGED_DELETED=()

# Known skill names before the SKAI prefix migration. These are used only for
# deleting generated legacy flat markdown copies, not target-owned custom skills.
DEPRECATED_UNPREFIXED_SKILLS=(commit review pr)

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

copy_root_seed() {
  local src="$1"
  local dest="$2"
  local generated

  generated="$TMP_DIR/$(basename "$src").root-seed"

  # Template files live one directory below the repo root, while seeded files
  # are written to the target root. Rewrite only local doc link targets.
  sed 's#](../agent-docs/#](agent-docs/#g' "$src" > "$generated"
  copy_seed "$generated" "$dest"
}

copy_root_seed "$SOURCE_DIR/templates/AGENTS.md" "$TARGET_DIR/AGENTS.md"
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

extract_skill_description() {
  local src="$1"

  # Skill frontmatter is what agents index before loading the body, so keep a
  # concise description derived from the shared source description section.
  awk '
    /^## (Description|설명)[[:space:]]*$/ { in_description=1; next }
    in_description && /^## / { exit }
    in_description && NF {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      print
    }
  ' "$src" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/[[:space:]]$//'
}

write_skill_package() {
  local src="$1"
  local dest="$2"
  local skill_name
  local description
  local generated

  skill_name="$(basename "$src" .md)"
  description="$(extract_skill_description "$src")"
  generated="$TMP_DIR/${skill_name}-SKILL.md"

  if [ -z "$description" ]; then
    description="Common agent workflow for ${skill_name}. Use when the user asks for this skill."
  fi

  # Claude Code and Codex both discover skills through SKILL.md frontmatter,
  # while the shared source stays agent-neutral markdown.
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

sync_skill_packages() {
  local src_dir="$1"
  local dest_root="$2"
  local src
  local skill_name
  local skill_dir
  local skill_file

  # Skill-aware agents use <root>/<name>/SKILL.md, so generate a directory per
  # shared skill source instead of copying the markdown directly.
  [ -d "$src_dir" ] || return 0

  for src in "$src_dir"/*.md; do
    [ -f "$src" ] || continue
    skill_name="$(basename "$src" .md)"
    write_skill_package "$src" "$dest_root/$skill_name/SKILL.md"
  done

  if [ -d "$dest_root" ]; then
    for skill_dir in "$dest_root"/*; do
      [ -d "$skill_dir" ] || continue
      skill_name="$(basename "$skill_dir")"
      skill_file="$skill_dir/SKILL.md"

      # Only delete stale skill packages that this sync script previously
      # generated. Target repos can keep their own custom skills.
      if [ ! -f "$src_dir/$skill_name.md" ] &&
        [ -f "$skill_file" ] &&
        grep -q 'Generated from agent-docs/skills/' "$skill_file"; then
        rm -rf "$skill_dir"
        MANAGED_DELETED+=("${skill_dir#"$TARGET_DIR/"}")
      fi
    done
  fi
}

remove_legacy_skill_source_copies() {
  local src_dir="$1"
  local dest_dir="$2"
  local src
  local dest

  # Older sync versions copied shared skill sources into target agent-docs.
  # Remove only exact generated copies so target-owned custom files survive.
  [ -d "$src_dir" ] || return 0
  [ -d "$dest_dir" ] || return 0

  for src in "$src_dir"/*.md; do
    [ -f "$src" ] || continue
    dest="$dest_dir/$(basename "$src")"
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
      rm "$dest"
      MANAGED_DELETED+=("${dest#"$TARGET_DIR/"}")
    fi
  done

  rmdir "$dest_dir" 2>/dev/null || true
}

remove_deprecated_unprefixed_skill_copies() {
  local dest_dir="$1"
  local old_name
  local dest
  local first_line

  # The skai-* rename means old flat markdown copies no longer have matching
  # source filenames, so remove only the known generated command files.
  [ -d "$dest_dir" ] || return 0

  for old_name in "${DEPRECATED_UNPREFIXED_SKILLS[@]}"; do
    dest="$dest_dir/$old_name.md"
    [ -f "$dest" ] || continue
    first_line="$(sed -n '1p' "$dest")"
    if [ "$first_line" = "# /$old_name" ]; then
      rm "$dest"
      MANAGED_DELETED+=("${dest#"$TARGET_DIR/"}")
    fi
  done

  rmdir "$dest_dir" 2>/dev/null || true
}

# Rule documents are managed as the shared source of truth for agent behavior.
sync_managed_dir "$SOURCE_DIR/agent-docs/rules" "$TARGET_DIR/agent-docs/rules"
remove_legacy_skill_source_copies "$SOURCE_DIR/agent-docs/skills" "$TARGET_DIR/agent-docs/skills"
remove_deprecated_unprefixed_skill_copies "$TARGET_DIR/agent-docs/skills"

copy_managed "$SOURCE_DIR/.claude/settings.json"           "$TARGET_DIR/.claude/settings.json"
copy_managed "$SOURCE_DIR/scripts/sync-agent-config.sh"    "$TARGET_DIR/scripts/sync-agent-config.sh"

# Older sync versions copied Claude skills as flat markdown files. Remove only
# exact generated copies before writing the official SKILL.md package layout.
remove_legacy_skill_source_copies "$SOURCE_DIR/agent-docs/skills" "$TARGET_DIR/.claude/skills"
remove_deprecated_unprefixed_skill_copies "$TARGET_DIR/.claude/skills"

# Claude Code and Codex read SKILL.md folders, so generate wrappers at sync time
# from the same shared source for both agent-specific locations.
sync_skill_packages "$SOURCE_DIR/agent-docs/skills" "$TARGET_DIR/.claude/skills"
sync_skill_packages "$SOURCE_DIR/agent-docs/skills" "$TARGET_DIR/.agents/skills"

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
