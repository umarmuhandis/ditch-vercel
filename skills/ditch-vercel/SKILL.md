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

Use `AskUserQuestion` to ask the target platform:

```
Where do you want to migrate?
- Cloudflare (Workers/Pages — serverless edge) (Recommended)
- VPS (Node.js + PM2 + Nginx — self-managed server)
- Other targets coming soon (Railway, Fly.io)
```

Read the target knowledge file:
- Cloudflare: [targets/cloudflare.md](targets/cloudflare.md)
- VPS: [targets/vps.md](targets/vps.md)

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

## Phase 3: PLAN + APPROVE

Generate a concrete migration plan, get explicit approval, then create the task list.

### 3a. Generate the migration plan

Based on Phases 1-2, produce a specific plan. List exact file paths, package names, and what changes will be made. Tag each item with its category.

```
Migration Plan: [Framework] on Vercel → [Target]
═══════════════════════════════════════════════════

Dependencies to ADD:
  - [package] [Automated]
  - ...

Dependencies to REMOVE:
  - [package] [Automated]
  - ...

Files to CREATE:
  - [filepath] — [description] [Automated]
  - ...

Files to MODIFY:
  - [filepath] — [description] [category]
  - ...

Files to DELETE:
  - [filepath] [Automated]
  - ...

Manual Action Items (post-migration):
  - [item] [Attention/Blocker]
  - ...
```

Each entry must be specific enough that the developer understands exactly what will happen.

### 3b. Approval gate

**This is a hard gate. Do NOT proceed without explicit approval.**

Use `AskUserQuestion`:

```
Approve the migration plan?
- "Yes, proceed with migration"
- "Modify the plan" → gather feedback, revise, re-approve
- "Cancel migration" → stop, no changes
```

If "Modify the plan": loop — gather feedback, revise the plan, present for approval again.
If "Cancel migration": stop. Output: `Migration cancelled. No changes made.`

**CRITICAL: Do NOT create, modify, or delete any project files before receiving "Yes, proceed with migration".**

### 3c. Create the task list

After the developer approves, immediately create tasks using `TaskCreate` for each migration action, in this exact order:

1. **"Create git safety checkpoint"** (activeForm: "Creating safety checkpoint")
2. One task per dependency to install (activeForm: "Installing [package]")
3. One task per dependency to remove (activeForm: "Removing [package]")
4. One task per file to create (activeForm: "Creating [filename]")
5. One task per file to modify (activeForm: "Updating [filename]")
6. One task per file to delete (activeForm: "Deleting [filename]")
7. **"Run build verification"** (activeForm: "Verifying build")
8. **"Run local dev server verification"** (activeForm: "Verifying local dev server")

Each task description must include the exact command or file change. Do NOT combine multiple actions into one task. Each task = one atomic action.

## Phase 4: EXECUTE

Execute the approved plan with safety nets and real-time task tracking.

### 4a. Git safety checkpoint

Set the checkpoint task to `in_progress`.

1. Check `git status`. If working tree is dirty:
   ```bash
   git add -A && git commit -m "chore: pre-migration checkpoint (ditch-vercel)"
   ```
2. If working tree is clean, note the current HEAD SHA.
3. Store the checkpoint SHA for rollback.
4. Mark the checkpoint task as `completed`.
5. Output:
   ```
   Safety checkpoint created (commit: <sha-short>). To undo: git reset --hard <sha>
   ```

### 4b. Detect package manager

Check the project root for lock files (first match wins):

| Lock file            | Package manager |
|----------------------|-----------------|
| `bun.lockb` or `bun.lock` | `bun`     |
| `pnpm-lock.yaml`    | `pnpm`          |
| `yarn.lock`         | `yarn`          |
| `package-lock.json` | `npm`           |

If no lock file found, default to `npm`.

### 4c. Cross-reference official docs

Before executing file changes, verify migration steps against current official documentation.

1. Read the `## Reference URLs` section from the loaded framework file and target file
2. **Prefer `llms.txt` URLs** (lines prefixed with `llms.txt:`) — these are machine-readable doc indexes optimized for LLMs. Fetch with `WebFetch` and use the index to locate the specific migration/deployment page, then fetch that page. If no `llms.txt` entry exists for a source, fall back to the regular doc URLs.
3. Fetch each URL using `WebFetch` with prompt: "Extract the current migration steps, required packages, config format, and any breaking changes or deprecation notices"
4. Compare fetched content against the migration steps you're about to execute. Look for:
   - Package name changes (e.g. adapter renamed)
   - New required config fields
   - Deprecated CLI flags or commands
   - Changed build output directories
5. If discrepancies found:
   - Show the user: "Official docs differ from migration template on: [list]"
   - Use `AskUserQuestion`: **"Follow official docs"** / **"Follow template"** / **"Let me decide per item"**
6. If WebFetch fails for any URL: skip silently, proceed with framework file instructions
7. Do NOT fetch URLs during Phase 1-3 (wastes context before user commits to migration)

### 4d. Execute each task

For each remaining task (dependencies, files, deletions):

**Important:** Follow the migration steps section in the framework knowledge file that matches the selected target platform. For example, if the target is VPS, follow `## Migration Steps (VPS)`. If the target is Cloudflare, follow `## Migration Steps (Cloudflare)`. Use the corresponding `## Compatibility Notes ([target])` section for replacement guidance.

