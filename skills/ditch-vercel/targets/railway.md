# Railway — Target Platform Knowledge

## Platform Overview

- **Runtime:** Full Node.js via Nixpacks (auto-detected). Railway builds and runs apps from source code with zero configuration in most cases.
- **Tooling:** `railway` CLI for deploys, logs, and environment management. Git-integrated — push to deploy. Dashboard for project management, metrics, and settings.
- **Database addons:** Native PostgreSQL, MySQL, Redis, and MongoDB as one-click addons. No external provisioning needed.
- **Best for:** Teams wanting managed infrastructure without serverless constraints. Full Node.js access, native DB addons, preview environments via PR deploys, and predictable pricing based on usage.

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

Mapping of Vercel features to Railway equivalents. Use this to generate the compatibility report in Phase 2.

| Vercel Feature | Railway Equivalent | Weight | Category | Status | Notes |
|---|---|---|---|---|---|
| Serverless Functions | Native Node.js server | 0 | Automated | Supported | Framework runs as a standard Node.js process. No function isolation — all routes served by one process. |
| Edge Middleware | Node.js middleware | 0 | Automated | Supported | Runs as standard server-side middleware. No geo-distributed execution, but functionally equivalent. |
| Image Optimization | `sharp` (self-hosted) | 1 | Attention | Partial | Install `sharp` for local image optimization. Works out of the box with most frameworks. No CDN optimization — consider adding Cloudflare CDN (free tier) in front. |
| ISR | Framework cache (file-based) | 1 | Attention | Partial | Framework-native caching works. Railway has ephemeral filesystem — cache lost on redeploy. For persistent cache, use Railway Redis addon. |
| Cron Jobs | Railway Cron Service | 1 | Attention | Partial | Create a separate Railway service with a cron schedule. Different setup from `vercel.json` crons — requires a dedicated service or `node-cron` in-process. |
| Environment Variables | Dashboard / CLI | 0 | Automated | Supported | Set via `railway variables set KEY=VALUE` or the dashboard. Shared variables available across services. |
| Preview Deployments | PR Environments | 0 | Automated | Supported | Railway automatically creates isolated environments for pull requests. Enable in project settings. |
| `@vercel/analytics` | Plausible / Umami | 1 | Attention | Partial | Remove `@vercel/analytics`. Self-host Plausible or Umami, or use any third-party analytics provider. |
| `@vercel/speed-insights` | — | 1 | Attention | Manual | No direct equivalent. Remove `@vercel/speed-insights`. Use Lighthouse CI or custom RUM for performance monitoring. |
| `@vercel/og` | Works as-is | 0 | Automated | Supported | `@vercel/og` uses `satori` + `@resvg/resvg-js` under the hood. Works natively in Node.js environments. No changes needed. |
| `@vercel/blob` | Volume or S3 | 1 | Attention | Partial | For simple use: Railway Volume for persistent file storage. For production: use S3-compatible storage (AWS S3, MinIO, Backblaze B2) via `@aws-sdk/client-s3`. |
| `@vercel/kv` | Railway Redis addon | 1 | Attention | Partial | Add Redis via `railway add --plugin redis`. Replace `@vercel/kv` with `ioredis`. API mapping: `kv.get()` → `redis.get()`, `kv.set()` → `redis.set()`. |
| `@vercel/postgres` | Railway Postgres addon | 0 | Automated | Supported | Add Postgres via `railway add --plugin postgresql`. Replace `@vercel/postgres` with `pg`. Railway provides `DATABASE_URL` automatically. If using Prisma or Drizzle, just update the connection string. |
| `@vercel/edge` | Node.js runtime | 0 | Automated | Supported | Remove package + `export const runtime = 'edge'` declarations. Routes run in Node.js instead. |
| `@vercel/edge-config` | Redis or config file | 1 | Attention | Partial | Replace with Redis (`ioredis`) via Railway Redis addon for dynamic config, or a JSON config file for static config. |
| Monorepo | Service per app | 0 | Automated | Supported | Create a Railway service per app. Set the root directory in service settings. |
| Rewrites | Framework-native config | 0 | Automated | Supported | Move from `vercel.json` to framework-native config (e.g., `next.config.js` rewrites). |
| Redirects | Framework-native config | 0 | Automated | Supported | Move from `vercel.json` to framework-native config. |
| Headers | Framework-native config | 0 | Automated | Supported | Move from `vercel.json` to framework-native config. |

---

## Known Limitations

- **No edge compute.** Railway runs in a single region per service (or multi-region on Pro plan). No geo-distributed edge execution like Cloudflare Workers.
- **Sleep on free plan.** Hobby plan services sleep after inactivity. Pro plan services run 24/7.
- **No built-in CDN.** Static assets served from a single region. Mitigation: add Cloudflare CDN (free tier) in front of the Railway service for caching and global distribution.
- **Ephemeral filesystem.** File system changes are lost on redeploy. Use Railway Volumes for persistent storage, or external object storage (S3).
- **8 GB RAM limit.** Per service on most plans. Monitor via Railway metrics dashboard. If insufficient, scale horizontally by adding replicas.
- **20-minute build limit.** Builds exceeding 20 minutes are terminated. Optimize build steps or use a pre-built Docker image.
- **Cron requires separate service.** No built-in cron trigger on the primary service. Create a separate service with a cron schedule, or use `node-cron` in-process.
- **WebSocket idle timeout.** Connections idle for more than 5 minutes may be dropped. Implement heartbeat/ping-pong to keep connections alive.

---

## Configuration Templates

### `railway.json` (optional — Nixpacks auto-detects)

Railway auto-detects most frameworks via Nixpacks. Use `railway.json` for explicit control:

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "<start-command>",
    "healthcheckPath": "/",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

The `<start-command>` varies per framework — see framework knowledge files for the exact value.

### `railway.toml` (alternative format)

```toml
[build]
builder = "NIXPACKS"

[deploy]
startCommand = "<start-command>"
healthcheckPath = "/"
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

---

## Essential Commands

| Action | Command |
|--------|---------|
| Deploy | `railway up` |
| Local dev with Railway env vars | `railway run npm run dev` |
| View logs | `railway logs` |
| Set environment variable | `railway variables set KEY=VALUE` |
| Add PostgreSQL addon | `railway add --plugin postgresql` |
| Add Redis addon | `railway add --plugin redis` |
| Link to existing project | `railway link` |
| Open dashboard | `railway open` |
| Check service status | `railway status` |

## Reference URLs
- https://docs.railway.com/guides/frameworks
- https://docs.railway.com/reference/config-as-code
- llms.txt: https://docs.railway.com/llms.txt
