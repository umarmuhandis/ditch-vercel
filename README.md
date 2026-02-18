# ditch-vercel

**AI-powered migration away from Vercel. One command. Zero config.**

An [agent skill](https://www.npmjs.com/package/skills) that analyzes your Vercel project, builds a migration plan, and executes it after your approval. Works with Claude Code, Cursor, GitHub Copilot, Codex, Windsurf, and other AI coding agents.

## Installation

```bash
npx skills add umarmuhandis/ditch-vercel
```

The interactive installer will prompt you to:

1. **Select agents** — Choose which AI coding agents to install to (Claude Code, Cursor, Copilot, Codex, Windsurf, etc.)
2. **Choose scope** — Project-level (shared with your team via git) or global (available in all your projects)
3. **Confirm** — Review what will be installed and where

### Agent-specific install

```bash
# Single agent
npx skills add umarmuhandis/ditch-vercel -a claude-code
npx skills add umarmuhandis/ditch-vercel -a cursor
npx skills add umarmuhandis/ditch-vercel -a copilot
npx skills add umarmuhandis/ditch-vercel -a codex
npx skills add umarmuhandis/ditch-vercel -a windsurf

# Multiple agents at once
npx skills add umarmuhandis/ditch-vercel -a claude-code -a cursor -a copilot
```

### Scope

```bash
# Project-level (default) — committed to git, shared with team
npx skills add umarmuhandis/ditch-vercel

# Global — installed to your home directory, available everywhere
npx skills add umarmuhandis/ditch-vercel -g
```

### Claude Code plugin (alternative)

```bash
claude plugin add github:umarmuhandis/ditch-vercel
```

## Usage

After installing, open your AI coding agent in a Vercel project:

| Agent | How to invoke |
|-------|--------------|
| **Claude Code** | `/ditch-vercel` |
| **Cursor** | Ask: *"migrate this project from Vercel"* |
| **GitHub Copilot** | Ask: *"use the ditch-vercel skill to migrate"* |
| **Codex** | Ask: *"run the ditch-vercel migration"* |
| **Windsurf** | Ask: *"migrate from Vercel using ditch-vercel"* |

The skill handles the rest — framework detection, compatibility analysis, migration planning, approval gate, and execution.

## How It Works

1. **Detect framework** — Identifies Next.js, Astro, Remix, SvelteKit, Nuxt, or static site
2. **Scan Vercel features** — Finds all `@vercel/*` packages, edge runtime usage, ISR, middleware, cron jobs, image optimization, etc.
3. **Select target** — Picks the target platform (Cloudflare in v1)
4. **Analyze compatibility** — Cross-references every detected feature against the target's support matrix
5. **Build migration plan** — Produces a concrete plan with exact file paths, package changes, and code modifications
6. **Get approval** — Presents the plan for your review. Nothing changes until you say "yes"
7. **Execute** — Installs packages, swaps adapters, rewrites configs, removes Vercel dependencies
8. **Next steps** — Prints a post-migration checklist: build commands, deploy commands, manual items

## Supported Frameworks

| Framework | Config Detection |
|-----------|-----------------|
| Next.js | `next` in deps, `next.config.*` |
| Astro | `astro` in deps, `astro.config.*` |
| Remix | `@remix-run/*` in deps |
| SvelteKit | `@sveltejs/kit` in deps, `svelte.config.*` |
| Nuxt | `nuxt` in deps, `nuxt.config.*` |
| Static | No framework deps detected |

## Supported Targets

| Target | Status |
|--------|--------|
| **Cloudflare** (Workers + Pages) | Available |
| **VPS** (Node.js + PM2 + Nginx) | Available |
| Railway | Planned |
| Fly.io | Planned |

## Project Structure

```
skills/ditch-vercel/
  SKILL.md              # Main orchestrator — the 5-phase migration flow
  frameworks/           # Framework-specific migration knowledge
    nextjs.md
    astro.md
    remix.md
    sveltekit.md
    nuxt.md
    static.md
  targets/              # Target platform knowledge
    cloudflare.md
    vps.md
```

## Contributing

### Add a new framework

Create `skills/ditch-vercel/frameworks/<framework>.md` with:

- Detection criteria (package.json deps, config files)
- Step-by-step migration instructions
- Compatibility notes (Supported / Partial / Manual)

Then add the framework to the detection table in `SKILL.md` Phase 1.

### Add a new target platform

Create `skills/ditch-vercel/targets/<target>.md` with:

- Platform overview
- Compatibility matrix (Vercel feature -> equivalent)
- Known limitations
- Config templates
- Essential CLI commands

Then add the target to `SKILL.md` Phase 1.

## License

[MIT](LICENSE)
