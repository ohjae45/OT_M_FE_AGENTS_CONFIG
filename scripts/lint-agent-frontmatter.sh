#!/usr/bin/env bash
# Lints agent and skill source files for frontmatter and body issues that
# would either break sync (e.g. ''' in agent body) or produce poor dispatch
# matching (missing or vague description).
#
# Runs against the canonical sources under agent-docs/. Templates are scanned
# but only for body-level rules — placeholder frontmatter in templates is
# tolerated since they are not synced to target repos.
#
# Usage:
#   bash scripts/lint-agent-frontmatter.sh
#
# Exit code 0 if no errors (warnings allowed), 1 if any error found.
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS_DIR="$REPO_ROOT/agent-docs/agents"
SKILLS_DIR="$REPO_ROOT/agent-docs/skills"
TEMPLATES_DIR="$REPO_ROOT/agent-docs/templates"

DESC_MIN_LEN=30
DESC_MAX_LEN=500
ALLOWED_MODELS=(opus sonnet haiku)

ERROR_COUNT=0
WARN_COUNT=0
CHECKED_COUNT=0

RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'
GREEN=$'\033[0;32m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

if [ ! -t 1 ]; then
  RED=""
  YELLOW=""
  GREEN=""
  BOLD=""
  RESET=""
fi

# ---------------------------------------------------------------------------
# Reporters
# ---------------------------------------------------------------------------
rel_path() {
  printf '%s' "${1#"$REPO_ROOT/"}"
}

