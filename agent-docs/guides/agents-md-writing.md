# AGENTS.md 작성 가이드

신규 프로젝트에서 [templates/AGENTS.md](../../templates/AGENTS.md)의 빈 섹션을 채울 때 참고하는 예시 모음입니다. 두 종류의 도메인을 비교 가능한 형태로 보여줍니다.

- **예시 A — 채팅 플랫폼**: LLM 기반 AI 어시스턴트 채팅 + 결과 확장(문서/스프레드시트/그래프).
- **예시 B — 비동기 분석 대시보드**: 백엔드 파이프라인이 만든 투자 리포트를 폴링으로 받아 시각화.

> 실제 SKAI 사내 프로젝트 두 곳(`OT_P_ONTOVIA_FRONTEND`, `OT_P_FE_STOCK`)의 AGENTS.md를 익명화한 발췌입니다.

## 공통 작성 원칙

- **AI가 코드 작성/탐색에 쓰는 정보만 적는다.** 마케팅 문구·일반론(예: "사용자 친화적", "직관적 UI")은 의사결정에 도움이 안 된다.
- **공통 규칙 문서에 이미 있는 내용은 반복하지 않는다.** [agent-docs/rules/](../rules/)와 *다른* 부분만 적는다.
- **코드에 등장하는 식별자를 그대로 사용한다.** 타입명·상태명·URL 경로를 한국어 풀이로 바꾸지 않는다 (`Assistant`, `BUY/HOLD/WATCH`).
- **빈 섹션은 빈 채로 둔다.** 채울 게 없으면 HTML 코멘트만 남기고 비워두는 게 노이즈를 줄인다.
- **PR마다 함께 갱신한다.** 새 도메인 용어가 등장하거나 페이지 구조가 바뀌면 같은 PR에서 AGENTS.md를 업데이트한다.

---

## 1. 제품 개요

**목적:** AI가 "이 프로젝트는 무엇을 만드는 코드인가"를 한 호흡에 이해하게 한다. 이후 판단(어떤 기능이 핵심인지, 무엇이 이 도메인에서 비정상인지)의 기준점이 된다.

**작성 팁**

- 한 줄: "**제품명** — 만든 주체와 한 문장 요약"
- 한 단락: 사용자가 무엇을 하는 제품인지 핵심 흐름 1~2개
- 백엔드/외부 시스템 의존이 큰 경우 그 구조도 짧게 (다이어그램은 텍스트 트리로 충분)

**예시 A — 채팅 플랫폼**

```markdown
## 제품 개요

**AI Assistant Hub** — LLM 기반 AI 어시스턴트 채팅 플랫폼.
사용자는 등록된 AI 어시스턴트를 선택해 채팅하고, 답변 결과를 문서/스프레드시트/그래프로 확장할 수 있다.
```

**예시 B — 비동기 분석 대시보드**

````markdown
## 제품 개요

**Investment Report Viewer — Frontend** — 멀티 에이전트 AI 주식 분석 결과를 시각화하는 React/TypeScript 프론트엔드.
백엔드(Python/LangGraph) 파이프라인이 생성한 투자 리포트(BUY/HOLD/WATCH + 기술 지표 + 감성 분석)를 수신·표시한다.

### 백엔드 파이프라인

```
Data Worker → [Technical Analyst || Market Critic] → Strategy Orchestrator
```

리포트 생성은 비동기, **최대 60초 소요** — 폴링(`refetchInterval: 3000`) 또는 WebSocket으로 처리한다.
````

> **차이**: A는 사용자 시나리오 중심, B는 백엔드 파이프라인 형상·비동기 특성 중심. 향후 자주 발생할 의사결정에 따라 강조점을 선택한다.

---

## 2. 핵심 도메인 개념

**목적:** 코드에 자주 등장하지만 일반 React 지식만으로는 의미를 알 수 없는 용어와 타입을 정리한다. AI가 변수명·상태명을 보고 의도를 오해하지 않게 한다.

**작성 팁**

