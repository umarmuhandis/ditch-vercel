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

### 3. Create `wrangler.toml`

Create `wrangler.toml` in the project root. Derive `name` from `package.json` `name`:

```toml
name = "<project-name-from-package.json>"
compatibility_date = "2024-09-23"
compatibility_flags = ["nodejs_compat"]

[assets]
directory = "dist/"
```

### 4. Update `package.json` scripts

```json
{
  "scripts": {
    "deploy": "nuxt build && wrangler pages deploy dist/",
    "preview": "nuxt build && wrangler pages dev dist/"
  }
}
```

Keep the existing `dev`, `build`, `generate`, and `postinstall` scripts unchanged.

### 5. Migrate `vercel.json` config

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

### 6. Delete `vercel.json`

Remove `vercel.json` from the project root.

---

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

### 2. Set Nitro preset to `node-server`

Update `nuxt.config.ts` to use the `node-server` preset:

```ts
export default defineNuxtConfig({
  nitro: {
    preset: 'node-server',
  },
});
```

If the config previously had `preset: 'vercel'` or `preset: 'vercel-edge'`, replace it.

### 3. Update `package.json` scripts

```json
{
  "scripts": {
    "start": "node .output/server/index.mjs"
  }
}
```

Keep the existing `dev`, `build`, `generate`, and `postinstall` scripts unchanged.

### 4. Create PM2 ecosystem config

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

### 5. Migrate `vercel.json` and clean up

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

### Partial

| Feature | Weight | Category | Status | Action |
|---------|--------|----------|--------|--------|
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

## Reference URLs
- https://nitro.build/deploy/providers/cloudflare
- https://developers.cloudflare.com/pages/framework-guide/deploy-a-nuxt-site/
- llms.txt: https://nuxt.com/llms.txt
- llms.txt: https://nitro.build/llms.txt
