# Frontend Migration Plan: Vite + JSX → Next.js + TSX

> **Status (2026-05-01): COMPLETE.** All phases 0–6 finished. `frontend/` is a fully working Next.js 15 + TypeScript (strict mode, zero `tsc` errors) project. `template/frontend/` has been synced and is the canonical template used by `start.sh`.

This plan converts the existing Vite/React/JSX frontend in [frontend/](frontend/) into a TypeScript Next.js (App Router) project, while keeping the Django backend unchanged. The goal is the smallest set of mechanical steps that gets you from "what works today" to "running on Next.js in TypeScript".

The current frontend is a fairly standard SPA: React 19, react-router-dom v6, Tailwind, Radix/shadcn-style components in [frontend/src/components/ui/](frontend/src/components/ui/), `@tanstack/react-query`, `axios` with cookie-based refresh, and lazy-loaded pages in [frontend/src/pages/](frontend/src/pages/). Nothing about it is exotic — that means the migration should be a few focused phases, not a rewrite.

---

## Part 1 — Read this first: pitfalls, do's, and don'ts

### The five things that bite people on this exact migration

1. **Server vs. client components.** In Next.js App Router, every component is a Server Component by default. Anything that uses `useState`, `useEffect`, `useContext`, browser APIs (`window`, `localStorage`, `document`), event handlers, or React Context **must** start with `'use client'`. Your [AuthContext](frontend/src/contexts/AuthContext.jsx), [SiteThemeContext](frontend/src/contexts/SiteThemeContext.jsx), [useToast](frontend/src/hooks/useToast.jsx), and every page that uses these hooks are all client components. Add `'use client'` as the very first line.

2. **Env vars must be renamed.** Vite's `import.meta.env.VITE_*` becomes Next.js's `process.env.NEXT_PUBLIC_*`. Anything not prefixed with `NEXT_PUBLIC_` is **server-only** and won't be visible in the browser. The two affected spots are [frontend/src/services/api.js:15](frontend/src/services/api.js#L15) (`VITE_API_URL`) and [frontend/src/pages/admin/AdminLayout.jsx:31](frontend/src/pages/admin/AdminLayout.jsx#L31) (`VITE_DJANGO_ADMIN_URL`).

3. **react-router-dom is gone.** Replace it with file-based routing under `app/`. `useNavigate` → `useRouter().push`, `useLocation` → `usePathname` + `useSearchParams`, `useParams` → the `params` prop or `useParams` from `next/navigation`, `<Link>` → `next/link`, `<Navigate>` → `redirect()` from `next/navigation`. Don't try to keep react-router alongside Next — pick one router.

