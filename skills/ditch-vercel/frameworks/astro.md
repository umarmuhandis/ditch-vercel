# Astro — Vercel Migration

## Detection

**package.json:** `astro` in `dependencies` or `devDependencies`

**Config files:** `astro.config.mjs`, `astro.config.ts`, `astro.config.js`

**Vercel adapter indicator:** `@astrojs/vercel` in `dependencies` or `devDependencies`

---

## Migration Steps (Cloudflare)

### 1. Uninstall Vercel adapter

```bash
npm uninstall @astrojs/vercel
```

### 2. Install Cloudflare adapter

```bash
npm install @astrojs/cloudflare
```

### 3. Update `astro.config.mjs`

Replace the Vercel adapter import and configuration with Cloudflare:

**Before:**
```js
import vercel from '@astrojs/vercel/serverless';
// or: import vercel from '@astrojs/vercel';

export default defineConfig({
  output: 'server',
  adapter: vercel(),
});
```

**After:**
```js
import cloudflare from '@astrojs/cloudflare';

export default defineConfig({
  output: 'server', // or 'hybrid' for selective prerendering
  adapter: cloudflare(),
});
```

If the project uses `output: 'static'` (no adapter), no adapter swap is needed — just set up Cloudflare Pages for static hosting (see `static.md`).

### 4. Create `wrangler.toml`

Create `wrangler.toml` in the project root. Derive `name` from `package.json` `name`:

```toml
name = "<project-name-from-package.json>"
compatibility_date = "2024-09-23"
compatibility_flags = ["nodejs_compat"]

[assets]
directory = "./dist/client"
```

### 5. Update `package.json` scripts

Add/replace these scripts:

```json
{
  "scripts": {
    "deploy": "astro build && wrangler pages deploy dist/",
    "preview": "astro build && wrangler pages dev dist/"
  }
}
```

Keep the existing `dev` and `build` scripts unchanged.

### 6. Migrate `vercel.json` config

If `vercel.json` has rewrites/redirects/headers:
- **Redirects:** Create a `public/_redirects` file (format: `from to statusCode`)
- **Headers:** Create a `public/_headers` file (format: `[path]\n  Header-Name: value`)
- **Rewrites:** Create entries in `public/_redirects` with status `200`

### 7. Delete `vercel.json`

Remove `vercel.json` from the project root.

---

---

## Migration Steps (VPS)

### 1. Uninstall Vercel adapter

```bash
npm uninstall @astrojs/vercel
```

### 2. Install Node.js adapter

```bash
npm install @astrojs/node
```

### 3. Update `astro.config.mjs`

Replace the Vercel adapter with the Node.js adapter:

**Before:**
```js
import vercel from '@astrojs/vercel/serverless';
// or: import vercel from '@astrojs/vercel';

export default defineConfig({
  output: 'server',
  adapter: vercel(),
});
```

**After:**
```js
import node from '@astrojs/node';

export default defineConfig({
  output: 'server', // or 'hybrid' for selective prerendering
  adapter: node({ mode: 'standalone' }),
});
```

If the project uses `output: 'static'` (no adapter), no adapter swap is needed — just serve the `dist/` directory with Nginx (see `static.md`).

### 4. Update `package.json` scripts

```json
{
  "scripts": {
    "start": "node dist/server/entry.mjs"
  }
}
```

Keep the existing `dev` and `build` scripts unchanged.

### 5. Create PM2 ecosystem config

Create `ecosystem.config.js` in the project root:

```js
module.exports = {
  apps: [{
    name: '<project-name-from-package.json>',
    script: 'dist/server/entry.mjs',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 4321,
    },
  }],
};
```

### 6. Migrate `vercel.json` and clean up

If `vercel.json` has rewrites/redirects/headers, move them to Astro middleware or Nginx config.

Delete `vercel.json` from the project root.

---

## Compatibility Notes (Cloudflare)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| SSR (server output) | 0 | Automated | Supported | First-class support. Cloudflare acquired the Astro team; Cloudflare is a primary deployment target. |
| Hybrid rendering | 0 | Automated | Supported | Use `output: 'hybrid'` with `export const prerender = true/false` per page. |
| Static output | 0 | Automated | Supported | Deploy `dist/` to Cloudflare Pages as static assets. |
| API endpoints | 0 | Automated | Supported | Run as Cloudflare Workers. |
| Astro 6+ Workers bindings | 0 | Automated | Supported | Native access to KV, R2, D1, etc. via `Astro.locals.runtime.env`. |
| Content Collections | 0 | Automated | Supported | Works unchanged. |
| View Transitions | 0 | Automated | Supported | Client-side feature, works unchanged. |

### Partial

| Feature | Weight | Category | Status | Action |
|---------|--------|----------|--------|--------|
| Image optimization (`astro:assets`) | 1 | Attention | Partial | Use Cloudflare Image Transforms (requires a plan that supports it) or configure a custom image service in `astro.config.mjs`. The `sharp` library is NOT available in Workers — use `@astrojs/cloudflare`'s built-in image service or an external service. |
| Node.js APIs in SSR | 1 | Attention | Partial | Workers runtime supports a subset of Node.js APIs. Use `nodejs_compat` compatibility flag. Some Node.js built-ins may not be available. |

### Manual

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@vercel/analytics` | 1 | Attention | Cloudflare Web Analytics | Remove the package. Add the Cloudflare Web Analytics JS snippet to the `<head>` of the base layout. |
| `@vercel/speed-insights` | 1 | Attention | None (remove) | No direct equivalent. Remove the package and component. |
| `@vercel/blob` | 3 | Blocker | Cloudflare R2 | Different API. Access R2 via `Astro.locals.runtime.env.BUCKET_NAME`. |
| `@vercel/kv` | 1 | Attention | Cloudflare KV | Different API. Access KV via `Astro.locals.runtime.env.KV_NAMESPACE`. Add binding to `wrangler.toml`. |

---

## Compatibility Notes (VPS)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| SSR (server output) | 0 | Automated | Supported | `@astrojs/node` with `mode: 'standalone'` produces a self-contained Node.js server. |
| Hybrid rendering | 0 | Automated | Supported | Use `output: 'hybrid'` with `export const prerender = true/false` per page. |
| Static output | 0 | Automated | Supported | Deploy `dist/` directory via Nginx. No Node.js process needed. |
| API endpoints | 0 | Automated | Supported | Run as part of the Node.js server process. |
| Content Collections | 0 | Automated | Supported | Works unchanged. |
| View Transitions | 0 | Automated | Supported | Client-side feature, works unchanged. |
| Image optimization (`astro:assets`) | 0 | Automated | Supported | `sharp` is available on VPS (unlike Cloudflare Workers). Image optimization works out of the box with `@astrojs/node`. |
| Node.js APIs in SSR | 0 | Automated | Supported | Full Node.js API access — no restrictions. `fs`, `path`, `crypto`, native addons all work. |

### Manual

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@vercel/analytics` | 1 | Attention | Plausible / Umami | Remove the package. Self-host Plausible or Umami, or add any analytics provider's JS snippet to the base layout. |
| `@vercel/speed-insights` | 1 | Attention | None (remove) | No direct equivalent. Remove the package and component. |
| `@vercel/blob` | 1 | Attention | Local filesystem or S3 SDK | Replace with `fs` for local storage or `@aws-sdk/client-s3` for S3-compatible storage. |
| `@vercel/kv` | 1 | Attention | Redis (`ioredis`) | Install Redis. Replace `@vercel/kv` with `ioredis`. |
