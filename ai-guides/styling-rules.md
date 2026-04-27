# 스타일 규칙

이 문서는 CSS, SCSS 작성 시 따라야 할 핵심 규칙을 정의한다.
SCSS는 CSS 컨벤션을 기본으로 따르며, 중첩과 `@include`, `@mixin` 사용 방식만 추가로 적용한다.

## 기본 원칙

- 스타일은 SCSS Modules를 우선 사용한다.
- 인라인 스타일 사용은 지양한다.
- 전역 스타일은 reset, common, font 등 공용 목적에 한해 제한적으로 사용한다.
- class, id, SCSS 변수명은 `kebab-case`를 사용한다.
- React에서 케밥 케이스 클래스는 `styles['class-name']` 형태로 접근한다.

## 파일 규칙

- CSS 파일명은 카멜 기법을 사용한다.
- 공용 SCSS 파일은 `src/assets/scss/` 아래에 둔다.
- 컴포넌트 단위 스타일은 `.module.scss` 파일로 분리한다.
- SCSS module 파일명은 프로젝트 기존 규칙을 우선 따른다.

## 스타일 재사용 기준

- 컴포넌트 이름을 가진 `.module.scss` 파일은 해당 컴포넌트 전용으로 간주한다.
- 한 컴포넌트가 다른 컴포넌트의 `.module.scss` 파일을 직접 import하는 방식은 금지한다.
- 두 개 이상 컴포넌트가 같은 스타일을 공유해야 하면, 기존 컴포넌트 스타일 파일을 재사용하지 말고 공용 목적이 드러나는 별도 스타일 파일로 분리한다.
- 공용 스타일 파일명과 클래스명은 컴포넌트명 기반이 아니라 역할 기반으로 작성한다.
- 예: `SearchBox.module.scss` 재사용 대신 `ControlField.module.scss`, `control-field`, `control-label`, `control-input`, `helper-text`
- 예외적으로 임시 재사용이 필요하면 이유를 코드 주석이나 작업 기록에 남기고, 같은 작업 안에서 공용 스타일로 정리하는 것을 우선한다.

## CSS 작성 규칙

- CSS는 한 줄 형식으로 작성한다.
- 선택자 선언 뒤에는 한 칸 공백을 둔다.
- 속성명, 콜론, 값 사이에는 공백을 두지 않는다.
- 속성들 사이에는 공백을 두지 않는다.
- 속성 순서는 아래 흐름을 따른다.
  - 표시
  - 시각적
  - 위치
  - 박스 모델
  - 배경
  - 색상/폰트
  - 사용자 인터페이스
  - 기타 속성

## SCSS 작성 규칙

- SCSS는 확장형(Expanded) 스타일로 작성한다.
- 줄바꿈과 들여쓰기를 사용한다.
- 속성명과 속성값 사이에는 공백을 둔다.
- 선언 순서는 `@include > 속성 > 중첩 선택자` 순으로 작성한다.
- `@include` 뒤에는 개행한다.
- 중첩은 최대 6뎁스까지 권장한다.

## 값 작성 규칙

- 공백이 포함된 글꼴명, 한글 글꼴명, 데이터 타입, `filter` 파라미터 값은 작은따옴표를 사용한다.
- 앳지시어(`@charset`, `@import`, `@use`)는 큰따옴표를 사용한다.
- 축약 가능한 색상 코드는 축약한다.
- 투명도가 필요할 때만 `rgba()`를 사용한다.
- 폰트 크기는 `rem`을 사용한다.
- border가 없을 때는 `none` 대신 `0`을 사용한다.
- z-index는 10부터 10단위로 사용한다.

## mixin 규칙

- `@mixin`은 중복 스타일 분리와 추상화에 사용한다.
- 인자가 없는 `@mixin`은 지양한다.

## 예시

```tsx
import styles from "./assistant.module.scss";

export function Assistant() {
  return <section className={styles["section-assistant"]}>어시스턴트</section>;
}
```

```scss
.section-assistant {
  @include position(relative);

  display: flex;
  background: #313131;

  .tit-assistant {
    color: #818181;
    font-size: 2.2rem;
  }
}
```

## 금지 사항

- 인라인 스타일 사용
- class, id를 camelCase 또는 PascalCase로 작성하는 방식
- 공통 스타일로 해결 가능한데 컴포넌트마다 중복 스타일을 반복 작성하는 방식
- 특정 컴포넌트 전용 `.module.scss` 파일을 다른 컴포넌트에서 공용 스타일처럼 가져다 쓰는 방식
- 인자가 없는 `@mixin`
- 과도한 중첩
- `z-index: 9999` 같은 임의의 큰 값 사용
