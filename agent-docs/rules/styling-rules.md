# 스타일 규칙

이 문서는 프로젝트에서 SCSS를 작성할 때 따라야 할 핵심 규칙을 정의한다.

## 기본 원칙

- 프로젝트에서 직접 작성하는 스타일은 CSS 대신 SCSS로 작성한다.
- 컴포넌트 단위 스타일은 SCSS Modules를 우선 사용한다.
- 외부 라이브러리가 제공하는 CSS는 필요한 경우 import할 수 있다.
- 인라인 스타일은 작성하지 않는다.
- 단, 런타임에 계산되는 CSS 변수, 외부 라이브러리에서 요구하는 style prop은 예외로 허용한다.
- 전역 스타일은 reset, common, font 등 공용 목적에 한해 제한적으로 사용한다.
- 외부 라이브러리, 브라우저 표준, 프레임워크 API에서 정한 이름은 임의로 변경하지 않는다.

## 주석

- 스타일 주석은 `/* 내용 */` 형식으로 작성한다.
- 복잡한 레이아웃, z-index, 브라우저 대응, 임시 예외처럼 의도가 코드만으로 드러나지 않는 경우에만 주석을 작성한다.
- 단순한 컴포넌트 wrapper, title, button 역할은 className으로 표현하고 주석을 작성하지 않는다.
- selector 블록 끝에 종료 주석을 작성하지 않는다.

## 스타일 파일과 네이밍

- 파일명과 디렉터리명은 `frontend-common-rules.md`의 파일 및 디렉터리명 규칙을 따른다.
- 공용 SCSS 파일은 `src/assets/scss/` 아래에 둔다.
- 브라우저 초기화, 공통 스타일, 폰트 스타일은 `reset.scss`, `common.scss`, `font.scss`처럼 공용 목적이 드러나게 작성한다.
- 컴포넌트 단위 스타일은 컴포넌트와 같은 영역에 `.module.scss` 파일로 분리한다.

### 네이밍 컨벤션

- SCSS Modules 파일 내 클래스명은 `camelCase`로 작성한다.
- React 컴포넌트에서 SCSS Modules 클래스는 dot notation으로 접근한다.
- 예: `styles.assistantTitle` (O), `styles['assistant-title']` (X)

| 대상        | 규칙         | 예시             |
| ----------- | ------------ | ---------------- |
| className   | `camelCase`  | `assistantTitle` |
| id          | `kebab-case` | `assistant-root` |
| SCSS 변수명 | `kebab-case` | `$primary-color` |

### 네이밍 축약어

아래 축약어는 className, SCSS 변수명 등 스타일 관련 이름 전반에 적용한다.

| 원어     | 축약어 |
| -------- | ------ |
| table    | `tbl`  |
| input    | `ipt`  |
| checkbox | `chk`  |
| password | `pw`   |
| button   | `btn`  |
| textarea | `txar` |
| title    | `tit`  |
| text     | `txt`  |
| label    | `lbl`  |
| select   | `slt`  |

## 스타일 재사용

- 컴포넌트 전용 `.module.scss` 파일은 다른 컴포넌트에서 직접 import하지 않는다.
- 두 개 이상 컴포넌트가 같은 스타일을 공유해야 하면 공용 목적이 드러나는 별도 스타일 파일로 분리한다.
- 공용 스타일 파일명과 className은 컴포넌트명 기반이 아니라 역할 기반으로 작성한다.
- 같은 모듈 내에서 기존 className을 다른 용도로 재사용할 때는 이름이 여전히 역할을 정확히 표현하는지 확인한다. 적용 범위가 달라졌다면 범용 이름으로 변경한다.
- 예: `SearchBox.module.scss` 재사용 대신 `ControlField.module.scss`, `controlField`, `controlLabel`, `controlInput`
- 예외적으로 임시 재사용이 필요하면 이유를 코드 주석이나 작업 기록에 남긴다.

## mixin

- 스타일 작성 전 공용 `mixin.scss`를 확인하고, 기존 mixin으로 해결 가능하면 우선 사용한다.
- `mixin.scss`에는 다른 SCSS 파일에서 재사용할 mixin, function, variable만 작성한다.
- `@mixin`은 중복 스타일 분리와 추상화에 사용한다.
- `@mixin`은 함수처럼 인자를 받아 재사용할 수 있게 작성한다.
- 인자가 없는 `@mixin`은 단순 묶음 용도로는 사용하지 않는다.
- 단, `visuallyHidden`, `textEllipsis`처럼 명확한 UI 패턴을 재사용하는 경우는 허용한다.

## SCSS 작성

