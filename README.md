# OT_M_FE_AGENTS_CONFIG

공통 AI 에이전트 설정 및 규칙 문서 원본 레포입니다.

## 현재 레포 구조

```
OT_M_FE_AGENTS_CONFIG/
├── agent-docs/
│   ├── rules/          # 공통 개발 규칙 문서 원본
│   ├── agents/         # 공통 FE 에이전트 정의 원본 (sync 시 도구별 포맷으로 분기)
│   ├── skills/         # 공통 스킬 원본 (skai-* + skai-orchestrator)
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
│   │   └── skai-*.md         ← agent-docs/agents/skai-*.md (managed)
│   └── skills/
│       └── <skill>/SKILL.md ← agent-docs/skills/*.md에서 생성 (managed)
├── .codex/
│   ├── config.toml         ← templates/codex-config.toml (seed)
│   └── agents/
│       └── skai-*.toml       ← agent-docs/agents/skai-*.md에서 TOML로 변환 (managed)
├── .agents/
│   └── skills/
│       └── <skill>/SKILL.md ← agent-docs/skills/*.md에서 생성 (managed)
└── scripts/
    └── sync-agent-config.sh ← scripts/sync-agent-config.sh (managed)
```

### Target repo 구성 요소 의미

| 경로                              | 관리 방식                   | 의미                                                                                                                                                                                                                                                                                                                                                                                                        |
| --------------------------------- | --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AGENTS.md`                       | seed + 변경 이력 표 managed | Codex와 Claude가 공통으로 따라야 하는 프로젝트 작업 원칙입니다. 프로젝트별 도메인 지식(용어·API 패턴·페이지 구조)과 하네스 트리거 규칙도 여기에 둡니다. 본체는 이미 있으면 덮어쓰지 않지만, "## 하네스: FE-COMMON" 안의 **변경 이력 표는 `<!-- harness-changelog:upstream:* -->` 마커 안쪽에 한해 sync 시 자동 갱신**됩니다. ([agent-docs/harness-changelog.md](agent-docs/harness-changelog.md) 단일 원본) |
| `CLAUDE.md`                       | seed                        | Claude Code 진입점입니다. `@AGENTS.md` import로 공용 규칙을 가져오고, Claude 네이티브 서브에이전트 dispatch(`Agent(subagent_type=...)`) 디테일만 추가로 안내합니다. 이미 있으면 덮어쓰지 않습니다.                                                                                                                                                                                                          |
| `.gitignore`                      | seed + backfill             | `skai-orchestrator`가 매 실행마다 생성하는 `_workspace/`·`_workspace_prev/`를 자동으로 ignore 처리합니다. 파일이 없으면 `templates/gitignore`를 시드로 복사하고, 이미 있으면 두 엔트리가 누락된 경우에만 파일 끝에 한 번 추가합니다.                                                                                                                                                                        |
| `agent-docs/rules/`               | managed                     | TypeScript, 스타일링, 상태 관리, 워크플로우 같은 공통 개발 규칙 문서입니다. Claude·Codex 양쪽이 동일하게 참조합니다.                                                                                                                                                                                                                                                                                        |
| `agent-docs/guides/`              | managed                     | 프로젝트별 문서를 채울 때 참고하는 가이드 모음입니다. 현재는 `AGENTS.md` 빈 섹션을 채우기 위한 두 도메인(채팅 플랫폼·분석 대시보드) 익명화 예시(`agents-md-writing.md`)가 있습니다.                                                                                                                                                                                                                         |
| `agent-docs/harness-changelog.md` | managed                     | AGENTS.md "변경 이력" 표의 단일 원본입니다. 마커(`<!-- harness-changelog:upstream:start -->` / `:end -->`) 안쪽 표가 sync 시 target의 AGENTS.md 마커 블록으로 복제됩니다. 변경 이력 행 추가는 이 파일에서만 합니다.                                                                                                                                                                                         |
| `.claude/settings.json`           | managed                     | Claude Code에서 사용할 공통 설정입니다.                                                                                                                                                                                                                                                                                                                                                                     |
| `.claude/agents/skai-*.md`        | managed                     | Claude Code가 읽는 프론트엔드 에이전트 팀(skai-analyst·skai-builder·skai-integration·skai-qa) 정의입니다. Claude Code는 frontmatter를 스캔해 `subagent_type="skai-analyst"` 같은 네이티브 dispatch로 자동 등록합니다. 도메인 중립이며 프로젝트별 지식은 `AGENTS.md`로 분리합니다.                                                                                                                           |
| `.claude/skills/<skill>/SKILL.md` | managed/generated           | Claude Code가 인식하는 repo-local 스킬 패키지입니다. `agent-docs/skills/*.md` 원본에 frontmatter를 붙여 생성합니다. (`skai-*` 공통 작업 + `skai-orchestrator`)                                                                                                                                                                                                                                              |
| `.codex/config.toml`              | seed                        | Codex CLI 프로젝트 설정입니다. 비워두면 사용자 `~/.codex/config.toml`이 그대로 적용되며, 프로젝트 단위로 model·sandbox_mode·MCP 서버 등을 override할 때 사용합니다. 이미 있으면 덮어쓰지 않습니다.                                                                                                                                                                                                          |
| `.codex/agents/skai-*.toml`       | managed/generated           | Codex CLI가 읽는 프론트엔드 서브에이전트 정의입니다. `agent-docs/agents/skai-*.md`의 frontmatter `name`/`description`과 본문을 TOML `name`/`description`/`developer_instructions`로 변환해 생성합니다. Codex는 자동 인식하며 자연어 dispatch("skai-analyst 서브에이전트로 X 실행하라")로 호출합니다.                                                                                                        |
| `.agents/skills/<skill>/SKILL.md` | managed/generated           | Codex가 인식하는 repo-local 스킬 패키지입니다. Claude용 스킬과 같은 원본에서 생성하되 Codex가 읽는 위치(`.agents/skills`)에 둡니다.                                                                                                                                                                                                                                                                         |
| `scripts/sync-agent-config.sh`    | managed                     | target repo에서 OT_M_FE_AGENTS_CONFIG를 다시 가져와 공통 규칙 문서, 설정, 에이전트, 스킬을 최신 상태로 맞추는 동기화 스크립트입니다.                                                                                                                                                                                                                                                                        |

## 동기화 정책

### Seed files

없을 때만 복사합니다. 이미 있으면 덮어쓰지 않습니다.

- `templates/AGENTS.md` → `AGENTS.md`
- `templates/CLAUDE.md` → `CLAUDE.md`
- `templates/gitignore` → `.gitignore`
- `templates/codex-config.toml` → `.codex/config.toml`

> **기존 target repo 업그레이드 (AGENTS.md 하네스 섹션):** seed라 덮어쓰지는 않지만, 기존 `AGENTS.md`에 `## 하네스` 섹션이 없으면 sync 시 템플릿의 하네스 섹션을 파일 끝에 자동으로 한 번 append 합니다. 그래야 하네스 도입 이전에 생성된 target repo도 `skai-orchestrator` 트리거 규칙을 받을 수 있습니다. 이미 `## 하네스` 섹션이 있으면 건드리지 않으므로, 프로젝트별로 수정한 내용은 그대로 보존됩니다. CLAUDE.md는 `@AGENTS.md` import로 그 본문을 가져오므로 별도 backfill 대상이 아닙니다.
>
> **`.gitignore` 워크스페이스 backfill:** 기존 `.gitignore`가 있으면 시드를 덮어쓰지 않는 대신, `_workspace/`·`_workspace_prev/` 두 엔트리가 누락된 경우에만 파일 끝에 한 번 추가합니다. `skai-orchestrator`가 매 실행마다 생성하는 런타임 산출물이 target repo에 그대로 커밋되지 않도록 보장하기 위한 정책입니다. 이미 두 엔트리가 (`foo`, `foo/`, `/foo` 등 일반 형태로) 등록돼 있으면 건드리지 않습니다.

### Managed files

항상 최신으로 덮어씁니다.

- `agent-docs/rules/*` → `agent-docs/rules/*`
- `agent-docs/guides/*` → `agent-docs/guides/*`
- `agent-docs/agents/skai-*.md` → `.claude/agents/skai-*.md` (Claude Code용, .md 그대로)
- `agent-docs/agents/skai-*.md` → `.codex/agents/skai-*.toml` (Codex CLI용, TOML로 변환)
- `.claude/settings.json` → `.claude/settings.json`
- `agent-docs/skills/*.md` → `.claude/skills/<skill>/SKILL.md`
- `agent-docs/skills/*.md` → `.agents/skills/<skill>/SKILL.md`
- `scripts/sync-agent-config.sh` → `scripts/sync-agent-config.sh`
- `agent-docs/harness-changelog.md`(마커 사이 표) → `AGENTS.md` "변경 이력" 표(마커 사이)

> **AGENTS.md "변경 이력" 표 자동 동기화:** AGENTS.md 본체는 seed라 덮어쓰지 않지만, 그 안의 "변경 이력" 표는 `<!-- harness-changelog:upstream:start -->`/`<!-- harness-changelog:upstream:end -->` 마커로 감싸져 있고, 마커 _안쪽 내용만_ sync 시 [`agent-docs/harness-changelog.md`](agent-docs/harness-changelog.md)의 표로 교체됩니다. 프로젝트별 변경 이력이 필요하면 마커 바깥에 별도 표를 두세요. 마커가 없는 구버전 AGENTS.md는 sync가 한 번에 한해 backfill하며(기존 표를 마커 블록으로 치환), 이때 사용자가 손으로 추가한 행이 있었다면 `⚠️  변경 이력 표 backfill 경고`가 콘솔에 떠 `git diff`로 확인하라고 안내합니다.

## 스킬 관리 원칙

| 항목           | 원칙                                                                                                            |
| -------------- | --------------------------------------------------------------------------------------------------------------- |
| 원본 위치      | 스킬 원본은 `agent-docs/skills/*.md`만 수정합니다. (`skai-*` 공통 작업 스킬 + `skai-orchestrator`)              |
| 이름 규칙      | SKAI 공통 작업 스킬은 `skai-` 접두사, FE 에이전트 팀 오케스트레이터는 `skai-orchestrator`를 사용합니다.         |
| 새 스킬 작성   | `agent-docs/templates/skill-template.md`를 복사해서 시작합니다. 이 템플릿은 target repo로 동기화하지 않습니다.  |
| 생성 위치      | sync 시 `.claude/skills/<skill>/SKILL.md`와 `.agents/skills/<skill>/SKILL.md`를 생성합니다.                     |
| 수정 금지 위치 | `.claude/skills`와 `.agents/skills` 아래 generated `SKILL.md`는 직접 수정하지 않습니다.                         |
| Codex 위치     | Codex repo-local skills는 `.agents/skills`를 사용합니다. `.codex`는 필요할 때 `config.toml` 같은 설정만 둡니다. |

### `skai-commit` 커밋 흐름

`skai-commit`은 커밋 요청이 들어오면 staged 변경만 보는 대신 워크트리 전체(staged, unstaged, untracked)를 확인하고, 변경 의도별로 파일 단위 커밋 그룹을 제안합니다. 그룹핑과 메시지는 사용자 승인을 받은 뒤에만 `git add`와 `git commit`을 실행합니다.

| 항목        | 동작                                                                                             |
| ----------- | ------------------------------------------------------------------------------------------------ |
| 변경 분석   | `git status --short`, `git diff`, `git diff --stat`, untracked 파일 내용을 기준으로 의도를 파악 |
| 그룹핑 단위 | hunk가 아니라 파일 단위로만 분리. 한 파일은 한 그룹에만 포함                                    |
| 승인 흐름   | 그룹별 대상 파일과 메시지 후보를 먼저 제안하고, 승인된 그룹만 순서대로 커밋                    |
| 예외 처리   | `.env*`, `*.key`, `credentials.*`, `*.pem` 등 비밀·환경 파일은 커밋 그룹에서 제외하고 먼저 확인 |
| Jira 표기   | 사용자 입력에 티켓 번호가 있으면 `{키워드}(Jira-1234): ...` 또는 `{키워드}(PROJ-1234): ...` 형식 사용 |

단일 작업이면 기존처럼 하나의 커밋 메시지만 제안하고, 서로 다른 의도가 섞여 있으면 여러 커밋으로 나눕니다. 한 파일 안에 여러 의도가 섞인 것으로 보이면 임의로 분리하지 않고 사용자에게 처리 방식을 확인합니다.

### 글로벌 스킬 등록 정책 (`GLOBAL_SKILL_NAMES`)

[`scripts/sync-agent-config.sh`](scripts/sync-agent-config.sh)의 `GLOBAL_SKILL_NAMES` 배열에 추가된 스킬은 sync 시 target repo의 `.claude/skills/<name>/`을 그대로 `~/.claude/skills/<name>/`에도 복사합니다. 즉, **해당 사용자의 모든 프로젝트(아직 sync를 돌리지 않은 빈 디렉토리 포함)에서 즉시 호출 가능**해집니다.

**등록 기준은 "프로젝트가 sync를 돌리기 _전에_ 동작해야 하는 스킬"인지로 판단합니다.** 그 외 스킬은 글로벌에 올리지 않고 repo-local(`.claude/skills/`·`.agents/skills/`)로만 두면 충분합니다.

| 분류                                           | 글로벌 등록                 | 예                                                                                                        |
| ---------------------------------------------- | --------------------------- | --------------------------------------------------------------------------------------------------------- |
| 빈 디렉토리에서 프로젝트를 부트스트랩하는 스킬 | ⭕️ 필요                     | `skai-fe-init` — 신규 React/TS 프로젝트 세팅. 아직 `agent:sync`를 돌릴 환경 자체가 없을 때 호출됨         |
| 이미 부트스트랩된 프로젝트의 작업 흐름 스킬    | ❌ 불필요                   | `skai-commit`, `skai-pr`, `skai-convention-review`, `skai-orchestrator` — sync 이후 repo-local만으로 동작 |
| 사용자 개인 워크플로우용 스킬                  | ❌ (이 레포 관리 대상 아님) | 개인 단축어·매크로는 사용자가 직접 `~/.claude/skills/`에 둡니다                                           |

**현재 등록 항목:** `skai-fe-init` 1개.

추가하려면 위 기준을 충족하는 스킬을 `agent-docs/skills/<name>.md`에 먼저 작성한 뒤, sync 스크립트의 `GLOBAL_SKILL_NAMES=("skai-fe-init")` 줄에 이름을 더합니다. 글로벌 복사는 항상 `target-repo/.claude/skills/<name>/`을 원본으로 사용하므로, 해당 디렉토리가 생성되지 않는 스킬(예: 원본 파일이 없는 이름)은 조용히 스킵됩니다.

## 에이전트 관리 원칙

| 항목                 | 원칙                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 원본 위치            | FE 에이전트 정의는 `agent-docs/agents/skai-*.md`만 수정합니다. Claude·Codex 모두 이 단일 원본에서 sync 시 분기 생성됩니다.                                                                                                                                                                                                                                                                                                                                               |
| Frontmatter          | 모든 에이전트 파일은 `name`, `description`, `model` frontmatter를 포함합니다. Claude Code는 이 메타데이터로 `subagent_type="<name>"` 자동 등록을, Codex sync는 같은 `name`·`description`을 TOML 필드로 추출합니다. (`model` 값은 Claude 전용이며 Codex TOML로 옮기지 않습니다 — Codex는 `.codex/config.toml`에서 모델을 설정합니다.)                                                                                                                                     |
| 도메인 중립          | 에이전트 정의는 프로젝트 도메인에 비의존적으로 작성합니다. 프로젝트별 도메인 지식(용어·API shape·페이지 구조)은 target repo의 `AGENTS.md`에 두고 참조만 합니다.                                                                                                                                                                                                                                                                                                          |
| 새 에이전트 작성     | `agent-docs/templates/agent-template.md`를 복사해서 시작합니다. 이 템플릿은 target repo로 동기화하지 않습니다. 본문에 `'''` 삼중 작은따옴표는 사용하지 않습니다 (Codex TOML 변환이 multi-line literal string을 사용하므로).                                                                                                                                                                                                                                              |
| 생성 위치            | sync 시 `.claude/agents/<name>.md`(원본 그대로)와 `.codex/agents/<name>.toml`(TOML 변환) 두 곳에 매번 덮어쓰기로 배포됩니다.                                                                                                                                                                                                                                                                                                                                             |
| 수정 금지 위치       | target repo의 `.claude/agents/`와 `.codex/agents/`에 있는 **upstream에서 sync된 산출물(`skai-*` 등)**은 직접 수정하지 않습니다. 프로젝트별 차이가 필요하면 `AGENTS.md`에 반영합니다.                                                                                                                                                                                                                                                                                     |
| 커스텀 에이전트 공존 | 프로젝트 고유 에이전트가 필요하면 `.claude/agents/`와 `.codex/agents/`에 직접 `<name>.md`/`<name>.toml`을 추가할 수 있습니다. sync는 **upstream 원본 마커가 박힌 파일만 cleanup 대상**으로 봅니다 (`.claude/agents`는 frontmatter 뒤 `<!-- Generated from agent-docs/agents/... -->` HTML 주석, `.codex/agents`는 TOML 상단 `# Generated from agent-docs/agents/...` 헤더). 마커가 없는 프로젝트 커스텀 파일은 정상 sync에서도, `--reset-managed-only`에서도 보존됩니다. |
| 환경 범위            | 하네스는 **Claude Code와 Codex CLI 두 환경**에서 동작합니다. Phase 흐름과 파일 핸드오프는 동일하고 dispatch만 다릅니다 — Claude는 `Agent(subagent_type="skai-analyst", ...)` 네이티브 도구, Codex는 자연어 지시("skai-analyst 서브에이전트로 X 실행하라"). Codex의 자연어 dispatch는 conversational이라 Phase 2 skai-builder ↔ skai-integration 병렬화는 더 제한적입니다 — 현재는 양 환경 모두 순차 실행을 표준으로 합니다.                                              |
| 트리거               | target repo의 `AGENTS.md` "하네스: FE-COMMON" 섹션이 `skai-orchestrator` 스킬을 트리거합니다. (Claude Code는 `@AGENTS.md` import로, Codex CLI는 `AGENTS.md` 자동 로딩으로 같은 본문을 읽습니다.)                                                                                                                                                                                                                                                                         |
| 호출 방식            | Claude: `Agent(subagent_type="skai-analyst", ...)` 네이티브 dispatch. Codex: 자연어 지시. `general-purpose`로 띄운 뒤 본문을 읽게 시키는 우회 패턴은 양쪽 모두 사용하지 않습니다.                                                                                                                                                                                                                                                                                        |

### Codex CLI PoC 검증 결과 (2026-05-13)

신규 target repo(빈 git 디렉토리)에 sync를 실행해 `.codex/agents/skai-{analyst,builder,integration,qa}.toml`을 생성한 뒤 Codex CLI에서 직접 확인한 결과:

- **자동 인식**: Codex CLI 0.130.0이 별도 등록 없이 4개 서브에이전트(`skai-analyst`·`skai-builder`·`skai-integration`·`skai-qa`)를 모두 인식. "사용 가능한 서브에이전트로 등록되어 있는가?" 질문에 **YES**.
- **자연어 dispatch**: "skai-analyst 서브에이전트에 X 작업을 위임하라" 발화로 Codex의 `collab: SpawnAgent` 런타임 도구가 트리거되고, 해당 서브에이전트가 TOML `developer_instructions`(에이전트 본문)를 시스템 프롬프트로 받아 `_workspace/01_analyst_plan.md`를 직접 작성했다. 즉, 상위 에이전트가 본문을 읽어 흉내내는 게 아니라 실제 sub-agent 컨텍스트가 분리 실행됨을 확인.
- **모델 호환성 제약**: Codex CLI 0.122.0의 기본 모델 `gpt-5.5`는 서버에서 "CLI 업그레이드 필요"로 거부됐고, `gpt-5`/`gpt-5.1`/`gpt-5-codex`/`o4-mini`는 ChatGPT 계정에서 미지원. **0.130.0 이상**에서만 PoC가 통과한다. 글로벌 README/온보딩에서 Codex CLI 0.130 이상을 권장 버전으로 명시한다.
- **관찰된 경고(비차단)**: 첫 SpawnAgent 호출에서 `Full-history forked agents inherit the parent agent type, model, and reasoning effort; omit agent_type, model, and reasoning_effort` 런타임 경고가 한 번 발생했으나 Codex가 자동으로 인자를 줄여 재호출해 성공. TOML 측에서 `model`/`reasoning_effort`를 비워둔 현재 정책이 올바름을 시사한다.

---

## 하네스 산출물(`_workspace/`) 구조

`skai-orchestrator`는 매 실행마다 target repo 루트의 `_workspace/`에 Phase별 산출물을 남기고, 다음 실행이 시작될 때 직전 산출물을 `_workspace_prev/`로 회전합니다. 디버깅·부분 재실행·실패 지점 파악 시 어디까지 진행됐는지 추적하는 1차 출처입니다. (두 디렉토리 모두 `.gitignore`에 자동 등록되어 커밋되지 않습니다 — [동기화 정책 > `.gitignore` 워크스페이스 backfill](#managed-files) 참고.)

| 파일                                   | 작성 주체          | 내용                                                                                                                           |
| -------------------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| `_workspace/01_analyst_plan.md`        | `skai-analyst`     | 사용자 요청 분석, 인터페이스 정의, 페이지·컴포넌트·훅 단위 계획                                                                |
| `_workspace/02a_builder_status.md`     | `skai-builder`     | 생성·수정한 컴포넌트 파일 경로, props 타입 정의 위치, 필요한 훅·스토어 명세, 재사용 vs 신규 결정, 미해결 TODO                  |
| `_workspace/02b_integration_status.md` | `skai-integration` | 생성·수정한 훅·스토어·API 함수 경로, 쿼리 키·캐시 전략, builder 컴포넌트 props와의 매칭 결과, 인터페이스 불일치 시 임시 해결책 |
| `_workspace/03_qa_report.md`           | `skai-qa`          | PASS/FAIL과 항목별 검증 결과. FAIL이면 오케스트레이터가 해당 에이전트(`skai-builder` 또는 `skai-integration`)를 재호출         |
| `_workspace_prev/`                     | 오케스트레이터     | 직전 1회분 스냅샷. 새 실행 진입 시 이전 `_workspace_prev/`는 삭제되고 현재 `_workspace/`가 이 위치로 이동 (직전 1회만 보관)    |

**디버깅 시 어디부터 보나:** 파일 번호(`01` → `02a`/`02b` → `03`)가 곧 Phase 진행도입니다. 마지막으로 존재하는 파일까지가 완료된 단계이고, 그 다음 단계에서 멈췄거나 실패했다는 뜻입니다. `_workspace_prev/`와 현재 `_workspace/`를 비교하면 이번 실행에서 무엇이 바뀌었는지 보입니다.

**부분 재실행과의 매핑:** 사용자가 "이 부분만 수정", "다시", "보완" 등을 요청할 때 어느 파일이 갱신되는지는 [skai-orchestrator의 부분 재실행 가이드](agent-docs/skills/skai-orchestrator.md#부분-재실행-가이드)를 따릅니다 — 컴포넌트 수정은 `02a`, 훅·스토어 수정은 `02b`만 갱신되고 `03`은 항상 재검증됩니다.

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
2. 이름 규칙: 공통 작업은 `skai-` 접두사 (예: `skai-commit`), FE 에이전트 팀 오케스트레이터는 `skai-orchestrator`. 그 외 도메인 스킬은 적절한 접두사로 분류.
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

## 적용 방법

target repo에 적용하는 절차는 **신규/기존 무관 동일**합니다. sync 스크립트가 내부적으로 자동 분기하므로 사용자가 의식할 필요가 없습니다.

### Step 1. 처음 적용 (부트스트랩)

target repo 루트에서 한 줄:

```bash
git clone --depth 1 --branch main https://github.com/skaiworldwide/OT_M_FE_AGENTS_CONFIG.git /tmp/ot-m-fe-agents-config && mkdir -p scripts && cp /tmp/ot-m-fe-agents-config/scripts/sync-agent-config.sh scripts/sync-agent-config.sh && chmod +x scripts/sync-agent-config.sh && rm -rf /tmp/ot-m-fe-agents-config && bash scripts/sync-agent-config.sh
```

이 명령은 sync 스크립트를 `scripts/sync-agent-config.sh`로 다운로드하고 한 번 실행합니다. **빈 repo든 코드가 있는 repo든 그대로 사용**합니다.

자동 분기 동작:

| 파일                                                                                                         | 빈 repo (신규) | 이미 코드 있는 repo (기존)                                              |
| ------------------------------------------------------------------------------------------------------------ | -------------- | ----------------------------------------------------------------------- |
| `AGENTS.md`                                                                                                  | 템플릿 생성    | 본체 보존 + `## 하네스` 섹션이 없으면 끝에 append + 변경 이력 표 동기화 |
| `CLAUDE.md`                                                                                                  | 생성           | 있으면 보존, 없으면 생성                                                |
| `.gitignore`                                                                                                 | 시드 생성      | 기존 유지 + `_workspace/`·`_workspace_prev/` 두 엔트리만 backfill       |
| `.codex/config.toml`                                                                                         | 시드 생성      | 보존                                                                    |
| `agent-docs/*`, `.claude/{agents,skills}`, `.codex/agents`, `.agents/skills`, `scripts/sync-agent-config.sh` | 모두 생성      | **항상 최신으로 덮어쓰기** (managed)                                    |

자세한 정책은 [동기화 정책](#동기화-정책) 참고.

### Step 2. 이후 반복 sync

부트스트랩 이후엔 로컬 스크립트만 다시 실행하면 됩니다:

```bash
bash scripts/sync-agent-config.sh
```

`package.json`에 alias를 등록하면 더 짧게 호출 가능 (선택):

```json
{
  "scripts": {
    "agent:sync": "bash scripts/sync-agent-config.sh"
  }
}
```

```bash
pnpm agent:sync
```

> **curl 한 줄 vs `pnpm agent:sync` 차이:** curl 한 줄은 스크립트를 _가져오면서_ 실행하므로 빈 repo에서도 동작합니다. `pnpm agent:sync`(= `bash scripts/sync-agent-config.sh`)는 _로컬에 이미 있는_ 스크립트를 실행하므로 부트스트랩 이후에만 동작합니다. 결과는 동일합니다.

일반 sync는 비파괴적입니다 — managed 파일은 덮어쓰지만 seed 파일과 프로젝트별 커스텀 에이전트·스킬은 보존됩니다.

### Step 3. 검증

#### 3-1. 정적 검증 (파일 존재)

target repo 루트에서:

```bash
ls .claude/agents/skai-{analyst,builder,integration,qa}.md
ls .claude/skills/{skai-orchestrator,skai-commit,skai-convention-review,skai-fe-init,skai-pr}/SKILL.md
ls .codex/agents/skai-*.toml
ls .agents/skills/*/SKILL.md
grep -nE "^## 하네스|harness-changelog:upstream:" AGENTS.md
grep -E "^/?_workspace/?" .gitignore
```

모든 줄이 출력을 가져야 통과합니다. 비는 줄이 있으면 그 단계가 막힌 신호입니다.

#### 3-2. 멱등성 검증

```bash
pnpm agent:sync 2>&1 | grep -E "Added|Modified|Deleted"
```

두 번째 sync에서 거의 비어 있어야 정상입니다. `Modified`가 또 잡히면 [self-replace 함정](#self-replace-함정) — 한 번 더 돌리면 회복됩니다.

#### 3-3. 연결 테스트 (가장 빠른 자가진단)

Claude Code에서 target repo를 열고 입력합니다:

> "사용자 프로필 카드 컴포넌트 만들어줘"

`_workspace/01_analyst_plan.md`가 자동 생성되면 **dispatch + skill trigger + 에이전트 정의 + AGENTS.md 하네스 섹션이 모두 정상**입니다.

생성되지 않으면 진단 순서:

1. `/agents` 자동완성에 `skai-analyst`·`skai-builder`·`skai-integration`·`skai-qa` 노출 → 안 보이면 `.claude/agents/` 누락
2. `/skills`에 `skai-orchestrator` 노출 → 안 보이면 `.claude/skills/skai-orchestrator/SKILL.md` 누락
3. `AGENTS.md`에 `## 하네스: FE-COMMON` 섹션 존재 → 없으면 sync 한 번 더 (backfill)
4. `CLAUDE.md`에 `@AGENTS.md` import 라인 존재

