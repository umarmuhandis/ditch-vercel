# DX Overhaul Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite the ditch-vercel plugin to deliver dream DX — complexity scoring, task-driven progress tracking, git safety checkpoints, and auto build verification.

**Architecture:** Replace SKILL.md's 8-step flow with a 5-phase flow (Scan → Report → Plan+Approve → Execute → Done). Add weight/category columns to all knowledge files. Instruct Claude to use TaskCreate/TaskUpdate for real-time progress tracking during Phase 4.

**Tech Stack:** Claude Code plugin (markdown only), TaskCreate/TaskUpdate/TaskList tools

---

### Task 1: Add Weight + Category columns to cloudflare.md

**Files:**
- Modify: `skills/ditch-vercel/targets/cloudflare.md:15-33`

**Step 1: Update the compatibility matrix table**

Replace the existing 4-column table with a 6-column table. Add `Weight` and `Category` columns:

```markdown
| Vercel Feature | Cloudflare Equivalent | Weight | Category | Status | Notes |
|---|---|---|---|---|---|
| Serverless Functions | Workers | 0 | Automated | Supported | Via OpenNext or framework adapter |
| Edge Middleware | Workers | 0 | Automated | Supported | Native edge compute |
| Image Optimization | Image Resizing / Cloudflare Images | 1 | Attention | Partial | Requires Business+ plan for Image Resizing, or use custom loader (unpic, cloudinary, imgix) |
| ISR | KV + Cache API | 1 | Attention | Partial | Via OpenNext cache handler or framework-specific caching |
| Cron Jobs | Cron Triggers | 1 | Attention | Partial | Define in `wrangler.toml`, different syntax from `vercel.json` crons |
| Environment Variables | wrangler.toml `[vars]` or dashboard | 0 | Automated | Supported | Use `wrangler secret put` for secrets (encrypted, not in toml) |
| Preview Deployments | `wrangler dev` / branch deploys | 0 | Automated | Supported | Git-integrated branch deploys available via Pages |
| Vercel Analytics | Cloudflare Web Analytics | 1 | Attention | Partial | Different SDK. Remove `@vercel/analytics`, add Cloudflare JS snippet from dashboard |
| Vercel Speed Insights | — | 1 | Attention | Manual | No direct equivalent. Remove `@vercel/speed-insights`. Use Cloudflare Observatory or Browser Insights for RUM |
| `@vercel/og` | `satori` + Workers | 1 | Attention | Partial | Manual setup needed. Alternative: `@cloudflare/pages-plugin-vercel-og` as near drop-in |
| Vercel Blob | R2 | 3 | Blocker | Partial | Different API. Use S3-compatible client or R2 bindings. Add `[[r2_buckets]]` to `wrangler.toml` |
| Vercel KV | Cloudflare KV | 1 | Attention | Partial | Different API, simpler. Add `[[kv_namespaces]]` to `wrangler.toml` |
| Vercel Postgres | D1 or Hyperdrive | 3 | Blocker | Partial | D1 = SQLite-compatible serverless DB. Hyperdrive = connection pool proxy to existing Postgres |
| Monorepo | Workers + Pages | 0 | Automated | Supported | Configure build output path per app |
| Rewrites | `_redirects` file (status 200) or next.config rewrites | 0 | Automated | Supported | Move from `vercel.json` to framework-native or `_redirects` |
| Redirects | `_redirects` file or next.config redirects | 0 | Automated | Supported | Move from `vercel.json` to framework-native or `_redirects` |
| Headers | `_headers` file or next.config headers | 0 | Automated | Supported | Move from `vercel.json` to framework-native or `_headers` |
```

**Step 2: Add scoring legend**

Add this section right before the compatibility matrix:

