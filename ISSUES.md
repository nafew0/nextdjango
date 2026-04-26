# Boilerplate Issues Audit

> Generated: 2026-04-10  
> Scope: Full project tree (`/backend`, `/frontend`, `/template`, root files)

---

## Critical — Breaks Clean Generation

### C1. `__dirname` used in ESM Vite config
- **File:** [frontend/vite.config.js:10](frontend/vite.config.js#L10)
- `__dirname` is not available in ESM modules. Replace with `import.meta.dirname` or use `fileURLToPath(import.meta.url)`.

### C2. `require()` used in ESM Tailwind config
- **File:** [frontend/tailwind.config.js:73](frontend/tailwind.config.js#L73)
- `require("tailwindcss-animate")` must be converted to an ESM import.

### C3. Hardcoded "reactdjango" in 50+ files
Every occurrence of "reactdjango" in the generated project is a stale template artifact that must be replaced with the actual project name at setup time. Key locations:

| File | Lines | Context |
|------|-------|---------|
| [backend/reactdjango/settings.py](backend/reactdjango/settings.py) | 3, 139, 142, 160–161, 177, 328 | Module paths, DB name, cookie name |
| [backend/accounts/password_reset.py](backend/accounts/password_reset.py) | 67 | Email subject line |
| [backend/accounts/verification.py](backend/accounts/verification.py) | 98 | Email subject line |
| [backend/subscriptions/stripe_service.py](backend/subscriptions/stripe_service.py) | 110, 182 | Error messages |
| [backend/subscriptions/tasks.py](backend/subscriptions/tasks.py) | 64, 66, 69, 72 | Email copy |
| [backend/accounts/templates/emails/password_reset.html](backend/accounts/templates/emails/password_reset.html) | 6, 16, 33, 35 | Email body text |
| [backend/accounts/templates/emails/verify_email.html](backend/accounts/templates/emails/verify_email.html) | 16, 32, 57 | Email body text |
| [frontend/index.html](frontend/index.html) | 7 | `<title>` tag |
| [frontend/src/pages/Home.jsx](frontend/src/pages/Home.jsx) | 688 | Footer brand name |
| [frontend/src/pages/Login.jsx](frontend/src/pages/Login.jsx) | 145 | Error message copy |
| [frontend/src/pages/Profile.jsx](frontend/src/pages/Profile.jsx) | 144, 314, 382 | Error messages |
| [frontend/src/pages/ForgotPassword.jsx](frontend/src/pages/ForgotPassword.jsx) | 13, 16, 24, 54 | Help text |
| [frontend/src/pages/ResetPassword.jsx](frontend/src/pages/ResetPassword.jsx) | 14, 15, 25, 26 | Page copy |
| [frontend/src/pages/admin/AdminLayout.jsx](frontend/src/pages/admin/AdminLayout.jsx) | 52 | Admin panel header |
| [frontend/src/pages/admin/AdminPayments.jsx](frontend/src/pages/admin/AdminPayments.jsx) | 331, 337 | CSV export filename |
| [frontend/src/lib/siteTheme.js](frontend/src/lib/siteTheme.js) | 9 | localStorage key |

### C4. Product-specific homepage copy (survey/questiz artifact)
The homepage contains copy that was written for a survey SaaS product, not a generic template. This must be replaced with truly generic placeholder content.

| File | Lines | Stale copy |
|------|-------|------------|
| [frontend/src/pages/Home.jsx](frontend/src/pages/Home.jsx) | 473 | "The Future of Feedback" |
| [frontend/src/pages/Home.jsx](frontend/src/pages/Home.jsx) | 533–535 | "The Analytical Luminary / We've reimagined data collection as a premium editorial experience" |
| [frontend/src/pages/Home.jsx](frontend/src/pages/Home.jsx) | 542 | "Architectural precision for your inquiries" |
| [frontend/src/pages/Home.jsx](frontend/src/pages/Home.jsx) | 573–577 | "Question Improver" feature — survey bias analysis copy |
| [frontend/src/pages/Home.jsx](frontend/src/pages/Home.jsx) | 607–617 | "Your data now speaks human" + survey/insights feature list |
| [frontend/src/pages/Home.jsx](frontend/src/pages/Home.jsx) | 22–46 | `TRUSTED_TRACK` and `ANALYTICS_CARDS` arrays with survey-domain labels |
| [frontend/src/pages/Home.jsx](frontend/src/pages/Home.jsx) | 642–644 | "Omni Distribution" section |

### C5. Missing favicon referenced in HTML
- **File:** [frontend/index.html:5](frontend/index.html#L5)
- References `/vite.svg` which does not exist in the project. Leftover from Vite starter.

---

## High — Bad User-Facing Experience

### H1. Literal placeholder text visible to users
- **File:** [frontend/src/pages/Home.jsx:688](frontend/src/pages/Home.jsx#L688) — Footer reads `reactdjango • your tagline here`
- **File:** [frontend/src/pages/Home.jsx:488](frontend/src/pages/Home.jsx#L488) — "Your app description goes here. Briefly explain the value your product delivers to users."
- **File:** [frontend/src/pages/Dashboard.jsx:52](frontend/src/pages/Dashboard.jsx#L52) — "This is a placeholder dashboard. Replace this page with your own app content."

### H2. Email subjects/bodies hardcoded to "reactdjango" brand
Users receive password reset and verification emails that say "reactdjango" regardless of the actual deployed project. See table in C3 above.

### H3. Auth error messages mention "reactdjango"
- **File:** [frontend/src/pages/Login.jsx:145](frontend/src/pages/Login.jsx#L145) — "reactdjango can resend a verification email"

---

## Medium — Workflow Friction / Tech Debt

### M1. Previous project lineage (AniFight) still documented
These references break the illusion of a clean, generic template:

| File | Line | Content |
|------|------|---------|
| [backend/reactdjango/settings.py](backend/reactdjango/settings.py) | 3 | `# Template created from AniFight project.` |
| [template/setup.sh](template/setup.sh) | 5 | `# Based on template from AniFight project` |
| [template/README.md](template/README.md) | 810 | "This template is based on the AniFight project." |
| [template/backend/{{PROJECT_NAME}}/settings.py](template/backend/{{PROJECT_NAME}}/settings.py) | 3 | Same AniFight comment |

### M2. Stale theme ID "quest-default" (questiz artifact)
- **File:** [frontend/src/lib/siteTheme.js:11](frontend/src/lib/siteTheme.js#L11) — `DEFAULT_SITE_THEME_ID = 'quest-default'`
- **File:** [frontend/src/lib/siteTheme.js:15](frontend/src/lib/siteTheme.js#L15) — Theme preset id `'quest-default'`
- The "quest" prefix is a leftover from the questiz project. Should use a neutral generic name.

### M3. No root `.gitignore`
The project has no `.gitignore` at the repo root, only inside `/backend` and `/frontend`. OS artifacts like `.DS_Store` are not excluded.

### M4. `.DS_Store` file committed / present at root
- **Path:** `.DS_Store` — macOS metadata file, should be in `.gitignore` and removed.

### M5. Stale backend tests
- **File:** [backend/accounts/tests.py:20,35,51](backend/accounts/tests.py#L20) — Tests use `example@example.com` and may assert on an outdated response structure. Needs review against current API serializers.

---

## Low — Minor Polish

### L1. Hardcoded localhost defaults throughout settings
These are fine for development but should be clearly marked or pulled from env:

| File | Lines | Value |
|------|-------|-------|
| [backend/reactdjango/settings.py](backend/reactdjango/settings.py) | 98, 101 | `ALLOWED_HOSTS` defaults |
| [backend/reactdjango/settings.py](backend/reactdjango/settings.py) | 105, 108 | CORS origins |
| [backend/reactdjango/settings.py](backend/reactdjango/settings.py) | 180 | `DB_HOST = "localhost"` |
| [backend/reactdjango/settings.py](backend/reactdjango/settings.py) | 277, 286 | `REDIS_HOST = "127.0.0.1"` |
| [backend/reactdjango/settings.py](backend/reactdjango/settings.py) | 303 | Celery broker URL |
| [frontend/vite.config.js:17](frontend/vite.config.js#L17) | 17 | Proxy target `http://localhost:8000` |
| [frontend/src/pages/admin/AdminLayout.jsx:31](frontend/src/pages/admin/AdminLayout.jsx#L31) | 31 | Fallback Django admin URL |

### L2. `DEFAULT_FROM_EMAIL` fallback to example.com
- **Files:** [backend/accounts/password_reset.py:74](backend/accounts/password_reset.py#L74), [backend/accounts/verification.py:100](backend/accounts/verification.py#L100), [backend/subscriptions/tasks.py:30](backend/subscriptions/tasks.py#L30)
- All fall back to `"no-reply@example.com"` — emails will silently send from a non-functional address if `DEFAULT_FROM_EMAIL` is not set in `.env`.

### L3. Template source tree mixed with generated app
The `/template/` directory lives alongside the active `/backend/` and `/frontend/` directories. This is confusing for developers and could cause accidental edits to the wrong files. Consider moving `/template/` to a separate repository or clearly documenting the distinction.

---

## Summary Counts

| Severity | Count |
|----------|-------|
| Critical | 5 |
| High | 3 |
| Medium | 5 |
| Low | 3 |
| **Total** | **16** |
