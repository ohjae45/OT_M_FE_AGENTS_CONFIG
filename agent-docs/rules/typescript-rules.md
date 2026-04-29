# TypeScript 규칙

이 문서는 TypeScript 작성 시 우선 적용할 규칙을 정의한다.

## 타입 안정성

- `any` 사용을 지양하고, 타입을 확정할 수 없는 값은 `unknown`으로 먼저 받는다.
- 외부 라이브러리 타입 결함, 점진적 마이그레이션, 테스트 mock처럼 불가피하게 `any`가 필요한 경우에는 사유 주석을 남기고 범위를 최소화한다.
- `unknown` 값은 타입 가드나 런타임 검증으로 좁힌 뒤 사용한다.
- 외부 API나 중요한 응답처럼 런타임 검증이 필요한 경우에만 스키마 검증 또는 타입 가드를 추가한다.

## Import 규칙

- 타입으로만 사용하는 심볼은 `import type`으로 가져오는 것을 우선한다.

## 타입 선언 기준

- 객체 형태는 `interface`를 우선 사용한다.
- 유니온, 원시 타입 별칭, 유틸 타입 조합은 `type`을 사용한다.
- `enum` 대신 유니온 타입 또는 `as const` 객체를 우선 사용한다.
- 복잡한 상태값은 discriminated union으로 표현한다.
- 변경되면 안 되는 배열과 객체 타입은 `readonly`를 우선 검토한다.
- 리터럴 객체의 형태 검증에는 필요한 경우 `satisfies`를 사용한다.

## 컴포넌트 Props 타입

- 특정 컴포넌트에서만 사용하는 props/config 타입은 컴포넌트 파일 내부에 선언한다.
- 일반 커스텀 컴포넌트의 props 타입은 `컴포넌트이름Props` 형식을 사용한다.
- HTML 기본 태그를 확장한 컴포넌트의 고유 설정 타입은 `컴포넌트이름Config` 형식을 사용한다.
- HTML 기본 태그의 속성과 config를 합친 최종 props 타입이 필요한 경우 `컴포넌트이름Props` 형식을 사용한다.
- 여러 컴포넌트나 훅에서 재사용되는 props/config 타입만 도메인 타입 파일로 분리한다.

## 타입 파일 구조

- 여러 도메인의 타입을 하나의 `types.ts` 파일에 모으지 않는다.
- 여러 파일에서 재사용되는 타입만 도메인 단위 타입 파일로 분리한다.
- 도메인 단위 타입 파일은 `user.types.ts`, `file-storage.types.ts`처럼 `도메인명.types.ts` 형식을 사용한다.
- API 요청/응답 타입은 `도메인명Params`, `도메인명Request`, `도메인명Response`처럼 역할이 드러나게 작성한다.

## 타입 단언 제한

- `as` 타입 단언과 non-null assertion(`!`)은 타입 좁히기나 명시적 분기 처리로 대체하는 것을 우선한다.
- `as` 타입 단언이 불가피한 경우에는 단언 근거를 주석으로 남긴다.

## 함수 작성 기준

- 공개 함수, 훅, 유틸 함수는 반환 타입을 명시한다.

## 권장 tsconfig / ESLint 규칙

- `strict`를 활성화한다.
- `noImplicitAny`를 활성화한다.
- `@typescript-eslint/no-explicit-any`를 활성화한다.
- `@typescript-eslint/consistent-type-imports`를 활성화한다.

## 코드 작성 예시

### 컴포넌트 Props 타입 구성

```ts
import type { ComponentPropsWithoutRef } from "react";
import type { DomainData } from "./domain.types";

/** 일반 커스텀 컴포넌트 props 타입 */
interface DomainProps {
  data: DomainData;
  isSelected?: boolean;
}

/** HTML 기본 태그 확장 컴포넌트의 고유 설정 타입 */
interface FieldConfig {
  label: string;
  errorMessage?: string;
}

/** HTML 기본 태그 속성과 고유 설정을 합친 최종 props 타입 */
type FieldProps = FieldConfig & ComponentPropsWithoutRef<"input">;
```
