# 상태 관리 규칙

이 문서는 클라이언트 상태와 서버 상태를 구분하고, 각 상태에 맞는 관리 도구 선택 기준을 정의한다.
코드를 생성할 때 이 규칙을 우선 적용한다.

## 클라이언트 상태

- **지역 상태**: 다른 컴포넌트와 공유할 필요가 없는 일시 상태는 `useState`를 사용한다.
- **전역 상태 남용 금지**: 부모-자식 또는 가까운 형제 컴포넌트 사이에서만 필요한 상태는 props와 지역 상태로 관리하고 Zustand로 올리지 않는다.
- **전역 상태**: 앱 전역에서 유지되어야 하는 클라이언트 상태만 Zustand를 사용한다.
- **스토어 액션명**: 액션 함수명은 `set[상태명]`, `reset[상태명]`처럼 동사로 시작한다.
- **스토어 타입**: Zustand 스토어 타입은 상태 타입과 액션 타입을 분리하고 `States & Actions` 형태로 조합한다.

## 서버 상태

- **서버 상태 원칙**: API 응답 데이터, 로딩 상태, 에러 상태는 TanStack Query로 관리한다.
- **중복 관리 금지**: 서버 상태를 Zustand에 복사해서 중복 관리하지 않는다.
- **Query Key**: Query Key와 Mutation Key는 배열을 사용하고, 첫 요소는 요청 목적이 드러나는 kebab-case 식별자로 작성한다.
- **Key 변수 순서**: Query Key와 Mutation Key의 두 번째 요소부터는 API 요청을 구분하는 id, params 같은 변수를 순서대로 넣는다.
- **Mutation 동기화**: Mutation 성공 후에는 연관 Query Key를 무효화하거나 캐시를 갱신해 최신 상태를 동기화한다.
- **GET 훅 반환**: 응답 데이터, 로딩 상태, 에러를 조회 대상 의미가 드러나는 이름으로 반환한다. 예: `domainDetailRes`, `isLoadingDomainDetail`, `domainDetailError`
- **Mutation 훅 반환**: `mutateAsync`를 액션명으로 감싸 반환하고, pending 상태를 액션 기준 이름으로 반환한다. 예: `createDomain`, `isCreatePending`

## 코드 작성 예시

### Zustand 스토어 구성

```ts
import { create } from "zustand";

/** 도메인 상태 타입 */
interface DomainStates {
  isVisible: boolean;
}

/** 도메인 액션 타입 */
interface DomainActions {
  setIsVisible: (isVisible: boolean) => void;
  resetState: () => void;
}

/** 도메인 스토어 */
export const useDomainStore = create<DomainStates & DomainActions>()((set) => ({
  isVisible: false,
  setIsVisible: (isVisible) => set({ isVisible }),
  resetState: () => set({ isVisible: false }),
}));
```
