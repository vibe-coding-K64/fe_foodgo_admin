# Project Guidelines

## Code Style
- Keep edits minimal and consistent with existing files.
- Prefer TypeScript for new frontend source files.
- Keep comments short and only for non-obvious logic.
- Write new code comments in Vietnamese unless the file area clearly uses another language convention.
- Keep import order/style aligned with current Prettier and ESLint configuration.
- Avoid broad refactors when solving a focused issue.

## Architecture
- Main app code is in src/ using Next.js App Router.
- Localized routes are under src/app/[lang]; unlocalized pages/docs are under src/app/(unlocalized).
- Auth and route protection logic live in src/middleware.ts and src/configs/auth-routes.ts.
- i18n config is in src/configs/i18n.ts; keep ltr/rtl behavior correct for en/ar.
- Prisma schema is in prisma/schema.prisma and client setup is in src/lib/prisma.ts.

## Build and Test
- Use pnpm (not npm).
- Install: pnpm install
- Dev server: pnpm dev
- Build: pnpm build
- Start production: pnpm start
- Lint: pnpm lint
- Lint fix: pnpm lint:fix
- Format: pnpm format
- Prisma migrate (dev): pnpm migrate

## Conventions
- Link, do not duplicate: refer contributors to README.md for project overview.
- Prefer small, reviewable diffs and avoid unrelated refactors.
- In next.config.mjs redirects, keep static paths before dynamic /:lang routes.
- Do not assume env vars always exist; add safe fallbacks for URL-based config when reasonable.
- Follow existing guest/public/protected route behavior when editing auth flows.
- If a convention is unclear, ask for confirmation instead of guessing.

## Environment
- Create .env.local from .env.example for local development.
- Common required vars: BASE_URL, API_URL, DATABASE_URL, NEXTAUTH_URL, NEXTAUTH_SECRET, HOME_PATHNAME.

## Team Preferences
- UI outputs should remove demo-only sections and keep screens lean/production-focused.
- Git workflow preference: main only receives merges from develop; no direct commits to main.
- Use feature/* branches for new features and defect/* branches for bug fixes.
- Commit message convention: <type>: <short description> where type is feat, fix, docs, refactor, test, or chore.
