# API 규칙

이 문서는 프론트엔드 프로젝트의 API 요청 함수, TanStack Query 훅, API DTO 타입, HTTP 클라이언트 설정 위치를 정의한다.

## 표준 디렉터리 구조

API 관련 파일은 아래 구조를 기준으로 작성한다.

```txt
src/api/
├── config/
│   ├── axios.config.ts
│   └── query.config.ts
├── constants/
│   └── http.ts
├── domains/
│   └── {domain}/
│       ├── {domain}.api.ts
│       └── {domain}.query.ts
└── types/
    └── {domain}.types.ts
```

- `{domain}` 디렉터리명과 파일명의 도메인 값은 동일하게 맞춘다.

## 파일 책임

- `{domain}.api.ts`에는 순수 API 요청 함수만 작성한다.
- `{domain}.query.ts`에는 TanStack Query의 `useQuery`, `useMutation`, Query Key, Query Options, 캐시 동기화 코드를 작성한다.
- `{domain}.query.ts`에서는 같은 도메인의 `{domain}.api.ts`에 있는 API 요청 함수를 호출한다.
- `{domain}.query.ts`에 HTTP 클라이언트를 직접 호출하는 API 요청 로직을 작성하지 않는다.
- `src/api/types/{domain}.types.ts`에는 API 요청/응답 DTO 타입을 작성한다.
- `src/api/config/axios.config.ts`에는 공용 axios 인스턴스와 `customAxios` wrapper만 작성한다.
- `src/api/config/query.config.ts`에는 TanStack Query `queryClient` 인스턴스만 작성한다.
- `src/api/constants/http.ts`에는 HTTP 관련 공용 상수(`ContentEnum`, `HttpMethod`)만 작성한다.

## DTO 타입 위치

- API 요청/응답 DTO 타입의 표준 위치는 `src/api/types/{domain}.types.ts`이다.
- API 파일 옆에 `src/api/domains/{domain}/{domain}.types.ts`를 만들지 않는다.
- `src/api/domains/types/`에는 새 DTO 타입 파일을 만들지 않는다.
- 컴포넌트 props, 화면 상태, UI 전용 설정 타입은 API DTO 타입 파일에 넣지 않는다.

## HTTP 클라이언트 설정

- 공용 axios 인스턴스는 `src/api/config/axios.config.ts`에서 한 번만 생성한다.
- 인스턴스 위에 `customAxios` wrapper(`get`, `post`, `put`, `delete`, `patch`, `upload`)를 함께 export한다.
- 도메인 API 파일은 `axiosInstance`를 직접 호출하지 않고 `customAxios.*`를 사용한다.
- API base URL은 `import.meta.env.VITE_API_BASE_URL`로 받고, 미설정 환경을 위해 fallback 값을 명시한다.
- HTTP 메서드와 Content-Type은 `as const` 객체(`HttpMethod`, `ContentEnum`)로 정의하고 같은 이름의 type alias를 함께 export한다. `enum` 키워드는 사용하지 않는다.

## TanStack Query 클라이언트

- `QueryClient` 인스턴스는 `src/api/config/query.config.ts`에서 단일로 생성해 `queryClient`로 export한다.
- 컴포넌트나 `main.tsx` 안에서 `new QueryClient()`를 만들지 않는다.
- 기본 옵션(`staleTime`, `refetchOnWindowFocus`, `retry` 등)은 이 파일에서 일괄 관리한다.