```markdown
## Scoring

Each feature has a weight used to calculate migration complexity:

| Weight | Category | Meaning |
|--------|----------|---------|
| 0 | Automated | ditch-vercel handles this entirely |
| 1 | Attention | Works but needs minor manual adjustment |
| 3 | Blocker | Significant effort, may prevent migration |

**Traffic light score** (sum of weights for detected features):
- 🟢 GREEN (0-2): ~1-2 hours — mostly automated
- 🟡 YELLOW (3-6): ~3-5 hours — several manual steps
- 🔴 RED (7+): ~1-2 days — significant refactoring or blockers
```

**Step 3: Commit**

```bash
git add skills/ditch-vercel/targets/cloudflare.md
git commit -m "feat: add weight/category scoring to Cloudflare compatibility matrix"
```

---

### Task 2: Add Weight + Category to all 6 framework knowledge files

**Files:**
- Modify: `skills/ditch-vercel/frameworks/nextjs.md` (compatibility tables at lines 107-133)
- Modify: `skills/ditch-vercel/frameworks/astro.md` (compatibility tables at lines 99-123)
- Modify: `skills/ditch-vercel/frameworks/remix.md` (compatibility tables at lines 159-186)
- Modify: `skills/ditch-vercel/frameworks/sveltekit.md` (compatibility tables at lines 126-153)
- Modify: `skills/ditch-vercel/frameworks/nuxt.md` (compatibility tables at lines 99-126)
- Modify: `skills/ditch-vercel/frameworks/static.md` (compatibility tables at lines 156-182)

**Step 1: Add Weight + Category columns to each file's compatibility tables**

For each framework file, add `Weight` and `Category` columns to the Supported/Partial/Manual tables. Use the same weight values as cloudflare.md:

**Weight assignments (apply consistently across all framework files):**
- Supported features (config, adapter swap, routing, SSR, etc.) → Weight 0, Category "Automated"
- `next/image` / image optimization → Weight 1, Category "Attention"
- Bundle size > 25MB → Weight 3, Category "Blocker"
- `@vercel/og` → Weight 1, Category "Attention"
- `@vercel/analytics` → Weight 1, Category "Attention"
- `@vercel/speed-insights` → Weight 1, Category "Attention"
- `@vercel/blob` → Weight 3, Category "Blocker"
- `@vercel/kv` → Weight 1, Category "Attention"
- `@vercel/postgres` → Weight 3, Category "Blocker"
- Session storage migration → Weight 1, Category "Attention"
- Node.js API compatibility → Weight 1, Category "Attention"
- Edge config → Weight 1, Category "Attention"

**Example transformation for nextjs.md Supported table:**

Before:
```
| Feature | Status | Notes |
| App Router | Supported | ... |
```

After:
```
| Feature | Weight | Category | Status | Notes |
| App Router | 0 | Automated | Supported | ... |
```

Apply the same pattern to Partial and Manual tables in each file.

**Step 2: Commit**

```bash
git add skills/ditch-vercel/frameworks/
git commit -m "feat: add weight/category scoring to all framework knowledge files"
```

---

### Task 3: Rewrite SKILL.md — Phase 1 (SCAN) and Phase 2 (REPORT)

This is the core rewrite. The SKILL.md goes from 302 lines / 8 steps → 5 phases.

**Files:**
- Modify: `skills/ditch-vercel/skills/ditch-vercel/SKILL.md` (full rewrite)

**Step 1: Write the new SKILL.md with Phase 1 and Phase 2**

Replace the entire SKILL.md content. New frontmatter:

```yaml
---
name: ditch-vercel
description: Migrate a project from Vercel to another platform. Use when user wants to leave Vercel, migrate to Cloudflare/Railway/VPS, or run /ditch-vercel.
argument-hint: "[target-platform]"
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TaskCreate, TaskUpdate, TaskList
---
```

**Phase 1: SCAN** should combine old Steps 1-3 into one fast, silent operation:
- Detect framework (same table as before)
- Read framework knowledge file
- Detect ALL Vercel features (same checklist as before)
- Ask target platform (AskUserQuestion with Cloudflare as only v1 option)
- Read target knowledge file

