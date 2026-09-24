# CLAUDE.md

Guidance for Claude Code when working in this repository.
Fill in the bracketed sections, then delete this comment.

---

## Project

**[PROJECT_NAME]** — [one-sentence description of what this project does and who it's for]

---

## CRITICAL RULES

### 1. Security First

**NEVER**: store credentials in plaintext · execute untrusted code outside a sandbox · trust user input without sanitization · skip audit logging for sensitive operations

**ALWAYS**: keep secrets in env vars / a vault, never in git · validate and sanitize all external input · apply least-privilege to API keys and DB roles · enable row-level security (or equivalent) on any multi-tenant data

### 2. GitHub-First Development

Before starting any non-trivial task: find or create a GitHub issue, branch from it (`feature/<issue-number>-<short-name>`).
After completing work: push, open a PR.

Check before writing code: `gh issue list --state open` · relevant labels/milestones for this repo.

### 3. Issue & Verification

Every bug/feature/task needs a tracked issue before work begins. When fixed: comment with what changed, the test scenario, and pass/fail criteria. Don't close an issue until it's actually been verified — "the code looks right" isn't verification.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | [e.g. Next.js 15+ (App Router)] |
| Language | [e.g. TypeScript 5+ (strict mode)] |
| Styling | [e.g. Tailwind CSS] |
| Database | [e.g. Postgres / Supabase] |
| Auth | [e.g. Supabase Auth] |
| Deployment | [e.g. Coolify / Vercel / PM2 + nginx] |

---

## Commands

```bash
[dev command]      # e.g. npm run dev
[build command]     # e.g. npm run build
[test command]      # e.g. npm test
[lint command]       # e.g. npm run lint
```

**Before marking any task complete, these must pass with zero errors.**

---

## Quality Standards

- Zero type errors, zero lint warnings, error boundaries and loading/error states for async operations
- [Accessibility target, e.g. WCAG 2.1 AA]
- [Performance target, e.g. Core Web Vitals, <2s load]

---

## Anti-Patterns

- Building UI before the API is stable
- Ignoring type errors or lint warnings
- Closing issues without manual verification
- Secrets in plaintext or committed to git
- Hardcoding values that should be configurable

---

## When Stuck: 131 Technique

Define the problem + 3 options + 1 recommendation. Don't proceed until confirmed.
