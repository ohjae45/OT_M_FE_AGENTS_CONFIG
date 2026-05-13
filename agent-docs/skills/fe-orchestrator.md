# /fe-orchestrator

## 설명

프론트엔드 기능 개발을 분석 → 빌드 → 통합 → 검증 파이프라인으로 처리하는 오케스트레이터.
컴포넌트 구현, 페이지 개발, API 연동, Zustand 스토어, TanStack Query 훅, SCSS 스타일,
기능 추가·수정·보완·재구현·다시 만들기, 이전 결과 기반 개선, 부분 재작업 등
모든 React/TypeScript 프론트엔드 개발 요청 시 반드시 이 스킬을 사용합니다.
단순 질문·코드 설명·에러 원인 문의는 제외합니다.

## 실행 모드

모든 Phase를 서브 에이전트 단위로 순차 실행한다:
- Phase 1 (분석): fe-analyst 단독
- Phase 2 (빌드): fe-builder → fe-integration **순차 호출** (`_workspace/` 파일로 핸드오프)
- Phase 3 (QA): fe-qa 단독

각 에이전트 정의는 단일 원본(`agent-docs/agents/fe-*.md`)에서 sync 시 도구별 위치·포맷으로 생성된다. 역할·원칙·입출력 프로토콜은 그 본문이 그대로 시스템 프롬프트로 주입된다.
프로젝트 도메인 지식은 `AGENTS.md`를 참조한다.

**병렬 + SendMessage 협업은 기본 모드가 아니다.** 서브 에이전트 간 SendMessage가 동작하려면 (1) 양쪽 에이전트 정의에 SendMessage tool 권한이 명시되어 있어야 하고, (2) 상대방 에이전트 ID/이름을 알 수 있어야 한다. 이 전제가 실제 환경에서 검증되기 전까지는 순차 실행 + 파일 핸드오프를 사용한다. 병렬화는 아래 "Phase 2 / 병렬화 옵션 (검증 후)" 섹션 참고.

## 도구별 dispatch 차이

서브 에이전트를 호출하는 방식만 다르고, Phase 흐름·파일 핸드오프 프로토콜·완료 조건은 동일하다.

| 도구 | 에이전트 정의 | dispatch 방식 |
|------|--------------|--------------|
| Claude Code | `.claude/agents/<name>.md` (frontmatter + body) | `Agent(subagent_type="<name>", description=..., prompt=...)` 네이티브 도구 호출 |
| Codex CLI | `.codex/agents/<name>.toml` (sync 시 자동 생성) | 자연어 지시 — 부모 세션에 "fe-analyst 서브에이전트로 다음 작업을 실행하라: ..." 형태로 prompt를 전달. Codex가 `developer_instructions`로 새 세션을 spawn |

아래 Phase 예시는 Claude Code 형식으로 작성되어 있다. Codex에서 동작할 때는 동일한 prompt 본문을 자연어 지시로 옮겨 사용한다. Codex의 자연어 dispatch는 conversational이므로 Phase 2 fe-builder ↔ fe-integration 같은 병렬화는 더 제한적이며, 현재는 양 환경 모두 순차 실행을 표준으로 한다.

## Phase 0: 컨텍스트 확인

실행 전에 기존 작업 상태를 판별한다:

1. `_workspace/` 디렉토리 존재 여부 확인
2. 실행 모드 결정:
   - `_workspace/` 없음 → **초기 실행** (Phase 1부터 전체 실행)
   - `_workspace/` 있음 + 사용자가 부분 수정 요청 → **부분 재실행** (해당 Phase만 재호출)
   - `_workspace/` 있음 + 새 기능 요청 → **새 실행** (기존 `_workspace_prev/`를 삭제하고 현재 `_workspace/`를 `_workspace_prev/`로 이동 후 전체 실행)

`_workspace_prev/`는 직전 1회분만 보관한다. 새 실행이 시작될 때 이전 `_workspace_prev/`는 삭제하여 누적을 방지한다.