- 표 형식이 가장 빠르게 스캔된다. `| 용어 | 설명 |`
- 코드 식별자는 백틱 인라인 코드로 표시 (`` `Assistant` ``, `` `'docs' | 'spread' | 'graph'` ``).
- API 응답 형태가 복잡하고 코드 전체에 영향을 준다면 TypeScript 인터페이스를 함께 둔다.
- 도메인이 클라이언트 전용이면 표만으로 충분. 백엔드 계산 결과를 표시하는 프로젝트라면 응답 인터페이스까지 적는 게 유리하다.

**예시 A — 채팅 플랫폼 (용어표만)**

```markdown
## 핵심 도메인 개념

| 용어 | 설명 |
|------|------|
| `Assistant` | LLM 기반 AI 어시스턴트. `data_type`으로 DBMS/GRAPH_RAG/VECTOR_RAG 구분 |
| `Thread` | 하나의 대화 세션. 날짜별로 그룹화되어 사이드바에 표시 |
| `SubThread` | Thread 내 개별 메시지 단위 |
| `ExpertType` | `'docs'`(문서) \| `'spread'`(스프레드시트) \| `'graph'`(지식 그래프) |
| 추론 과정 | AI 답변 생성 시 검색/추론 단계를 패널로 시각화 |
```

**예시 B — 분석 대시보드 (용어표 + 응답 인터페이스)**

````markdown
## 핵심 도메인 개념

### 도메인 용어

| 용어 | 설명 |
|------|------|
| OHLCV | 시가·고가·저가·종가·거래량 |
| SMA5 / SMA20 | 5일/20일 단순 이동평균선 |
| 골든크로스 | SMA5 > SMA20 (단기 상승 신호) |
| RSI | 상대강도지수. 70 이상 과매수, 30 이하 과매도 |
| BUY / HOLD / WATCH | 매수 / 관망 / 주시 의견 |

### API 응답 TypeScript 인터페이스

```typescript
type InvestmentOpinion = 'BUY' | 'HOLD' | 'WATCH';

interface StockReport {
  ticker: string;
  opinion: InvestmentOpinion;
  rationale: string;
  riskWarnings: string[];
  technical: TechnicalIndicators;
  sentiment: MarketSentiment;
  reportMarkdown: string;
  generatedAt: string;
}

interface ReportStatus {
  jobId: string;
  status: 'pending' | 'processing' | 'done' | 'error';
  report?: StockReport;
  error?: string;
}
```
````

> **차이**: A는 도메인 용어가 비교적 안정적이고 백엔드와의 계약면이 좁아 표만으로 충분. B는 폴링으로 받는 상태 머신(`pending` → `processing` → `done`)과 응답 인터페이스가 화면 로직을 좌우하므로 타입을 함께 둔다.

---

## 3. 페이지 구조

**목적:** "이 기능은 어느 페이지에 있지?"를 AI가 추론 없이 답할 수 있게 한다. 각 페이지의 핵심 역할을 한 줄로.

**작성 팁**

- 트리 + 한 줄 코멘트가 가장 정보 밀도가 높다.
- 페이지가 1~2개뿐이면 트리도 짧게.
- 페이지 내부 주요 영역(사이드바·모달·패널)이 코드 곳곳에 영향을 준다면 페이지 아래 들여쓰기로 추가한다.

**예시 A — 다중 페이지 (영역 주석 포함)**

````markdown
## 페이지 구조

```
pages/
├── login/          # 이메일+비밀번호 로그인 (세션 30분)
├── home/           # 메인 — AI 어시스턴트 목록(최대 3개) + 업데이트 내역 탭
├── assistant/      # 채팅 페이지
│   ├── 사이드바: 홈/채팅/검색/내비게이션 토글
│   ├── 채팅 입력/출력 (Thread 기반)
│   ├── 대화 검색 & 편집 모달
│   └── 답변 기능: 복사, 재시도, 피드백, 추론 과정 패널
├── expert/         # 전문가 모드 (답변 확장)
│   ├── document/   # 문서 — Tiptap 에디터, AI 편집, Google Docs/docx 내보내기
│   ├── spread/     # 스프레드시트 — Univer, 차트, Google Sheets/Excel/CSV 내보내기
│   └── graph/      # 지식 그래프 — Sigma.js + Graphology 시각화
├── updates/        # 업데이트 내역 목록 & 상세
└── error/          # 에러 페이지
```
````

