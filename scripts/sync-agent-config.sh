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
# Argument parsing
#
# Default sync is non-destructive — managed files overwrite, seed files are
# preserved, and project-owned custom agents/skills survive. --reset is the
# only mode that wipes user content and is intended for one-time clean
# reinstalls.
# ---------------------------------------------------------------------------
RESET_MODE=0
RESET_MANAGED_MODE=0
ASSUME_YES=0

print_usage() {
  cat <<'USAGE'
Usage: bash scripts/sync-agent-config.sh [--reset | --reset-managed-only] [--yes]

Sync OT_M_FE_AGENTS_CONFIG into the current project (run from project root).

Options:
  --reset                Destructive one-time reinstall. Wipes every path
                         this repo manages (AGENTS.md, CLAUDE.md, .gitignore,
                         .codex/config.toml, .claude/settings.json,
                         agent-docs/, .claude/agents/, .claude/skills/,
                         .codex/agents/, .agents/skills/) — including
                         user-added custom files inside those directories —
                         then runs a fresh sync. Requires typing RESET to
                         confirm.
  --reset-managed-only   Wipe only sync-managed artifacts (agent-docs/rules,
                         agent-docs/guides, agent-docs/harness-changelog.md,
                         upstream fe-* agents under .claude/agents and
                         .codex/agents, generated <skill>/SKILL.md packages,
                         .claude/settings.json) then run a fresh sync.
                         Seed files (AGENTS.md, CLAUDE.md, .gitignore,
                         .codex/config.toml) and any project-added custom
                         agents/skills whose names do not match upstream
                         entries are preserved. Requires typing
                         RESET-MANAGED to confirm.
  -y, --yes              Skip the confirmation prompt (use only for automation).
  -h, --help             Print this help and exit.

Both reset modes require a clean git working tree (no staged, unstaged, or
untracked changes). This guard is unconditional — `--yes` does not bypass
it. Run `git status` and commit/stash/discard before retrying.

Without --reset / --reset-managed-only the sync is safe to run repeatedly:
managed files are overwritten with upstream content, seed files (AGENTS.md,
CLAUDE.md, etc.) are kept as-is, and project-specific custom agents/skills
are preserved.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --reset)
      RESET_MODE=1
      shift
      ;;
    --reset-managed-only)
      RESET_MANAGED_MODE=1
      shift
      ;;
    -y|--yes)
      ASSUME_YES=1
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run with --help for usage." >&2
      exit 2
      ;;
  esac
done

if [ "$RESET_MODE" = "1" ] && [ "$RESET_MANAGED_MODE" = "1" ]; then
  echo "Error: --reset and --reset-managed-only are mutually exclusive." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
TARGET_DIR="$(pwd)"

# Reset modes wipe paths irreversibly, including any uncommitted edits or
# untracked custom agents/skills inside managed directories. Require a clean
# working tree so the operator can recover via `git restore` / `git stash pop`
# if the reset turns out to be wrong. Skipped when not in a git work tree —
# users running this in a non-versioned dir have no recovery path either way.
# `--yes` intentionally does NOT bypass: automation should clean its own state
# before invoking a destructive reset.
assert_clean_worktree_for_reset() {
  local mode_label="$1"

  if ! git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  if [ -z "$(git -C "$TARGET_DIR" status --porcelain 2>/dev/null)" ]; then
    return 0
  fi

  echo "" >&2
  echo "Error: ${mode_label} aborted — git working tree is not clean." >&2
  echo "" >&2
  echo "Reset deletes managed paths irreversibly and may overlap with your" >&2
  echo "uncommitted or untracked changes. Commit, stash, or discard them first:" >&2
  echo "" >&2
  echo "  git status" >&2
  echo "  git stash --include-untracked   # keep changes for later" >&2
  echo "" >&2
  exit 1
}

if [ "$RESET_MODE" = "1" ]; then
  assert_clean_worktree_for_reset "--reset"
fi
if [ "$RESET_MANAGED_MODE" = "1" ]; then
  assert_clean_worktree_for_reset "--reset-managed-only"