```bash
ls _workspace/ 2>/dev/null || echo "초기 실행"
rm -rf _workspace_prev/ && mv _workspace/ _workspace_prev/  # 새 실행 진입 시
```

## Phase 1: 분석 (서브 에이전트 모드)

`fe-analyst` 서브에이전트를 직접 호출한다.

```
Agent(
  description="FE 요청 분석 및 계획 수립",
  subagent_type="fe-analyst",
  prompt="""
사용자 요청: {사용자 요청 원문}
실행 모드: {초기/부분/새 실행}

프로젝트 도메인 지식은 AGENTS.md를 본다.
_workspace/01_analyst_plan.md를 생성하고 완료하라.
  """
)
```

Phase 1 완료 조건: `_workspace/01_analyst_plan.md` 파일 생성됨

## Phase 2: 빌드 (순차 실행)

`_workspace/01_analyst_plan.md` 완료 확인 후 fe-builder → fe-integration 순서로 호출한다. 두 에이전트 사이의 핸드오프는 `_workspace/02a_builder_status.md` 파일을 통해 이루어진다 (SendMessage 의존 없음).

### 1단계: fe-builder 호출

```
Agent(
  description="컴포넌트/스타일 구현",
  subagent_type="fe-builder",
  prompt="""
_workspace/01_analyst_plan.md를 읽고 fe-builder 지시사항에 따라 컴포넌트를 구현하라.
완료 후 _workspace/02a_builder_status.md를 작성하라. 다음 항목을 반드시 포함하라:
- 생성/수정한 컴포넌트 파일 경로
- 각 컴포넌트의 props 타입 정의 위치 (fe-integration이 데이터 shape을 맞출 수 있도록)
- 데이터 페칭이 필요한 지점 (어떤 훅·스토어가 필요한지 명시)
- 재사용 vs 신규 작성 결정
- 미해결 이슈·TODO
  """
)
```

1단계 완료 조건: `_workspace/02a_builder_status.md` 파일 생성됨.

### 2단계: fe-integration 호출

fe-builder 완료 후 호출한다.

```
Agent(
  description="훅/스토어/API 연동 구현",
  subagent_type="fe-integration",
  prompt="""
_workspace/01_analyst_plan.md와 _workspace/02a_builder_status.md를 읽어라.
02a_builder_status.md에 명시된 props 타입·데이터 shape에 맞춰
fe-integration 지시사항에 따라 훅·스토어·API를 구현하라.
완료 후 _workspace/02b_integration_status.md를 작성하라. 다음 항목을 포함하라:
- 생성/수정한 훅·스토어·API 함수 파일 경로
- 쿼리 키·캐시 전략·스토어 분리 결정
- fe-builder 컴포넌트 props와 매칭 결과 (불일치 발생 시 어떻게 해결했는지)
- 미해결 이슈·TODO
  """
)
```

2단계 완료 조건: `_workspace/02b_integration_status.md` 파일 생성됨.

### 인터페이스 불일치 처리

fe-integration이 02a_builder_status.md의 props 타입과 실제 API 응답이 맞지 않는다고 판단하면, 02b_integration_status.md에 불일치 내역과 임시 해결책을 명시하고 진행한다. fe-qa가 Phase 3에서 교차 검증으로 잡아낸다 (필요 시 fe-builder 재호출).

### Phase 2 완료 조건

`_workspace/02a_builder_status.md` + `_workspace/02b_integration_status.md` 두 파일 모두 생성됨.

### 병렬화 옵션 (검증 후)

향후 다음이 모두 검증되면 두 에이전트를 `run_in_background: true`로 병렬 실행 + SendMessage 협업으로 전환할 수 있다:
1. fe-builder, fe-integration 에이전트 정의에 SendMessage tool 권한이 부여되어 있음
2. 호출 시 서로의 에이전트 ID/이름을 참조할 수 있는 메커니즘이 동작함
3. SendMessage로 props 타입 합의가 실제로 이루어지는지 샘플 시나리오로 확인됨

