---
name: ditch-vercel
description: Migrate a project from Vercel to another platform. Use when user wants to leave Vercel, migrate to Cloudflare/Railway/VPS, or run /ditch-vercel.
argument-hint: "[target-platform]"
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion
---

# Ditch Vercel — Migration Orchestrator

You are running the **ditch-vercel** migration skill. Follow the 8-step flow below **exactly in order**. Do NOT skip steps. Do NOT make any file changes until step 7 (after explicit user approval in step 6).

---

## Step 1: DETECT FRAMEWORK

Scan the user's project to identify the framework in use.

**How to detect:**

1. Read `package.json` — examine `dependencies` and `devDependencies`.
2. Check for framework config files using Glob.
3. Match against this table (check in order — first match wins):

| Framework  | package.json indicator             | Config file pattern        |
|------------|------------------------------------|----------------------------|
| Next.js    | `next` in deps                     | `next.config.*`            |
| Astro      | `astro` in deps                    | `astro.config.*`           |
| Remix      | `@remix-run/*` in deps             | `remix.config.*` (optional)|
| SvelteKit  | `@sveltejs/kit` in deps            | `svelte.config.*`          |
| Nuxt       | `nuxt` in deps                     | `nuxt.config.*`            |
| Static     | None of the above framework deps   | N/A                        |

4. After detecting the framework, read the corresponding knowledge file for migration guidance:
   - Next.js: [frameworks/nextjs.md](frameworks/nextjs.md)
   - Astro: [frameworks/astro.md](frameworks/astro.md)
   - Remix: [frameworks/remix.md](frameworks/remix.md)
   - SvelteKit: [frameworks/sveltekit.md](frameworks/sveltekit.md)
   - Nuxt: [frameworks/nuxt.md](frameworks/nuxt.md)
   - Static: [frameworks/static.md](frameworks/static.md)

5. Report the detected framework and its version to the user before proceeding.

---

## Step 2: DETECT VERCEL FEATURES

Scan the project for all Vercel-specific features and integrations. Check every item below — do NOT skip any.

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
- **ISR (Incremental Static Regeneration)**: Grep for `export const revalidate` or `revalidate:` in page/route files.
- **API Routes**: Glob for `app/api/**/route.{ts,js}` or `pages/api/**/*.{ts,js}` (Next.js), or equivalent in other frameworks.
- **Middleware**: Check for `middleware.{ts,js}` at project root or `src/`.
- **Cron jobs**: Check `vercel.json` for `crons` field.
- **Environment variables**: Check for `.env*` files. Note which env vars exist (names only, never values).
- **Serverless/Edge functions config**: Check for `export const config = { runtime: ... }` patterns.

**Output a feature inventory** listing every detected Vercel feature, e.g.:
```
Vercel Feature Inventory:
- vercel.json: Found (rewrites, headers)
- @vercel/analytics: Found
- @vercel/speed-insights: Found
- next/image: Used in 4 files
- Edge Runtime: 2 routes
- ISR: 3 pages with revalidate
- API Routes: 5 routes
- Middleware: Found
- Cron jobs: None
- @vercel/blob: Not found
- @vercel/kv: Not found
- @vercel/postgres: Not found
- Environment variables: 8 vars in .env.local
```

---

## Step 3: SELECT TARGET PLATFORM

For v1, the target platform is **Cloudflare** (Cloudflare Pages + Workers).

Read the target knowledge file for migration mappings and instructions:
- Cloudflare: [targets/cloudflare.md](targets/cloudflare.md)

If the user passed a target-platform argument, acknowledge it. For now, only Cloudflare is supported — inform the user that other targets (Railway, Fly.io, VPS) are coming soon. Proceed with Cloudflare.

---

## Step 4: ANALYZE COMPATIBILITY

Cross-reference every Vercel feature detected in Step 2 against the target platform's compatibility (from the target knowledge file).

**Output a compatibility report** using these indicators:
- **Supported** — Direct equivalent exists, migration is straightforward.
- **Partial** — Equivalent exists but with caveats, limitations, or different behavior.
- **Manual** — No direct equivalent; requires manual work or architectural change.

Format the report as a table:

```
Compatibility Report: Vercel → Cloudflare
──────────────────────────────────────────
Feature              Status     Notes
──────────────────────────────────────────
next/image           Partial    Use Cloudflare Image Resizing or custom loader
ISR                  Partial    Use on-demand revalidation via Cache API
API Routes           Supported  Runs as Cloudflare Workers
Edge Runtime         Supported  Native on Cloudflare Workers
Middleware           Supported  Runs on Cloudflare edge
@vercel/analytics    Manual     Replace with Cloudflare Web Analytics or remove
@vercel/blob         Manual     Replace with Cloudflare R2
@vercel/kv           Manual     Replace with Cloudflare KV
@vercel/postgres     Manual     Replace with Cloudflare D1 or Hyperdrive
Cron jobs            Partial    Use Cloudflare Cron Triggers
Rewrites/Redirects   Supported  Use _redirects / _headers or wrangler.toml
──────────────────────────────────────────
```

Only include rows for features actually detected in the project. Derive the specific status and notes from the target knowledge file.

---

## Step 5: PLAN MIGRATION

