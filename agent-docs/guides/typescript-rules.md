# TypeScript 규칙

이 문서는 TypeScript 작성 시 반드시 지켜야 할 규칙을 정의한다.

## 기본 규칙

- `any`는 사용하지 않는다.
- 알 수 없는 값은 먼저 `unknown`으로 받는다.
- 필요한 경우 타입 가드로 타입을 좁힌다.
- 타입 전용 import는 반드시 `import type`을 사용한다.
- 객체 형태는 `interface`를 우선 사용한다.
- 유니온, 원시 타입 별칭, 유틸 타입 조합은 `type`을 사용한다.

## 예시

```ts
import type { User } from "./types";

interface UserProps {
  id: string;
  name: string;
}

type Status = "idle" | "loading" | "error";

const data: unknown = response.data;

if (isUser(data)) {
  console.log(data.name);
}
```

## 금지 사항

```ts
const data: any = response.data;
import { User } from "./types";
```