- `.scss`, `.module.scss` 파일은 확장형(Expanded) 스타일로 작성한다.
- 중첩마다 줄바꿈과 들여쓰기를 사용한다.
- 속성명과 속성값 사이에는 공백을 둔다.
- 선언 순서는 `@include > 일반 속성 > 중첩 선택자` 순으로 작성하고, `@include` 뒤에는 개행한다.
- 연산과 관계 선택자를 표현할 때는 좌우에 공백 한 칸을 둔다.

## SCSS 중첩 기준

- 중첩은 기본 2뎁스 이하로 작성한다.
- 3뎁스 중첩은 상태, 가상 요소, 하위 요소를 같은 블록에서 표현해야 할 때만 사용한다.
- 4뎁스 이상 중첩은 작성하지 않는다.
- DOM 구조를 그대로 옮기기 위한 중첩은 작성하지 않는다.
- selector가 길어지면 중첩하지 말고 독립 className을 추가한다.
- `&`는 `&:hover`, `&.isActive`, `&::before`처럼 현재 selector에 직접 붙는 경우만 사용한다.
- 미디어 쿼리의 중첩은 뎁스 계산에 포함하지 않는다.

## 속성 작성 순서

- SCSS의 스타일 속성은 아래 그룹 순서와 대표 순서를 기준으로 작성한다.

| 그룹                   | 대표 순서                                                                                                                                                                                                                                        |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 표시                   | `display`, `justify-content`, `align-items`, `align-content`, `align-self`, `flex-direction`, `flex-wrap`, `flex`, `gap`, `grid-template-columns`, `grid-template-rows`, `grid-column`, `grid-row`, `place-content`, `place-items`, `place-self` |
| 시각                   | `visibility`, `overflow`, `overflow-x`, `overflow-y`, `float`, `clear`                                                                                                                                                                           |
| 위치                   | `position`, `inset`, `top`, `right`, `bottom`, `left`, `z-index`, `transform`, `transform-origin`                                                                                                                                                |
| 박스 모델              | `box-sizing`, `width`, `min-width`, `max-width`, `height`, `min-height`, `max-height`, `aspect-ratio`, `margin`, `padding`, `border`, `border-radius`                                                                                            |
| 배경                   | `background`, `background-color`, `background-image`, `background-position`, `background-size`, `background-repeat`, `box-shadow`                                                                                                                |
| 색상                   | `color`, `fill`, `stroke`, `accent-color`                                                                                                                                                                                                        |
| 폰트                   | `font-style`, `font-weight`, `font-size`, `line-height`, `font-family`                                                                                                                                                                           |
| 텍스트                 | `text-decoration`, `text-indent`, `text-align`, `vertical-align`, `letter-spacing`, `word-spacing`, `word-break`, `word-wrap`, `white-space`, `text-overflow`, `text-transform`                                                                  |
| 이미지/미디어          | `object-fit`, `object-position`                                                                                                                                                                                                                  |
| 사용자 인터페이스/효과 | `appearance`, `outline`, `cursor`, `pointer-events`, `user-select`, `resize`, `opacity`, `transition`, `animation`, `will-change`                                                                                                                |

## 값 작성

### 따옴표

- `url()` 안의 경로는 따옴표 없이 작성한다.

### 색상

- 색상은 헥스코드를 기본으로 사용하고, 축약 가능한 값은 축약한다.
- 투명도가 필요한 색상만 `rgba()`를 사용한다.
- 배경색은 `background-color` 대신 `background`로 작성한다.

### 단위

- UI 크기 단위는 기본적으로 `rem`을 사용한다.
- `1px` border, divider, outline, shadow, 아이콘 위치 보정처럼 시각적으로 고정되어야 하는 값은 `px`를 허용한다.
- `%`, `vw`, `vh`는 각각 부모 기준, 뷰포트 기준 크기에 사용한다.

### 수치 및 특수 값

- border가 없을 때는 `none` 대신 `0`을 사용한다.
- z-index는 10부터 10단위로 사용하고 최대 1000을 넘지 않는다.
- 예외적으로 1000에 가까운 z-index가 필요하면 해당 값이 필요한 이유를 주석으로 남긴다.

## 속성 그룹과 벤더 프리픽스

- `margin`, `padding`, `border`, `background`처럼 의미가 명확한 shorthand 속성은 사용할 수 있다.
- 특정 방향이나 일부 속성만 지정하는 경우에는 longhand 속성을 사용한다.
- `font`는 전역 `font-family`, `font-style`과 중복되기 쉬우므로 개별 속성 사용을 권장한다.
- 벤더 프리픽스 프로퍼티는 일반 프로퍼티보다 먼저 선언한다.
- 벤더 프리픽스가 반복되면 전역으로 사용할 수 있도록 모듈화한다.
