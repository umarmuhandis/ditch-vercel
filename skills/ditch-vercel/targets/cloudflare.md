# Cloudflare — Target Platform Knowledge

## Platform Overview

- **Cloudflare Workers** — Serverless compute at the edge. Runs JavaScript/TypeScript on Cloudflare's global network. Best for dynamic apps, APIs, and full-stack frameworks.
- **Cloudflare Pages** — Static + SSR hosting platform. Originally static-only, now supports full-stack via Pages Functions (which are Workers under the hood). Cloudflare is merging Pages into Workers.
- **Recommendation:** Use Workers for dynamic/full-stack apps. Use Pages for static or hybrid sites. For most Vercel migrations, Workers (via OpenNext or framework adapter) is the right choice.

---

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

---

## Compatibility Matrix

Mapping of Vercel features to Cloudflare equivalents. Use this to generate the compatibility report in Phase 2.

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

---

## Known Limitations

- **Worker bundle size:** 25 MiB compressed on paid plans. 10 MiB compressed on the free plan (Pages). If the Vercel project has a large bundle, this can be a blocker — recommend aggressive code-splitting and dynamic imports.
- **Node.js API compatibility:** Not all Node.js built-ins are available. Mitigated by the `nodejs_compat` compatibility flag, which enables most common APIs (`Buffer`, `crypto`, `streams`, etc.). Some packages relying on native addons or unsupported APIs will fail.
- **No serverless function dashboard:** Unlike Vercel's function logs UI, Cloudflare has no built-in dashboard for Workers logs. Use `wrangler tail` for real-time streaming logs, or Cloudflare Logpush for persistent logging.
- **No build cache persistence:** Cloudflare does not persist build caches between deployments (unlike Vercel). Builds start fresh each time.
- **Memory limit:** Workers have a 128 MB memory limit (both free and paid). Not configurable. Large in-memory operations (e.g., image processing, large JSON parsing) may hit this limit.
- **CPU time limit:** 10 ms on free plan, 30 s on paid (Bundled) or 15 min (Unbound). Long-running computations may need to be restructured.
- **No native monorepo detection:** Unlike Vercel's root directory setting, Cloudflare requires manual build output path configuration for monorepos.
- **WebSocket support:** Available but requires Workers configuration. Not automatic like Vercel's edge functions.

---

## General `wrangler.toml` Template

Base configuration for any framework. Framework-specific files (e.g., `nextjs.md`) extend this with additional fields like `main` and `[assets]`.

```toml
name = "<project-name>"
compatibility_date = "2024-09-23"
compatibility_flags = ["nodejs_compat"]
```

**With KV namespace:**
```toml
[[kv_namespaces]]
binding = "KV"
id = "<namespace-id>"
```

**With R2 bucket:**
```toml
[[r2_buckets]]
binding = "BUCKET"
bucket_name = "<bucket-name>"
```

**With D1 database:**
```toml
[[d1_databases]]
binding = "DB"
database_name = "<db-name>"
database_id = "<db-id>"
```

**With Cron Triggers:**
```toml
[triggers]
crons = ["0 * * * *", "*/15 * * * *"]
```

---

## Essential Commands

| Action | Command |
|--------|---------|
| Deploy | `npx wrangler deploy` |
| Local dev | `npx wrangler dev` |
| Pages deploy | `npx wrangler pages deploy <directory>` |
| Pages dev | `npx wrangler pages dev <directory>` |
| Stream logs | `npx wrangler tail` |
| Set secret | `npx wrangler secret put SECRET_NAME` |
| List secrets | `npx wrangler secret list` |
| Create KV namespace | `npx wrangler kv namespace create <NAME>` |
| Create R2 bucket | `npx wrangler r2 bucket create <NAME>` |
| Create D1 database | `npx wrangler d1 create <NAME>` |

## Reference URLs
- https://developers.cloudflare.com/pages/migrations/migrating-from-vercel/
- https://developers.cloudflare.com/workers/frameworks/
- llms.txt: https://developers.cloudflare.com/llms.txt