**예시 B — 단일 페이지**

````markdown
## 페이지 구조

```
pages/
└── StockAnalysis/    # 메인 — 종목 분석 리포트 + 기술 지표 + 감성 분석 사이드바
```
````

> **차이**: 페이지가 많을수록 영역·외부 라이브러리·외부 연동을 함께 적는 게 유리하다. 단일 페이지 프로젝트는 짧게 두고, 대신 UI 패턴 섹션을 따로 만든다(아래 6번).

---

## 4. API 패턴

**목적:** 공통 규칙([api-rules.md](../rules/api-rules.md))과 다른 프로젝트 전용 패턴을 적는다. 파일 분리·HTTP 클라이언트·에러·인증 처리.

**작성 팁**

- 공통 규칙과 동일하면 적지 않는다.
- 클라이언트 인스턴스 이름과 위치를 명시한다 (`customAxios` from `src/api/config/axios.config.ts`).
- 비동기·폴링·WebSocket·SSE처럼 일반 REST와 다른 패턴이 있으면 그 부분을 강조한다.

**예시 A — 표준 REST + 인터셉터**

```markdown
## API 패턴

- **파일 분리**: `*.api.ts` (API 함수) + `*.query.ts` (TanStack Query 훅)
- **HTTP 클라이언트**: `customAxios` (`src/api/config/axios.config.ts`)
  - `customAxios.get<T>`, `.post<T>`, `.put<T>`, `.delete<T>`, `.patch<T>`, `.upload<T>` 사용
  - Axios 인터셉터에서 토큰 자동 주입 + 401 시 refresh 처리
- **에러**: `HttpError` 클래스로 통일 (`src/api/utils/error/HttpError.ts`)
```

**예시 B — 비동기 폴링**

```markdown
## API 패턴

- 클라이언트: `src/api/stockApi.ts`에 API 함수 정의
- 비동기 리포트 생성: `useQuery` + `refetchInterval: 3000`, `status === 'done'`이면 폴링 중단
- 작업 상태 추적은 별도 훅(`useReportStatus`) 또는 단일 훅(`useStockReport`) 내부에서 처리
- 에러 처리는 API 경계에서만 — 응답 파싱 실패 시 콘솔 로그 + 사용자에게 에러 상태 노출
```

> **차이**: A는 다중 도메인 표준 패턴(파일 분리 컨벤션이 중요), B는 단일 워크플로의 비동기 처리(폴링 중단 조건이 중요).

---

## 5. 디렉토리 구조 / 경로 별칭

**목적:** AI가 새 파일을 어디에 둘지 판단할 수 있게 한다. 별칭은 import 경로를 잘못 쓰지 않게.

**작성 팁**

- 트리 + 한 줄 코멘트.
- `pages/`·`components/`·`stores/` 같은 일반적인 폴더만 있으면 생략 가능 — 공통 규칙으로 충분.
- 별칭 표는 `tsconfig.json` 또는 `vite.config.ts`의 정의를 그대로 옮긴다.

**예시 (공용)**

````markdown
## 디렉토리 구조

```
src/
├── api/          # Axios 인스턴스 및 API 함수
├── components/   # 공유 컴포넌트
├── hooks/        # 커스텀 훅 (useIsMobile, useDateGroupedThreads 등)
├── pages/        # 라우트 페이지 (폴더명 kebab-case)
├── stores/       # Zustand 스토어 (use[Domain]Store 패턴)
├── types/        # 공유 타입 정의
└── utils/        # 유틸리티 함수
```

## 경로 별칭 (Path Aliases)

