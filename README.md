# OT_M_FE_AGENTS_CONFIG

공통 AI 에이전트 설정 및 규칙 문서 원본 레포입니다.

## 현재 레포 구조

```
OT_M_FE_AGENTS_CONFIG/
├── agent-docs/
│   ├── rules/          # 공통 개발 규칙 문서 원본
│   ├── agents/         # 공통 FE 에이전트 정의 원본 (sync 시 도구별 포맷으로 분기)
│   ├── skills/         # 공통 스킬 원본 (skai-* + fe-orchestrator)
│   ├── guides/         # 프로젝트 문서 작성 가이드 (AGENTS.md 섹션 채우기 예시 등)
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
├── AGENTS.md               ← templates/AGENTS.md (seed + 변경 이력 표 managed)
├── CLAUDE.md               ← templates/CLAUDE.md (seed)
├── .gitignore              ← templates/gitignore (seed + 워크스페이스 backfill)
├── agent-docs/
│   ├── rules/              ← agent-docs/rules/* (managed)
│   ├── guides/             ← agent-docs/guides/* (managed, AGENTS.md 작성 가이드)
│   └── harness-changelog.md ← agent-docs/harness-changelog.md (managed, 변경 이력 표 원본)
├── .claude/
│   ├── settings.json       ← .claude/settings.json (managed)
│   ├── agents/
│   │   └── fe-*.md         ← agent-docs/agents/fe-*.md (managed)
│   └── skills/
│       └── <skill>/SKILL.md ← agent-docs/skills/*.md에서 생성 (managed)
├── .codex/
│   ├── config.toml         ← templates/codex-config.toml (seed)
│   └── agents/
│       └── fe-*.toml       ← agent-docs/agents/fe-*.md에서 TOML로 변환 (managed)
├── .agents/
│   └── skills/
│       └── <skill>/SKILL.md ← agent-docs/skills/*.md에서 생성 (managed)
└── scripts/
    └── sync-agent-config.sh ← scripts/sync-agent-config.sh (managed)
```

### Target repo 구성 요소 의미

| 경로 | 관리 방식 | 의미 |
| --- | --- | --- |
| `AGENTS.md` | seed + 변경 이력 표 managed | Codex와 Claude가 공통으로 따라야 하는 프로젝트 작업 원칙입니다. 프로젝트별 도메인 지식(용어·API 패턴·페이지 구조)과 하네스 트리거 규칙도 여기에 둡니다. 본체는 이미 있으면 덮어쓰지 않지만, "## 하네스: FE-COMMON" 안의 **변경 이력 표는 `<!-- harness-changelog:upstream:* -->` 마커 안쪽에 한해 sync 시 자동 갱신**됩니다. ([agent-docs/harness-changelog.md](agent-docs/harness-changelog.md) 단일 원본) |
| `CLAUDE.md` | seed | Claude Code 진입점입니다. `@AGENTS.md` import로 공용 규칙을 가져오고, Claude 네이티브 서브에이전트 dispatch(`Agent(subagent_type=...)`) 디테일만 추가로 안내합니다. 이미 있으면 덮어쓰지 않습니다. |
| `.gitignore` | seed + backfill | `fe-orchestrator`가 매 실행마다 생성하는 `_workspace/`·`_workspace_prev/`를 자동으로 ignore 처리합니다. 파일이 없으면 `templates/gitignore`를 시드로 복사하고, 이미 있으면 두 엔트리가 누락된 경우에만 파일 끝에 한 번 추가합니다. |
| `agent-docs/rules/` | managed | TypeScript, 스타일링, 상태 관리, 워크플로우 같은 공통 개발 규칙 문서입니다. Claude·Codex 양쪽이 동일하게 참조합니다. |
| `agent-docs/guides/` | managed | 프로젝트별 문서를 채울 때 참고하는 가이드 모음입니다. 현재는 `AGENTS.md` 빈 섹션을 채우기 위한 두 도메인(채팅 플랫폼·분석 대시보드) 익명화 예시(`agents-md-writing.md`)가 있습니다. |
| `agent-docs/harness-changelog.md` | managed | AGENTS.md "변경 이력" 표의 단일 원본입니다. 마커(`<!-- harness-changelog:upstream:start -->` / `:end -->`) 안쪽 표가 sync 시 target의 AGENTS.md 마커 블록으로 복제됩니다. 변경 이력 행 추가는 이 파일에서만 합니다. |
| `.claude/settings.json` | managed | Claude Code에서 사용할 공통 설정입니다. |
| `.claude/agents/fe-*.md` | managed | Claude Code가 읽는 프론트엔드 에이전트 팀(fe-analyst·fe-builder·fe-integration·fe-qa) 정의입니다. Claude Code는 frontmatter를 스캔해 `subagent_type="fe-analyst"` 같은 네이티브 dispatch로 자동 등록합니다. 도메인 중립이며 프로젝트별 지식은 `AGENTS.md`로 분리합니다. |
| `.claude/skills/<skill>/SKILL.md` | managed/generated | Claude Code가 인식하는 repo-local 스킬 패키지입니다. `agent-docs/skills/*.md` 원본에 frontmatter를 붙여 생성합니다. (`skai-*` 공통 작업 + `fe-orchestrator`) |
| `.codex/config.toml` | seed | Codex CLI 프로젝트 설정입니다. 비워두면 사용자 `~/.codex/config.toml`이 그대로 적용되며, 프로젝트 단위로 model·sandbox_mode·MCP 서버 등을 override할 때 사용합니다. 이미 있으면 덮어쓰지 않습니다. |
| `.codex/agents/fe-*.toml` | managed/generated | Codex CLI가 읽는 프론트엔드 서브에이전트 정의입니다. `agent-docs/agents/fe-*.md`의 frontmatter `name`/`description`과 본문을 TOML `name`/`description`/`developer_instructions`로 변환해 생성합니다. Codex는 자동 인식하며 자연어 dispatch("fe-analyst 서브에이전트로 X 실행하라")로 호출합니다. |
| `.agents/skills/<skill>/SKILL.md` | managed/generated | Codex가 인식하는 repo-local 스킬 패키지입니다. Claude용 스킬과 같은 원본에서 생성하되 Codex가 읽는 위치(`.agents/skills`)에 둡니다. |
| `scripts/sync-agent-config.sh` | managed | target repo에서 OT_M_FE_AGENTS_CONFIG를 다시 가져와 공통 규칙 문서, 설정, 에이전트, 스킬을 최신 상태로 맞추는 동기화 스크립트입니다. |

