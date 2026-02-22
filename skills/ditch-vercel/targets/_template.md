# [Platform Name] — Target Platform Knowledge

## Platform Overview

<!-- High-level description of the platform: runtime, tooling, and what it's best for. -->

- **Runtime:** Description of the compute environment
- **Tooling:** Key CLI tools and deployment mechanisms
- **Best for:** Target use cases and strengths

---

## Scoring

<!-- Copy this table verbatim — it's the universal scoring legend used across all targets. -->

Each feature has a weight used to calculate migration complexity:

| Weight | Category | Meaning |
|--------|----------|---------|
| 0 | Automated | ditch-vercel handles this entirely |
| 1 | Attention | Works but needs minor manual adjustment |
| 3 | Blocker | Significant effort, may prevent migration |

**Traffic light score** (sum of weights for detected features):
- GREEN (0-2): ~1-2 hours — mostly automated
- YELLOW (3-6): ~3-5 hours — several manual steps
- RED (7+): ~1-2 days — significant refactoring or blockers

---

## Compatibility Matrix

<!-- Mapping of Vercel features to this platform's equivalents.
     Used by SKILL.md Phase 2 to generate the compatibility report.

     Every row must include Weight, Category, and Status columns.
     Weight: 0 (Automated), 1 (Attention), 3 (Blocker)
     Category: Automated, Attention, Blocker
     Status: Supported, Partial, Manual
-->

| Vercel Feature | [Platform] Equivalent | Weight | Category | Status | Notes |
|---|---|---|---|---|---|
| Serverless Functions | [equivalent] | 0 | Automated | Supported | How it maps |
| Edge Middleware | [equivalent] | 0 | Automated | Supported | How it maps |
| Image Optimization | [equivalent or "—"] | 1 | Attention | Partial | What the developer needs to do |
| ISR | [equivalent or "—"] | 1 | Attention | Partial | How caching works on this platform |
| Cron Jobs | [equivalent] | 1 | Attention | Partial | Syntax/config differences |
| Environment Variables | [mechanism] | 0 | Automated | Supported | How env vars are configured |
| Preview Deployments | [mechanism or "—"] | 0 | Automated | Supported | How previews work |
| `@vercel/analytics` | [alternative] | 1 | Attention | Manual | Replacement instructions |
| `@vercel/speed-insights` | [alternative or "—"] | 1 | Attention | Manual | Replacement instructions |
| `@vercel/og` | [equivalent] | 1 | Attention | Partial | What changes are needed |
| `@vercel/blob` | [equivalent] | 3 | Blocker | Partial | API differences and migration effort |
| `@vercel/kv` | [equivalent] | 1 | Attention | Partial | API differences |
| `@vercel/postgres` | [equivalent] | 3 | Blocker | Partial | Migration path |
| `@vercel/edge` | [equivalent] | 0 | Automated | Supported | Edge runtime mapping |
| `@vercel/edge-config` | [equivalent] | 1 | Attention | Partial | Config store replacement |
| Rewrites | [mechanism] | 0 | Automated | Supported | Config format |
| Redirects | [mechanism] | 0 | Automated | Supported | Config format |
| Headers | [mechanism] | 0 | Automated | Supported | Config format |

---

## Known Limitations

<!-- Bulleted list of platform-specific constraints that may affect migration.
     Include: size limits, runtime restrictions, missing features, pricing tiers. -->

- **Limitation 1:** Description and impact
- **Limitation 2:** Description and impact

---

## Configuration Templates

<!-- Config file stubs with <placeholder> markers for project-specific values.
     Include the primary deployment config and any supplementary configs. -->

### Primary config file

```
# Example: wrangler.toml, ecosystem.config.js, etc.
<placeholder> = "<value>"
```

<!-- Add additional config templates as needed (reverse proxy, systemd, Dockerfile, etc.) -->

---

## Essential Commands

<!-- Action-to-command mapping table. Include deploy, dev, logs, and platform-specific commands. -->

| Action | Command |
|--------|---------|
| Deploy | `<deploy-command>` |
| Local dev | `<dev-command>` |
| View logs | `<logs-command>` |
| Set secret | `<secret-command>` |

## Reference URLs

<!-- List official documentation URLs for this platform's deployment/migration guides.
     Prefix machine-readable LLM doc indexes with "llms.txt:" — the skill prefers these
     for doc verification in Phase 3-pre.
-->
- https://example.com/docs/deployment
- llms.txt: https://example.com/docs/llms.txt
