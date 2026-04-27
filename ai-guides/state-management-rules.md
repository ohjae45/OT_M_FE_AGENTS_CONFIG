# 상태 관리 규칙

이 문서는 상태 관리 도구 선택 기준을 정의한다.

## 기본 규칙

- 전역 클라이언트 상태는 Zustand를 사용한다.
- 서버 상태는 TanStack Query를 사용한다.
- 다른 컴포넌트와 공유할 필요가 없는 단순 UI 상태는 `useState`를 사용한다.
- Zustand 스토어 파일은 `src/stores/` 아래에 둔다.
- Zustand 스토어 이름은 `use[도메인명]Store` 패턴을 따른다.

## 예시

```ts
export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}));

const { data } = useQuery({
  queryKey: ["user", userId],
  queryFn: () => getUser(userId),
});
```
