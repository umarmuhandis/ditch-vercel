# Nuxt — Vercel Migration

## Detection

**package.json:** `nuxt` in `dependencies` or `devDependencies`

**Config files:** `nuxt.config.ts`, `nuxt.config.js`

**Vercel indicator:** `vercel` preset in `nuxt.config`, or `NITRO_PRESET=vercel` environment variable, or `@nuxtjs/vercel-analytics` in modules

---

## Migration Steps (Cloudflare)

### 1. Set Nitro preset to Cloudflare Pages

Update `nuxt.config.ts` to use the `cloudflare-pages` preset:

```ts
export default defineNuxtConfig({
  nitro: {
    preset: 'cloudflare-pages',
  },
});
```

If the config previously had `preset: 'vercel'` or `preset: 'vercel-edge'`, replace it.

### 2. Remove Vercel-specific modules

If `nuxt.config.ts` uses Vercel-specific modules, remove them:

```ts
// Remove from modules array:
// - '@nuxtjs/vercel-analytics'
// - Any other Vercel-specific Nuxt module
```

Uninstall the packages:

```bash
npm uninstall @nuxtjs/vercel-analytics
```

### 3. Remove common Vercel packages

If the project uses any common Vercel packages, uninstall them:

```bash
npm uninstall @vercel/analytics @vercel/speed-insights @vercel/og
```

Only run for packages actually in `package.json`. Remove their imports and usage from source files (see Compatibility Notes for replacements).

### 4. Create `wrangler.toml`

Create `wrangler.toml` in the project root. Derive `name` from `package.json` `name`:

```toml
name = "<project-name-from-package.json>"
compatibility_date = "<today's date in YYYY-MM-DD format>"
compatibility_flags = ["nodejs_compat"]

[assets]
directory = ".output/public"
```

### 5. Update `package.json` scripts

```json
{
  "scripts": {
    "deploy": "nuxt build && wrangler pages deploy .output/public",
    "preview": "nuxt build && wrangler pages dev .output/public"
  }
}
```

Keep the existing `dev`, `build`, `generate`, and `postinstall` scripts unchanged.

### 6. Migrate `vercel.json` config

If `vercel.json` has rewrites/redirects/headers:
- **Redirects:** Create a `public/_redirects` file (format: `from to statusCode`)
- **Headers:** Create a `public/_headers` file (format: `[path]\n  Header-Name: value`)
- **Rewrites:** Create entries in `public/_redirects` with status `200`

Alternatively, Nuxt handles redirects and rewrites natively via `routeRules` in `nuxt.config.ts`:

```ts
export default defineNuxtConfig({
  routeRules: {
    '/old-path': { redirect: '/new-path' },
    '/api/**': { proxy: 'https://backend.example.com/**' },
  },
});
```

### 7. Migrate environment variables

Copy environment variable names from the Vercel dashboard (Settings > Environment Variables).

- **Non-secret values:** Add to `wrangler.toml` under `[vars]`
- **Secrets (API keys, tokens):** Use `wrangler secret put <NAME>`
- **Dashboard alternative:** Cloudflare dashboard > Workers/Pages > Settings > Environment Variables

### 8. Delete `vercel.json`

Remove `vercel.json` from the project root.

---

## Migration Steps (VPS)

### 1. Remove Vercel-specific modules

If `nuxt.config.ts` uses Vercel-specific modules, remove them:

```ts
// Remove from modules array:
// - '@nuxtjs/vercel-analytics'
// - Any other Vercel-specific Nuxt module
```

Uninstall the packages:

```bash
npm uninstall @nuxtjs/vercel-analytics
```

### 2. Remove common Vercel packages

If the project uses any common Vercel packages, uninstall them:

```bash
npm uninstall @vercel/analytics @vercel/speed-insights @vercel/og
```

Only run for packages actually in `package.json`. Remove their imports and usage from source files (see Compatibility Notes (VPS) for replacements).

### 3. Set Nitro preset to `node-server`

Update `nuxt.config.ts` to use the `node-server` preset:

```ts
export default defineNuxtConfig({
  nitro: {
    preset: 'node-server',
  },
});
```

If the config previously had `preset: 'vercel'` or `preset: 'vercel-edge'`, replace it.

### 4. Update `package.json` scripts

```json
{
  "scripts": {
    "start": "node .output/server/index.mjs"
  }
}
```

