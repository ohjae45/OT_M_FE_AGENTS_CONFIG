# /fe-orchestrator

## 설명

프론트엔드 기능 개발을 분석 → 빌드 → 통합 → 검증 파이프라인으로 처리하는 오케스트레이터.
컴포넌트 구현, 페이지 개발, API 연동, Zustand 스토어, TanStack Query 훅, SCSS 스타일,
기능 추가·수정·보완·재구현·다시 만들기, 이전 결과 기반 개선, 부분 재작업 등
모든 React/TypeScript 프론트엔드 개발 요청 시 반드시 이 스킬을 사용합니다.
단순 질문·코드 설명·에러 원인 문의는 제외합니다.

## 실행 모드

하이브리드 모드:
- Phase 1 (분석): 서브 에이전트 (fe-analyst 단독)
- Phase 2 (빌드): 에이전트 팀 (fe-builder + fe-integration 협업)
- Phase 3 (QA): 서브 에이전트 (fe-qa 단독)

각 에이전트는 Claude Code 네이티브 서브에이전트(`.claude/agents/fe-*.md`)로 등록되어 있어 `subagent_type="fe-analyst"`처럼 직접 호출한다. 역할·원칙·입출력 프로토콜은 해당 파일 본문이 그대로 시스템 프롬프트로 주입된다.
프로젝트 도메인 지식은 `AGENTS.md`를 참조한다.

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

## Phase 2: 빌드 (에이전트 팀 모드)

`_workspace/01_analyst_plan.md` 완료 확인 후 에이전트 팀을 구성한다.

### 팀 구성
- **팀 이름**: `fe-build-team`
- **팀원**: fe-builder, fe-integration
- **작업 할당**: analyst 계획에 따라 분리

### 작업 정의

**fe-builder 작업:**
```
Agent(
  subagent_type="fe-builder",
  prompt="""
_workspace/01_analyst_plan.md를 읽고 fe-builder 지시사항에 따라 컴포넌트를 구현하라.
완료 후 _workspace/02a_builder_status.md를 작성하라.
fe-integration에게 SendMessage로 컴포넌트 목록과 필요한 props 타입을 전달하라.
  """
)
```

**fe-integration 작업 (fe-builder와 병렬 시작, 팀 통신으로 조율):**
```
Agent(
  subagent_type="fe-integration",
  prompt="""
_workspace/01_analyst_plan.md를 읽고 fe-integration 지시사항에 따라 훅·스토어·API를 구현하라.
fe-builder의 SendMessage를 수신해 props 타입과 인터페이스를 맞춰라.
완료 후 _workspace/02b_integration_status.md를 작성하라.
fe-qa에게 SendMessage로 구현 목록을 전달하라.
  """
)
```

두 에이전트를 `run_in_background: true`로 동시 시작하고 팀 통신으로 자체 조율한다.

각 status 파일은 다음을 포함한 짧은 보고서다:
- 생성/수정 파일 목록 (경로)
- 적용된 주요 결정 (재사용 vs 신규, 타입 정의 위치 등)
- 다음 에이전트(integration / qa)에게 넘기는 핸드오프 노트

Phase 2 완료 조건: `_workspace/02a_builder_status.md` + `_workspace/02b_integration_status.md` 두 파일 모두 생성됨 + fe-qa에게 알림 발신

## Phase 3: QA (서브 에이전트 모드)

fe-integration의 완료 알림 수신 후 `fe-qa`를 호출한다.

```
Agent(
  subagent_type="fe-qa",
  prompt="""
Phase 2에서 구현된 파일들을 검증하라.
_workspace/03_qa_report.md를 생성하라.
수정 필요 항목이 있으면 해당 에이전트(fe-builder 또는 fe-integration)에게 SendMessage로 수정 요청하라.
  """
)
```

QA PASS 시 Phase 4로 이동. FAIL 시 수정 후 재검증.

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
| 빌드 에이전트 충돌 | fe-builder/fe-integration이 스스로 SendMessage로 조율. 1회 재조율 후 실패 시 analyst에 재설계 요청 |
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

- 에이전트 정의: `.claude/agents/fe-*.md`
- 공통 개발 규칙: `agent-docs/rules/`
- 프로젝트 도메인 지식: `AGENTS.md`