Codex CLI(0.130+)라면 동일 입력 + `/skills`에서 5개 노출 확인.

---

## 고급 옵션

운영 도입·예외 상황에서만 사용하는 옵션입니다. 일반 적용에는 위 [적용 방법](#적용-방법) 한 흐름이면 충분합니다.

### 태그 pin (운영 도입 시 권장)

`main` 대신 릴리스 태그(또는 커밋 SHA)로 고정하면 원본이 사후에 바뀌어도 부트스트랩 결과가 변하지 않습니다.

```bash
REF=v0.1.0 \
  && mkdir -p scripts \
  && curl -fsSL "https://raw.githubusercontent.com/skaiworldwide/OT_M_FE_AGENTS_CONFIG/${REF}/scripts/sync-agent-config.sh" -o scripts/sync-agent-config.sh \
  && chmod +x scripts/sync-agent-config.sh \
  && bash scripts/sync-agent-config.sh
```

`main`은 하네스/개발 단계에서만 사용하고, 신규 target repo 온보딩 시점에는 그 시점의 최신 태그로 pin하는 것을 기본으로 하세요. 첫 sync 이후 target repo의 `scripts/sync-agent-config.sh`가 managed로 갱신되므로, 이후 버전 업은 원본 레포에서 새 태그를 끊은 뒤 target에서 일반 sync(`pnpm agent:sync`)를 돌리면 됩니다.

### 사내 미러 (네트워크 제약 환경)

GitHub raw에 직접 닿을 수 없는 환경에서는 `BASE_URL`만 사내 미러로 치환합니다.

```bash
BASE_URL="https://git.internal.example.com/skaiworldwide/OT_M_FE_AGENTS_CONFIG/-/raw" \
REF=v0.1.0 \
  && mkdir -p scripts \
  && curl -fsSL "${BASE_URL}/${REF}/scripts/sync-agent-config.sh" -o scripts/sync-agent-config.sh \
  && chmod +x scripts/sync-agent-config.sh \
  && bash scripts/sync-agent-config.sh
```

미러 경로 패턴(`/-/raw/`, `/raw/`, `/blob/<ref>/...?raw=true` 등)은 호스팅마다 달라지므로 사내 표준에 맞춰 `BASE_URL`만 바꿔 씁니다. 미러를 쓸 때도 가능하면 `REF`는 태그/SHA로 pin하세요.

### 작업 브랜치 검증 (PoC 용)

머지 전 작업 브랜치로 미리 결과를 확인할 때 `REMOTE_BRANCH` 환경변수로 override합니다.

```bash
# 부트스트랩 + sync 모두 같은 브랜치로
REMOTE_BRANCH=feat/your-branch \
  && mkdir -p scripts \
  && curl -fsSL "https://raw.githubusercontent.com/skaiworldwide/OT_M_FE_AGENTS_CONFIG/${REMOTE_BRANCH}/scripts/sync-agent-config.sh" -o scripts/sync-agent-config.sh \
  && chmod +x scripts/sync-agent-config.sh \
  && REMOTE_BRANCH="${REMOTE_BRANCH}" bash scripts/sync-agent-config.sh

# 부트스트랩 이후 반복 sync
REMOTE_BRANCH=feat/your-branch pnpm agent:sync
```

머지 후엔 환경변수를 빼면 자동으로 `main`으로 돌아갑니다. **운영엔 사용하지 말고 검증·PoC 용도로만** 씁니다.

### `--reset` / `--reset-managed-only` (강제 재설치)

managed 정의가 꼬여서 깨끗하게 재설치할 때만 사용합니다. 일반 동기화 흐름과 분리된 일회성 옵션이며, 동시에 지정하면 오류가 납니다.

```bash
bash scripts/sync-agent-config.sh --reset-managed-only    # managed만 재설치 (권장)
bash scripts/sync-agent-config.sh --reset                  # seed 포함 전체 재시드 (destructive)
bash scripts/sync-agent-config.sh --reset --yes            # CI/자동화에서 프롬프트 생략
bash scripts/sync-agent-config.sh --help                   # 옵션 도움말
```

| 옵션                   | 삭제 대상                                                                                                                                                                                                                                        | 보존                                                                                        |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| `--reset-managed-only` | upstream에 존재하는 이름의 managed 산출물만 (`agent-docs/rules`·`guides`·`harness-changelog.md`, `.claude/settings.json`, upstream과 같은 이름의 `.claude/agents/*.md`·`.codex/agents/*.toml`·`.claude/skills/<name>/`·`.agents/skills/<name>/`) | seed 파일(AGENTS.md·CLAUDE.md·.gitignore·.codex/config.toml), 프로젝트 커스텀 에이전트·스킬 |
| `--reset`              | 위 + seed 파일 + `.claude/agents/`·`.claude/skills/`·`.codex/agents/`·`.agents/skills/` 디렉토리 통째                                                                                                                                            | `scripts/sync-agent-config.sh` 본인, 소스 코드, 나열되지 않은 모든 프로젝트 파일            |

> **대부분의 reset 시나리오는 `--reset-managed-only`가 안전합니다.** `--reset`은 target repo를 초기 시드 상태로 완전히 되돌리고 싶을 때만 사용하세요 — 프로젝트별로 채워둔 AGENTS.md 내용도 함께 사라집니다.

> **Marker 도입 이전(2026-05-13 이전)에 sync한 target repo**는 옛 managed 사본에 marker가 없어 cleanup 대상에서 빠집니다. marker 도입 후 **첫 sync 직후 한 번** `--reset-managed-only`를 실행해 옛 사본을 정리하세요. 이후 정상 sync는 marker 기반으로 정확히 cleanup됩니다.

> reset 직전에 `git status`로 작업 중 변경이 없는지 확인하고, reset 후엔 `git diff`로 변경 폭을 확인합니다. `--yes`는 reset의 확인 프롬프트(`RESET`/`RESET-MANAGED` 타이핑)만 생략할 뿐, working tree clean 검사는 우회되지 않습니다.

### self-replace 함정

sync 스크립트(`scripts/sync-agent-config.sh`)는 다른 managed 파일과 마찬가지로 **자기 자신도 sync 대상**입니다. upstream에서 sync 스크립트의 **변환 로직이 바뀐 직후**의 첫 sync는 다음 순서로 진행됩니다.

1. 옛 스크립트가 실행 → 옛 로직으로 파일 생성
2. 마지막 단계에서 `scripts/sync-agent-config.sh` 자신을 새 버전으로 교체
3. 종료

즉 **첫 실행 결과는 옛 로직 산출물**이고, 새 변환은 **다음 sync부터** 효과가 있습니다. `pnpm agent:sync`를 **연달아 두 번** 실행하면 새 로직까지 반영된 결과를 얻습니다.

증상 예시 — 한 번 sync 후 결과 파일이 옛 형태(예: 잘못된 경로의 markdown 링크, 옛 헤더 포맷 등) 그대로면 두 번째 sync로 해결되는지 먼저 확인합니다. 두 번째에도 그대로면 upstream 변환 로직에 별도 버그가 있다는 신호입니다.