Keep the existing `dev`, `build`, `generate`, and `postinstall` scripts unchanged.

### 5. Create PM2 ecosystem config

Create `ecosystem.config.js` in the project root:

```js
module.exports = {
  apps: [{
    name: '<project-name-from-package.json>',
    script: '.output/server/index.mjs',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
    },
  }],
};
```

### 6. Migrate `vercel.json` and clean up

If `vercel.json` has rewrites/redirects/headers, move them to `routeRules` in `nuxt.config.ts`:

```ts
export default defineNuxtConfig({
  nitro: {
    preset: 'node-server',
  },
  routeRules: {
    '/old-path': { redirect: '/new-path' },
    '/api/**': { proxy: 'https://backend.example.com/**' },
  },
});
```

### 7. Migrate environment variables

Copy environment variable names from the Vercel dashboard (Settings > Environment Variables).

- Create or update `.env` in the project root
- For PM2: add to the `env` block in `ecosystem.config.js`

### 8. Delete `vercel.json`

Delete `vercel.json` from the project root.

---

## Compatibility Notes (Cloudflare)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| SSR | 0 | Automated | Supported | Nitro has native Cloudflare Pages preset. First-class support. |
| Static generation (`nuxt generate`) | 0 | Automated | Supported | Pre-rendered pages deploy as static assets on Cloudflare Pages. |
| Hybrid rendering (`routeRules`) | 0 | Automated | Supported | Per-route rendering rules work with the Cloudflare preset. |
| API routes (`server/api/`) | 0 | Automated | Supported | Run as Cloudflare Workers via Nitro. |
| Server middleware | 0 | Automated | Supported | Runs in the Worker. |
| Nitro route rules | 0 | Automated | Supported | `routeRules` for caching, redirects, prerendering work on Cloudflare. |

### Partial

| Feature | Weight | Category | Status | Action |
|---------|--------|----------|--------|--------|
| `nuxt/image` (`@nuxt/image`) | 1 | Attention | Partial | The Vercel provider (`provider: 'vercel'`) must be replaced. Use `provider: 'cloudflare'` for Cloudflare Image Resizing (requires compatible plan), or `provider: 'ipx'` for self-hosted optimization, or an external provider. |
| Node.js APIs | 1 | Attention | Partial | Workers runtime has limited Node.js compat. Use `nodejs_compat` flag. File system APIs are NOT available at runtime. |
| ISR | 1 | Attention | Partial | Nitro supports `routeRules` with `swr` (stale-while-revalidate) on Cloudflare. Configure cache duration per route. |
| NuxtHub | 0 | Automated | Supported | If using NuxtHub, it provides native Cloudflare KV, D1, and R2 bindings with zero config. Consider adopting NuxtHub for the easiest Cloudflare integration. |