| 별칭 | 경로 |
|------|------|
| `@/*` | `src/*` |
| `@api/*` | `src/api/*` |
| `@components/*` | `src/components/*` |
| `@hooks/*` | `src/hooks/*` |
| `@stores/*` | `src/stores/*` |
````

---

## 6. (선택) UI 패턴

**목적:** 화면 구성 규칙 중 *코드에서 반복적으로 강제해야 하는* 부분을 적는다. 디자인 시스템 컴포넌트가 부족해 색상·뱃지·로딩 표시를 컴포넌트 단위로 통일해야 할 때 유효하다.

**언제 추가하는가**

- 같은 시각 규칙(예: "BUY는 green, HOLD는 yellow")이 여러 컴포넌트에서 반복될 때.
- 디자인 토큰을 하드코딩하지 못하게 강제할 때 (`--color-buy` CSS 변수만 사용).
- 로딩·에러 UI 패턴이 페이지마다 다르면 안 될 때.

**예시 B — 분석 대시보드**

```markdown
## UI 패턴

### OpinionBadge — 투자 의견 표시

`BUY` / `HOLD` / `WATCH`는 시각적으로 구분되는 색상으로 표시한다. **색상은 SCSS CSS 변수(`--color-buy`, `--color-hold`, `--color-watch`)로 정의하고 컴포넌트에 하드코딩하지 않는다.**

### 기술 지표 — 값 + 시그널 상태

각 지표 카드는 **지표명 / 현재값 / 상태 뱃지** 구조로 표시한다.

- SMA5 > SMA20: 상승(green), SMA5 < SMA20: 하락(red)
- RSI > 70: 과매수(orange), RSI < 30: 과매도(blue), 그 외: 중립(gray)

### 리포트 생성 로딩

최대 60초 대기. 진행 단계를 사용자에게 명확히 표시한다("데이터 수집 중", "지표 계산 중", "리포트 생성 중"). 에러 시 재시도 버튼을 제공한다.
```

> 채팅 플랫폼(A)은 별도 UI 패턴 섹션이 없다 — Mantine UI를 표준으로 쓰고 있어 컴포넌트 단에서 자연스럽게 통일된다. 디자인 시스템이 강하면 이 섹션은 생략한다.

---

## 7. (선택) 프로젝트 설정 / PR 형식

**목적:** 공통 규칙과 다른 프로젝트 전용 명령어·환경변수·PR 템플릿이 있을 때만 적는다.

**예시 — PR 본문 형식**

````markdown
## PR 작성 형식

PR 본문은 `.github/pull_request_template.md` 기반으로 아래 형식을 따른다.

```markdown
## #️⃣ 연관된 이슈

> [JIRA-KEY](jira 링크)

## 📋 작업 개요

> PR 목적과 의도를 간단히 설명.

## 📝 작업 내용

### 주요 작업
- 항목 1

### 추가 작업 (없으면 섹션 생략)
- 항목 1
```

**규칙:**
- `📋 작업 개요`는 인용 블록(`>`)으로 서술체 작성
- `📝 작업 내용`은 주요/추가 작업으로 나눠 불릿 리스트로 작성
- 스크린샷 섹션은 첨부할 내용 없으면 생략
````

---

## 채우는 순서 권장

1. **제품 개요**부터. 한 줄·한 단락으로 시작해 다음 작업 흐름이 잡힌 뒤 다듬는다.
2. **핵심 도메인 개념** — 코드를 훑으며 자주 등장하는 식별자부터 표에 옮긴다.
3. **디렉토리 구조 / 경로 별칭** — `tsconfig.json`을 보고 그대로 옮기면 끝.
4. **페이지 구조** — `pages/` 폴더 트리를 보고 한 줄씩.
5. **API 패턴** — 공통 규칙과 다른 부분만.
6. (필요 시) UI 패턴, PR 형식 등.

빈 섹션은 굳이 채우지 말고 HTML 코멘트만 남긴다. 작성하지 않은 섹션은 AI가 무시한다.