report_error() {
  local file="$1"
  local msg="$2"
  printf '%s%sERROR%s %s — %s\n' "$BOLD" "$RED" "$RESET" "$(rel_path "$file")" "$msg"
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

report_warn() {
  local file="$1"
  local msg="$2"
  printf '%s%sWARN%s  %s — %s\n' "$BOLD" "$YELLOW" "$RESET" "$(rel_path "$file")" "$msg"
  WARN_COUNT=$((WARN_COUNT + 1))
}

# ---------------------------------------------------------------------------
# Frontmatter helpers — same parsing convention as sync-agent-config.sh so a
# field that lints clean here also extracts cleanly during sync.
# ---------------------------------------------------------------------------
has_frontmatter() {
  awk 'NR==1 && /^---[[:space:]]*$/ {found=1} END {exit found ? 0 : 1}' "$1"
}

extract_frontmatter_field() {
  local src="$1"
  local field="$2"
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

extract_body() {
  awk '
    /^---[[:space:]]*$/ { count++; if (count == 2) { in_body = 1; next } }
    in_body { print }
  ' "$1"
}

# Same logic as scripts/sync-agent-config.sh:extract_skill_description.
extract_skill_description_body() {
  awk '
    /^## (Description|설명)[[:space:]]*$/ { in_description=1; next }
    in_description && /^## / { exit }
    in_description && NF {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      print
    }
  ' "$1" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/[[:space:]]$//'
}

contains_placeholder() {
  # Matches unfilled template tokens such as <역할>, <대표 요청>, <...>.
  printf '%s' "$1" | grep -Eq '<[^<>]{1,80}>'
}

contains_todo_marker() {
  printf '%s' "$1" | grep -Eqi '(^|[^A-Za-z])(TODO|TBD|FIXME)([^A-Za-z]|$)'
}

is_in_allowed_models() {
  local v="$1"
  local m
  for m in "${ALLOWED_MODELS[@]}"; do
    [ "$v" = "$m" ] && return 0
  done
  return 1
}

# ---------------------------------------------------------------------------
# Agent lint
# ---------------------------------------------------------------------------
lint_agent_file() {
  local file="$1"
  local basename_no_ext
  basename_no_ext="$(basename "$file" .md)"

  CHECKED_COUNT=$((CHECKED_COUNT + 1))

  if ! has_frontmatter "$file"; then
    report_error "$file" "frontmatter 블록(---)이 없습니다. name/description/model 3개 필드를 추가하세요."
    return
  fi

  local name description model
  name="$(extract_frontmatter_field "$file" name)"
  description="$(extract_frontmatter_field "$file" description)"
  model="$(extract_frontmatter_field "$file" model)"

  if [ -z "$name" ]; then
    report_error "$file" "frontmatter에 name 필드가 없거나 비어 있습니다."
  else
    if [ "$name" != "$basename_no_ext" ]; then
      report_error "$file" "frontmatter name='$name' 이 파일명($basename_no_ext)과 다릅니다. Claude subagent_type/Codex agent name이 매핑되지 않습니다."
    fi
    if ! printf '%s' "$name" | grep -Eq '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
      report_error "$file" "name='$name' 이 kebab-case가 아닙니다 (소문자/숫자/하이픈만 허용)."
    fi
  fi

  if [ -z "$description" ]; then
    report_error "$file" "frontmatter에 description 필드가 없거나 비어 있습니다."
  else
    local len=${#description}
    if [ "$len" -lt "$DESC_MIN_LEN" ]; then
      report_warn "$file" "description이 너무 짧습니다 (${len}자 < ${DESC_MIN_LEN}자). 트리거 조건과 다른 에이전트와의 경계를 한 문장으로 적으세요."
    fi
    if [ "$len" -gt "$DESC_MAX_LEN" ]; then
      report_warn "$file" "description이 너무 깁니다 (${len}자 > ${DESC_MAX_LEN}자). dispatch 매칭 정확도가 떨어질 수 있습니다."
    fi
    if contains_placeholder "$description"; then
      report_error "$file" "description에 미채운 템플릿 자리표시자(<...>)가 남아 있습니다."
    fi
    if contains_todo_marker "$description"; then
      report_warn "$file" "description에 TODO/TBD/FIXME 표시가 남아 있습니다."
    fi
  fi

  if [ -z "$model" ]; then
    report_error "$file" "frontmatter에 model 필드가 없거나 비어 있습니다 (opus/sonnet/haiku 중 하나)."
  elif ! is_in_allowed_models "$model"; then
    report_error "$file" "model='$model' 이 허용 값(opus/sonnet/haiku)에 없습니다."
  fi

  # Body-level checks — sync_codex_agents refuses ''' in TOML literal strings,
  # so block it here before sync runs.
  local body
  body="$(extract_body "$file")"
  if printf '%s' "$body" | grep -q "'''"; then
    report_error "$file" "본문에 ''' (TOML literal 종료 시퀀스)가 있습니다. sync가 거부합니다."
  fi
}

# ---------------------------------------------------------------------------
# Skill lint — sync extracts description from "## Description"/"## 설명"
# section, so the body must carry that section with usable content.
# ---------------------------------------------------------------------------
lint_skill_file() {
  local file="$1"
  local basename_no_ext
  basename_no_ext="$(basename "$file" .md)"

  CHECKED_COUNT=$((CHECKED_COUNT + 1))

  # Skill naming convention: skai-* for common skills, fe-orchestrator for the
  # FE harness driver. Other prefixes are allowed but warned so reviewers can
  # confirm the choice.
  if ! printf '%s' "$basename_no_ext" | grep -Eq '^(skai-[a-z0-9-]+|fe-orchestrator)$'; then
    report_warn "$file" "스킬 파일명 규칙(skai-* 또는 fe-orchestrator)에 맞지 않습니다."
  fi

  if ! grep -Eq '^## (Description|설명)[[:space:]]*$' "$file"; then
    report_error "$file" "## Description 또는 ## 설명 섹션이 없습니다. sync가 frontmatter description을 생성하지 못해 dispatch 매칭이 약해집니다."
    return
  fi

  local description
  description="$(extract_skill_description_body "$file")"

  if [ -z "$description" ]; then
    report_error "$file" "## 설명 섹션이 비어 있습니다. 한 문장 이상 작성하세요."
    return
  fi

  local len=${#description}
  if [ "$len" -lt "$DESC_MIN_LEN" ]; then
    report_warn "$file" "추출된 스킬 description이 너무 짧습니다 (${len}자 < ${DESC_MIN_LEN}자)."
  fi
  if [ "$len" -gt "$DESC_MAX_LEN" ]; then
    report_warn "$file" "추출된 스킬 description이 너무 깁니다 (${len}자 > ${DESC_MAX_LEN}자)."
  fi
  if contains_placeholder "$description"; then
    report_error "$file" "스킬 설명에 미채운 템플릿 자리표시자(<...>)가 남아 있습니다."
  fi
  if contains_todo_marker "$description"; then
    report_warn "$file" "스킬 설명에 TODO/TBD/FIXME 표시가 남아 있습니다."
  fi
}

# ---------------------------------------------------------------------------
# Template body-level lint — templates themselves keep placeholder
# frontmatter, but the body should not contain ''' so copy-paste authors
# do not silently introduce a sync-breaking sequence.
# ---------------------------------------------------------------------------
lint_template_body_only() {
  local file="$1"
  CHECKED_COUNT=$((CHECKED_COUNT + 1))
  if grep -q "'''" "$file"; then
    report_error "$file" "본문에 ''' 시퀀스가 있습니다. 템플릿에서 복사된 새 에이전트가 sync에서 거부됩니다."
  fi
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
echo "=== Linting agent and skill frontmatter ==="
echo "  repo: $REPO_ROOT"
echo ""

if [ -d "$AGENTS_DIR" ]; then
  for f in "$AGENTS_DIR"/*.md; do
    [ -f "$f" ] || continue
    lint_agent_file "$f"
  done
fi

if [ -d "$SKILLS_DIR" ]; then
  for f in "$SKILLS_DIR"/*.md; do
    [ -f "$f" ] || continue
    lint_skill_file "$f"
  done
fi

if [ -d "$TEMPLATES_DIR" ]; then
  for f in "$TEMPLATES_DIR"/*.md; do
    [ -f "$f" ] || continue
    lint_template_body_only "$f"
  done
fi

echo ""
echo "=== Summary ==="
printf '  files checked: %d\n' "$CHECKED_COUNT"
printf '  errors:        %s%d%s\n' "$( [ "$ERROR_COUNT" -gt 0 ] && echo "$RED" )" "$ERROR_COUNT" "$RESET"
printf '  warnings:      %s%d%s\n' "$( [ "$WARN_COUNT" -gt 0 ] && echo "$YELLOW" )" "$WARN_COUNT" "$RESET"

if [ "$ERROR_COUNT" -gt 0 ]; then
  printf '%s%sLint failed.%s 위 에러를 수정하고 다시 실행하세요.\n' "$BOLD" "$RED" "$RESET"
  exit 1
fi

printf '%sLint passed.%s\n' "$GREEN" "$RESET"
exit 0
