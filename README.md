# ditch-vercel

**AI-powered migration away from Vercel. One command. Zero config.**

Analyzes your Vercel project, builds a migration plan, and executes it after your approval. Works with Claude Code, Cursor, GitHub Copilot, Codex, Windsurf, and other AI coding agents.

## Prerequisites

- **git** — required for the safety checkpoint (rollback on failure)
- **Node.js 18+** — required by most frameworks
- **wrangler** — required for Cloudflare deployments (`npm i -g wrangler`)
- **curl** or **wget** — required for the bash installer

## Quickstart

```bash
# In your Vercel project directory:
curl -fsSL https://raw.githubusercontent.com/umarmuhandis/ditch-vercel/main/install.sh | bash

# Then open your AI coding agent and run the migration
```

## Installation

### Claude Code plugin (recommended)

```bash
claude plugin marketplace add umarmuhandis/ditch-vercel
claude plugin install ditch-vercel
```

### Bash installer (universal, zero dependencies)

```bash
curl -fsSL https://raw.githubusercontent.com/umarmuhandis/ditch-vercel/main/install.sh | bash
```

Automatically detects installed agents, downloads skill files, and sets up adapters. Supports `--dry-run` and `--uninstall`.

### Manual

Copy the `skills/ditch-vercel/` directory and `AGENTS.md` into your project root. For agent-specific adapters, also copy the relevant file from `adapters/`.

### npx skills (legacy)

> **Note:** The `skills` npm package is maintained by Vercel Labs. If you'd rather avoid that dependency, use any of the methods above.

```bash
npx skills add umarmuhandis/ditch-vercel
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
AGENTS.md                     # Universal agent discovery (Linux Foundation standard)
install.sh                    # Zero-dependency bash installer
adapters/
  cursor.mdc                  # Cursor adapter
  windsurf.md                 # Windsurf adapter
  clinerules.md               # Cline/Roo adapter
skills/ditch-vercel/
  SKILL.md                    # Main orchestrator — the 5-phase migration flow
  frameworks/                 # Framework-specific migration knowledge
    nextjs.md, astro.md, remix.md, sveltekit.md, nuxt.md, static.md
  targets/                    # Target platform knowledge
    cloudflare.md, vps.md
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
