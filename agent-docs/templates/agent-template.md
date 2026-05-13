<!-- 새 에이전트 정의를 작성할 때 사용하는 템플릿입니다.
이 템플릿(agent-template.md) 자체는 target repo로 동기화되지 않습니다.
실제 에이전트 정의 파일(agents/fe-*.md)만 sync 대상입니다.

작성 규칙 (README "에이전트 관리 원칙" 참조):
- 이름 규칙: 파일명은 `fe-` 접두사를 사용한 kebab-case (예: `fe-analyst.md`, `fe-builder.md`).
  frontmatter의 `name`과 파일명이 일치해야 하며, `subagent_type="<name>"`으로 호출된다.
- 저장 위치: `agent-docs/agents/fe-<role>.md` (sync 시 target repo의 `.claude/agents/fe-<role>.md`로 매번 덮어쓰기 복사된다).
- 도메인 중립: 프로젝트 도메인(용어·API shape·페이지 구조·라우팅 등)에 비의존적으로 작성한다.
  프로젝트별 차이는 target repo의 `AGENTS.md`에 두고, 본문에서는 "AGENTS.md를 참조한다"고만 적는다.
- 공통 규칙 참조: 코드 스타일·TypeScript·워크플로우 같은 공통 규칙은 `agent-docs/rules/`를 참조하고 본문에 중복 기재하지 않는다.
- 호출 방식: `fe-orchestrator` 스킬에서 `subagent_type="fe-<role>"`로 직접 호출된다.
  `general-purpose`로 띄워 본문을 읽게 시키는 우회 패턴은 사용하지 않으므로, 본문은 곧 시스템 프롬프트로 들어간다는 전제로 작성한다.

frontmatter 필수:
- name: 파일명과 동일한 kebab-case 이름 (`fe-` 접두사 포함).
- description: 언제 이 에이전트를 호출해야 하는지 한 문장. 다른 fe-* 에이전트와의 경계가 드러나도록 적는다.
- model: 기본 모델(opus / sonnet / haiku). 호출 측에서 override 가능.

파일 본문은 그대로 시스템 프롬프트로 주입되므로 역할·원칙·입출력 프로토콜을 명확히 적는다. -->

---
name: fe-<role>
description: <언제 이 에이전트를 호출하는지 한 문장 — 다른 fe-* 에이전트와의 경계가 드러나도록>
model: opus
---

# <Agent Name>

## 핵심 역할
<에이전트가 어떤 작업을 책임지는지 한 문단으로 설명. 협업 대상 fe-* 에이전트와의 경계를 명확히 한다.
프로젝트별 도메인 지식은 적지 말고, 필요하면 target repo의 AGENTS.md를 참조한다고 적는다.>

## 작업 원칙
- <반드시 지킬 규칙. 공통 규칙은 [agent-docs/rules/](../rules/)를 참조한다>
- <판단 기준>
- <기존 자원 재사용·재확인 등 효율 원칙>

## 입력/출력 프로토콜

### 입력
- <상위 에이전트나 사용자가 넘기는 자료>
- <참조해야 하는 기존 산출물>

### 출력
- <생성·수정하는 파일 경로>
- <`_workspace/` 산출물의 형식이 있으면 코드 블록으로 명시>

## 에러 핸들링
- <실패 시 재시도/우회 정책>
- <환경 미구성 시 정적 분석으로 대체하는 등의 폴백>

## 팀 통신 프로토콜
오케스트레이터가 순차 실행 모드로 호출하므로 기본은 `_workspace/` 파일 핸드오프다. SendMessage 협업은 권한·참조 메커니즘이 검증된 이후에만 사용한다.
- 수신: <어느 `_workspace/` 파일 또는 어떤 사전 산출물을 읽는가>
- 발신: <완료 후 어떤 `_workspace/` 파일을 작성해 다음 에이전트가 읽도록 하는가>
- 충돌·불일치 시: <발신 파일의 어떤 섹션에 기록해 오케스트레이터/다음 단계가 인지하도록 하는가>
