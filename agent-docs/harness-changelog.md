# 하네스 변경 이력 (Upstream)

이 표는 `scripts/sync-agent-config.sh`가 target repo의 `AGENTS.md` "변경 이력" 표를 채울 때 사용하는 **단일 원본**입니다. 변경이 생기면 아래 마커 안쪽의 표 상단(헤더 직하단)에 최신 행을 추가합니다.

target repo의 `AGENTS.md` 안에는 동일한 마커가 들어가며, sync가 매번 그 마커 사이 내용을 이 표로 교체합니다. **target repo에서 마커 안쪽을 직접 편집하지 마세요** — 다음 sync에서 덮어써집니다. 프로젝트별 변경 이력이 필요하면 마커 바깥에 별도 표("프로젝트 변경 이력" 등)를 둡니다.

<!-- harness-changelog:upstream:start -->
| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-05-20 | 에이전트/스킬 파일명 `fe-*` → `skai-*` 통일 | `agent-docs/agents/skai-{analyst,builder,integration,qa}.md`, `agent-docs/skills/skai-orchestrator.md` | 스킬 접두사 규칙(`skai-`) 일관성 확보. 기존 `fe-*` 이름은 sync cleanup 대상으로 정리됨 |
| 2026-05-13 | 하네스 변경 이력 표 자동 동기화 도입 | `agent-docs/harness-changelog.md`, `scripts/sync-agent-config.sh`, `templates/AGENTS.md` | 수동 관리되던 표가 `YYYY-MM-DD` 자리표시자로 남는 문제 해결 |
| 2026-05-12 | Codex CLI TOML 분기 + `.agents/skills` 동기화 | `scripts/sync-agent-config.sh`, `.codex/agents/*.toml`, `.agents/skills/*/SKILL.md` | Claude Code와 Codex CLI 양 환경 동시 지원 |
| 2026-05-12 | 하네스 FE-COMMON 도입 | `agent-docs/agents/fe-{analyst,builder,integration,qa}.md`, `agent-docs/skills/fe-orchestrator.md`, `templates/AGENTS.md` 하네스 섹션 | FE 분석 → 빌드 → 통합 → 검증 파이프라인 표준화 |
<!-- harness-changelog:upstream:end -->

## 행 추가 가이드

- 컬럼 4종은 고정합니다: `날짜 | 변경 내용 | 대상 | 사유`
- `날짜`는 `YYYY-MM-DD` (커밋 일자, KST 기준)
- `대상`은 영향을 받은 파일·디렉토리·섹션을 백틱으로 적습니다 (예: `agent-docs/agents/skai-*.md`)
- `사유`는 *왜* 바꿨는지 한 줄로 (변경한 내용 반복 금지)
- 최신순(최신이 위)으로 정렬합니다

## sync 동작

target repo의 `AGENTS.md`에서 마커가 존재하면 그 사이 본문을 위 표로 항상 교체합니다. 마커가 없는 경우(하네스 도입 이전 시드로 생성된 target) sync가 "**변경 이력:**" 문단 다음의 기존 표를 마커 블록으로 한 번 변환합니다. 자세한 동작은 [scripts/sync-agent-config.sh](scripts/sync-agent-config.sh)의 `sync_harness_changelog_block` 함수를 참고합니다.
