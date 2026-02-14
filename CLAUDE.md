# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code plugin (`claude plugin add github:umarmuhandis/ditch-vercel`) that automates migrating web apps from Vercel to other platforms. No build system, no tests, no compiled code — the entire plugin is markdown-based knowledge files that Claude follows as instructions.

## Architecture

```
.claude-plugin/plugin.json    → Plugin metadata (name, version, description)
skills/ditch-vercel/
  SKILL.md                    → Orchestrator: 5-phase flow (scan → report → plan+approve → execute → done)
  frameworks/<name>.md        → Per-framework migration knowledge (6 files)
  targets/<name>.md           → Per-target-platform knowledge (currently only cloudflare.md)
```

**SKILL.md** is the entry point. It defines a 5-phase flow: scan (detect framework + Vercel features + target) → report (complexity scoring with GREEN/YELLOW/RED traffic light) → plan+approve (hard gate) → execute (with git safety checkpoint, task-driven progress via TaskCreate/TaskUpdate, and auto build verification) → done (summary + undo instructions). Framework and target files are referenced from SKILL.md and read during execution.

**Framework files** (`nextjs.md`, `astro.md`, `remix.md`, `sveltekit.md`, `nuxt.md`, `static.md`) each contain: detection criteria, step-by-step migration instructions, and a compatibility matrix with Weight/Category/Status ratings for complexity scoring.

**Target files** (`cloudflare.md`) contain: scoring legend, Vercel-to-platform feature mapping with Weight/Category columns, known limitations, config templates (`wrangler.toml`), and CLI commands.

The separation is intentional — adding a new framework means creating one file in `frameworks/` and adding a row to SKILL.md Phase 1. Adding a new target means creating one file in `targets/` and updating Phase 1.

## Contributing Conventions

- When adding a framework: create `skills/ditch-vercel/frameworks/<name>.md`, then add detection entry to the table in SKILL.md Phase 1.
- When adding a target platform: create `skills/ditch-vercel/targets/<name>.md`, then update SKILL.md Phase 1.
- Use exact package names, file paths, and CLI commands — never be vague.
- Compatibility ratings must be one of: **Supported**, **Partial**, **Manual**.
- Compatibility entries must include **Weight** (0/1/3) and **Category** (Automated/Attention/Blocker).
- The Phase 3 approval gate is non-negotiable — no file changes before user approval.

## Commit Messages

Override global commit footer for this project. Use only:

```
---
Session: <current Claude Code session ID>
```

Do NOT include `Prompt:` line or `claude --resume` hint.