Important: Phase 1 should NOT output verbose text. Just a single line:
```
Scanning... Detected Next.js 15 (App Router) with 8 Vercel features.
```

**Phase 2: REPORT** is the NEW anxiety reducer. Instructions for Claude:
1. Cross-reference detected features against the target's compatibility matrix
2. Calculate complexity score: sum all weights of detected features
3. Determine traffic light: GREEN (0-2), YELLOW (3-6), RED (7+)
4. Categorize features into 3 groups: Automated (weight 0), Attention (weight 1), Blocker (weight 3)
5. Output the formatted report (use the format from design doc)
6. Ask the developer: "Ready to migrate?" with options:
   - "Yes, show me the plan"
   - "No, just wanted to see the report"
   If "No" → stop gracefully. Say "No changes made. Run /ditch-vercel anytime to continue."

**Step 2: Verify Phase 1 + 2 content is complete, save partial file**

At this point the SKILL.md should have frontmatter + Phase 1 + Phase 2 + a placeholder for remaining phases.

**Step 3: Commit (partial — phases 1-2)**

```bash
git add skills/ditch-vercel/SKILL.md
git commit -m "feat: rewrite SKILL.md phases 1-2 (scan + report with scoring)"
```

---

### Task 4: Rewrite SKILL.md — Phase 3 (PLAN + APPROVE)

**Files:**
- Modify: `skills/ditch-vercel/SKILL.md` (add Phase 3)

**Step 1: Write Phase 3**

Phase 3 combines old Steps 5+6 (Plan + Approve) with these improvements:
- Plan format stays the same (deps to add/remove, files to create/modify/delete, manual items)
- But now each plan item is tagged with its category (Automated/Attention/Blocker)
- Approval gate uses AskUserQuestion with 3 options:
  - "Yes, proceed with migration"
  - "Modify the plan" (loop: gather feedback → revise → re-approve)
  - "Cancel migration" (stop, no changes)
- **CRITICAL:** After approval, immediately create the task list using TaskCreate. Instructions:

```
After the developer approves:

1. Create tasks using TaskCreate for each migration action, in this exact order:
   a. "Create git safety checkpoint" (activeForm: "Creating safety checkpoint")
   b. One task per dependency to install (activeForm: "Installing [package]")
   c. One task per dependency to remove (activeForm: "Removing [package]")
   d. One task per file to create (activeForm: "Creating [filename]")
   e. One task per file to modify (activeForm: "Updating [filename]")
   f. One task per file to delete (activeForm: "Deleting [filename]")
   g. "Run build verification" (activeForm: "Verifying build")

2. Each task description should include the exact command or file change.
3. Do NOT combine multiple actions into one task. Each task = one atomic action.
```

**Step 2: Commit**

```bash
git add skills/ditch-vercel/SKILL.md
git commit -m "feat: add SKILL.md phase 3 (plan + approve + task creation)"
```

---

### Task 5: Rewrite SKILL.md — Phase 4 (EXECUTE with safety)

**Files:**
- Modify: `skills/ditch-vercel/SKILL.md` (add Phase 4)

**Step 1: Write Phase 4**

Phase 4 is the enhanced execution with safety nets and task tracking:

**4a. Git safety checkpoint:**
```
- Check git status. If working tree is dirty, run:
  git add -A && git commit -m "chore: pre-migration checkpoint (ditch-vercel)"
- If working tree is clean, note the current HEAD SHA.
- Store the checkpoint SHA.
- Mark the checkpoint task as completed.
- Output: "Safety checkpoint created (commit: <sha>). To undo: git reset --hard <sha>"
```

