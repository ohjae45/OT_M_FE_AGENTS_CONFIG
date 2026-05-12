# /skai-fe-init

## 설명

SKAI 표준 React + TypeScript 프로젝트 초기 세팅을 수행합니다.
"React TS 프로젝트 세팅", "프론트엔드 초기 세팅", "신규 프로젝트 세팅해줘", "vite react 프로젝트 만들어줘", "프론트 보일러플레이트 세팅", "fe 초기 설정", "프로젝트 초기화"처럼 요청할 때 사용합니다.
Prettier, TypeScript, Vite, ESLint, Husky를 SKAI 표준으로 구성하고 기본 src 폴더 구조를 생성합니다.

## 중단 조건

- `src/` 폴더와 `package.json`이 이미 존재하고 의존성도 설치된 상태면, 덮어쓸 파일 목록을 사용자에게 보여주고 확인을 받는다.
- 사용자가 덮어쓰기를 거부하면 중단한다.

## 금지 사항

- 사용자 확인 없이 기존 `src/` 코드를 덮어쓰지 않는다.
- 프로젝트별 비즈니스 로직(도메인 API, 페이지 컴포넌트 등)을 생성하지 않는다.

## 진행 단계

### Phase 1: 현황 확인

현재 디렉토리 상태를 파악한다.

- `package.json` 존재 여부 확인
- `src/` 폴더 존재 여부 확인
- 기존 설정 파일(`.prettierrc`, `tsconfig*.json`, `vite.config*`, `eslint.config.js`) 목록 확인

기존 파일이 있으면 사용자에게 덮어쓸 목록을 보여주고 확인을 받은 뒤 진행한다.

### Phase 2: Vite 프로젝트 초기화

`package.json`이 없을 때만 실행한다.

```bash
pnpm create vite@latest . -- --template react-swc-ts
```

이미 `package.json`이 있으면 건너뛴다.

### Phase 3: SKAI 표준 설정 파일 적용

`설정 파일 기준` 섹션의 내용으로 아래 파일들을 생성/교체한다.

- `.prettierrc`
- `tsconfig.json`
- `tsconfig.app.json`
- `tsconfig.node.json`
- `vite.config.base.ts` (신규 생성)
- `vite.config.ts` (교체)
- `eslint.config.js`

### Phase 4: package.json 스크립트 및 의존성 추가

`scripts` 항목을 아래와 같이 업데이트한다.

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "eslint . --ext .ts,.tsx",
    "preview": "vite preview",
    "typecheck": "tsc -b --noEmit",
    "prepare": "husky install"
  }
}
```

`의존성` 섹션의 패키지를 설치한다.

```bash
pnpm add react-router-dom zustand @tanstack/react-query axios humps
pnpm add -D sass-embedded husky prettier prettier-plugin-import-sort eslint-config-prettier eslint-plugin-import eslint-import-resolver-typescript @types/humps
```

### Phase 5: src 폴더 구조 생성

`src 디렉토리 구조` 섹션 기준으로 폴더를 생성한다. 기존에 이미 있는 폴더는 건너뛴다.
빈 폴더는 `.gitkeep`으로 유지한다.

### Phase 6: Husky pre-push hook 설정

```bash
pnpm dlx husky init
```

`.husky/pre-push` 파일을 아래 내용으로 작성한다.

```sh
pnpm lint && pnpm typecheck && pnpm build
```

### Phase 7: pnpm install

```bash
pnpm install
```

### Phase 8: 완료 보고

생성/수정된 파일 목록을 출력하고 아래 사항을 안내한다.

- 개발 서버 실행: `pnpm dev`
- `vite.config.ts`의 `server.port`와 `proxy.target` 값을 프로젝트에 맞게 조정할 것
- SCSS global mixin이 필요하면 `vite.config.base.ts`의 `css.preprocessorOptions.scss.additionalData`에 추가할 것

---

## 설정 파일 기준 (SKAI 표준)

### .prettierrc

```json
{
  "semi": true,
  "singleQuote": true,
  "jsxSingleQuote": true,
  "trailingComma": "all",
  "printWidth": 120,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf",
  "singleAttributePerLine": true,
  "plugins": ["prettier-plugin-import-sort"],
  "overrides": [
    {
      "files": ["*.ts", "*.tsx", "*.js", "*.jsx"],
      "options": { "singleQuote": true }
    },
    {
      "files": ["*.ts", "*.tsx", "*.js", "*.jsx"],
      "options": { "parser": "babel-ts" }
    }
  ],
  "importSort": {
    ".js, .ts, .tsx": {
      "parser": "typescript",
      "style": "module"
    }
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "paths": {
      "@api/*": ["./src/api/*"],
      "@components/*": ["./src/components/*"],
      "@pages/*": ["./src/pages/*"],
      "@stores/*": ["./src/stores/*"],
      "@hooks/*": ["./src/hooks/*"],
      "@utils/*": ["./src/utils/*"],
      "@images/*": ["./src/assets/images/*"],
      "@scss/*": ["./src/assets/scss/*"],
      "@constants/*": ["./src/constants/*"]
    }
  },
  "files": [],
  "references": [
    { "path": "./tsconfig.app.json" },
    { "path": "./tsconfig.node.json" }
  ]
}
```

### tsconfig.app.json

```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "tsBuildInfoFile": "./node_modules/.tmp/tsconfig.app.tsbuildinfo",
    "target": "ES2022",
    "useDefineForClassFields": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "types": ["vite/client", "node"],
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "erasableSyntaxOnly": true,
    "forceConsistentCasingInFileNames": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedSideEffectImports": true
  },
  "include": ["src"]
}
```

### tsconfig.node.json

```json
{
  "compilerOptions": {
    "tsBuildInfoFile": "./node_modules/.tmp/tsconfig.node.tsbuildinfo",
    "target": "ES2023",
    "lib": ["ES2023"],
    "module": "ESNext",
    "types": [],
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force",
    "noEmit": true,
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "erasableSyntaxOnly": true,
    "forceConsistentCasingInFileNames": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedSideEffectImports": true
  },
  "include": ["vite.config.ts", "vite.config.base.ts"]
}
```

### vite.config.base.ts

공통 alias와 플러그인을 관리한다. 환경별 파일(`vite.config.ts`)에서는 여기에 덧붙이는 옵션만 정의한다.

```typescript
import react from '@vitejs/plugin-react-swc';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import type { Alias, UserConfig } from 'vite';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const sharedAlias: Alias[] = [
  { find: '@api', replacement: path.resolve(__dirname, './src/api') },
  { find: '@components', replacement: path.resolve(__dirname, './src/components') },
  { find: '@pages', replacement: path.resolve(__dirname, './src/pages') },
  { find: '@stores', replacement: path.resolve(__dirname, './src/stores') },
  { find: '@hooks', replacement: path.resolve(__dirname, './src/hooks') },
  { find: '@utils', replacement: path.resolve(__dirname, './src/utils') },
  { find: '@constants', replacement: path.resolve(__dirname, './src/constants') },
  { find: '@images', replacement: path.resolve(__dirname, './src/assets/images') },
  { find: '@scss', replacement: path.resolve(__dirname, './src/assets/scss') },
];