### Manual

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@nuxtjs/vercel-analytics` | 1 | Attention | Cloudflare Web Analytics | Remove the module from `nuxt.config.ts` `modules` array. Uninstall the package. Add Cloudflare Web Analytics JS snippet to `app.vue` or a Nuxt plugin. |
| `@vercel/analytics` | 1 | Attention | Cloudflare Web Analytics | Remove the package. Add Cloudflare Web Analytics snippet. |
| `@vercel/speed-insights` | 1 | Attention | None (remove) | No direct equivalent. Remove the package. |
| `@vercel/blob` | 3 | Blocker | Cloudflare R2 | Different API. Access R2 via `hubBlob()` (NuxtHub) or Nitro's `useStorage()` with Cloudflare driver. |
| `@vercel/kv` | 1 | Attention | Cloudflare KV | Different API. Access KV via `hubKV()` (NuxtHub) or Nitro's `useStorage()` with Cloudflare KV driver. |
| `@vercel/postgres` | 3 | Blocker | Cloudflare D1 or Hyperdrive | D1 uses SQLite. Access via `hubDatabase()` (NuxtHub) or Nitro's `useDatabase()`. Hyperdrive can proxy existing Postgres. |
| `@vercel/edge` | 0 | Automated | Workers Runtime | Workers natively run at edge. Remove the package — no replacement needed. |
| `@vercel/edge-config` | 1 | Attention | Cloudflare KV | Replace with KV namespace. Access via `hubKV()` (NuxtHub) or Nitro's `useStorage()` with Cloudflare KV driver. |

---

## Compatibility Notes (VPS)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| SSR | 0 | Automated | Supported | Nitro `node-server` preset produces a self-contained Node.js server. |
| Static generation (`nuxt generate`) | 0 | Automated | Supported | Pre-rendered pages served as static files via Nginx or the Node.js server. |
| Hybrid rendering (`routeRules`) | 0 | Automated | Supported | Per-route rendering rules work with the `node-server` preset. |
| API routes (`server/api/`) | 0 | Automated | Supported | Run as part of the Nitro Node.js server. |
| Server middleware | 0 | Automated | Supported | Runs in the Node.js process. |
| Nitro route rules | 0 | Automated | Supported | `routeRules` for caching, redirects, prerendering work on Node.js. |
| Node.js APIs | 0 | Automated | Supported | Full Node.js API access — no restrictions. |
| ISR | 0 | Automated | Supported | Nitro supports `routeRules` with `swr` (stale-while-revalidate) natively on the `node-server` preset. |
| `nuxt/image` (`@nuxt/image`) | 0 | Automated | Supported | Replace `provider: 'vercel'` with `provider: 'ipx'` for self-hosted optimization. `ipx` uses `sharp` under the hood — works natively on VPS. |

### Manual

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@nuxtjs/vercel-analytics` | 1 | Attention | Plausible / Umami | Remove the module from `nuxt.config.ts` `modules` array. Uninstall the package. Self-host Plausible or Umami, or add any analytics provider. |
| `@vercel/analytics` | 1 | Attention | Plausible / Umami | Remove the package. Add analytics provider snippet. |
| `@vercel/speed-insights` | 1 | Attention | None (remove) | No direct equivalent. Remove the package. |
| `@vercel/blob` | 1 | Attention | Local filesystem or S3 SDK | Replace with Nitro's `useStorage()` with filesystem driver, or `@aws-sdk/client-s3` for S3-compatible storage. |
| `@vercel/kv` | 1 | Attention | Redis (`ioredis`) | Install Redis. Replace with Nitro's `useStorage()` with Redis driver, or use `ioredis` directly. |
| `@vercel/postgres` | 1 | Attention | PostgreSQL (`pg`) | Install PostgreSQL. Replace `@vercel/postgres` with `pg` or Nitro's `useDatabase()` with PostgreSQL driver. If using Prisma or Drizzle, just update the connection string. |
| `@vercel/edge` | 0 | Automated | Node.js runtime | Remove the package. No replacement needed — Nuxt on VPS runs in full Node.js via Nitro. |
| `@vercel/edge-config` | 1 | Attention | Redis or config file | Replace with Redis via Nitro's `useStorage()` with Redis driver, or use a JSON config file for static config. |

## Migration Steps (Railway)

### 1. Remove Vercel-specific modules

If `nuxt.config.ts` uses Vercel-specific modules, remove them:

```ts
// Remove from modules array:
// - '@nuxtjs/vercel-analytics'
// - Any other Vercel-specific Nuxt module
```

Uninstall the packages:

```bash
npm uninstall @nuxtjs/vercel-analytics
```

### 2. Remove common Vercel packages

If the project uses any common Vercel packages, uninstall them:

```bash
npm uninstall @vercel/analytics @vercel/speed-insights @vercel/og @vercel/edge @vercel/edge-config
```

Only run for packages actually in `package.json`. Remove their imports and usage from source files (see Compatibility Notes (Railway) for replacements).

### 3. Set Nitro preset to `node-server`

Update `nuxt.config.ts` to use the `node-server` preset:

```ts
export default defineNuxtConfig({
  nitro: {
    preset: 'node-server',
  },
});
```

If the config previously had `preset: 'vercel'` or `preset: 'vercel-edge'`, replace it.

### 4. Update `package.json` scripts

```json
{
  "scripts": {
    "start": "node .output/server/index.mjs"
  }
}
```

Keep the existing `dev`, `build`, `generate`, and `postinstall` scripts unchanged.

### 5. Create `railway.json` (recommended)

Create `railway.json` in the project root for explicit control:

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "node .output/server/index.mjs",
    "healthcheckPath": "/",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

This is optional — Railway auto-detects Nuxt via Nixpacks, but explicit config gives more control.

### 6. Replace Vercel data packages