4. **`localStorage` / `window` access during render.** Server Components and even Client Components run on the server during the first render. Code like the `readInitialThemeState()` in [frontend/src/contexts/SiteThemeContext.jsx:15](frontend/src/contexts/SiteThemeContext.jsx#L15) — which already has a `typeof window === 'undefined'` guard, good — is the right pattern. Read storage **inside `useEffect`**, not in the initial state, or you'll get hydration mismatches.

5. **Cookie refresh + CORS.** Your axios client uses `withCredentials: true` and a refresh cookie. That keeps working in Next.js, **but** dev requests now go through Next's port (e.g. `:3000`), not Vite's `:5555`. Re-check `CORS_ALLOWED_ORIGINS`, `CSRF_TRUSTED_ORIGINS`, and your refresh-cookie `Domain`/`SameSite` settings on the Django side. Use a Next.js rewrite (see Phase 4) so the browser keeps calling `/api` on the same origin and you don't need to touch CORS at all.

### Do

- **Migrate one folder at a time.** Get the project booting on Next.js with everything still in `.jsx` (Next supports JSX out of the box). Then convert files to `.tsx` in a second pass.
- **Keep your existing Tailwind config.** [tailwind.config.js](frontend/tailwind.config.js), [postcss.config.js](frontend/postcss.config.js), [components.json](frontend/components.json), and [src/index.css](frontend/src/index.css) carry over almost unchanged — only the `content` glob needs updating.
- **Keep the `@/*` alias.** Set `paths` in `tsconfig.json` so existing imports like `@/lib/siteTheme` keep working.
- **Use TypeScript's `strict: true` from day one** but allow JSX during the move. `allowJs: true` lets `.jsx` and `.tsx` coexist while you convert.
- **Type the easy stuff first** — services and contexts give the biggest win. Pages can stay `any`-ish during the move.

### Don't

- **Don't use `getServerSideProps` / `getStaticProps`.** Those are Pages Router. You're on App Router; data fetching happens in Server Components or with `react-query` in Client Components.
- **Don't try to SSR the auth gate.** Your auth is cookie-based with an in-memory access token. SSR-ing protected pages means re-implementing auth on the server. For this migration, keep auth client-side — protected pages render a loading state, then redirect on the client. SSR-aware auth is a separate, later project.
- **Don't add a state library or rewrite contexts.** `AuthContext` and `SiteThemeContext` work fine; just add `'use client'` and convert to `.tsx`.
- **Don't convert every component to a Server Component.** Most of your tree (anything below a context provider) is unavoidably client. Trying to push the boundary deep is a rabbit hole — leave the entire `app/(routes)/*` tree as client components for v1.
- **Don't delete the Vite project until Next.js is fully running.** Keep both side-by-side in a branch until you've verified login, register, theme switching, dashboard, admin, and payment flows work.
- **Don't bother with `next/image` for migration v1.** Plain `<img>` tags work. Optimize images after the migration is stable.

---

## Phase 0 — Prep ✓ (30 min)

1. Confirm the current frontend builds and runs (`./start_frontend.sh`).
2. Decide on a folder layout. Recommended: rename `frontend/` to `frontend-vite/` and create a fresh `frontend/` for the Next.js app. Keeps both runnable until cutover.

---

## Phase 1 — Bootstrap the Next.js project ✓ (1 hour)

1. From the repo root: `npx create-next-app@latest frontend --typescript --tailwind --app --src-dir --import-alias "@/*"`. Say **no** to ESLint if you want; you can copy the existing one later. Say **no** to Turbopack unless you want to debug it separately.
2. `cd frontend && npm run dev` — confirm the default Next page loads on `http://localhost:3000`.
3. Update [start_frontend.sh](start_frontend.sh) and [start.sh](start.sh) to run `npm run dev` from the new `frontend/` (Next defaults to port 3000; change with `next dev -p 5555` if you want to keep the old port).
4. Copy these files from `frontend-vite/` into the new `frontend/`, overwriting the defaults:
   - [tailwind.config.js](frontend/tailwind.config.js) — change `content` to `['./src/**/*.{js,ts,jsx,tsx,mdx}']`
   - [postcss.config.js](frontend/postcss.config.js)
   - [components.json](frontend/components.json)
   - [src/index.css](frontend/src/index.css) → rename to `src/app/globals.css` (replacing the one create-next-app made)
   - `.env` and `.env.example` — rename `VITE_*` keys to `NEXT_PUBLIC_*`
5. Install runtime deps (everything **except** `react-router-dom`, `@vitejs/*`, `vite`):
   ```
   npm install axios @tanstack/react-query @tanstack/react-table \
     @radix-ui/react-avatar @radix-ui/react-dialog @radix-ui/react-dropdown-menu \
     @radix-ui/react-label @radix-ui/react-separator @radix-ui/react-slider \
     @radix-ui/react-slot @radix-ui/react-toast \
     class-variance-authority clsx lucide-react recharts \
     tailwind-merge tailwindcss-animate
   ```

**Done when:** `npm run dev` shows the default Next.js page styled with Tailwind.

---

## Phase 2 — Port shared code ✓ (1–2 hours)

Goal: get every non-routing file into the new `src/` tree, keep extensions as-is.

1. Copy these folders from `frontend-vite/src/` into `frontend/src/`:
   - `components/` (all of it)
   - `contexts/`
   - `hooks/`
   - `lib/`
   - `services/`
   - `utils/`
   - `assets/`
2. Add `'use client'` as the **first line** of every file in `contexts/`, `hooks/`, and any `components/*.jsx` that uses state, effects, or browser APIs. Quick rule: if it imports `react` and uses `useState`/`useEffect`/`useContext`/event handlers, mark it.
3. In [services/api.js](frontend/src/services/api.js), change `import.meta.env.VITE_API_URL` → `process.env.NEXT_PUBLIC_API_URL`.
4. In [pages/admin/AdminLayout.jsx](frontend/src/pages/admin/AdminLayout.jsx) (which you'll move in Phase 3), change `VITE_DJANGO_ADMIN_URL` → `NEXT_PUBLIC_DJANGO_ADMIN_URL`.

**Done when:** TypeScript compile passes (it should — `allowJs` is on by default in create-next-app's tsconfig). Don't worry about runtime yet; nothing renders these files.

---

## Phase 3 — Replace routing with the App Router ✓ (2–4 hours)

This is the biggest phase. Map each route in [src/App.jsx:54-103](frontend/src/App.jsx#L54-L103) to a folder under `src/app/`.

### 3.1 Build the root layout

Create `src/app/layout.tsx`:

```tsx
import './globals.css'
import { Providers } from './providers'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
```

Create `src/app/providers.tsx` — this is where everything from [main.jsx](frontend/src/main.jsx) and the provider stack from [App.jsx:46-50](frontend/src/App.jsx#L46-L50) goes:

```tsx
'use client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider } from '@/contexts/AuthContext'
import { SiteThemeProvider } from '@/contexts/SiteThemeContext'
import { ToastProvider } from '@/hooks/useToast'
import { useState } from 'react'

export function Providers({ children }: { children: React.ReactNode }) {
  const [client] = useState(() => new QueryClient({
    defaultOptions: { queries: { staleTime: 1000 * 60 * 2, retry: 1 } },
  }))
  return (
    <QueryClientProvider client={client}>
      <AuthProvider>
        <SiteThemeProvider>
          <ToastProvider>{children}</ToastProvider>
        </SiteThemeProvider>
      </AuthProvider>
    </QueryClientProvider>
  )
}
```

### 3.2 Create a layout for routes that show the navbar

Most pages share the navbar; three don't (`/reset-password`, `/forgot-password`, `/auth/social/callback` — see [App.jsx:41-44](frontend/src/App.jsx#L41-L44)).

- Create `src/app/(with-nav)/layout.tsx` — contains `<Navbar />` and `<main className="pt-16">{children}</main>`.
- Create `src/app/(no-nav)/layout.tsx` — just `<main>{children}</main>`.

The parentheses make these "route groups" — they don't appear in the URL.

### 3.3 Create one folder per page

Inside the right route group, create `page.tsx` (or `page.jsx` for now) for each:

| Old route | New file |
|---|---|
| `/` | `app/(with-nav)/page.tsx` |
| `/login` | `app/(with-nav)/login/page.tsx` |
| `/register` | `app/(with-nav)/register/page.tsx` |
| `/verify-email` | `app/(with-nav)/verify-email/page.tsx` |
| `/pricing` | `app/(with-nav)/pricing/page.tsx` |
| `/payment/success` | `app/(with-nav)/payment/success/page.tsx` |
| `/payment/failed` | `app/(with-nav)/payment/failed/page.tsx` |
| `/dashboard` | `app/(with-nav)/dashboard/page.tsx` |
| `/profile` | `app/(with-nav)/profile/page.tsx` |
| `/forgot-password` | `app/(no-nav)/forgot-password/page.tsx` |
| `/reset-password` | `app/(no-nav)/reset-password/page.tsx` |
| `/auth/social/callback` | `app/(no-nav)/auth/social/callback/page.tsx` |
| `/admin` | `app/(with-nav)/admin/layout.tsx` + `page.tsx` |
| `/admin/users` | `app/(with-nav)/admin/users/page.tsx` |
| `/admin/users/:userId` | `app/(with-nav)/admin/users/[userId]/page.tsx` |
| `/admin/payments` | `app/(with-nav)/admin/payments/page.tsx` |
| `/admin/settings` | `app/(with-nav)/admin/settings/page.tsx` |

Each `page.tsx` is tiny — it just imports and renders the page component you already have:

```tsx
'use client'
import Login from '@/pages/Login'
export default function Page() { return <Login /> }
```

This lets you keep the existing page files in `src/pages/` untouched for now and fix routing inside them in step 3.4. Once it's all working you can flatten the page component into the `page.tsx` file directly.

### 3.4 Replace router hooks inside page/component files

Search and replace across the files listed by `grep` (you already have the list — pages, Navbar, AdminRoute, ProtectedRoute, UsageBanner):

| Old | New |
|---|---|
| `import { useNavigate } from 'react-router-dom'` | `import { useRouter } from 'next/navigation'` |
| `const navigate = useNavigate()` | `const router = useRouter()` |
| `navigate('/foo')` | `router.push('/foo')` |
| `navigate(-1)` | `router.back()` |
| `useLocation().pathname` | `usePathname()` from `'next/navigation'` |
| `useLocation().search` / query parsing | `useSearchParams()` from `'next/navigation'` |
| `useParams()` | `useParams()` from `'next/navigation'` (same name, different import) |
| `import { Link } from 'react-router-dom'` | `import Link from 'next/link'` |
| `<Link to="/foo">` | `<Link href="/foo">` |
| `<Navigate to="/x" replace />` | call `router.replace('/x')` in a `useEffect` |

For protected/admin guards in [ProtectedRoute.jsx](frontend/src/components/ProtectedRoute.jsx) and [AdminRoute.jsx](frontend/src/components/AdminRoute.jsx), the pattern becomes: in a `useEffect`, if not authed call `router.replace('/login')`; otherwise render `children`. Same logic, different API.

### 3.5 Delete the old App.jsx and main.jsx

Once every route renders, delete `src/App.jsx`, `src/main.jsx`, and the `src/pages/` shim files (move their content into the corresponding `page.tsx` files). Also delete `index.html` and [vite.config.js](frontend/vite.config.js) — Next handles both.

**Done when:** every URL from the old app loads on Next, navbar shows/hides on the right pages, and the admin nested routes work.

---

## Phase 4 — Wire up the Django backend proxy ✓ (15 min)

Replace the Vite proxy from [vite.config.js:14-21](frontend/vite.config.js#L14-L21) with a Next.js rewrite. Create/edit `next.config.js`:

```js
/** @type {import('next').NextConfig} */
module.exports = {
  async rewrites() {
    return [
      { source: '/api/:path*', destination: 'http://localhost:8000/api/:path*' },
    ]
  },
}
```

Now `/api/*` calls from the browser stay same-origin, just like before. No CORS changes needed for dev.

For production, either keep the rewrite (simple) or point `NEXT_PUBLIC_API_URL` directly at your Django host (and configure CORS + cookie domain on Django).

**Done when:** logging in works end-to-end.

---

## Phase 5 — Convert `.jsx` → `.tsx` ✓ (2–4 hours, incremental)

Now everything runs. Add types in this order; commit after each group.

1. **`src/services/*.js` → `.ts`.** Type the request/response shapes for `auth`, `payments`, `subscriptions`, `admin`. Start with `unknown` and refine. Export a `User`, `Subscription`, `Payment`, etc. type from each.
2. **`src/contexts/*.jsx` → `.tsx`.** Type the context value object (`AuthContextValue`, `SiteThemeContextValue`). Replace `createContext()` with `createContext<AuthContextValue | null>(null)`.
3. **`src/hooks/useToast.jsx` → `.tsx`.** Type the toast payload.
4. **`src/lib/*.js` → `.ts`.** These are pure utilities; types are easy.
5. **`src/components/ui/*.jsx` → `.tsx`.** These are shadcn-style; the canonical shadcn TypeScript versions are online if you want a reference, but mostly it's adding `React.ComponentProps<'button'>` etc.
6. **`src/components/**/*.jsx` → `.tsx`.** Higher-level components.
7. **`src/app/**/page.jsx` → `page.tsx`.** Last, because they tend to import everything else.

Recommended `tsconfig.json` adjustments (the create-next-app default is fine, just confirm):

```json
{
  "compilerOptions": {
    "strict": true,
    "allowJs": true,
    "paths": { "@/*": ["./src/*"] }
  }
}
```

Once everything is `.tsx`, flip `allowJs` to `false` to lock it in.

**Done when:** `npm run build` passes with no `tsc` errors and the app behaves identically to the Vite version.

---

## Phase 6 — Cleanup ✓ (30 min)

1. Delete `frontend-vite/`.
2. Update [start.sh](start.sh) and [start_frontend.sh](start_frontend.sh) for the new project structure.
3. Update [BOILERPLATE_PROBLEMS.md](BOILERPLATE_PROBLEMS.md) and [ISSUES.md](ISSUES.md) to reflect the new stack.
4. Update Django's `CORS_ALLOWED_ORIGINS` / `CSRF_TRUSTED_ORIGINS` if you're not using the rewrite in prod.
5. Commit, push, done.

---

## Rough time estimate

| Phase | Time |
|---|---|
| 0 — Prep | 30 min |
| 1 — Bootstrap | 1 hr |
| 2 — Port shared code | 1–2 hr |
| 3 — Routing migration | 2–4 hr |
| 4 — Backend proxy | 15 min |
| 5 — TS conversion | 2–4 hr (can be split across days) |
| 6 — Cleanup | 30 min |
| **Total** | **~1–2 working days** |

The risky phase is 3 (routing). The slow phase is 5 (TypeScript), but you can ship after Phase 4 with `.jsx` everywhere and convert to TS gradually — Next.js doesn't care.