export function createBaseViteConfig(): UserConfig {
  return {
    plugins: [react()],
    resolve: {
      alias: sharedAlias,
    },
    css: {
      preprocessorOptions: {
        scss: {
          api: 'modern-compiler',
        },
      },
    },
  };
}
```

### vite.config.ts

포트와 proxy는 프로젝트마다 다르므로 생성 후 조정한다.

```typescript
import { defineConfig, mergeConfig } from 'vite';
import { createBaseViteConfig } from './vite.config.base';

export default defineConfig(
  mergeConfig(createBaseViteConfig(), {
    server: {
      port: 5173,
      host: true,
      proxy: {
        '/api': {
          target: 'http://localhost:8000',
          changeOrigin: true,
        },
      },
    },
  }),
);
```

### eslint.config.js

```javascript
import js from '@eslint/js';
import importPlugin from 'eslint-plugin-import';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import { defineConfig, globalIgnores } from 'eslint/config';
import globals from 'globals';
import prettier from 'eslint-config-prettier';
import tseslint from 'typescript-eslint';

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx,js,jsx}'],
    extends: [
      js.configs.recommended,
      ...tseslint.configs.recommended,
      reactHooks.configs['recommended-latest'],
      reactRefresh.configs.vite,
      prettier,
    ],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    plugins: { import: importPlugin },
    settings: {
      'import/resolver': {
        typescript: { project: './tsconfig.json' },
        node: { extensions: ['.js', '.jsx', '.ts', '.tsx', '.scss', '.sass'] },
      },
      'import/extensions': ['.js', '.jsx', '.ts', '.tsx', '.scss'],
    },
    rules: {
      'import/no-unresolved': ['error', { caseSensitive: true, caseSensitiveStrict: true }],
      'no-var': 'error',
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      'no-multiple-empty-lines': 'error',
      'react-hooks/exhaustive-deps': 'off',
    },
  },
]);
```

---

## src 디렉토리 구조

```
src/
├── api/
│   ├── config/         # Axios 인스턴스 설정
│   ├── constants/      # HTTP 메서드/콘텐츠 타입 상수
│   ├── domains/        # 도메인별 API 함수 + Query 훅
│   ├── types/          # API 공통 타입
│   └── utils/          # 인증 토큰, 에러 처리 유틸
├── assets/
│   ├── fonts/
│   ├── images/
│   └── scss/
├── components/
│   └── common/
├── constants/
├── hooks/
├── layouts/
├── pages/
├── routes/
├── stores/
└── utils/
```

---

## 의존성

### dependencies

| 패키지 | 용도 |
|--------|------|
| `react-router-dom` | 라우팅 |
| `zustand` | 전역 상태 관리 |
| `@tanstack/react-query` | 서버 상태 관리 |
| `axios` | HTTP 클라이언트 |
| `humps` | camelCase ↔ snake_case 자동 변환 |

### devDependencies

| 패키지 | 용도 |
|--------|------|
| `sass-embedded` | SCSS 컴파일 |
| `husky` | git hooks |
| `prettier` | 코드 포맷터 |
| `prettier-plugin-import-sort` | import 정렬 |
| `eslint-config-prettier` | ESLint-Prettier 충돌 방지 |
| `eslint-plugin-import` | import 규칙 |
| `eslint-import-resolver-typescript` | TS path alias 해석 |
| `@types/humps` | humps 타입 정의 |