1. Set task status to `in_progress` using `TaskUpdate`
2. Execute the action:
   - **Install dep**: `[pkg-manager] add <pkg>` / `[pkg-manager] add -D <pkg>`
   - **Remove dep**: `[pkg-manager] remove <pkg>`
   - **Create file**: Use `Write` tool
   - **Modify file**: Use `Edit` tool
   - **Delete file**: Use `Bash` with `rm`
3. If successful: set task status to `completed`
4. If failed: keep status as `in_progress`, show the error, and ask the developer using `AskUserQuestion`:
   - **"Fix it"** → Read the error, attempt a fix, retry the action
   - **"Skip this step"** → Update task description with "[SKIPPED]", set to `completed`, continue
   - **"Rollback everything"** → Run `git reset --hard <checkpoint-sha>`, mark all remaining tasks as `deleted`, stop execution

### 4e. Build **verification**

After all file changes are complete:

1. Set the build verification task to `in_progress`
2. Detect the build command:
   - Next.js + Cloudflare: `<pkg> run build:cf` (or the build:cf script added in migration)
   - Next.js + VPS: `<pkg> run build`
   - Astro: `<pkg> run build` (runs `astro build`)
   - Remix: `<pkg> run build` (runs `remix vite:build`)
   - SvelteKit: `<pkg> run build`
   - Nuxt: `<pkg> run build` (runs `nuxt build`)
   - Static with build script: `<pkg> run build`
   - Static without build: skip (no build needed)
3. Run the build command via `Bash`
4. If build passes: mark task `completed`
5. If build fails:
   - Show the error output (first 50 lines)
   - Ask the developer using `AskUserQuestion`:
     - **"Fix it"** → Read the error, attempt to fix the code, re-run the build
     - **"Rollback everything"** → Run `git reset --hard <checkpoint-sha>`, stop
     - **"Continue anyway"** → Mark task `completed` with note "[BUILD FAILED - manual fix needed]"

### 4f. Local dev server verification

After build passes, verify the app starts and responds locally.

1. Set the local dev server task to `in_progress`
2. Detect the preview command:
   - Next.js + Cloudflare: `npx wrangler dev` (port 8787)
   - Next.js + VPS: `node .next/standalone/server.js` (port 3000)
   - Astro + Cloudflare: `npx wrangler pages dev dist/` (port 8788)
   - Astro + VPS: `node dist/server/entry.mjs` (port 4321)
   - Remix + Cloudflare: `npx wrangler pages dev build/client` (port 8788)
   - Remix + VPS: `npx remix-serve build/server/index.js` (port 3000)
   - SvelteKit + Cloudflare: `npx wrangler pages dev .svelte-kit/cloudflare` (port 8788)
   - SvelteKit + VPS: `node build/index.js` (port 3000)
   - Nuxt + Cloudflare: `npx wrangler pages dev dist/` (port 8788)
   - Nuxt + VPS: `node .output/server/index.mjs` (port 3000)
   - Static + Cloudflare: `npx wrangler pages dev <output-dir>` (port 8788)
   - Static + VPS: `npx serve <output-dir>` (port 3000)
3. Start the preview command in the background via Bash (run_in_background)
4. Wait ~5 seconds for the server to start
5. Run `curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>/` to check for a 200 response
6. Kill the background process
7. If curl returns 200: mark task `completed`
8. If curl fails or non-200:
   - Show the output
   - Ask the developer using `AskUserQuestion`:
     - **"Fix it"** → investigate, fix, retry
     - **"Skip"** → mark completed with "[DEV SERVER CHECK SKIPPED]"
     - **"Rollback everything"** → `git reset --hard <checkpoint-sha>`, stop

## Phase 5: DONE

Output the final migration summary with everything the developer needs.

### 5a. Migration summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MIGRATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Created:   [list files]
  Modified:  [list files]
  Removed:   [list files]
  Installed: [list packages]
  Removed:   [list packages]

  STILL NEEDS YOUR ATTENTION:
  [list any Attention/Blocker items from the report that weren't fully automated]

  NEXT STEPS:
  1. [deploy command] — deploy to [target]
  2. Set environment variables in [target] dashboard
  3. [any other manual items]

  To undo everything:
  git reset --hard [checkpoint-sha]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Only include "STILL NEEDS YOUR ATTENTION" if there are remaining items. Derive the local dev command, deploy command, and manual items from the target knowledge file and framework knowledge file.

---

## General Rules

- **Be precise**: Use exact file paths, package names, and commands. Never be vague.
- **Be safe**: Never touch files outside the project directory. Never expose env var values.
- **Be transparent**: Show the user what you found and what you plan to do before doing it.
- **Handle errors**: If a knowledge file is missing, work from your own knowledge but warn the user. If a scan finds nothing, say so explicitly rather than guessing.
- **One framework only**: If multiple frameworks are detected, ask the user to clarify which one is the primary framework.
- **Monorepo awareness**: If the project root contains `apps/` or `packages/` directories, ask the user which app to migrate.
- **Always use TaskCreate/TaskUpdate** to track execution progress during Phase 4.
- **Task #1 must always be the git safety checkpoint.**
- **Never mark a task as completed if the action failed.** Failed tasks stay `in_progress` with recovery options presented to the developer. Note: user-initiated skips (where the developer explicitly chooses "Skip this step") are NOT failures — mark these `completed` with a "[SKIPPED]" tag.
