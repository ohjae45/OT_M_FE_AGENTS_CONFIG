# OT_M_FE_AGENTS_CONFIG

공통 AI 에이전트 설정 및 규칙 문서 원본 레포입니다.

## 현재 레포 구조

```
OT_M_FE_AGENTS_CONFIG/
├── agent-docs/
│   ├── rules/          # 공통 개발 규칙 문서 원본
│   ├── agents/         # 공통 FE 에이전트 정의 원본
│   ├── skills/         # 공통 스킬 원본 (skai-* + fe-orchestrator)
│   └── templates/      # 에이전트·스킬 작성용 원본 템플릿
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
│   ├── agents/
│   │   └── fe-*.md         ← agent-docs/agents/fe-*.md (managed)
│   └── skills/
│       └── <skill>/SKILL.md ← agent-docs/skills/*.md에서 생성 (managed)
├── .agents/
│   └── skills/
│       └── <skill>/SKILL.md ← agent-docs/skills/*.md에서 생성 (managed)
└── scripts/
    └── sync-agent-config.sh ← scripts/sync-agent-config.sh (managed)
```

### Target repo 구성 요소 의미

| 경로 | 관리 방식 | 의미 |
| --- | --- | --- |
| `AGENTS.md` | seed | Codex, Claude 같은 에이전트가 공통으로 따라야 하는 프로젝트 작업 원칙입니다. 프로젝트별 도메인 지식(용어·API 패턴·페이지 구조)도 여기에 둡니다. 이미 있으면 덮어쓰지 않습니다. |
| `CLAUDE.md` | seed | Claude Code가 우선 읽는 프로젝트 지침입니다. `AGENTS.md`를 참조하고 하네스(FE 에이전트 팀) 트리거 규칙을 안내합니다. 이미 있으면 덮어쓰지 않습니다. |
| `agent-docs/rules/` | managed | TypeScript, 스타일링, 상태 관리, 워크플로우 같은 공통 개발 규칙 문서입니다. |
| `.claude/settings.json` | managed | Claude Code에서 사용할 공통 설정입니다. |
| `.claude/agents/fe-*.md` | managed | 프론트엔드 에이전트 팀(fe-analyst·fe-builder·fe-integration·fe-qa) 정의입니다. 도메인 중립이며 프로젝트별 지식은 `AGENTS.md`로 분리합니다. |
| `.claude/skills/<skill>/SKILL.md` | managed/generated | Claude Code가 인식하는 repo-local 스킬 패키지입니다. `agent-docs/skills/*.md` 원본에 frontmatter를 붙여 생성합니다. (`skai-*` 공통 작업 + `fe-orchestrator`) |
| `.agents/skills/<skill>/SKILL.md` | managed/generated | Codex가 인식하는 repo-local 스킬 패키지입니다. Claude용 스킬과 같은 원본에서 생성하되 Codex가 읽는 위치에 둡니다. |
| `scripts/sync-agent-config.sh` | managed | target repo에서 OT_M_FE_AGENTS_CONFIG를 다시 가져와 공통 규칙 문서, 설정, 에이전트, 스킬을 최신 상태로 맞추는 동기화 스크립트입니다. |

## 동기화 정책

### Seed files

없을 때만 복사합니다. 이미 있으면 덮어쓰지 않습니다.

- `templates/AGENTS.md` → `AGENTS.md`
- `templates/CLAUDE.md` → `CLAUDE.md`

> **기존 target repo 업그레이드:** seed라 덮어쓰지는 않지만, 기존 `AGENTS.md`/`CLAUDE.md`에 `## 하네스` 섹션이 없으면 sync 시 템플릿의 하네스 섹션을 파일 끝에 자동으로 한 번 append 합니다. 그래야 하네스 도입 이전에 생성된 target repo도 `fe-orchestrator` 트리거 규칙을 받을 수 있습니다. 이미 `## 하네스` 섹션이 있으면 건드리지 않으므로, 프로젝트별로 수정한 내용은 그대로 보존됩니다.

### Managed files

항상 최신으로 덮어씁니다.

- `agent-docs/rules/*` → `agent-docs/rules/*`
- `agent-docs/agents/fe-*.md` → `.claude/agents/fe-*.md`
- `.claude/settings.json` → `.claude/settings.json`
- `agent-docs/skills/*.md` → `.claude/skills/<skill>/SKILL.md`
- `agent-docs/skills/*.md` → `.agents/skills/<skill>/SKILL.md`
- `scripts/sync-agent-config.sh` → `scripts/sync-agent-config.sh`

## 스킬 관리 원칙

| 항목 | 원칙 |
| --- | --- |
| 원본 위치 | 스킬 원본은 `agent-docs/skills/*.md`만 수정합니다. (`skai-*` 공통 작업 스킬 + `fe-orchestrator` 파이프라인) |
| 이름 규칙 | SKAI 공통 작업 스킬은 `skai-` 접두사, FE 에이전트 팀 오케스트레이터는 `fe-orchestrator`를 사용합니다. |
| 새 스킬 작성 | `agent-docs/templates/skill-template.md`를 복사해서 시작합니다. 이 템플릿은 target repo로 동기화하지 않습니다. |
| 생성 위치 | sync 시 `.claude/skills/<skill>/SKILL.md`와 `.agents/skills/<skill>/SKILL.md`를 생성합니다. |
| 수정 금지 위치 | `.claude/skills`와 `.agents/skills` 아래 generated `SKILL.md`는 직접 수정하지 않습니다. |
| Codex 위치 | Codex repo-local skills는 `.agents/skills`를 사용합니다. `.codex`는 필요할 때 `config.toml` 같은 설정만 둡니다. |

## 에이전트 관리 원칙

| 항목 | 원칙 |
| --- | --- |
| 원본 위치 | FE 에이전트 정의는 `agent-docs/agents/fe-*.md`만 수정합니다. |
| Frontmatter | 모든 에이전트 파일은 `name`, `description`, `model` frontmatter를 포함합니다. Claude Code가 이 메타데이터를 읽어 `subagent_type="<name>"`으로 등록하고, 파일 본문을 시스템 프롬프트로 주입합니다. |
| 도메인 중립 | 에이전트 정의는 프로젝트 도메인에 비의존적으로 작성합니다. 프로젝트별 도메인 지식(용어·API shape·페이지 구조)은 target repo의 `AGENTS.md`에 두고 참조만 합니다. |
| 새 에이전트 작성 | `agent-docs/templates/agent-template.md`를 복사해서 시작합니다. 이 템플릿은 target repo로 동기화하지 않습니다. |
| 생성 위치 | sync 시 target repo의 `.claude/agents/fe-*.md`로 직접 복사됩니다(매번 덮어쓰기). |
| 수정 금지 위치 | target repo의 `.claude/agents/fe-*.md`는 직접 수정하지 않습니다. 프로젝트별 차이가 필요하면 `AGENTS.md`에 반영합니다. |
| 트리거 | target repo의 `CLAUDE.md`가 `fe-orchestrator` 스킬을 트리거하면 에이전트 팀이 활성화됩니다. |
| 호출 방식 | `fe-orchestrator` 스킬은 `subagent_type="fe-analyst"`처럼 네이티브 서브에이전트 타입을 직접 지정해 호출합니다. `general-purpose`로 띄운 뒤 본문을 읽게 시키는 우회 패턴은 사용하지 않습니다. |

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
