# Dashboard app

React + Vite + React Router. Vitest with Testing Library for unit tests, Playwright for end-to-end tests.

- `npm run dev` serves on http://localhost:5199
- `npm test` runs unit tests (`src/**/*.test.tsx`)
- `npm run e2e` runs Playwright tests (`e2e/`); it starts the dev server itself
- `npm run typecheck` runs TypeScript

Shared UI lives in `src/components/`. Use the `Button` component for every button. Styles use the tokens in `src/styles.css`.