fi

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Cloning OT_M_FE_AGENTS_CONFIG (--depth 1)..."
git clone --depth 1 --branch "$REMOTE_BRANCH" "$REMOTE_REPO" "$TMP_DIR/config" --quiet
SOURCE_DIR="$TMP_DIR/config"

# Fail fast if upstream sources are malformed. The lint catches ''' in agent
# bodies (which would break TOML generation), missing/invalid frontmatter
# fields, and skill files without a Description section. Skipping the check
# would let a bad upstream commit propagate silently to every target repo.
if [ -f "$SOURCE_DIR/scripts/lint-agent-frontmatter.sh" ]; then
  echo "Linting upstream agent/skill sources..."
  if ! bash "$SOURCE_DIR/scripts/lint-agent-frontmatter.sh"; then
    echo "Sync aborted: upstream lint failed." >&2
    exit 1
  fi
fi

SEEDS_SKIPPED=()
MANAGED_ADDED=()
MANAGED_MODIFIED=()
MANAGED_UNCHANGED=()
MANAGED_DELETED=()
HARNESS_APPENDED=()
GITIGNORE_UPDATED=()
CHANGELOG_UPDATED=()
CHANGELOG_BACKFILLED=()
RESET_REMOVED=()

# ---------------------------------------------------------------------------
# Phase 0 (optional): --reset — wipe everything this repo owns before sync.
#
# Removes both managed artifacts and project-owned custom files inside the
# managed directories so the subsequent sync starts from a clean slate. Only
# touches paths this script writes to; leaves unrelated project content
# (other .claude/ subdirs, scripts/, source code) untouched.
# ---------------------------------------------------------------------------
if [ "$RESET_MODE" = "1" ]; then
  RESET_CANDIDATES=(
    "AGENTS.md"
    "CLAUDE.md"
    ".gitignore"
    ".codex/config.toml"
    ".claude/settings.json"
    "agent-docs"
    ".claude/agents"
    ".claude/skills"
    ".codex/agents"
    ".agents/skills"
  )

  RESET_EXISTING=()
  for p in "${RESET_CANDIDATES[@]}"; do
    if [ -e "$TARGET_DIR/$p" ]; then
      RESET_EXISTING+=("$p")
    fi
  done

  echo ""
  echo "=== --reset will remove these paths from $TARGET_DIR ==="
  if [ ${#RESET_EXISTING[@]} -eq 0 ]; then
    echo "  (nothing to remove — target is already clean)"
  else
    for p in "${RESET_EXISTING[@]}"; do
      echo "  - $p"
    done
    echo ""
    echo "After removal a fresh sync recreates managed files from upstream."
    echo "Project-specific edits inside these paths will be LOST — including"
    echo "any custom agents/skills you added under .claude/ or .codex/."
  fi
  echo ""

  if [ ${#RESET_EXISTING[@]} -gt 0 ] && [ "$ASSUME_YES" != "1" ]; then
    if [ ! -t 0 ]; then
      echo "Refusing to wipe without confirmation. Re-run with --yes for non-interactive use." >&2
      exit 1
    fi
    printf 'Type RESET to confirm (anything else aborts): '
    read -r answer
    if [ "$answer" != "RESET" ]; then
      echo "Aborted." >&2
      exit 1
    fi
  fi

  for p in "${RESET_EXISTING[@]}"; do
    rm -rf "$TARGET_DIR/$p"
    RESET_REMOVED+=("$p")
  done

  if [ ${#RESET_REMOVED[@]} -gt 0 ]; then
    echo "Wiped ${#RESET_REMOVED[@]} path(s). Continuing with fresh sync..."
    echo ""
  fi
fi

# ---------------------------------------------------------------------------
# Phase 0b (optional): --reset-managed-only — wipe only the artifacts this
# repo generates and own, leaving seed files and project-owned custom
# agents/skills intact.
#
# Concrete managed paths are enumerated from the upstream sources so files
# whose names do not match an upstream entry (project-specific custom agents
# or skills) survive. agent-docs/ is wiped at the subdirectory level rather
# than wholesale so that any project-added notes inside agent-docs/ are also
# preserved.
# ---------------------------------------------------------------------------
if [ "$RESET_MANAGED_MODE" = "1" ]; then
  RESET_MANAGED_CANDIDATES=(
    "agent-docs/rules"
    "agent-docs/guides"
    "agent-docs/harness-changelog.md"
    ".claude/settings.json"
  )

  if [ -d "$SOURCE_DIR/agent-docs/agents" ]; then
    for src in "$SOURCE_DIR/agent-docs/agents"/*.md; do
      [ -f "$src" ] || continue
      base="$(basename "$src" .md)"
      RESET_MANAGED_CANDIDATES+=(".claude/agents/${base}.md")
      RESET_MANAGED_CANDIDATES+=(".codex/agents/${base}.toml")
    done
  fi

  if [ -d "$SOURCE_DIR/agent-docs/skills" ]; then
    for src in "$SOURCE_DIR/agent-docs/skills"/*.md; do
      [ -f "$src" ] || continue
      base="$(basename "$src" .md)"
      RESET_MANAGED_CANDIDATES+=(".claude/skills/${base}")
      RESET_MANAGED_CANDIDATES+=(".agents/skills/${base}")
    done
  fi

  RESET_EXISTING=()
  for p in "${RESET_MANAGED_CANDIDATES[@]}"; do
    if [ -e "$TARGET_DIR/$p" ]; then
      RESET_EXISTING+=("$p")
    fi
  done

  echo ""
  echo "=== --reset-managed-only will remove these managed paths from $TARGET_DIR ==="
  if [ ${#RESET_EXISTING[@]} -eq 0 ]; then
    echo "  (nothing to remove — managed paths are already absent)"
  else
    for p in "${RESET_EXISTING[@]}"; do
      echo "  - $p"
    done
    echo ""
    echo "Preserved:"
    echo "  - Seed files (AGENTS.md, CLAUDE.md, .gitignore, .codex/config.toml)"
    echo "  - User custom agents/skills whose names do not match upstream entries"
    echo "  - Any files under agent-docs/ outside rules/, guides/, harness-changelog.md"
    echo ""
    echo "After removal a fresh sync recreates managed files from upstream."
  fi
  echo ""

  if [ ${#RESET_EXISTING[@]} -gt 0 ] && [ "$ASSUME_YES" != "1" ]; then
    if [ ! -t 0 ]; then
      echo "Refusing to wipe without confirmation. Re-run with --yes for non-interactive use." >&2
      exit 1
    fi
    printf 'Type RESET-MANAGED to confirm (anything else aborts): '
    read -r answer
    if [ "$answer" != "RESET-MANAGED" ]; then
      echo "Aborted." >&2
      exit 1
    fi
  fi

  for p in "${RESET_EXISTING[@]}"; do
    rm -rf "$TARGET_DIR/$p"
    RESET_REMOVED+=("$p")
  done

  if [ ${#RESET_REMOVED[@]} -gt 0 ]; then
    echo "Wiped ${#RESET_REMOVED[@]} managed path(s). Continuing with fresh sync..."
    echo ""
  fi
fi

# Workspace directories that fe-orchestrator generates on every run. They hold
# transient analyst/builder/QA notes and must never be committed.
HARNESS_WORKSPACE_ENTRIES=("_workspace/" "_workspace_prev/")

# Known skill names before the SKAI prefix migration. These are used only for
# deleting generated legacy flat markdown copies, not target-owned custom skills.
# Mapping to current names: commit → skai-commit, review → skai-convention-review,
# pr → skai-pr.
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
copy_seed "$SOURCE_DIR/templates/gitignore"  "$TARGET_DIR/.gitignore"
copy_seed "$SOURCE_DIR/templates/codex-config.toml" "$TARGET_DIR/.codex/config.toml"

# ---------------------------------------------------------------------------
# Phase 1b: Harness section back-fill — for target repos that were seeded
# before the FE-COMMON harness section existed in the templates.
#
# Seeds are never overwritten, so an existing AGENTS.md/CLAUDE.md from an
# earlier sync would otherwise miss the trigger rules that activate the
# fe-orchestrator pipeline. Detect the missing section and append it once.
# ---------------------------------------------------------------------------
extract_harness_section() {
  # Capture from the harness heading to end of file. The leading separator is
  # added at append time so the section attaches cleanly to existing content.
  awk '/^## 하네스/{found=1} found {print}' "$1"
}

append_harness_section_if_missing() {
  local src="$1"
  local dest="$2"

  [ -f "$dest" ] || return 0
  if grep -q '^## 하네스' "$dest"; then
    return 0
  fi

  local section
  section="$(extract_harness_section "$src")"
  [ -n "$section" ] || return 0

  # Ensure a blank line before the appended separator regardless of whether
  # the existing file ends with a newline.
  if [ -s "$dest" ] && [ "$(tail -c1 "$dest"; echo x)" != $'\nx' ]; then
    printf '\n' >> "$dest"
  fi

  {
    printf '\n---\n\n'
    printf '%s\n' "$section"
  } >> "$dest"

  HARNESS_APPENDED+=("${dest#"$TARGET_DIR/"}")
}

# The harness section now lives in AGENTS.md only; CLAUDE.md imports it via
# `@AGENTS.md`. Old target CLAUDE.md files that already contain `## 하네스`
# from prior syncs keep their content (seed policy never overwrites).
append_harness_section_if_missing "$SOURCE_DIR/templates/AGENTS.md" "$TARGET_DIR/AGENTS.md"

# ---------------------------------------------------------------------------
# Phase 1c: .gitignore workspace backfill — for target repos that already had
# a .gitignore before the harness landed. fe-orchestrator writes runtime notes
# under _workspace/ and rotates the previous run to _workspace_prev/, so both
# must be ignored. Skip seeded repos (already covered) and any line that
# already lists the entry in a recognised form.
# ---------------------------------------------------------------------------
gitignore_has_entry() {
  local dest="$1"
  local name="$2"
  name="${name%/}"
  # Accept the common idiomatic forms: foo, foo/, /foo, /foo/ — optionally
  # followed by an inline comment. _workspace names contain no regex metas.
  grep -Eq "^[[:space:]]*/?${name}/?[[:space:]]*(#.*)?$" "$dest"
}

ensure_gitignore_workspace_entries() {
  local dest="$TARGET_DIR/.gitignore"
  local missing=()
  local entry

  [ -f "$dest" ] || return 0

  for entry in "${HARNESS_WORKSPACE_ENTRIES[@]}"; do
    if ! gitignore_has_entry "$dest" "$entry"; then
      missing+=("$entry")
    fi
  done

  [ ${#missing[@]} -gt 0 ] || return 0

  if [ -s "$dest" ] && [ "$(tail -c1 "$dest"; echo x)" != $'\nx' ]; then
    printf '\n' >> "$dest"
  fi

  {
    printf '\n# FE-COMMON 하네스 워크스페이스 (런타임 산출물, 커밋 금지)\n'
    printf '%s\n' "${missing[@]}"
  } >> "$dest"

  GITIGNORE_UPDATED+=("${dest#"$TARGET_DIR/"}: $(IFS=,; echo "${missing[*]}")")
}

ensure_gitignore_workspace_entries

# ---------------------------------------------------------------------------
# Phase 1d: Harness changelog auto-sync
#
# The "변경 이력" table inside AGENTS.md "## 하네스" section used to be
# maintained by hand, which left placeholder rows (`YYYY-MM-DD | ... | 초기
# 시드`) in older targets. The canonical table now lives in
# agent-docs/harness-changelog.md and is bounded by:
#
#     <!-- harness-changelog:upstream:start -->
#     ...table...
#     <!-- harness-changelog:upstream:end -->
#
# This phase replaces the contents between those markers in the target
# AGENTS.md with the upstream block on every sync. Targets that predate the
# markers are backfilled once: the "**변경 이력:**" paragraph is detected and
# whatever markdown table follows it is replaced with the marker block.
# AGENTS.md itself remains a seed (never recreated wholesale); only this
# specific subsection is managed.
# ---------------------------------------------------------------------------
CHANGELOG_START='<!-- harness-changelog:upstream:start -->'
CHANGELOG_END='<!-- harness-changelog:upstream:end -->'

extract_changelog_block() {
  # Pull the table between the markers in the upstream changelog file. Lines
  # are emitted verbatim so column alignment from the source is preserved.
  awk -v start="$CHANGELOG_START" -v end="$CHANGELOG_END" '
    $0 == start { capture = 1; next }
    $0 == end { capture = 0; exit }
    capture { print }
  ' "$1"
}

sync_harness_changelog_block() {
  local source_file="$SOURCE_DIR/agent-docs/harness-changelog.md"
  local dest="$TARGET_DIR/AGENTS.md"
  local block_file
  local generated

  [ -f "$source_file" ] || return 0
  [ -f "$dest" ] || return 0

  # BSD awk (default on macOS) rejects newlines in `-v var=...` values, so the
  # block is staged to a temp file and pulled in via getline rather than
  # passed inline.
  block_file="$TMP_DIR/harness-changelog-block.md"
  extract_changelog_block "$source_file" > "$block_file"
  [ -s "$block_file" ] || return 0

  generated="$TMP_DIR/AGENTS.md.with-changelog"
  local is_backfill=0

  if grep -qF "$CHANGELOG_START" "$dest"; then
    # Marker present: replace only the contents between the markers, leaving
    # surrounding paragraphs (including any project-specific tables) intact.
    awk -v start="$CHANGELOG_START" -v end="$CHANGELOG_END" -v blockfile="$block_file" '
      function emit_block(   line) {
        while ((getline line < blockfile) > 0) print line
        close(blockfile)
      }
      $0 == start { print; emit_block(); in_block = 1; next }
      $0 == end { in_block = 0; print; next }
      !in_block { print }
    ' "$dest" > "$generated"
  elif grep -q '^\*\*변경 이력:' "$dest"; then
    is_backfill=1
    # Backfill path for targets seeded before markers existed. Drop the legacy
    # table that follows the "변경 이력:" paragraph and emit the marker block
    # in its place. Lines after the table (e.g. additional notes) are kept.
    awk -v start="$CHANGELOG_START" -v end="$CHANGELOG_END" -v blockfile="$block_file" '
      BEGIN { state = "before" }
      function emit_markers(   line) {
        print start
        while ((getline line < blockfile) > 0) print line
        close(blockfile)
        print end
        emitted = 1
      }
      state == "before" && /^\*\*변경 이력:/ { state = "after-paragraph"; print; next }
      state == "after-paragraph" && /^\|/ { state = "in-table"; emit_markers(); next }
      state == "in-table" && /^\|/ { next }
      state == "in-table" { state = "after-table" }
      { print }
      END {
        # No table existed at all — append the marker block at end of file so
        # the canonical changelog still lands somewhere.
        if (state == "after-paragraph" && !emitted) {
          print ""
          emit_markers()
        }
      }
    ' "$dest" > "$generated"
  else
    # Target has no harness section yet (Phase 1b should have appended one
    # already, but bail out defensively to avoid mutating unrelated content).
    return 0
  fi

  if ! cmp -s "$generated" "$dest"; then
    cp "$generated" "$dest"
    CHANGELOG_UPDATED+=("${dest#"$TARGET_DIR/"}")
    if [ "$is_backfill" = "1" ]; then
      CHANGELOG_BACKFILLED+=("${dest#"$TARGET_DIR/"}")
    fi
  fi
}

sync_harness_changelog_block

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

# ---------------------------------------------------------------------------
# Codex subagent TOML generation
#
# Codex reads .codex/agents/*.toml for project-scoped subagents. Each TOML
# file requires `name`, `description`, and `developer_instructions`; dispatch
# happens via natural-language calls ("Have fe-analyst do X"), so the body of
# the shared markdown source becomes the agent's system prompt verbatim.
# ---------------------------------------------------------------------------
extract_md_frontmatter_field() {
  local src="$1"
  local field="$2"

  # Only scan between the first and second `---` so body content that happens
  # to start with `name:` cannot leak into the TOML output.
  awk -v field="$field" '
    /^---[[:space:]]*$/ { count++; if (count == 1) { in_fm = 1; next }; if (count == 2) exit }
    in_fm && index($0, field ":") == 1 {
      sub(/^[^:]+:[[:space:]]*/, "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$src"
}

extract_md_body() {
  # Capture everything after the closing frontmatter marker.
  awk '
    /^---[[:space:]]*$/ { count++; if (count == 2) { in_body = 1; next } }
    in_body { print }
  ' "$1"
}

escape_toml_basic_string() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# TOML basic strings forbid raw control chars (U+0000-U+001F, U+007F), and
# Claude Code renders frontmatter description on a single line in its subagent
# menu. Awk extraction is line-based so a real LF cannot reach here, but CR
# (CRLF source files) and TAB can — both produce invalid TOML. Normalize the
# common cases and reject the rest so generation fails loudly.
normalize_frontmatter_description() {
  local s="$1"
  s="${s//$'\r'/}"
  s="${s//$'\t'/ }"
  # `grep -q '[[:cntrl:]]'` would miss raw LF (grep is line-oriented), so use
  # bash's regex engine which matches against the whole string.
  if [[ "$s" =~ [[:cntrl:]] ]]; then
    return 1
  fi
  printf '%s' "$s"
}

write_codex_agent_toml() {
  local src="$1"
  local dest="$2"
  local agent_name
  local description
  local generated
  local body

  agent_name="$(extract_md_frontmatter_field "$src" name)"
  description="$(extract_md_frontmatter_field "$src" description)"

  if [ -z "$agent_name" ]; then
    echo "skip: $src has no frontmatter name; cannot generate Codex TOML." >&2
    return 0
  fi
  if [ -z "$description" ]; then
    description="Subagent generated from agent-docs/agents/${agent_name}.md."
  fi
  if ! description="$(normalize_frontmatter_description "$description")"; then
    echo "error: $src description contains control characters that cannot be normalized." >&2
    return 1
  fi

  body="$(extract_md_body "$src")"

  # TOML multi-line literal strings (''' ... ''') preserve content verbatim,
  # so markdown stays untouched. Refuse files that already contain ''' so the
  # generated TOML cannot terminate early.
  if printf '%s' "$body" | grep -q "'''"; then
    echo "error: $src body contains ''' which would break TOML literal string." >&2
    return 1
  fi

  generated="$TMP_DIR/${agent_name}.codex.toml"

  {
    printf '# Generated from agent-docs/agents/%s.md by scripts/sync-agent-config.sh.\n' "$agent_name"
    printf '# Edit the source markdown instead.\n'
    printf 'name = "%s"\n' "$(escape_toml_basic_string "$agent_name")"
    printf 'description = "%s"\n' "$(escape_toml_basic_string "$description")"
    printf "developer_instructions = '''\n"
    printf '%s' "$body"
    # extract_md_body already prints trailing newlines; ensure the closing
    # delimiter sits on its own line.
    if [ -n "$body" ] && [ "${body: -1}" != $'\n' ]; then
      printf '\n'
    fi
    printf "'''\n"
  } > "$generated"

  copy_managed "$generated" "$dest"
}

sync_codex_agents() {
  local src_dir="$1"
  local dest_dir="$2"
  local src
  local agent_name
  local f

  [ -d "$src_dir" ] || return 0

  for src in "$src_dir"/*.md; do
    [ -f "$src" ] || continue
    agent_name="$(extract_md_frontmatter_field "$src" name)"
    [ -n "$agent_name" ] || continue
    write_codex_agent_toml "$src" "$dest_dir/$agent_name.toml"
  done

  if [ -d "$dest_dir" ]; then
    # Remove only previously generated TOML files whose source is gone. Custom
    # project-owned Codex agents (no generation header) stay untouched.
    for f in "$dest_dir"/*.toml; do
      [ -f "$f" ] || continue
      local fname
      fname="$(basename "$f" .toml)"
      if [ ! -f "$src_dir/$fname.md" ] &&
         grep -q '^# Generated from agent-docs/agents/' "$f"; then
        rm "$f"
        MANAGED_DELETED+=("${f#"$TARGET_DIR/"}")
      fi
    done
  fi
}

# ---------------------------------------------------------------------------
# Claude Code agent markdown generation
#
# Claude Code reads .claude/agents/*.md verbatim, so the body cannot be
# transformed. To distinguish managed copies from project-added custom
# agents (which would otherwise be deleted by the cleanup loop), an HTML
# comment marker is injected immediately after the frontmatter. Markdown
# parsers treat it as a no-op, and the cleanup loop only deletes files that
# carry the marker — custom agents added by the project survive.
# ---------------------------------------------------------------------------
write_claude_agent_md() {
  local src="$1"
  local dest="$2"
  local agent_name
  local generated

  agent_name="$(basename "$src" .md)"
  generated="$TMP_DIR/${agent_name}.claude.md"

  awk -v src_path="agent-docs/agents/${agent_name}.md" '
    BEGIN { fm = 0; injected = 0 }
    /^---[[:space:]]*$/ {
      print
      fm++
      if (fm == 2 && !injected) {
        print ""
        print "<!-- Generated from " src_path " by scripts/sync-agent-config.sh. Edit the source file instead. -->"
        injected = 1
      }
      next
    }
    { print }
  ' "$src" > "$generated"

  copy_managed "$generated" "$dest"
}

sync_claude_agents() {
  local src_dir="$1"
  local dest_dir="$2"
  local src
  local f
  local fname

  [ -d "$src_dir" ] || return 0

  for src in "$src_dir"/*.md; do
    [ -f "$src" ] || continue
    write_claude_agent_md "$src" "$dest_dir/$(basename "$src")"
  done

  if [ -d "$dest_dir" ]; then
    # Remove only previously generated agent files whose source is gone.
    # Custom project-owned Claude agents (no generation marker) stay untouched.
    # Legacy managed files written by older sync versions (before the marker
    # existed) also stay until manually cleaned — this is a deliberate
    # fail-safe so an upstream removal does not silently delete pre-marker
    # files that may still be in use.
    for f in "$dest_dir"/*.md; do
      [ -f "$f" ] || continue
      fname="$(basename "$f" .md)"
      if [ ! -f "$src_dir/$fname.md" ] &&
         grep -q '^<!-- Generated from agent-docs/agents/' "$f"; then
        rm "$f"
        MANAGED_DELETED+=("${f#"$TARGET_DIR/"}")
      fi
    done
  fi
}

# Rule documents are managed as the shared source of truth for agent behavior.
sync_managed_dir "$SOURCE_DIR/agent-docs/rules" "$TARGET_DIR/agent-docs/rules"

# Writing guides for project-level docs (e.g. how to fill AGENTS.md sections).
# Synced so target repos can reference examples locally while filling the seed.
sync_managed_dir "$SOURCE_DIR/agent-docs/guides" "$TARGET_DIR/agent-docs/guides"

# Harness changelog single source — AGENTS.md "변경 이력" 표 자동 동기화의 원본.
# target 측에서도 같은 파일이 보여야 AGENTS.md 안의 링크가 깨지지 않으므로
# managed 사본을 함께 둔다.
copy_managed "$SOURCE_DIR/agent-docs/harness-changelog.md" "$TARGET_DIR/agent-docs/harness-changelog.md"

# Frontend agent definitions are shared across projects and overwrite local
# copies on every sync; project-specific domain knowledge belongs in AGENTS.md.
# Claude Code reads .claude/agents/*.md verbatim and dispatches via the
# subagent_type API. Codex reads .codex/agents/*.toml and dispatches via
# natural-language calls; the TOML is generated from the same markdown source
# in sync_codex_agents below so a single source of truth covers both tools.
sync_claude_agents "$SOURCE_DIR/agent-docs/agents" "$TARGET_DIR/.claude/agents"
sync_codex_agents  "$SOURCE_DIR/agent-docs/agents" "$TARGET_DIR/.codex/agents"

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
# Phase 3: Global skills — install to ~/.claude/skills/ for cross-project use
#
# Skills listed here are copied to the user's global Claude skills directory so
# they are available in any project, including brand-new ones that have not yet
# run agent:sync.  Add a skill name here when it needs to work before a project
# is bootstrapped (e.g. project-init helpers).
# ---------------------------------------------------------------------------
GLOBAL_SKILL_NAMES=("skai-fe-init")
GLOBAL_INSTALLED=()
GLOBAL_UNCHANGED=()
GLOBAL_OVERWRITTEN=()

for skill_name in "${GLOBAL_SKILL_NAMES[@]}"; do
  src="$TARGET_DIR/.claude/skills/$skill_name"
  dest="$HOME/.claude/skills/$skill_name"
  [ -d "$src" ] || continue

  mkdir -p "$HOME/.claude/skills"
  if [ -d "$dest" ]; then
    # Compare recursively — if the existing global copy already matches
    # upstream, leave it alone so a user-customized fork is not silently
    # wiped on every sync. Different content triggers an overwrite that is
    # surfaced separately in the summary.
    if diff -rq "$src" "$dest" >/dev/null 2>&1; then
      GLOBAL_UNCHANGED+=("$skill_name → ~/.claude/skills/$skill_name")
    else
      rm -rf "$dest"
      cp -r "$src" "$dest"
      GLOBAL_OVERWRITTEN+=("$skill_name → ~/.claude/skills/$skill_name (overwritten existing)")
    fi
  else
    cp -r "$src" "$dest"
    GLOBAL_INSTALLED+=("$skill_name → ~/.claude/skills/$skill_name")
  fi
done

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

print_section "🧹"  "Reset removed (wiped before sync)" "$RED" "${RESET_REMOVED[@]+"${RESET_REMOVED[@]}"}"
print_section "⏭️"   "Seed skipped (already exists)"  "" "${SEEDS_SKIPPED[@]+"${SEEDS_SKIPPED[@]}"}"
print_section "💤"  "Unchanged"                       "" "${MANAGED_UNCHANGED[@]+"${MANAGED_UNCHANGED[@]}"}"
print_section "✅"  "Added"                           "" "${MANAGED_ADDED[@]+"${MANAGED_ADDED[@]}"}"
print_section "✏️"   "Modified"                        "" "${MANAGED_MODIFIED[@]+"${MANAGED_MODIFIED[@]}"}"
print_section "❌"  "Deleted"                         "$RED" "${MANAGED_DELETED[@]+"${MANAGED_DELETED[@]}"}"
print_section "🔧"  "Harness section appended"        "" "${HARNESS_APPENDED[@]+"${HARNESS_APPENDED[@]}"}"
print_section "🛡️"   ".gitignore workspace entries appended" "" "${GITIGNORE_UPDATED[@]+"${GITIGNORE_UPDATED[@]}"}"
print_section "📜"  "Harness changelog table updated" "" "${CHANGELOG_UPDATED[@]+"${CHANGELOG_UPDATED[@]}"}"
print_section "🌐"  "Global skills installed"         "" "${GLOBAL_INSTALLED[@]+"${GLOBAL_INSTALLED[@]}"}"
print_section "💤"  "Global skills unchanged"         "" "${GLOBAL_UNCHANGED[@]+"${GLOBAL_UNCHANGED[@]}"}"
print_section "♻️"   "Global skills overwritten"      "$RED" "${GLOBAL_OVERWRITTEN[@]+"${GLOBAL_OVERWRITTEN[@]}"}"

if [ ${#GLOBAL_OVERWRITTEN[@]} -gt 0 ]; then
  echo ""
  printf '%s\n' "${RED}⚠️  글로벌 스킬 덮어쓰기 경고${RESET}"
  printf '    %s\n' "~/.claude/skills/ 아래 기존 사본이 upstream 내용과 달라 덮어썼습니다."
  printf '    %s\n' "사용자가 글로벌 스킬을 커스터마이즈했다면 변경분이 사라졌을 수 있습니다."
  printf '    %s\n' "필요하면 git 등으로 원본을 복구한 뒤 upstream과 머지하거나, 다른 이름으로 분기해주세요."
fi

if [ ${#CHANGELOG_BACKFILLED[@]} -gt 0 ]; then
  echo ""
  printf '%s\n' "${RED}⚠️  변경 이력 표 backfill 경고${RESET}"
  printf '    %s\n' "마커가 없던 AGENTS.md의 기존 변경 이력 표를 upstream 표로 교체했습니다."
  printf '    %s\n' "프로젝트별로 추가했던 행(예: 프로젝트 특화 변경)이 있었다면 'git diff'로 확인하고,"
  printf '    %s\n' "마커 바깥쪽에 별도 표(예: '## 프로젝트 변경 이력')를 만들어 옮겨주세요."
fi

echo ""
echo "Review changes with 'git diff', then commit and open a PR manually."
