# ditch-vercel

**AI-powered migration away from Vercel. One command. Zero config.**

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that analyzes your Vercel project, builds a migration plan, and executes it after your approval.

## Installation

```bash
claude plugin add github:umarmuhandis/ditch-vercel
```

## Usage

```bash
cd your-vercel-project
claude
> /ditch-vercel
```

That's it. The plugin handles the rest.

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
| Railway | Planned |
| Fly.io | Planned |
| VPS / Docker | Planned |

## Project Structure

```
skills/ditch-vercel/
  SKILL.md              # Main orchestrator — the 8-step migration flow
  frameworks/           # Framework-specific migration knowledge
    nextjs.md
    astro.md
    remix.md
    sveltekit.md
    nuxt.md
    static.md
  targets/              # Target platform knowledge
    cloudflare.md
```

## Contributing

### Add a new framework

Create `skills/ditch-vercel/frameworks/<framework>.md` with:

- Detection criteria (package.json deps, config files)
- Step-by-step migration instructions
- Compatibility notes (Supported / Partial / Manual)

Then add the framework to the detection table in `SKILL.md` Step 1.

### Add a new target platform

Create `skills/ditch-vercel/targets/<target>.md` with:

- Platform overview
- Compatibility matrix (Vercel feature -> equivalent)
- Known limitations
- Config templates
- Essential CLI commands

Then add the target to `SKILL.md` Step 3.

## License

[MIT](LICENSE)
