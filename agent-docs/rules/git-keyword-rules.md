# Git Keyword Rules

커밋 메시지, 브랜치명, PR 제목에서 사용하는 작업 키워드 기준입니다.

## 키워드 정의

| 키워드 | 설명 |
|--------|------|
| `feat` | 새로운 기능 추가 (화면 최초 구현 포함) |
| `improve` | 기존 기능 개선 및 수정 |
| `fix` | 버그 및 에러 수정 |
| `style` | 디자인·UI 변경 (기능 영향 없음, 이미 존재하는 화면의 CSS 수정) |
| `refactor` | 코드 리팩터링 (기능 변화 없음) |
| `docs` | 문서·주석 추가 및 수정 (README, 위키 등) |
| `conf` | 설정 파일 수정 (eslint, vite, env, tsconfig 등) |
| `chore` | 유지보수·패키지 관리 (PR 템플릿, GitHub Actions, 의존성 정리 등) |
| `deploy` | 배포 관련 변경 |
| `test` | 테스트 코드 추가·수정 |

## 구분 기준

### style vs feat

| 상황 | 타입 |
|------|------|
| 화면/페이지 최초 구현 | `feat` |
| 이미 존재하는 페이지의 디자인만 수정 | `style` |
| 이미 존재하는 페이지에 기능 추가 | `feat` |
| 퍼블리싱만 완성하고 기능은 미구현 | `style` |

### conf vs chore

| 상황 | 타입 |
|------|------|
| eslint, vite, env, tsconfig 등 설정 파일 수정 | `conf` |
| 패키지 관리, CI, PR 템플릿, 유지보수 작업 | `chore` |