Based on Steps 1-4, produce a concrete migration plan. Be specific — list exact file paths, package names, and what changes will be made.

**Plan format:**

```
Migration Plan: [Framework] on Vercel → Cloudflare
═══════════════════════════════════════════════════

Dependencies to ADD:
  - @opennextjs/cloudflare (if Next.js)
  - wrangler (dev dependency)
  - ...

Dependencies to REMOVE:
  - @vercel/analytics
  - @vercel/speed-insights
  - ...

Files to CREATE:
  - wrangler.toml — Cloudflare Workers configuration
  - ...

Files to MODIFY:
  - next.config.js — Add Cloudflare adapter/config
  - src/app/layout.tsx — Replace @vercel/analytics import
  - ...

Files to DELETE:
  - vercel.json
  - ...

Manual Action Items (post-migration):
  - Set up Cloudflare Pages project in dashboard
  - Configure environment variables in Cloudflare dashboard
  - Set up R2 bucket if using blob storage
  - Update DNS settings
  - ...
```

Each entry must be specific enough that the user can understand exactly what will happen. For file modifications, briefly describe what changes.

---

## Step 6: APPROVE

**This is a hard gate. Do NOT proceed without explicit approval.**

Use the `AskUserQuestion` tool to present the plan and ask the user to approve.

Provide these options:
1. **Yes, proceed** — Execute the migration plan as described.
2. **Modify plan** — User wants to change something. Ask what to modify, update the plan, then ask for approval again.
3. **Cancel** — Abort the migration. No changes made.

If the user selects "Modify plan", loop: gather feedback, revise the plan, and present for approval again.

**CRITICAL: Do NOT create, modify, or delete any project files before receiving "Yes, proceed".**

---

## Step 7: EXECUTE

Now execute the approved migration plan.

**7a. Detect package manager**

Check the project root for lock files (first match wins):
| Lock file            | Package manager |
|----------------------|-----------------|
| `bun.lockb` or `bun.lock` | `bun`     |
| `pnpm-lock.yaml`    | `pnpm`          |
| `yarn.lock`         | `yarn`          |
| `package-lock.json` | `npm`           |

If no lock file found, default to `npm`.

**7b. Install new dependencies**

Use the detected package manager:
- `bun add <pkg>` / `bun add -d <pkg>`
- `pnpm add <pkg>` / `pnpm add -D <pkg>`
- `yarn add <pkg>` / `yarn add -D <pkg>`
- `npm install <pkg>` / `npm install -D <pkg>`

**7c. Uninstall Vercel dependencies**

Remove all `@vercel/*` packages that are being replaced:
- `bun remove <pkg>`
- `pnpm remove <pkg>`
- `yarn remove <pkg>`
- `npm uninstall <pkg>`

**7d. Create new files**

Write configuration files (e.g., `wrangler.toml`) using the Write tool.

**7e. Modify existing files**

Use Edit tool for surgical changes. Examples:
- Replace `@vercel/analytics` imports with the Cloudflare alternative or remove them.
- Update framework config to add Cloudflare adapter.
- Replace `@vercel/blob` usage with R2 client code.
- Adjust image component usage if needed.

**7f. Delete files**

Remove Vercel-specific files (e.g., `vercel.json`) using Bash `rm`.

**7g. Output execution summary**

```
Migration Executed
══════════════════
Packages installed: @opennextjs/cloudflare, wrangler
Packages removed: @vercel/analytics, @vercel/speed-insights
Files created: wrangler.toml
Files modified: next.config.js, src/app/layout.tsx
Files deleted: vercel.json
```

---

## Step 8: NEXT STEPS

Print a clear post-migration checklist for the user.

**Always include:**

1. **Build verification command** — The exact command to test the build locally:
   - Next.js on Cloudflare: `npx @opennextjs/cloudflare` (or equivalent with detected pkg manager)
   - Astro on Cloudflare: `astro build`
   - Other frameworks: the appropriate build command

2. **Local dev command** — How to run locally with the new target:
   - e.g., `npx wrangler pages dev`

3. **Deploy command** — The exact command to deploy:
   - Cloudflare Pages: `npx wrangler pages deploy` or connect via Git integration in dashboard

4. **Manual items remaining** — Any items from the plan that require manual action:
   - Environment variables to set in the Cloudflare dashboard
   - DNS/domain configuration
   - Storage setup (R2, KV, D1) if applicable
   - Cron trigger configuration if applicable
   - Monitoring/analytics dashboard setup

5. **Cleanup reminder** — Suggest the user:
   - Remove the project from Vercel dashboard when ready
   - Update any CI/CD pipelines
   - Update team documentation

Format this as a numbered checklist the user can follow sequentially.

---

## General Rules

- **Be precise**: Use exact file paths, package names, and commands. Never be vague.
- **Be safe**: Never touch files outside the project directory. Never expose env var values.
- **Be transparent**: Show the user what you found and what you plan to do before doing it.
- **Handle errors**: If a knowledge file is missing, work from your own knowledge but warn the user. If a scan finds nothing, say so explicitly rather than guessing.
- **One framework only**: If multiple frameworks are detected, ask the user to clarify which one is the primary framework.
- **Monorepo awareness**: If the project root contains `apps/` or `packages/` directories, ask the user which app to migrate.
