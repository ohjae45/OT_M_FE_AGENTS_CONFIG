# COMMON_AGENT_CONFIG

공통 AI 에이전트 설정 및 가이드 원본 레포입니다.

## 레포 구조

```
COMMON_AGENT_CONFIG/
├── agent-docs/
│   ├── guides/         # 공통 개발 가이드 원본
│   └── skills/         # 공통 스킬 원본
├── templates/          # 초기 세팅용 템플릿 (seed)
├── .claude/
│   └── settings.json   # Claude 공통 설정 원본
└── scripts/
    └── sync-agent-config.sh   # 동기화 스크립트
```

## Target repo에 적용되는 구조

```
target-repo/
├── AGENTS.md               ← templates/AGENTS.md (seed)
├── CLAUDE.md               ← templates/CLAUDE.md (seed)
├── agent-docs/
│   ├── guides/             ← agent-docs/guides/* (managed)
│   └── skills/             ← agent-docs/skills/* (managed source copy)
├── .claude/
│   ├── settings.json       ← .claude/settings.json (managed)
│   └── skills/             ← agent-docs/skills/*에서 생성 (managed)
└── .agents/
    └── skills/
        └── <skill>/SKILL.md ← agent-docs/skills/*에서 생성 (managed)
```

## 스킬 관리 원칙

스킬 원본은 `agent-docs/skills/*.md`만 수정합니다. COMMON_AGENT_CONFIG에는 `.claude/skills`나 `.agents/skills` 복사본을 두지 않습니다.

`scripts/sync-agent-config.sh`가 target repo에 동기화할 때 다음 산출물을 생성합니다.

- `.claude/skills/*.md`: Claude가 바로 읽는 plain markdown 복사본
- `.agents/skills/<skill>/SKILL.md`: Codex가 읽는 frontmatter 포함 스킬 파일

Codex repo-local skills는 `.agents/skills`를 사용합니다. `.codex`는 필요할 때 `config.toml` 같은 Codex 설정만 둡니다.

### Seed files

없을 때만 복사합니다. 이미 있으면 덮어쓰지 않습니다.

- `templates/AGENTS.md` → `AGENTS.md`
- `templates/CLAUDE.md` → `CLAUDE.md`

### Managed files

항상 최신으로 덮어씁니다.

- `agent-docs/guides/*` → `agent-docs/guides/*`
- `agent-docs/skills/*` → `agent-docs/skills/*`
- `.claude/settings.json` → `.claude/settings.json`
- `agent-docs/skills/*` → `.claude/skills/*`
- `agent-docs/skills/*` → `.agents/skills/<skill>/SKILL.md`
- `scripts/sync-agent-config.sh` → `scripts/sync-agent-config.sh`

---

## 새 target repo 온보딩

### 1. 최초 1회만 수동으로 스크립트를 가져옵니다.

```bash
# 1. COMMON_AGENT_CONFIG를 임시로 클론
git clone --depth 1 git@github.com:woic-ej/COMMON_AGENT_CONFIG.git /tmp/common-config

# 2. 스크립트를 내 프로젝트에 복사
mkdir -p scripts
cp /tmp/common-config/scripts/sync-agent-config.sh scripts/
chmod +x scripts/sync-agent-config.sh

# 3. 임시 디렉토리 삭제
rm -rf /tmp/common-config
```

### 2. package.json에 동기화 스크립트를 추가합니다.

```json
{
  "scripts": {
    "agent:sync": "bash scripts/sync-agent-config.sh"
  }
}
```

### 3. 이후 동기화를 실행합니다.

```bash
pnpm agent:sync
```

---

## 이후 동기화 방법

COMMON_AGENT_CONFIG에 변경이 생기면 각 target repo에서 아래를 실행합니다.

```bash
pnpm agent:sync
git add -A
git commit -m "chore: sync common agent config"
```
