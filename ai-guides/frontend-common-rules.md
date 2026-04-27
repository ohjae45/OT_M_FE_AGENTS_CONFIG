# FrontEnd 공통 규칙

이 문서는 프론트엔드 프로젝트 전반에 공통으로 적용하는 기본 규칙을 정의한다.

## 프로젝트 설정

- 패키지 매니저는 `pnpm`만 사용한다.
- `npm`, `yarn`은 사용하지 않는다.
- 주요 명령어는 아래와 같다.
  - `pnpm dev`
  - `pnpm build`
  - `pnpm lint`
  - `pnpm typecheck`
- 기본 PR 대상 브랜치는 `dev`이다.

## 네이밍 규칙

- 변수와 함수는 `camelCase`를 사용한다.
- 클래스, 컴포넌트, 타입, 인터페이스는 `PascalCase`를 사용한다.
- 상수는 `UPPER_SNAKE_CASE`를 사용한다.
- 커스텀 훅은 `use` 접두사를 사용한다.
- 컴포넌트 파일명은 `PascalCase`를 사용한다.
- SCSS 모듈 파일명은 `camelCase`를 사용하며 `*.module.scss` 형식을 사용한다.

## Path Alias 관리 규칙

`src/` 바로 아래에 새로운 최상위 폴더를 도입하는 경우, 프로젝트 import 규칙의 일관성을 위해 path alias를 함께 등록한다.

Alias를 추가할 때는 아래 두 설정을 함께 수정한다.

- `tsconfig.json` 또는 `tsconfig.app.json`
- `vite.config.ts`

### 예시

```json
{
  "compilerOptions": {
    "paths": {
      "@services/*": ["src/services/*"]
    }
  }
}
```

```ts
{
  find: '@services',
  replacement: path.resolve(__dirname, './src/services'),
}
```

단, 특정 페이지나 컴포넌트 내부 전용 폴더에는 alias를 추가하지 않는다.

```txt
Good:
src/services/
src/layouts/
src/features/

Bad:
src/pages/assistant/components/
src/components/UserCard/internal/
```

## 코드 작성 원칙

- 모든 주석은 한글로 작성한다.
- 파일 상단 주석은 파일 전체의 역할과 책임을 설명하는 형태로 작성한다.
- 컴포넌트 상단 주석은 해당 컴포넌트의 역할과 책임을 설명하는 형태로 작성한다.
- 훅 상단 주석은 해당 훅의 역할과 상태 흐름을 설명하는 형태로 작성한다.
- 유틸 함수 상단 주석은 해당 함수의 목적과 반환값 성격을 설명하는 형태로 작성한다.
- 변수, 상태, ref 주석은 이름만으로 의도가 충분히 드러나지 않는 경우에만 작성한다.
- 동일한 의미의 주석은 파일, 컴포넌트, 훅, 함수에 중복 작성하지 않는다.
- 인라인 주석은 필요한 경우에만 최소한으로 작성한다.
- WHY 설명은 꼭 필요한 경우에만 짧고 명확하게 작성한다.
- 컴포넌트는 단일 책임 원칙을 지향한다.
- 컴포넌트가 길어지거나 역할이 많아지면 분리를 검토한다.
- 이미 존재하는 공용 컴포넌트나 유틸이 있으면 우선 재사용한다.

## 금지 사항

- `npm`, `yarn` 사용 금지
- 요구사항 없는 미래 지향 추상화 금지
- 불필요한 전역 스타일 작성 금지
- 불필요한 새 공용 컴포넌트 생성 금지