**4b-4f. Execute each action:**
```
For each remaining task:
1. Set task status to in_progress using TaskUpdate
2. Execute the action (install dep, remove dep, create file, modify file, delete file)
3. If successful: set task status to completed
4. If failed: keep status as in_progress, show error, ask developer:
   - "Fix it" → AI reads error and attempts fix, then retries
   - "Skip this step" → mark task description with "[SKIPPED]", continue
   - "Rollback everything" → run git reset --hard <checkpoint-sha>, mark all remaining tasks as deleted
```

**4g. Build verification:**
```
- Detect the build command:
  - Next.js + Cloudflare: npm run build:cf (or the script we added)
  - Astro: astro build
  - Remix: remix vite:build
  - SvelteKit: npm run build
  - Nuxt: nuxt build
  - Static with build script: npm run build
  - Static without build: skip (no build needed)
- Set build verification task to in_progress
- Run the build command via Bash
- If build passes: mark task completed
- If build fails:
  1. Show the error output (first 50 lines)
  2. Ask developer:
     - "Fix it" → AI reads error, attempts to fix the code, re-runs build
     - "Rollback everything" → git reset --hard <checkpoint-sha>
     - "Continue anyway" → mark task completed with note "[BUILD FAILED - manual fix needed]"
```

**Step 2: Commit**

```bash
git add skills/ditch-vercel/SKILL.md
git commit -m "feat: add SKILL.md phase 4 (execute with safety + task tracking)"
```

---

### Task 6: Rewrite SKILL.md — Phase 5 (DONE) + General Rules

**Files:**
- Modify: `skills/ditch-vercel/SKILL.md` (add Phase 5 + General Rules)

**Step 1: Write Phase 5**

Phase 5 is the enhanced completion phase:

```
Output the migration summary:

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
  1. [local dev command] — test locally
  2. [deploy command] — deploy to [target]
  3. Set environment variables in [target] dashboard
  4. [any other manual items]

  To undo everything:
  git reset --hard [checkpoint-sha]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Step 2: Write General Rules section**

Keep the existing general rules but add:
- "Always use TaskCreate/TaskUpdate to track execution progress"
- "Task #1 must always be the git safety checkpoint"
- "Never mark a task as completed if the action failed"
- Package manager detection rules (same as before)
- Monorepo awareness (same as before)
- One framework only (same as before)

**Step 3: Commit**

```bash
git add skills/ditch-vercel/SKILL.md
git commit -m "feat: add SKILL.md phase 5 (done) + general rules"
```

---

### Task 7: Update CLAUDE.md to reflect new flow

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update the architecture description**

Replace "8-step migration flow" with "5-phase migration flow" and update the description:

Replace the SKILL.md description line:
```
SKILL.md — Orchestrator: 8-step migration flow (the "main" file)
```
With:
```
SKILL.md — Orchestrator: 5-phase flow (scan → report → plan+approve → execute → done)
```

Update the architecture paragraph to mention:
- Complexity scoring (GREEN/YELLOW/RED)
- Task-driven progress tracking (TaskCreate/TaskUpdate)
- Git safety checkpoints
- Auto build verification

Update contributing conventions:
- Compatibility ratings must include Weight (0/1/3) and Category (Automated/Attention/Blocker)

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for new 5-phase flow"
```

---

### Task 8: Push to GitHub

**Step 1: Push all commits**

```bash
git push origin main
```

**Step 2: Verify**

```bash
git log --oneline -10
```

---

## Verification Checklist

After all tasks are complete, test by:
- [ ] Running `/ditch-vercel` in a sample Next.js + Vercel project
- [ ] Complexity score (GREEN/YELLOW/RED) appears first
- [ ] Categorized breakdown shows Automated / Attention / Blocker
- [ ] "No, just wanted to see" stops cleanly with no changes
- [ ] "Yes, proceed" creates task list via TaskCreate
- [ ] Task #1 is always the git safety checkpoint
- [ ] Each task transitions: pending → in_progress → completed
- [ ] Build verification runs automatically after file changes
- [ ] Undo instructions show the checkpoint SHA
- [ ] Failed task stays in_progress with recovery options
