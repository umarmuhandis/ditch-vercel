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

1. **Scan** — Detects your framework, scans every `@vercel/*` dependency and Vercel-specific feature, and asks you to pick a target platform
2. **Report** — Calculates a complexity score (GREEN / YELLOW / RED) showing estimated effort, automated items, attention items, and blockers
3. **Plan + Approve** — Generates a concrete migration plan with exact file paths, package changes, and code modifications. **Nothing changes until you approve**
4. **Execute** — Creates a git safety checkpoint, then installs packages, swaps adapters, rewrites configs, removes Vercel dependencies, and runs build + dev server verification
5. **Done** — Prints a summary of all changes, remaining manual items, deploy commands, and undo instructions

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
