# CLAUDE.md

이 문서는 이 프로젝트에서 Claude Code가 우선 따라야 할 작업 원칙을 정의한다.
공통 작업 원칙·프로젝트 맥락·하네스 트리거 규칙은 `AGENTS.md`를 따른다.

@AGENTS.md

---

## Claude Code 특화 안내

- 하네스 정의와 트리거 조건은 `AGENTS.md`의 "하네스: FE-COMMON" 섹션을 참조한다. (Claude Code는 `@AGENTS.md` import로 그 본문을 함께 읽는다.)
- Claude Code는 `.claude/agents/fe-*.md`를 frontmatter 기반으로 자동 등록한다. `fe-orchestrator` 스킬은 `Agent(subagent_type="fe-analyst", ...)`처럼 네이티브 서브에이전트 dispatch로 호출한다.
- `general-purpose`로 띄운 뒤 본문을 읽게 시키는 우회 패턴은 사용하지 않는다.