Migrate Vercel SDK packages to Railway-native equivalents:
- `@vercel/kv` → `ioredis` + Railway Redis addon (`railway add --plugin redis`), or use Nitro's `useStorage()` with Redis driver
- `@vercel/postgres` → `pg` + Railway Postgres addon (`railway add --plugin postgresql`). Railway provides `DATABASE_URL` automatically. Or use Nitro's `useDatabase()`.
- `@vercel/blob` → `@aws-sdk/client-s3` with S3-compatible storage, or Railway Volume, or Nitro's `useStorage()` with filesystem driver

### 7. Migrate `vercel.json` and clean up

If `vercel.json` has rewrites/redirects/headers, move them to `routeRules` in `nuxt.config.ts`:

```ts
export default defineNuxtConfig({
  nitro: {
    preset: 'node-server',
  },
  routeRules: {
    '/old-path': { redirect: '/new-path' },
    '/api/**': { proxy: 'https://backend.example.com/**' },
  },
});
```

### 8. Migrate environment variables

Copy environment variable names from the Vercel dashboard (Settings > Environment Variables).

- Use `railway variables set KEY=VALUE` via CLI
- Or set via the Railway dashboard > Service > Variables tab
- Railway provides database connection strings automatically when addons are linked

### 9. Delete `vercel.json`

Delete `vercel.json` from the project root.

---

## Compatibility Notes (Railway)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| SSR | 0 | Automated | Supported | Nitro `node-server` preset produces a self-contained Node.js server. |
| Static generation (`nuxt generate`) | 0 | Automated | Supported | Pre-rendered pages served as static files by the Node.js server. |
| Hybrid rendering (`routeRules`) | 0 | Automated | Supported | Per-route rendering rules work with the `node-server` preset. |
| API routes (`server/api/`) | 0 | Automated | Supported | Run as part of the Nitro Node.js server. |
| Server middleware | 0 | Automated | Supported | Runs in the Node.js process. |
| Nitro route rules | 0 | Automated | Supported | `routeRules` for caching, redirects, prerendering work on Node.js. |
| Node.js APIs | 0 | Automated | Supported | Full Node.js API access — no restrictions. |
| ISR | 0 | Automated | Supported | Nitro supports `routeRules` with `swr` (stale-while-revalidate) natively on the `node-server` preset. |
| `nuxt/image` (`@nuxt/image`) | 0 | Automated | Supported | Replace `provider: 'vercel'` with `provider: 'ipx'` for self-hosted optimization. `ipx` uses `sharp` under the hood — works natively on Railway. |
| `@vercel/edge` | 0 | Automated | Supported | Remove the package. No replacement needed — Nuxt on Railway runs in full Node.js via Nitro. |
| Preview Deployments | 0 | Automated | Supported | Railway automatically creates isolated environments for PRs. |

### Manual

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@nuxtjs/vercel-analytics` | 1 | Attention | Plausible / Umami | Remove the module from `nuxt.config.ts` `modules` array. Uninstall the package. Self-host Plausible or Umami, or add any analytics provider. |
| `@vercel/analytics` | 1 | Attention | Plausible / Umami | Remove the package. Add analytics provider snippet. |
| `@vercel/speed-insights` | 1 | Attention | None (remove) | No direct equivalent. Remove the package. |
| `@vercel/blob` | 1 | Attention | Railway Volume or S3 SDK | Replace with Nitro's `useStorage()` with filesystem driver and Railway Volume, or `@aws-sdk/client-s3` for S3-compatible storage. |
| `@vercel/kv` | 1 | Attention | Redis (`ioredis`) | Add Redis via `railway add --plugin redis`. Replace with Nitro's `useStorage()` with Redis driver, or use `ioredis` directly. |
| `@vercel/postgres` | 0 | Automated | Railway Postgres addon | Add Postgres via `railway add --plugin postgresql`. Replace `@vercel/postgres` with `pg` or Nitro's `useDatabase()` with PostgreSQL driver. Railway provides `DATABASE_URL` automatically. If using Prisma or Drizzle, just update the connection string. |
| `@vercel/edge-config` | 1 | Attention | Redis or config file | Replace with Redis via Nitro's `useStorage()` with Redis driver on Railway Redis addon, or use a JSON config file for static config. |

---

## Reference URLs
- https://nitro.build/deploy/providers/cloudflare
- https://developers.cloudflare.com/pages/framework-guide/deploy-a-nuxt-site/
- llms.txt: https://nuxt.com/llms.txt
- llms.txt: https://nitro.build/llms.txt