## 동기화 정책

### Seed files

없을 때만 복사합니다. 이미 있으면 덮어쓰지 않습니다.

- `templates/AGENTS.md` → `AGENTS.md`
- `templates/CLAUDE.md` → `CLAUDE.md`
- `templates/gitignore` → `.gitignore`
- `templates/codex-config.toml` → `.codex/config.toml`

> **기존 target repo 업그레이드 (AGENTS.md 하네스 섹션):** seed라 덮어쓰지는 않지만, 기존 `AGENTS.md`에 `## 하네스` 섹션이 없으면 sync 시 템플릿의 하네스 섹션을 파일 끝에 자동으로 한 번 append 합니다. 그래야 하네스 도입 이전에 생성된 target repo도 `fe-orchestrator` 트리거 규칙을 받을 수 있습니다. 이미 `## 하네스` 섹션이 있으면 건드리지 않으므로, 프로젝트별로 수정한 내용은 그대로 보존됩니다. CLAUDE.md는 `@AGENTS.md` import로 그 본문을 가져오므로 별도 backfill 대상이 아닙니다.
>
> **`.gitignore` 워크스페이스 backfill:** 기존 `.gitignore`가 있으면 시드를 덮어쓰지 않는 대신, `_workspace/`·`_workspace_prev/` 두 엔트리가 누락된 경우에만 파일 끝에 한 번 추가합니다. `fe-orchestrator`가 매 실행마다 생성하는 런타임 산출물이 target repo에 그대로 커밋되지 않도록 보장하기 위한 정책입니다. 이미 두 엔트리가 (`foo`, `foo/`, `/foo` 등 일반 형태로) 등록돼 있으면 건드리지 않습니다.

### Managed files

항상 최신으로 덮어씁니다.

- `agent-docs/rules/*` → `agent-docs/rules/*`
- `agent-docs/guides/*` → `agent-docs/guides/*`
- `agent-docs/agents/fe-*.md` → `.claude/agents/fe-*.md` (Claude Code용, .md 그대로)
- `agent-docs/agents/fe-*.md` → `.codex/agents/fe-*.toml` (Codex CLI용, TOML로 변환)
- `.claude/settings.json` → `.claude/settings.json`
- `agent-docs/skills/*.md` → `.claude/skills/<skill>/SKILL.md`
- `agent-docs/skills/*.md` → `.agents/skills/<skill>/SKILL.md`
- `scripts/sync-agent-config.sh` → `scripts/sync-agent-config.sh`
- `agent-docs/harness-changelog.md`(마커 사이 표) → `AGENTS.md` "변경 이력" 표(마커 사이)