검증 전까지는 본 문서의 순차 실행이 정식 동작이다.

## Phase 3: QA (서브 에이전트 모드)

`_workspace/02b_integration_status.md` 생성 확인 후 `fe-qa`를 호출한다.

```
Agent(
  description="FE 구현 결과 QA 검증",
  subagent_type="fe-qa",
  prompt="""
_workspace/01_analyst_plan.md, 02a_builder_status.md, 02b_integration_status.md를 읽고
Phase 2에서 구현된 파일들을 검증하라.
_workspace/03_qa_report.md를 생성하라. PASS/FAIL과 항목별 결과를 포함하라.
  """
)
```

QA FAIL 시 오케스트레이터가 보고서를 읽고 해당 에이전트(fe-builder 또는 fe-integration)를 재호출해 수정 후 fe-qa를 다시 호출한다. PASS 시 Phase 4로 이동.

## Phase 4: 완료 보고

`_workspace/03_qa_report.md`를 읽고 사용자에게 요약 보고:

```markdown
## 구현 완료

### 생성된 파일
[파일 목록]

### 주요 변경사항
[변경 내용 요약]

### QA 결과
[PASS / 수정 후 PASS]

### 다음 단계 (있는 경우)
[남은 작업이 있으면 명시]
```

## 에러 핸들링

| 상황 | 처리 |
|------|------|
| fe-analyst 계획 생성 실패 | 재시도 1회 후 실패 시 사용자에게 요청 구체화 요청 |
| 빌드 단계 인터페이스 불일치 | fe-integration이 02b_integration_status.md에 불일치 내역을 기록하고 진행. fe-qa가 잡아내면 오케스트레이터가 fe-builder를 재호출해 props 타입 수정 후 fe-integration·fe-qa 재실행 |
| QA FAIL (수정 2회 후에도) | 실패 항목을 보고서에 명시하고 사용자에게 수동 수정 안내 |
| `pnpm typecheck` 환경 없음 | 정적 분석으로 대체, 보고서에 "빌드 환경 미구성" 명시 |

## 부분 재실행 가이드

사용자가 "이 부분만 수정", "다시", "개선", "보완" 등을 요청할 때:

- 컴포넌트 수정 → Phase 2 (fe-builder만, `_workspace/02a_builder_status.md` 갱신) + Phase 3
- 훅/스토어 수정 → Phase 2 (fe-integration만, `_workspace/02b_integration_status.md` 갱신) + Phase 3
- 인터페이스 변경 → Phase 1 재실행 후 Phase 2 전체 + Phase 3
- QA 재검증만 → Phase 3만

`_workspace/`의 산출물 번호(01 → 02a/02b → 03)로 "어디까지 끝났는지" 추적한다.

## 테스트 시나리오

### 정상 흐름
1. "사용자 프로필 카드 컴포넌트 만들어줘" 입력
2. Phase 0: `_workspace` 없음 → 초기 실행
3. Phase 1: analyst가 컴포넌트 계획 + 인터페이스 정의
4. Phase 2: builder가 `*.tsx`/`*.module.scss` 구현, integration이 `use*` 훅 구현
5. Phase 3: QA가 props ↔ 훅 타입 교차 검증
6. Phase 4: 생성 파일 목록과 사용법 보고

### 에러 흐름
1. "버튼 색상 수정해줘" 입력
2. Phase 0: `_workspace` 있음 + 부분 수정 → Phase 2 (fe-builder만) + Phase 3
3. Phase 2: builder가 해당 모듈 SCSS 수정
4. Phase 3: QA FAIL — SCSS 변수 미사용 → builder 재수정 → QA PASS

## 참고 문서

- 에이전트 원본: `agent-docs/agents/fe-*.md` (sync 시 `.claude/agents/fe-*.md`·`.codex/agents/fe-*.toml`로 분기 생성)
- 공통 개발 규칙: `agent-docs/rules/`
- 프로젝트 도메인 지식: `AGENTS.md`
