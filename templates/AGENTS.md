# AGENTS.md

이 문서는 이 프로젝트에서 AI coding agent가 우선 따라야 할 작업 원칙을 정의한다.
상세 규칙은 [agent-docs/rules/](agent-docs/rules/) 아래 문서를 참고한다.

> **빈 섹션 채우는 방법**: 아래 각 섹션의 HTML 코멘트(`<!-- ... -->`)에 짧은 안내가 있고, 두 종류 도메인의 익명화 예시 모음은 [agent-docs/guides/agents-md-writing.md](agent-docs/guides/agents-md-writing.md)에 있다. 채울 게 없는 섹션은 코멘트만 남기고 비워둔다.

---

## 제품 개요

<!--
한 줄 제품 설명. 아래 항목을 채운다.

- 제품명과 만든 주체
- 어떤 문제를 해결하는가
- 핵심 사용 흐름 (사용자가 무엇을 하는 제품인가)

예시:
**온토비아 (ONTOVIA)** — SKAI Worldwide가 개발한 LLM 기반 AI 어시스턴트 플랫폼.
사용자는 등록된 AI 어시스턴트를 선택해 채팅하고, 답변 결과를 문서/스프레드시트/그래프로 확장할 수 있다.
-->

## 핵심 도메인 개념

<!--
이 프로젝트에서만 쓰는 용어와 개념을 정리한다.
AI가 코드를 읽거나 작성할 때 의미를 오해하지 않도록 하는 게 목적이다.
코드에 자주 등장하는 타입명, 상태명, 도메인 용어 위주로 작성한다.

| 용어 | 설명 |
|------|------|
| `Foo` | ... |
| `Bar` | ... |
-->

## 페이지 구조

<!--
라우트 단위로 페이지 구조를 트리 형태로 정리한다.
각 페이지의 핵심 역할을 한 줄로 적는다.
AI가 "이 기능은 어느 페이지에 있지?"를 판단할 수 있을 정도면 충분하다.

예시:
pages/
├── login/       # 이메일+비밀번호 로그인
├── home/        # 메인 — 어시스턴트 목록 + 업데이트 탭
└── assistant/   # 채팅 페이지
-->

## API 패턴

<!--
이 프로젝트의 API 작성 규칙을 정의한다.
공통 API 규칙 문서에 없는 프로젝트 전용 패턴만 적는다.

아래 항목을 채운다.
- HTTP 클라이언트 (예: customAxios, fetch 등)
- 에러 처리 방식
- 인증 처리 방식 (인터셉터, 토큰 등)
-->

## 프로젝트 설정

<!--
공통 규칙 문서의 내용과 다른 부분만 적는다.
패키지 매니저, 브랜치 전략은 공통 규칙과 동일하면 생략해도 된다.

아래 항목 중 이 프로젝트에만 해당하는 것만 채운다.
- 추가 명령어 (공통 외에 이 프로젝트에만 있는 것)
- 브랜치 전략 예외사항
- 환경변수 파일 위치
-->

## 디렉토리 구조

<!--
src/ 아래 주요 디렉토리와 역할을 정리한다.
AI가 새 파일을 만들 때 어디에 둬야 할지 판단할 수 있을 정도면 충분하다.

예시:
src/
├── api/          # Axios 인스턴스 및 API 함수
├── components/   # 공유 컴포넌트
├── pages/        # 라우트 페이지
├── stores/       # Zustand 스토어
└── types/        # 공유 타입 정의
-->

## 경로 별칭 (Path Aliases)

<!--
tsconfig 또는 vite.config에 설정된 경로 별칭을 정리한다.
AI가 import 경로를 잘못 쓰지 않도록 하는 게 목적이다.

| 별칭 | 경로 |
|------|------|
| `@/*` | `src/*` |
-->

## 공통 규칙 문서

작업 내용에 따라 관련 문서를 먼저 확인한다.

| 작업 유형                                | 참고 문서                                                                  |
| ---------------------------------------- | -------------------------------------------------------------------------- |
| React 컴포넌트, 폴더 구조, 네이밍        | [frontend-common-rules.md](agent-docs/rules/frontend-common-rules.md)   |
| API 함수, Query 훅, DTO 타입 위치        | [api-rules.md](agent-docs/rules/api-rules.md)                           |
| TypeScript 타입, any, unknown, 타입 가드 | [typescript-rules.md](agent-docs/rules/typescript-rules.md)             |
| SCSS, SCSS Modules, className, mixin     | [styling-rules.md](agent-docs/rules/styling-rules.md)                   |
| Zustand, TanStack Query, 전역 상태       | [state-management-rules.md](agent-docs/rules/state-management-rules.md) |
| 작업 절차, 구조 변경, 검증, 문서화       | [workflow-rules.md](agent-docs/rules/workflow-rules.md)                 |
| Git 커밋 메시지, 작업 키워드             | [git-keyword-rules.md](agent-docs/rules/git-keyword-rules.md)           |

## 우선순위

여러 규칙이 충돌하면 아래 순서를 따른다.

1. 현재 사용자 요청
2. 현재 프로젝트 요구사항
3. 이 `AGENTS.md`
4. 관련 상세 규칙 문서 : [agent-docs/rules/](agent-docs/rules/)
5. 기존 코드 패턴

---

## 하네스: FE-COMMON

**목표:** React/TypeScript 프론트엔드 기능 개발을 분석 → 빌드 → 통합 → 검증 파이프라인으로 자동화

**트리거:** 컴포넌트·페이지·API 연동·Zustand 스토어·TanStack Query 훅·SCSS 스타일·기능 추가/수정/보완/재구현 등 프론트엔드 개발 작업 요청 시 `skai-orchestrator` 스킬을 사용한다. 단순 질문이나 코드 설명은 직접 응답한다.

**구성:**
- 에이전트 원본: `agent-docs/agents/skai-{analyst,builder,integration,qa}.md` (sync 시 도구별 위치·포맷으로 분기 생성)
- 오케스트레이터: `agent-docs/skills/skai-orchestrator.md` (sync 시 `.claude/skills/`·`.agents/skills/` 양쪽에 SKILL.md 패키지로 배포)
- 도메인 지식 출처: `AGENTS.md`의 "핵심 도메인 개념" 섹션과 그 안에서 참조하는 문서

**환경 범위:** Claude Code와 Codex CLI 두 환경에서 동작한다. Phase 흐름과 파일 핸드오프는 동일하고, dispatch만 다르다.

| 도구 | 에이전트 위치 | dispatch |
|------|--------------|----------|
| Claude Code | `.claude/agents/skai-*.md` | `Agent(subagent_type="skai-analyst", ...)` 네이티브 도구 |
| Codex CLI | `.codex/agents/skai-*.toml` | 자연어 지시 ("skai-analyst 서브에이전트로 X를 실행하라") |

**변경 이력:** 아래 표는 [`agent-docs/harness-changelog.md`](agent-docs/harness-changelog.md)에서 sync 시 자동 갱신된다. 마커 안쪽은 직접 편집하지 않는다 — 다음 sync에서 덮어써진다. 프로젝트별 변경 이력이 필요하면 마커 바깥에 별도 표를 둔다.

<!-- harness-changelog:upstream:start -->
| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-05-12 | 하네스 FE-COMMON 도입 | `agent-docs/agents/fe-{analyst,builder,integration,qa}.md`, `agent-docs/skills/fe-orchestrator.md`, `templates/AGENTS.md` 하네스 섹션 | FE 분석 → 빌드 → 통합 → 검증 파이프라인 표준화 |
<!-- harness-changelog:upstream:end -->
