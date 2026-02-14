# ditch-vercel DX Overhaul — Design Doc

## Context

The v1 plugin works but skips the emotional journey. It goes straight to "here's the plan, approve it" without reducing anxiety first, providing safety nets during execution, or verifying success after. The dream DX transforms **anxiety into confidence** at every stage.

## Core Principle

> Every `/ditch-vercel` run starts by answering: "How hard is this?" — before asking the developer to commit to anything.

## The New Flow

5 phases replace the current 8 steps:

```
Phase 1: SCAN
  Detect framework + Vercel features + ask target platform
  (Steps 1-3 combined into one fast, silent phase)

Phase 2: REPORT  ← NEW — the anxiety reducer
  Show complexity score (GREEN/YELLOW/RED + time estimate)
  Categorize features: Automated / Needs Attention / Not Supported
  Ask: "Ready to migrate?" or "No, just wanted to see"

Phase 3: PLAN + APPROVE
  Show exact file changes, deps to add/remove, manual items
  Get explicit consent before any changes

Phase 4: EXECUTE  ← ENHANCED with safety
  Git checkpoint → make changes → run build → verify
  If build fails: offer fix / rollback / continue

Phase 5: DONE  ← ENHANCED with verification
  Summary + attention items + next steps + undo instructions
```

## Complexity Scoring System

Each Vercel feature gets a weight based on migration difficulty to the target:

| Weight | Category | Meaning |
|--------|----------|---------|
| 0 | Automated | ditch-vercel handles this entirely |
| 1 | Attention | Works but needs minor manual adjustment |
| 3 | Blocker | Significant effort, may prevent migration |

**Traffic light:**
```
Total = sum of all detected feature weights

🟢 GREEN  (0-2):  ~1-2 hours — mostly automated
🟡 YELLOW (3-6):  ~3-5 hours — several manual steps
🔴 RED    (7+):   ~1-2 days  — significant refactoring or blockers
```

**Weights are defined in knowledge files** (framework + target), so they can be tuned per combination.

## Report Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MIGRATION COMPLEXITY: 🟢 GREEN
  Estimated effort: ~1-2 hours
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  AUTOMATED (ditch-vercel handles these):
  ✅ Config migration (vercel.json → wrangler.toml)
  ✅ Adapter swap (@opennextjs/cloudflare)
  ✅ Build script updates
  ✅ 3 API routes → Workers
  ✅ 7 environment variables mapped

  NEEDS YOUR ATTENTION:
  ⚠️  @vercel/analytics → Remove or add Cloudflare Web Analytics
  ⚠️  next/image (4 files) → Needs Cloudflare Image Resizing plan

  NOT SUPPORTED ON TARGET:
  ❌ @vercel/speed-insights → No equivalent. Will be removed.
```

## Task-Driven Progress Tracking

The SKILL.md must instruct Claude to use **TaskCreate / TaskUpdate / TaskList** to give the developer real-time, visual progress tracking throughout the migration. Instead of a wall of text, the developer sees tasks appear, spin as in-progress, and check off as completed.

**How it works:**

After the developer approves the migration plan (Phase 3), Claude creates a task list based on the specific migration steps for THIS project. Example:

```
Tasks created for migration:

#1. [pending]      Create git safety checkpoint
#2. [pending]      Install @opennextjs/cloudflare
#3. [pending]      Remove @vercel/analytics, @vercel/speed-insights
#4. [pending]      Create wrangler.toml
#5. [pending]      Update next.config.mjs (add OpenNext config)
#6. [pending]      Update package.json scripts
#7. [pending]      Delete vercel.json
#8. [pending]      Run build verification
```

As Claude executes each step, the developer sees:
```
#1. [completed]    Create git safety checkpoint
#2. [in_progress]  Install @opennextjs/cloudflare    ← spinner
#3. [pending]      Remove @vercel/analytics, @vercel/speed-insights
...
```

**Rules for task creation:**
- Tasks are created ONLY after the developer approves the plan (Phase 3)
- Each task corresponds to one atomic, reversible action
- Task descriptions include the exact command or file change
- `activeForm` shows present-tense action (e.g., "Installing @opennextjs/cloudflare")
- Tasks marked `completed` only when the step is verified successful
- If a task fails, it stays `in_progress` and Claude presents recovery options

**Task categories (always in this order):**
1. Safety checkpoint (git commit)
2. Dependency additions
3. Dependency removals
4. File creations (new config files)
5. File modifications (existing config updates)
6. File deletions (Vercel-specific files)
7. Build verification
8. (If build fails) Recovery tasks

This gives the developer:
- A sense of **progress** — items checking off feels satisfying
- A sense of **control** — they can see exactly where things are
- A sense of **safety** — task #1 is always the git checkpoint
- Easy **debugging** — if something fails, they know exactly which step broke

## Safety Net: Git Checkpoint + Build Verification

**Before execution:**
- Auto-commit current state (or stash if working tree is dirty)
- Print undo command: `git reset --hard <sha>`

**After execution:**
- Run `npm run build` (or framework equivalent) automatically
- If build passes: show success summary
- If build fails: show error + offer 3 options:
  1. **Fix it** — AI reads the error and fixes the code
  2. **Rollback** — undo all changes to checkpoint
  3. **Continue** — developer will fix manually

**Final output always includes:**
```
To undo everything: git reset --hard <sha>
```

## Knowledge File Updates

Each compatibility entry in framework + target files needs a weight column:

```markdown
| Vercel Feature | Cloudflare Equivalent | Weight | Category | Notes |
|---|---|---|---|---|
| vercel.json | wrangler.toml | 0 | Automated | Direct conversion |
| @vercel/analytics | Web Analytics | 1 | Attention | Different SDK |
| @vercel/postgres | D1 / Hyperdrive | 3 | Blocker | Schema conversion needed |
```

## SKILL.md allowed-tools Update

The frontmatter must add task tools:
```yaml
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TaskCreate, TaskUpdate, TaskList
```

## Files to Modify

1. **`skills/ditch-vercel/SKILL.md`** — Rewrite to 5-phase flow with scoring + safety + task tracking
2. **`skills/ditch-vercel/targets/cloudflare.md`** — Add weight column to compatibility matrix
3. **`skills/ditch-vercel/frameworks/nextjs.md`** — Add weight per Vercel feature (Cloudflare-specific)
4. **`skills/ditch-vercel/frameworks/astro.md`** — Same
5. **`skills/ditch-vercel/frameworks/remix.md`** — Same
6. **`skills/ditch-vercel/frameworks/sveltekit.md`** — Same
7. **`skills/ditch-vercel/frameworks/nuxt.md`** — Same
8. **`skills/ditch-vercel/frameworks/static.md`** — Same

## Verification

Test the new flow by:
1. Running `/ditch-vercel` in a sample Next.js + Vercel project
2. Verify the complexity score appears FIRST
3. Verify categorized breakdown is correct (Automated / Attention / Blocker)
4. Say "No, just wanted to see" — verify it stops cleanly
5. Run again, proceed to migration
6. Verify git checkpoint is created
7. Verify build runs automatically after execution
8. Verify undo instructions are shown
9. Test build failure scenario — verify fix/rollback/continue options work
10. Verify tasks are created after plan approval (not before)
11. Verify each migration step updates its task status (pending → in_progress → completed)
12. Verify failed steps stay in_progress with recovery options
13. Verify task #1 is always the git safety checkpoint
