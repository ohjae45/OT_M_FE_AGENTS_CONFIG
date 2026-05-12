# FrontEnd 공통 규칙

이 문서는 프론트엔드 프로젝트 전반에 공통으로 적용하는 기본 규칙을 정의한다.

## 규칙 적용 우선순위

- 외부 라이브러리, 브라우저 표준, 프레임워크 API에서 정한 이름은 임의로 변경하지 않는다.
- 프로젝트 내부에서 새로 작성하는 이름에는 이 문서의 네이밍 규칙을 적용한다.
- 기존 코드와 충돌하는 경우에는 같은 파일 또는 같은 도메인의 기존 패턴을 우선 확인한다.

## 프로젝트 설정

- 패키지 매니저는 `pnpm`만 사용한다.
- `npm`, `yarn`은 사용하지 않는다.
- 의존성 설치, 추가, 제거, 스크립트 실행은 모두 `pnpm` 명령으로 수행한다.
- 프로젝트별 실행 스크립트는 해당 프로젝트의 `package.json`을 기준으로 확인한다.

## 네이밍 규칙

### 기본 식별자

- 변수와 함수는 `camelCase`를 사용한다.
- 일반 `const` 변수도 `camelCase`를 사용한다.
- 재사용되는 고정 설정값, 매직 넘버 대체값, 환경 설정 상수는 `UPPER_SNAKE_CASE`를 사용한다.
- 클래스, 컴포넌트, 타입, 인터페이스는 `PascalCase`를 사용한다.
- Boolean 변수와 상태 값은 `is`, `has`, `can`, `should` 등 의미가 드러나는 접두사를 사용한다.
- 단, HTML 표준 prop 이름이나 외부 라이브러리 API에서 정한 이름은 그대로 따른다.

### React 관련 네이밍

- 커스텀 훅은 `use` 접두사를 사용한다.
- 이벤트 핸들러 함수는 `handle` 접두사를 사용한다.
- 컴포넌트가 props로 받는 이벤트 콜백은 `on` 접두사를 사용한다.
- props 이름에는 `handle` 접두사를 사용하지 않는다.

### 파일 및 디렉터리명

- **디렉터리명**: 새로 만드는 디렉터리는 `camelCase`를 사용한다.
- **컴포넌트 파일명**: `PascalCase`를 사용한다.
- **커스텀 훅 파일명**: export하는 훅 이름과 동일하게 작성한다. 예: `useSomething.ts`
- **Zustand 스토어 파일명**: 파일명과 훅 이름은 `use[도메인명]Store` 패턴을 따른다.
- **도메인 보조 파일명**: 도메인 관련 보조 파일명은 `도메인명.역할명.ts` 형식을 사용하며, 도메인명은 `camelCase`를 사용한다.
- **역할명**: 역할명은 파일에 담긴 코드 종류가 명확히 드러나는 이름을 사용한다. 예: `types`, `utils`, `api`, `query`, `constants`
- **API 파일**: `api` 파일에는 순수 API 요청 함수만 작성한다.
- **Query 파일**: `query` 파일에는 TanStack Query의 `useQuery`, `useMutation`, Query Key, Query Options 관련 코드를 작성한다.
- **유틸 파일**: 유틸 함수가 하나만 있더라도 파일명은 도메인 기준의 `도메인명.utils.ts` 형식을 사용한다.
- **SCSS 모듈 파일명**: `camelCase`를 사용하며 `*.module.scss` 형식을 사용한다.

## 코드 작성 원칙

### Import 정렬

- import는 외부 라이브러리, alias 경로, 상대 경로 순서로 작성한다.
- 같은 그룹 안에서는 기존 파일의 정렬 패턴을 우선 따른다.
- 사용하지 않는 import는 남기지 않는다.

### 주석 작성

- 모든 주석은 한글로 작성한다.
- 주석은 존댓말 서술형으로 작성하지 않는다.
- 주석은 짧은 문장, 명사형, 동사 원형 중심으로 작성한다.
- 컴포넌트, 훅, 유틸 함수 등 선언부를 설명하는 대표 주석은 import문 아래, 설명 대상 선언부 바로 위에 `/** */` 형식으로 작성한다.
- 대표 주석에는 대상의 역할과 책임을 설명하며, 훅은 상태 흐름, 유틸 함수는 목적과 반환값 성격을 함께 설명한다.
- 파일 전체의 역할이 대표 선언부만으로 드러나지 않는 경우에만 `/** */` 형식의 별도 파일 역할 주석을 작성한다.
- 함수 내부의 보조 주석은 이름만으로 의도가 부족하거나 복잡한 이유를 설명해야 할 때만 `//` 형식으로 작성한다.
- 동일한 의미의 주석은 중복 작성하지 않는다.

### 컴포넌트 작성

- 상태 관리, 이벤트 처리, 조건부 렌더링, 데이터 변환 책임이 한 컴포넌트에 함께 섞이면 하위 컴포넌트, 훅, 유틸 함수로 분리한다.
- 같은 JSX 구조가 2회 이상 반복되면 하위 컴포넌트로 분리한다.

### 추상화와 재사용

- 이미 존재하는 공용 컴포넌트나 유틸이 있으면 우선 재사용한다.
- 요구사항 없는 미래 지향 추상화는 하지 않는다.
- 불필요한 새 공용 컴포넌트는 만들지 않는다.

## Path Alias 관리 규칙

`src/` 바로 아래에 새로운 최상위 폴더를 도입하는 경우, 프로젝트 import 규칙의 일관성을 위해 path alias를 함께 등록한다.

Alias를 추가할 때는 아래 두 설정을 함께 수정한다.

- `tsconfig.json`
- `vite.config.ts`

### TypeScript 설정 기준

- path alias의 기준 파일은 항상 `tsconfig.json`이다.
- `tsconfig.app.json`에는 `compilerOptions.paths`를 중복 선언하지 않는다.
- `tsconfig.app.json`이 있는 프로젝트는 `extends`로 `tsconfig.json`을 참조한다.
- 프로젝트별 세부 옵션이 필요해도 alias 설정은 `tsconfig.json`에만 둔다.

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

`tsconfig.app.json`이 별도로 존재하는 경우에는 아래처럼 공통 설정을 상속한다.

```json
{
  "extends": "./tsconfig.json"
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
@services/
@layouts/
@features/

Bad:
src/pages/assistant/components/
src/components/UserCard/internal/
```
