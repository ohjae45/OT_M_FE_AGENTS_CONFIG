# COMMON_AGENT_CONFIG

공통 AI 에이전트 설정 및 가이드 원본 레포입니다.

## 레포 구조

```
COMMON_AGENT_CONFIG/
├── ai-guides/          # 공통 개발 가이드 (managed)
├── templates/          # 초기 세팅용 템플릿 (seed)
├── .claude/
│   ├── settings.json   # Claude 공통 설정 (managed)
│   └── skills/         # Claude 공통 스킬 (managed)
└── scripts/
    └── sync-agent-config-from-remote.sh   # 동기화 스크립트 초안
```

## Target repo에 적용되는 구조

```
target-repo/
├── AGENTS.md               ← templates/AGENTS.md (seed)
├── CLAUDE.md               ← templates/CLAUDE.md (seed)
├── docs/
│   └── ai-guides/          ← ai-guides/* (managed)
└── .claude/
    ├── settings.json       ← .claude/settings.json (managed)
    └── skills/             ← .claude/skills/* (managed)
```

### Seed files

없을 때만 복사합니다. 이미 있으면 덮어쓰지 않습니다.

- `templates/AGENTS.md` → `AGENTS.md`
- `templates/CLAUDE.md` → `CLAUDE.md`
- `scripts/sync-agent-config-from-remote.sh` → `scripts/sync-agent-config-from-remote.sh`

### Managed files

항상 최신으로 덮어씁니다.

- `ai-guides/*` → `docs/ai-guides/*`
- `.claude/settings.json` → `.claude/settings.json`
- `.claude/skills/*` → `.claude/skills/*`

---

## 새 target repo 온보딩

최초 1회만 수동으로 스크립트를 가져옵니다.

```bash
# 1. COMMON_AGENT_CONFIG를 임시로 클론
git clone --depth 1 git@github.com:woic-ej/COMMON_AGENT_CONFIG.git /tmp/common-config

# 2. 스크립트를 내 프로젝트에 복사
mkdir -p scripts
cp /tmp/common-config/scripts/sync-agent-config-from-remote.sh scripts/
chmod +x scripts/sync-agent-config-from-remote.sh

# 3. 임시 디렉토리 삭제
rm -rf /tmp/common-config
```

package.json에 스크립트를 추가합니다.

```json
{
  "scripts": {
    "agent:sync": "bash scripts/sync-agent-config-from-remote.sh"
  }
}
```

이후 동기화를 실행합니다.

```bash
pnpm agent:sync
```

---

## 이후 동기화 방법

COMMON_AGENT_CONFIG에 변경이 생기면 각 target repo에서 아래를 실행합니다.

```bash
pnpm agent:sync
git diff                              # 변경사항 확인
git checkout -b chore/sync-agent-config
git add -A
git commit -m "chore: sync common agent config"
# GitHub에서 PR 생성
```