> **AGENTS.md "변경 이력" 표 자동 동기화:** AGENTS.md 본체는 seed라 덮어쓰지 않지만, 그 안의 "변경 이력" 표는 `<!-- harness-changelog:upstream:start -->`/`<!-- harness-changelog:upstream:end -->` 마커로 감싸져 있고, 마커 *안쪽 내용만* sync 시 [`agent-docs/harness-changelog.md`](agent-docs/harness-changelog.md)의 표로 교체됩니다. 프로젝트별 변경 이력이 필요하면 마커 바깥에 별도 표를 두세요. 마커가 없는 구버전 AGENTS.md는 sync가 한 번에 한해 backfill하며(기존 표를 마커 블록으로 치환), 이때 사용자가 손으로 추가한 행이 있었다면 `⚠️  변경 이력 표 backfill 경고`가 콘솔에 떠 `git diff`로 확인하라고 안내합니다.

## 스킬 관리 원칙

| 항목 | 원칙 |
| --- | --- |
| 원본 위치 | 스킬 원본은 `agent-docs/skills/*.md`만 수정합니다. (`skai-*` 공통 작업 스킬 + `fe-orchestrator` 파이프라인) |
| 이름 규칙 | SKAI 공통 작업 스킬은 `skai-` 접두사, FE 에이전트 팀 오케스트레이터는 `fe-orchestrator`를 사용합니다. |
| 새 스킬 작성 | `agent-docs/templates/skill-template.md`를 복사해서 시작합니다. 이 템플릿은 target repo로 동기화하지 않습니다. |
| 생성 위치 | sync 시 `.claude/skills/<skill>/SKILL.md`와 `.agents/skills/<skill>/SKILL.md`를 생성합니다. |
| 수정 금지 위치 | `.claude/skills`와 `.agents/skills` 아래 generated `SKILL.md`는 직접 수정하지 않습니다. |
| Codex 위치 | Codex repo-local skills는 `.agents/skills`를 사용합니다. `.codex`는 필요할 때 `config.toml` 같은 설정만 둡니다. |

### 글로벌 스킬 등록 정책 (`GLOBAL_SKILL_NAMES`)

[`scripts/sync-agent-config.sh`](scripts/sync-agent-config.sh)의 `GLOBAL_SKILL_NAMES` 배열에 추가된 스킬은 sync 시 target repo의 `.claude/skills/<name>/`을 그대로 `~/.claude/skills/<name>/`에도 복사합니다. 즉, **해당 사용자의 모든 프로젝트(아직 sync를 돌리지 않은 빈 디렉토리 포함)에서 즉시 호출 가능**해집니다.

**등록 기준은 "프로젝트가 sync를 돌리기 *전에* 동작해야 하는 스킬"인지로 판단합니다.** 그 외 스킬은 글로벌에 올리지 않고 repo-local(`.claude/skills/`·`.agents/skills/`)로만 두면 충분합니다.

| 분류 | 글로벌 등록 | 예 |
| --- | --- | --- |
| 빈 디렉토리에서 프로젝트를 부트스트랩하는 스킬 | ⭕️ 필요 | `skai-fe-init` — 신규 React/TS 프로젝트 세팅. 아직 `agent:sync`를 돌릴 환경 자체가 없을 때 호출됨 |
| 이미 부트스트랩된 프로젝트의 작업 흐름 스킬 | ❌ 불필요 | `skai-commit`, `skai-pr`, `skai-convention-review`, `fe-orchestrator` — sync 이후 repo-local만으로 동작 |
| 사용자 개인 워크플로우용 스킬 | ❌ (이 레포 관리 대상 아님) | 개인 단축어·매크로는 사용자가 직접 `~/.claude/skills/`에 둡니다 |

**현재 등록 항목:** `skai-fe-init` 1개.

추가하려면 위 기준을 충족하는 스킬을 `agent-docs/skills/<name>.md`에 먼저 작성한 뒤, sync 스크립트의 `GLOBAL_SKILL_NAMES=("skai-fe-init")` 줄에 이름을 더합니다. 글로벌 복사는 항상 `target-repo/.claude/skills/<name>/`을 원본으로 사용하므로, 해당 디렉토리가 생성되지 않는 스킬(예: 원본 파일이 없는 이름)은 조용히 스킵됩니다.

## 에이전트 관리 원칙

