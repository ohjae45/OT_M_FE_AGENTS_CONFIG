# OT_M_FE_AGENTS_CONFIG

공통 AI 에이전트 설정 및 규칙 문서 원본 레포입니다.

## 현재 레포 구조

```
OT_M_FE_AGENTS_CONFIG/
├── agent-docs/
│   ├── rules/          # 공통 개발 규칙 문서 원본
│   ├── skills/         # 공통 skai-* 스킬 원본
│   └── templates/      # 스킬 작성용 원본 템플릿
├── templates/          # 초기 세팅용 템플릿 (seed)
├── .claude/
│   └── settings.json   # Claude 공통 설정 원본
└── scripts/
    └── sync-agent-config.sh   # 동기화 스크립트
```

## Target repo에 적용되는 구조

```
target-repo/
├── AGENTS.md               ← templates/AGENTS.md (seed)
├── CLAUDE.md               ← templates/CLAUDE.md (seed)
├── agent-docs/
│   └── rules/              ← agent-docs/rules/* (managed)
├── .claude/
│   ├── settings.json       ← .claude/settings.json (managed)
│   └── skills/
│       └── <skai-skill>/SKILL.md ← OT_M_FE_AGENTS_CONFIG/agent-docs/skills/skai-*에서 생성 (managed)
├── .agents/
│   └── skills/
│       └── <skai-skill>/SKILL.md ← OT_M_FE_AGENTS_CONFIG/agent-docs/skills/skai-*에서 생성 (managed)
└── scripts/
    └── sync-agent-config.sh ← scripts/sync-agent-config.sh (managed)
```

### Target repo 구성 요소 의미

| 경로 | 관리 방식 | 의미 |
| --- | --- | --- |
| `AGENTS.md` | seed | Codex, Claude 같은 에이전트가 공통으로 따라야 하는 프로젝트 작업 원칙입니다. 이미 있으면 덮어쓰지 않습니다. |
| `CLAUDE.md` | seed | Claude Code가 우선 읽는 프로젝트 지침입니다. `AGENTS.md`를 참조하고 사용 가능한 SKAI 스킬 목록을 안내합니다. 이미 있으면 덮어쓰지 않습니다. |
| `agent-docs/rules/` | managed | TypeScript, 스타일링, 상태 관리, 워크플로우 같은 공통 개발 규칙 문서입니다. |
| `.claude/settings.json` | managed | Claude Code에서 사용할 공통 설정입니다. |
| `.claude/skills/<skai-skill>/SKILL.md` | managed/generated | Claude Code가 인식하는 repo-local 스킬 패키지입니다. `agent-docs/skills/skai-*.md` 원본에 frontmatter를 붙여 생성합니다. |
| `.agents/skills/<skai-skill>/SKILL.md` | managed/generated | Codex가 인식하는 repo-local 스킬 패키지입니다. Claude용 스킬과 같은 원본에서 생성하되 Codex가 읽는 위치에 둡니다. |
| `scripts/sync-agent-config.sh` | managed | target repo에서 OT_M_FE_AGENTS_CONFIG를 다시 가져와 공통 규칙 문서, 설정, 스킬을 최신 상태로 맞추는 동기화 스크립트입니다. |

## 동기화 정책

### Seed files

없을 때만 복사합니다. 이미 있으면 덮어쓰지 않습니다.

- `templates/AGENTS.md` → `AGENTS.md`
- `templates/CLAUDE.md` → `CLAUDE.md`

### Managed files

항상 최신으로 덮어씁니다.

- `agent-docs/rules/*` → `agent-docs/rules/*`
- `.claude/settings.json` → `.claude/settings.json`
- `OT_M_FE_AGENTS_CONFIG/agent-docs/skills/skai-*` → `.claude/skills/<skai-skill>/SKILL.md`
- `OT_M_FE_AGENTS_CONFIG/agent-docs/skills/skai-*` → `.agents/skills/<skai-skill>/SKILL.md`
- `scripts/sync-agent-config.sh` → `scripts/sync-agent-config.sh`

## 스킬 관리 원칙

| 항목 | 원칙 |
| --- | --- |
| 원본 위치 | 스킬 원본은 `agent-docs/skills/skai-*.md`만 수정합니다. |
| 이름 규칙 | SKAI 공통 스킬임을 구분할 수 있도록 `skai-` 접두사를 사용합니다. |
| 새 스킬 작성 | `agent-docs/templates/skill-template.md`를 복사해서 시작합니다. 이 템플릿은 target repo로 동기화하지 않습니다. |
| 생성 위치 | sync 시 `.claude/skills/<skai-skill>/SKILL.md`와 `.agents/skills/<skai-skill>/SKILL.md`를 생성합니다. |
| 수정 금지 위치 | `.claude/skills`와 `.agents/skills` 아래 generated `SKILL.md`는 직접 수정하지 않습니다. |
| Codex 위치 | Codex repo-local skills는 `.agents/skills`를 사용합니다. `.codex`는 필요할 때 `config.toml` 같은 설정만 둡니다. |

---

## 새 target repo 온보딩

### 1. 최초 1회만 수동으로 스크립트를 가져옵니다.

```bash
# 1. OT_M_FE_AGENTS_CONFIG를 임시로 클론
git clone --depth 1 https://github.com/skaiworldwide/OT_M_FE_AGENTS_CONFIG.git /tmp/ot-m-fe-agents-config

# 2. 스크립트를 내 프로젝트에 복사
mkdir -p scripts
cp /tmp/ot-m-fe-agents-config/scripts/sync-agent-config.sh scripts/
chmod +x scripts/sync-agent-config.sh

# 3. 임시 디렉토리 삭제
rm -rf /tmp/ot-m-fe-agents-config
```

### 2. package.json에 동기화 스크립트를 추가합니다.

```json
{
  "scripts": {
    "agent:sync": "bash scripts/sync-agent-config.sh"
  }
}
```

### 3. 이후 동기화를 실행합니다.

```bash
pnpm agent:sync
```

---

## 이후 동기화 방법

OT_M_FE_AGENTS_CONFIG에 변경이 생기면 각 target repo에서 아래를 실행합니다.

```bash
pnpm agent:sync
git add -A
git commit -m "chore: sync common agent config"
```
