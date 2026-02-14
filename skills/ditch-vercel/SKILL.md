---
name: ditch-vercel
description: Migrate a project from Vercel to another platform. Use when user wants to leave Vercel, migrate to Cloudflare/Railway/VPS, or run /ditch-vercel.
argument-hint: "[target-platform]"
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TaskCreate, TaskUpdate, TaskList
---

# Ditch Vercel — Migration Orchestrator

You are running the **ditch-vercel** migration skill. Follow the 5-phase flow below **exactly in order**. Do NOT skip phases. Do NOT make any file changes until Phase 4 (after explicit user approval in Phase 3).

---

## Phase 1: SCAN

Silently detect framework, Vercel features, and target platform in one pass. Minimal output — the report comes in Phase 2.

### 1a. Detect framework

Read `package.json` — examine `dependencies` and `devDependencies`. Check for framework config files using Glob. Match against this table (first match wins):

| Framework  | package.json indicator             | Config file pattern        |
|------------|------------------------------------|----------------------------|
| Next.js    | `next` in deps                     | `next.config.*`            |
| Astro      | `astro` in deps                    | `astro.config.*`           |
| Remix      | `@remix-run/*` in deps             | `remix.config.*` (optional)|
| SvelteKit  | `@sveltejs/kit` in deps            | `svelte.config.*`          |
| Nuxt       | `nuxt` in deps                     | `nuxt.config.*`            |
| Static     | None of the above framework deps   | N/A                        |

Read the corresponding knowledge file:
- Next.js: [frameworks/nextjs.md](frameworks/nextjs.md)
- Astro: [frameworks/astro.md](frameworks/astro.md)
- Remix: [frameworks/remix.md](frameworks/remix.md)
- SvelteKit: [frameworks/sveltekit.md](frameworks/sveltekit.md)
- Nuxt: [frameworks/nuxt.md](frameworks/nuxt.md)
- Static: [frameworks/static.md](frameworks/static.md)

### 1b. Detect ALL Vercel features

Scan for every Vercel-specific feature. Check every item — do NOT skip any.

**Configuration:**
- `vercel.json` — Read it fully if present. Note: rewrites, redirects, headers, cron, functions config, regions.

**Vercel SDK packages** — Check `package.json` deps and devDeps for:
- `@vercel/analytics`
- `@vercel/speed-insights`
- `@vercel/blob`
- `@vercel/kv`
- `@vercel/postgres`
- `@vercel/edge`
- `@vercel/og`
- Any other `@vercel/*` package

**Framework-specific Vercel features** — Scan source files:
- **Edge Runtime**: Grep for `export const runtime = 'edge'` or `export const runtime = "edge"` in route/API files.
- **next/image**: Grep for `import.*from ['"]next/image['"]` — Vercel's image optimization is used.
- **ISR**: Grep for `export const revalidate` or `revalidate:` in page/route files.
- **API Routes**: Glob for `app/api/**/route.{ts,js}` or `pages/api/**/*.{ts,js}` (Next.js), or equivalent in other frameworks.
- **Middleware**: Check for `middleware.{ts,js}` at project root or `src/`.
- **Cron jobs**: Check `vercel.json` for `crons` field.
- **Environment variables**: Check for `.env*` files. Note which env vars exist (names only, never values).
- **Serverless/Edge functions config**: Check for `export const config = { runtime: ... }` patterns.

### 1c. Select target platform

Use `AskUserQuestion` to ask the target platform. For v1, Cloudflare is the only option:

```
Where do you want to migrate?
- Cloudflare (Recommended)
- Other targets coming soon (Railway, Fly.io, VPS)
```

Read the target knowledge file:
- Cloudflare: [targets/cloudflare.md](targets/cloudflare.md)

### 1d. Output (one line only)

```
Scanning... Detected [Framework] [version] ([variant]) with [N] Vercel features.
```

Example: `Scanning... Detected Next.js 15 (App Router) with 8 Vercel features.`

---

## Phase 2: REPORT

The anxiety reducer. Show the developer exactly how hard this migration is BEFORE asking them to commit to anything.

### 2a. Calculate complexity score

Cross-reference every detected Vercel feature against the target's compatibility matrix (from the target knowledge file AND the framework knowledge file).

For each detected feature:
1. Look up its **Weight** and **Category** from the knowledge files
2. Sum all weights to get the total complexity score
3. Determine the traffic light:
   - 🟢 **GREEN** (0-2): ~1-2 hours — mostly automated
   - 🟡 **YELLOW** (3-6): ~3-5 hours — several manual steps
   - 🔴 **RED** (7+): ~1-2 days — significant refactoring or blockers

### 2b. Categorize features into 3 groups

- **Automated** (Weight 0): ditch-vercel handles these entirely
- **Attention** (Weight 1): Works but needs minor manual adjustment
- **Blocker** (Weight 3): Significant effort, may prevent migration

### 2c. Output the report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MIGRATION COMPLEXITY: [🟢 GREEN / 🟡 YELLOW / 🔴 RED]
  Estimated effort: [time estimate]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  AUTOMATED (ditch-vercel handles these):
  ✅ [feature] → [what happens]
  ✅ [feature] → [what happens]
  ...

  NEEDS YOUR ATTENTION:
  ⚠️  [feature] → [what the developer needs to do]
  ⚠️  [feature] → [what the developer needs to do]
  ...

  BLOCKERS:
  ❌ [feature] → [why it's a blocker and what's needed]
  ...
```

Only include sections that have items. If there are no Blockers, omit the BLOCKERS section. If there are no Attention items, omit the NEEDS YOUR ATTENTION section.

### 2d. Ask the developer

Use `AskUserQuestion`:

```
Ready to migrate?
- "Yes, show me the plan"
- "No, just wanted to see the report"
```

If the developer selects "No": stop gracefully. Output: `No changes made. Run /ditch-vercel anytime to continue.`

If "Yes": proceed to Phase 3.

---

<!-- Phases 3-5 will be added in subsequent commits -->

## Phase 3: PLAN + APPROVE

_Coming next._

## Phase 4: EXECUTE

_Coming next._

## Phase 5: DONE

_Coming next._

---

## General Rules

- **Be precise**: Use exact file paths, package names, and commands. Never be vague.
- **Be safe**: Never touch files outside the project directory. Never expose env var values.
- **Be transparent**: Show the user what you found and what you plan to do before doing it.
- **Handle errors**: If a knowledge file is missing, work from your own knowledge but warn the user. If a scan finds nothing, say so explicitly rather than guessing.
- **One framework only**: If multiple frameworks are detected, ask the user to clarify which one is the primary framework.
- **Monorepo awareness**: If the project root contains `apps/` or `packages/` directories, ask the user which app to migrate.