| 항목 | 원칙 |
| --- | --- |
| 원본 위치 | FE 에이전트 정의는 `agent-docs/agents/fe-*.md`만 수정합니다. Claude·Codex 모두 이 단일 원본에서 sync 시 분기 생성됩니다. |
| Frontmatter | 모든 에이전트 파일은 `name`, `description`, `model` frontmatter를 포함합니다. Claude Code는 이 메타데이터로 `subagent_type="<name>"` 자동 등록을, Codex sync는 같은 `name`·`description`을 TOML 필드로 추출합니다. (`model` 값은 Claude 전용이며 Codex TOML로 옮기지 않습니다 — Codex는 `.codex/config.toml`에서 모델을 설정합니다.) |
| 도메인 중립 | 에이전트 정의는 프로젝트 도메인에 비의존적으로 작성합니다. 프로젝트별 도메인 지식(용어·API shape·페이지 구조)은 target repo의 `AGENTS.md`에 두고 참조만 합니다. |
| 새 에이전트 작성 | `agent-docs/templates/agent-template.md`를 복사해서 시작합니다. 이 템플릿은 target repo로 동기화하지 않습니다. 본문에 `'''` 삼중 작은따옴표는 사용하지 않습니다 (Codex TOML 변환이 multi-line literal string을 사용하므로). |
| 생성 위치 | sync 시 `.claude/agents/<name>.md`(원본 그대로)와 `.codex/agents/<name>.toml`(TOML 변환) 두 곳에 매번 덮어쓰기로 배포됩니다. |
| 수정 금지 위치 | target repo의 `.claude/agents/`와 `.codex/agents/`에 있는 **upstream에서 sync된 산출물(`fe-*` 등)**은 직접 수정하지 않습니다. 프로젝트별 차이가 필요하면 `AGENTS.md`에 반영합니다. |
| 커스텀 에이전트 공존 | 프로젝트 고유 에이전트가 필요하면 `.claude/agents/`와 `.codex/agents/`에 직접 `<name>.md`/`<name>.toml`을 추가할 수 있습니다. sync는 **upstream 원본 마커가 박힌 파일만 cleanup 대상**으로 봅니다 (`.claude/agents`는 frontmatter 뒤 `<!-- Generated from agent-docs/agents/... -->` HTML 주석, `.codex/agents`는 TOML 상단 `# Generated from agent-docs/agents/...` 헤더). 마커가 없는 프로젝트 커스텀 파일은 정상 sync에서도, `--reset-managed-only`에서도 보존됩니다. |
| 환경 범위 | 하네스는 **Claude Code와 Codex CLI 두 환경**에서 동작합니다. Phase 흐름과 파일 핸드오프는 동일하고 dispatch만 다릅니다 — Claude는 `Agent(subagent_type="fe-analyst", ...)` 네이티브 도구, Codex는 자연어 지시("fe-analyst 서브에이전트로 X 실행하라"). Codex의 자연어 dispatch는 conversational이라 Phase 2 fe-builder ↔ fe-integration 병렬화는 더 제한적입니다 — 현재는 양 환경 모두 순차 실행을 표준으로 합니다. |
| 트리거 | target repo의 `AGENTS.md` "하네스: FE-COMMON" 섹션이 `fe-orchestrator` 스킬을 트리거합니다. (Claude Code는 `@AGENTS.md` import로, Codex CLI는 `AGENTS.md` 자동 로딩으로 같은 본문을 읽습니다.) |
| 호출 방식 | Claude: `Agent(subagent_type="fe-analyst", ...)` 네이티브 dispatch. Codex: 자연어 지시. `general-purpose`로 띄운 뒤 본문을 읽게 시키는 우회 패턴은 양쪽 모두 사용하지 않습니다. |

### Codex CLI PoC 검증 결과 (2026-05-13)

신규 target repo(빈 git 디렉토리)에 sync를 실행해 `.codex/agents/fe-{analyst,builder,integration,qa}.toml`을 생성한 뒤 Codex CLI에서 직접 확인한 결과:

- **자동 인식**: Codex CLI 0.130.0이 별도 등록 없이 4개 서브에이전트(`fe-analyst`·`fe-builder`·`fe-integration`·`fe-qa`)를 모두 인식. "사용 가능한 서브에이전트로 등록되어 있는가?" 질문에 **YES**.
- **자연어 dispatch**: "fe-analyst 서브에이전트에 X 작업을 위임하라" 발화로 Codex의 `collab: SpawnAgent` 런타임 도구가 트리거되고, 해당 서브에이전트가 TOML `developer_instructions`(에이전트 본문)를 시스템 프롬프트로 받아 `_workspace/01_analyst_plan.md`를 직접 작성했다. 즉, 상위 에이전트가 본문을 읽어 흉내내는 게 아니라 실제 sub-agent 컨텍스트가 분리 실행됨을 확인.
- **모델 호환성 제약**: Codex CLI 0.122.0의 기본 모델 `gpt-5.5`는 서버에서 "CLI 업그레이드 필요"로 거부됐고, `gpt-5`/`gpt-5.1`/`gpt-5-codex`/`o4-mini`는 ChatGPT 계정에서 미지원. **0.130.0 이상**에서만 PoC가 통과한다. 글로벌 README/온보딩에서 Codex CLI 0.130 이상을 권장 버전으로 명시한다.
- **관찰된 경고(비차단)**: 첫 SpawnAgent 호출에서 `Full-history forked agents inherit the parent agent type, model, and reasoning effort; omit agent_type, model, and reasoning_effort` 런타임 경고가 한 번 발생했으나 Codex가 자동으로 인자를 줄여 재호출해 성공. TOML 측에서 `model`/`reasoning_effort`를 비워둔 현재 정책이 올바름을 시사한다.

