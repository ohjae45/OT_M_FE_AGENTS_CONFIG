# CLAUDE.md

이 문서는 이 프로젝트에서 Claude Code가 우선 따라야 할 작업 원칙을 정의한다.
공통 작업 원칙과 프로젝트 맥락은 `AGENTS.md`를 따른다.

@AGENTS.md

---

## 하네스: FE-COMMON

**목표:** React/TypeScript 프론트엔드 기능 개발을 분석 → 빌드 → 통합 → 검증 파이프라인으로 자동화

**트리거:** 컴포넌트·페이지·API 연동·Zustand 스토어·TanStack Query 훅·SCSS 스타일·기능 추가/수정/보완/재구현 등 프론트엔드 개발 작업 요청 시 `fe-orchestrator` 스킬을 사용한다. 단순 질문이나 코드 설명은 직접 응답한다.

**구성:**
- 에이전트: `.claude/agents/fe-analyst.md`, `fe-builder.md`, `fe-integration.md`, `fe-qa.md`
- 오케스트레이터: `.claude/skills/fe-orchestrator/SKILL.md`
- 도메인 지식 출처: `AGENTS.md`의 "핵심 도메인 개념" 섹션과 그 안에서 참조하는 문서

**변경 이력:** 하네스 구성이 변경될 때마다 아래 표에 한 줄을 추가한다. (날짜는 `YYYY-MM-DD` 형식)

| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
