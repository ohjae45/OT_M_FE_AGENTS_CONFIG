# API 규칙

이 문서는 프론트엔드 프로젝트의 API 요청 함수, TanStack Query 훅, API DTO 타입 위치를 정의한다.

## 표준 디렉터리 구조

API 관련 파일은 아래 구조를 기준으로 작성한다.

```txt
src/api/
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

## DTO 타입 위치

- API 요청/응답 DTO 타입의 표준 위치는 `src/api/types/{domain}.types.ts`이다.
- API 파일 옆에 `src/api/domains/{domain}/{domain}.types.ts`를 만들지 않는다.
- `src/api/domains/types/`에는 새 DTO 타입 파일을 만들지 않는다.
- 컴포넌트 props, 화면 상태, UI 전용 설정 타입은 API DTO 타입 파일에 넣지 않는다.