---

## 하네스 산출물(`_workspace/`) 구조

`fe-orchestrator`는 매 실행마다 target repo 루트의 `_workspace/`에 Phase별 산출물을 남기고, 다음 실행이 시작될 때 직전 산출물을 `_workspace_prev/`로 회전합니다. 디버깅·부분 재실행·실패 지점 파악 시 어디까지 진행됐는지 추적하는 1차 출처입니다. (두 디렉토리 모두 `.gitignore`에 자동 등록되어 커밋되지 않습니다 — [동기화 정책 > `.gitignore` 워크스페이스 backfill](#managed-files) 참고.)

| 파일 | 작성 주체 | 내용 |
| --- | --- | --- |
| `_workspace/01_analyst_plan.md` | `fe-analyst` | 사용자 요청 분석, 인터페이스 정의, 페이지·컴포넌트·훅 단위 계획 |
| `_workspace/02a_builder_status.md` | `fe-builder` | 생성·수정한 컴포넌트 파일 경로, props 타입 정의 위치, 필요한 훅·스토어 명세, 재사용 vs 신규 결정, 미해결 TODO |
| `_workspace/02b_integration_status.md` | `fe-integration` | 생성·수정한 훅·스토어·API 함수 경로, 쿼리 키·캐시 전략, builder 컴포넌트 props와의 매칭 결과, 인터페이스 불일치 시 임시 해결책 |
| `_workspace/03_qa_report.md` | `fe-qa` | PASS/FAIL과 항목별 검증 결과. FAIL이면 오케스트레이터가 해당 에이전트(`fe-builder` 또는 `fe-integration`)를 재호출 |
| `_workspace_prev/` | 오케스트레이터 | 직전 1회분 스냅샷. 새 실행 진입 시 이전 `_workspace_prev/`는 삭제되고 현재 `_workspace/`가 이 위치로 이동 (직전 1회만 보관) |

**디버깅 시 어디부터 보나:** 파일 번호(`01` → `02a`/`02b` → `03`)가 곧 Phase 진행도입니다. 마지막으로 존재하는 파일까지가 완료된 단계이고, 그 다음 단계에서 멈췄거나 실패했다는 뜻입니다. `_workspace_prev/`와 현재 `_workspace/`를 비교하면 이번 실행에서 무엇이 바뀌었는지 보입니다.

**부분 재실행과의 매핑:** 사용자가 "이 부분만 수정", "다시", "보완" 등을 요청할 때 어느 파일이 갱신되는지는 [fe-orchestrator의 부분 재실행 가이드](agent-docs/skills/fe-orchestrator.md#부분-재실행-가이드)를 따릅니다 — 컴포넌트 수정은 `02a`, 훅·스토어 수정은 `02b`만 갱신되고 `03`은 항상 재검증됩니다.

---

## 새 에이전트/스킬 추가 워크플로우

새 FE 에이전트나 공통 스킬을 추가할 때는 항상 **원본 파일**(`agent-docs/agents/`, `agent-docs/skills/`)에만 작업합니다. target repo의 산출물은 sync가 매번 덮어쓰므로 직접 수정하면 안 됩니다.

### 새 에이전트 추가

1. 원본 작성: `agent-docs/templates/agent-template.md`를 `agent-docs/agents/<name>.md`로 복사.
2. frontmatter 채우기 — 3개 필드 모두 필수:
   - `name`: kebab-case, 파일명과 동일하게 (Claude `subagent_type`과 Codex `name` 양쪽에 그대로 매핑됨)
   - `description`: 한 문단. Claude는 자동 dispatch 매칭에, Codex는 `description` TOML 필드로 사용. 트리거 조건을 명확히 적습니다.
   - `model`: Claude 모델 별칭 (`opus`/`sonnet`/`haiku`). Codex는 무시하고 `.codex/config.toml`의 모델 설정을 따릅니다.
3. 본문에는 역할·작업 원칙·입출력 프로토콜을 적되, **삼중 작은따옴표(`'''`)는 사용 금지**입니다. Codex TOML 변환이 multi-line literal string을 쓰기 때문에 본문에 `'''`이 있으면 sync가 거부합니다.
4. 도구별 산출물 확인: sync 실행 후 target repo에서 `.claude/agents/<name>.md`와 `.codex/agents/<name>.toml`이 생성됐는지 확인.

### 새 스킬 추가

1. 원본 작성: `agent-docs/templates/skill-template.md`를 `agent-docs/skills/<name>.md`로 복사.
2. 이름 규칙: 공통 작업은 `skai-` 접두사 (예: `skai-commit`), FE 에이전트 팀 오케스트레이터는 `fe-orchestrator`. 그 외 도메인 스킬은 적절한 접두사로 분류.
3. 본문에 `## Description` 또는 `## 설명` 섹션을 두면 sync가 그 내용을 SKILL.md frontmatter의 `description`으로 자동 추출합니다. (없으면 기본 문구가 들어가지만 매칭 정확도가 떨어집니다.)
4. 도구별 산출물 확인: sync 실행 후 `.claude/skills/<name>/SKILL.md`와 `.agents/skills/<name>/SKILL.md` 두 곳 모두 생성됐는지 확인.
5. 글로벌 설치가 필요한 스킬(예: 새 프로젝트 부트스트랩에 쓰이는 스킬)은 [`scripts/sync-agent-config.sh`](scripts/sync-agent-config.sh)의 `GLOBAL_SKILL_NAMES` 배열에 이름을 추가합니다 — sync 시 `~/.claude/skills/`에도 복사됩니다. 등록 기준은 [글로벌 스킬 등록 정책](#글로벌-스킬-등록-정책-global_skill_names) 참고.

### 검증 순서

1. **원본 레포에서 lint 먼저 실행**: `bash scripts/lint-agent-frontmatter.sh` 로 에이전트/스킬 frontmatter와 본문을 검증한다. 필수 필드 누락, `name`↔파일명 불일치, 허용되지 않은 `model` 값, 본문에 `'''` 포함, `<...>` 자리표시자 잔류 등은 ERROR이며 sync도 함께 거부한다. description 길이(30~500자) 이탈은 WARN. sync 스크립트가 clone 직후 같은 린트를 자동 실행하므로, 결함이 머지되면 어떤 target repo에서도 sync가 중단된다.
2. **원본 변경 후 로컬에서 sync 시뮬레이션**: target repo에서 `pnpm agent:sync` 실행 → 콘솔에서 ✅/✏️/❌ 분류로 의도한 파일만 변경됐는지 확인.
3. **Claude Code 검증**: target repo를 Claude Code로 열어 새 에이전트/스킬이 자동 인식되는지 확인. 에이전트의 경우 `Agent(subagent_type="<name>", ...)` 호출이 동작해야 합니다.
4. **Codex CLI 검증**: 같은 target repo에서 Codex CLI를 실행해 자연어 dispatch("`<name>` 에이전트로 X 실행")가 동작하는지, `/skills`로 스킬 목록에 노출되는지 확인.
5. PR을 올리고, 다른 target repo에서 `pnpm agent:sync`로 다시 가져온 뒤 동일 검증을 반복합니다.

---

## 새 target repo 온보딩

### 빠른 설치 (한 줄 부트스트랩)

target repo 루트에서 아래 한 줄을 실행하면 sync 스크립트를 받아 바로 실행합니다.

```bash
mkdir -p scripts && curl -fsSL https://raw.githubusercontent.com/skaiworldwide/OT_M_FE_AGENTS_CONFIG/main/scripts/sync-agent-config.sh -o scripts/sync-agent-config.sh && chmod +x scripts/sync-agent-config.sh && bash scripts/sync-agent-config.sh
```

처음 한 번만 받아두면 이후엔 그대로 `bash scripts/sync-agent-config.sh`(또는 아래 `pnpm agent:sync`)로 동기화할 수 있습니다. sync 자체가 `scripts/sync-agent-config.sh`를 managed로 갱신하므로 부트스트랩 스크립트는 첫 실행 이후 자동으로 최신 버전이 됩니다.

### package.json에 스크립트 등록 (선택)

```json
{
  "scripts": {
    "agent:sync": "bash scripts/sync-agent-config.sh"
  }
}
```

이후 동기화는 `pnpm agent:sync`로 실행합니다.

---

## 이후 동기화 방법

OT_M_FE_AGENTS_CONFIG에 변경이 생기면 각 target repo에서 아래를 실행합니다.

```bash
pnpm agent:sync
git add -A
git commit -m "chore: sync common agent config"
```

일반 sync는 비파괴적입니다 — managed 파일은 덮어쓰지만 seed 파일과 프로젝트별 커스텀 에이전트·스킬은 보존됩니다.

---

## 강제 재설치 (`--reset` / `--reset-managed-only`)

기존 target repo를 **완전히 깨끗한 상태로 다시 깔아야 할 때**(예: 구버전 경로·이름의 잔재 정리, seed 파일까지 강제 재시드) `--reset`을, **seed와 프로젝트 커스텀은 보존한 채 managed 산출물만 다시 깔고 싶을 때** `--reset-managed-only`를 사용합니다. 둘 다 일반 동기화 흐름과 분리된 일회성 옵션이며, 동시에 지정하면 오류가 납니다.

```bash
bash scripts/sync-agent-config.sh --reset                    # 전체 재시드 (RESET 타이핑)
bash scripts/sync-agent-config.sh --reset-managed-only       # managed만 재설치 (RESET-MANAGED 타이핑)
bash scripts/sync-agent-config.sh --reset --yes              # 자동화/CI에서 프롬프트 생략
bash scripts/sync-agent-config.sh --reset-managed-only --yes # 자동화/CI에서 프롬프트 생략
bash scripts/sync-agent-config.sh --help                     # 옵션 도움말
```

### `--reset` (destructive — seed 포함 전체 재시드)

**지우는 경로:**

| 경로 | 비고 |
| --- | --- |
| `AGENTS.md` / `CLAUDE.md` | seed라 일반 sync에서 보존되지만 reset 시엔 템플릿으로 재시드 — 프로젝트별로 채운 내용은 사라집니다 |
| `.gitignore` | seed 재시드. 프로젝트별 ignore 패턴이 있다면 사전 백업 |
| `.codex/config.toml` | seed 재시드 |
| `.claude/settings.json` | managed |
| `agent-docs/` | 디렉토리 통째 |
| `.claude/agents/` · `.claude/skills/` | 디렉토리 통째 — 사용자가 추가한 커스텀 에이전트·스킬도 함께 삭제 |
| `.codex/agents/` · `.agents/skills/` | 디렉토리 통째 |

**건드리지 않는 것:** `scripts/sync-agent-config.sh` 자체, `.claude/`·`.codex/`·`.agents/` 디렉토리 본체(위에 나열되지 않은 하위 항목, 예: `.claude/commands/`·`.claude/output-styles/` 등), 소스 코드, 그 외 모든 프로젝트 파일.

### `--reset-managed-only` (managed 산출물만 재설치)

`--reset`은 seed까지 날려서 프로젝트별로 채워둔 AGENTS.md/CLAUDE.md 내용을 잃습니다. 그게 부담스러울 때 — 예를 들어 managed 규칙·에이전트·스킬만 강제로 깨끗하게 재설치하고 싶을 때 — 이 옵션을 사용합니다. **upstream 원본에 존재하는 이름의 managed 산출물만 골라서 삭제**하므로 같은 디렉토리에 있는 프로젝트 커스텀 파일은 살아남습니다.

**지우는 경로 (upstream 기반으로 동적 결정):**

| 경로 | 비고 |
| --- | --- |
| `agent-docs/rules/` | managed 디렉토리 통째 |
| `agent-docs/guides/` | managed 디렉토리 통째 |
| `agent-docs/harness-changelog.md` | managed 파일 |
| `.claude/settings.json` | managed 파일 |
| `.claude/agents/<name>.md` | upstream `agent-docs/agents/<name>.md`에 대응하는 파일만 (예: `fe-analyst.md`·`fe-builder.md` 등). 같은 디렉토리의 프로젝트 커스텀 에이전트는 보존 |
| `.codex/agents/<name>.toml` | 위와 동일 매칭 규칙. 프로젝트 커스텀 TOML은 보존 |
| `.claude/skills/<name>/` · `.agents/skills/<name>/` | upstream `agent-docs/skills/<name>.md`에 대응하는 스킬 디렉토리만. 다른 이름의 프로젝트 커스텀 스킬은 보존 |

**건드리지 않는 것:**

- **Seed 파일**: `AGENTS.md`(본체), `CLAUDE.md`, `.gitignore`, `.codex/config.toml` — 프로젝트별로 채워둔 내용 그대로 유지
- **프로젝트 커스텀 에이전트·스킬**: 이름이 upstream과 다르면 보존 (예: 프로젝트가 추가한 `my-team-helper.md` 또는 `proj-utils/SKILL.md`)
- `agent-docs/` 안에 프로젝트가 추가한 파일 (rules/, guides/, harness-changelog.md 바깥)
- `scripts/sync-agent-config.sh` 자체, 그 외 모든 프로젝트 파일

> **언제 어느 쪽을 쓰나:**
> - **`--reset`**: target repo를 초기 시드 상태로 완전히 되돌리고 싶을 때 (드물게 사용)
> - **`--reset-managed-only`**: managed 정의가 꼬여서 깨끗하게 재설치하고 싶지만 프로젝트별 AGENTS.md·커스텀 에이전트는 잃고 싶지 않을 때 (대부분의 reset 시나리오는 이쪽이 더 안전)

> **권장 사용 흐름:** reset 직전에 `git status`로 작업 중 변경이 없는지 확인하고, reset 후엔 `git diff`로 변경 폭을 확인합니다. **이후의 정상 sync는 비파괴적이므로 프로젝트별 커스텀이 사라지지 않습니다** — reset은 일회성 정리 용도입니다.

---

## sync 결과 예시

빈 git 디렉토리에서 처음 `pnpm agent:sync`를 실행했을 때의 콘솔 출력과 생성되는 파일 구조 예시입니다. 두 번째 실행부터는 변경된 파일만 `✏️ Modified`로 나타나고, 나머지는 `💤 Unchanged`로 분류되어 멱등하게 동작합니다.

### 첫 실행 (빈 target repo)

```text
$ pnpm agent:sync
Cloning OT_M_FE_AGENTS_CONFIG (--depth 1)...
Linting upstream agent/skill sources...
=== Linting agent and skill frontmatter ===
  files checked: 11
  errors:        0
  warnings:      0
Lint passed.

=== Sync Complete ===

✅  Added
    - AGENTS.md
    - CLAUDE.md
    - .gitignore
    - .codex/config.toml
    - agent-docs/rules/{api,frontend-common,git-keyword,state-management,styling,typescript,workflow}-rules.md
    - agent-docs/guides/agents-md-writing.md
    - agent-docs/harness-changelog.md
    - .claude/agents/fe-{analyst,builder,integration,qa}.md
    - .codex/agents/fe-{analyst,builder,integration,qa}.toml
    - .claude/settings.json
    - scripts/sync-agent-config.sh
    - .claude/skills/{fe-orchestrator,skai-commit,skai-convention-review,skai-fe-init,skai-pr}/SKILL.md
    - .agents/skills/{fe-orchestrator,skai-commit,skai-convention-review,skai-fe-init,skai-pr}/SKILL.md

🌐  Global skills installed
    - skai-fe-init → ~/.claude/skills/skai-fe-init

Review changes with 'git diff', then commit and open a PR manually.
```

### 결과 파일 트리

```text
target-repo/
├── AGENTS.md                                # seed (덮어쓰지 않음)
├── CLAUDE.md                                # seed
├── .gitignore                               # seed + _workspace/ backfill
├── agent-docs/
│   ├── guides/agents-md-writing.md          # managed
│   ├── harness-changelog.md                 # managed (변경 이력 표 단일 원본)
│   └── rules/                               # managed (7개 규칙 문서)
│       ├── api-rules.md
│       ├── frontend-common-rules.md
│       ├── git-keyword-rules.md
│       ├── state-management-rules.md
│       ├── styling-rules.md
│       ├── typescript-rules.md
│       └── workflow-rules.md
├── .claude/
│   ├── settings.json                        # managed
│   ├── agents/                              # managed (Claude 네이티브 dispatch)
│   │   ├── fe-analyst.md
│   │   ├── fe-builder.md
│   │   ├── fe-integration.md
│   │   └── fe-qa.md
│   └── skills/                              # managed/generated
│       ├── fe-orchestrator/SKILL.md
│       ├── skai-commit/SKILL.md
│       ├── skai-convention-review/SKILL.md
│       ├── skai-fe-init/SKILL.md
│       └── skai-pr/SKILL.md
├── .codex/
│   ├── config.toml                          # seed (비어있는 override 템플릿)
│   └── agents/                              # managed/generated (TOML, Codex 자연어 dispatch)
│       ├── fe-analyst.toml
│       ├── fe-builder.toml
│       ├── fe-integration.toml
│       └── fe-qa.toml
├── .agents/
│   └── skills/                              # managed/generated (Codex 표준 스캔 경로)
│       ├── fe-orchestrator/SKILL.md
│       ├── skai-commit/SKILL.md
│       ├── skai-convention-review/SKILL.md
│       ├── skai-fe-init/SKILL.md
│       └── skai-pr/SKILL.md
└── scripts/
    └── sync-agent-config.sh                 # managed (자기 자신을 갱신)
```

### 두 번째 실행 (멱등)

원본이 변경되지 않았다면 모든 managed 파일이 `💤 Unchanged`로 분류되고, seed 파일은 그대로 `⏭️ Seed skipped`로 표시됩니다. 원본에 변경이 생긴 항목만 `✏️ Modified`(내용 차이) 또는 `❌ Deleted`(원본 삭제로 인한 정리)로 보입니다.

```text
$ pnpm agent:sync
...
💤  Unchanged
    - agent-docs/rules/...
    - .claude/agents/fe-{analyst,builder,integration,qa}.md
    - .codex/agents/fe-{analyst,builder,integration,qa}.toml
    - .claude/skills/.../SKILL.md
    - .agents/skills/.../SKILL.md
    ...

🌐  Global skills installed
    - skai-fe-init → ~/.claude/skills/skai-fe-init
```

`🌐 Global skills installed`은 변경 유무와 관계없이 매번 표시됩니다 — sync 스크립트가 항상 `~/.claude/skills/skai-fe-init`을 최신본으로 덮어쓰기 때문입니다([글로벌 스킬 등록 정책](#글로벌-스킬-등록-정책-global_skill_names) 참고).
