# Next.js — Vercel Migration

## Detection

**package.json:** `next` in `dependencies` or `devDependencies`

**Config files:** `next.config.js`, `next.config.mjs`, `next.config.ts`

**Router detection:**
- **App Router:** `app/` directory exists (with `layout.tsx`/`layout.js` and `page.tsx`/`page.js` files)
- **Pages Router:** `pages/` directory exists (with `_app.tsx`/`_app.js` and `_document.tsx`/`_document.js`)
- **Both:** Some projects use both — App Router is primary, Pages Router for legacy routes

---

## Migration Steps (Cloudflare)

### 1. Install OpenNext for Cloudflare

Add `@opennextjs/cloudflare` as a dev dependency:

```bash
npm install -D @opennextjs/cloudflare
```

### 2. Create `wrangler.toml`

Create `wrangler.toml` in the project root. Derive the `name` field from `package.json` `name`:

```toml
name = "<project-name-from-package.json>"
main = ".open-next/worker.js"
compatibility_date = "<today's date in YYYY-MM-DD format>"
compatibility_flags = ["nodejs_compat"]

[assets]
directory = ".open-next/assets"
binding = "ASSETS"
```

### 3. Update `package.json` scripts

Add/replace these scripts:

```json
{
  "scripts": {
    "build:cf": "npx opennextjs-cloudflare",
    "deploy": "npm run build:cf && wrangler deploy",
    "preview": "npm run build:cf && wrangler dev"
  }
}
```

Keep the existing `dev`, `build`, `start`, and `lint` scripts unchanged.

### 4. Remove `@vercel/*` packages

Uninstall all `@vercel/*` packages found in `package.json`. Common ones:

```bash
npm uninstall @vercel/analytics @vercel/speed-insights @vercel/og @vercel/blob @vercel/kv @vercel/postgres @vercel/edge
```

Remove their imports and usage from source files (see Compatibility Notes for replacements).

### 5. Migrate `vercel.json` rewrites/redirects

If `vercel.json` contains `rewrites` or `redirects`, move them to `next.config.js` using Next.js native support:

```js
// next.config.js
module.exports = {
  async redirects() {
    return [
      { source: '/old-path', destination: '/new-path', permanent: true },
    ];
  },
  async rewrites() {
    return [
      { source: '/api/:path*', destination: 'https://backend.example.com/:path*' },
    ];
  },
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
        ],
      },
    ];
  },
};
```

### 6. Migrate environment variables

Copy environment variable names from the Vercel dashboard (Settings > Environment Variables).

- **Non-secret values:** Add to `wrangler.toml` under `[vars]`
- **Secrets (API keys, tokens):** Use `wrangler secret put <NAME>`
- **Dashboard alternative:** Cloudflare dashboard > Workers/Pages > Settings > Environment Variables

### 7. Delete `vercel.json`

Remove `vercel.json` from the project root after migrating its contents.

---

## Migration Steps (VPS)

### 1. Configure standalone output

Update `next.config.js` (or `.mjs`/`.ts`) to enable standalone output mode:

```js
module.exports = {
  output: 'standalone',
};
```

This produces a self-contained `.next/standalone/` directory with all dependencies bundled. The server runs on plain Node.js with no adapter needed.

### 2. Remove `@vercel/*` packages

Uninstall all `@vercel/*` packages found in `package.json`:

```bash
npm uninstall @vercel/analytics @vercel/speed-insights @vercel/og @vercel/blob @vercel/kv @vercel/postgres @vercel/edge
```

Remove their imports and usage from source files (see Compatibility Notes (VPS) for replacements).

### 3. Migrate `vercel.json` rewrites/redirects

If `vercel.json` contains `rewrites`, `redirects`, or `headers`, move them to `next.config.js` using Next.js native support:

```js
// next.config.js
module.exports = {
  output: 'standalone',
  async redirects() {
    return [
      { source: '/old-path', destination: '/new-path', permanent: true },
    ];
  },
  async rewrites() {
    return [
      { source: '/api/:path*', destination: 'https://backend.example.com/:path*' },
    ];
  },
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
        ],
      },
    ];
  },
};
```

### 4. Update `package.json` scripts

```json
{
  "scripts": {
    "start": "node .next/standalone/server.js"
  }
}
```

Keep the existing `dev`, `build`, and `lint` scripts unchanged.

### 5. Create PM2 ecosystem config

Create `ecosystem.config.js` in the project root:

```js
module.exports = {
  apps: [{
    name: '<project-name-from-package.json>',
    script: '.next/standalone/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
    },
  }],
};
```

### 6. Handle static assets

Next.js standalone output does NOT include `public/` and `.next/static/`. These must be served separately.

**Option A (recommended): Serve via Nginx**

Add to the Nginx server block:

```nginx
location /_next/static/ {
    alias /var/www/<project-name>/.next/static/;
    expires 1y;
    access_log off;
}

location /public/ {
    alias /var/www/<project-name>/public/;
    expires 1y;
    access_log off;
}
```

**Option B: Copy into standalone directory**

Add a `postbuild` script to `package.json`:

```json
{
  "scripts": {
    "postbuild": "cp -r public .next/standalone/public && cp -r .next/static .next/standalone/.next/static"
  }
}
```

### 7. Migrate environment variables

Copy environment variable names from the Vercel dashboard (Settings > Environment Variables).

- Create or update `.env` in the project root
- For PM2: add to the `env` block in `ecosystem.config.js`

### 8. Delete `vercel.json`

Remove `vercel.json` from the project root after migrating its contents.

---

## Compatibility Notes (Cloudflare)

### Supported (works with OpenNext on Cloudflare)

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| App Router | 0 | Automated | Supported | Fully supported via OpenNext |
| Pages Router | 0 | Automated | Supported | Fully supported via OpenNext |
| API Routes | 0 | Automated | Supported | Run as Cloudflare Workers |
| Edge Middleware | 0 | Automated | Supported | Runs on Cloudflare edge via OpenNext |
| Edge Runtime routes | 0 | Automated | Supported | Native on Cloudflare Workers |
| Server Actions | 0 | Automated | Supported | Handled by OpenNext worker |
| ISR | 0 | Automated | Supported | Via OpenNext's cache handler with Cloudflare KV |

### Partial (works with caveats)

| Feature | Weight | Category | Status | Action |
|---------|--------|----------|--------|--------|
| `next/image` | 1 | Attention | Partial | Works with OpenNext. Uses Cloudflare Image Resizing (requires a plan that supports it). Alternative: use a custom image loader (e.g., `unpic`, `cloudinary`, or `imgix`). |
| Bundle size > 25MB | 3 | Blocker | Partial | Cloudflare Workers have a 25MB compressed size limit for the worker script. If the bundle exceeds this, it is a **potential blocker**. Mitigation: code-split aggressively, move large deps to client-side, use dynamic imports. |

### Manual (requires code changes)

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@vercel/og` | 1 | Attention | `satori` + Workers or `@cloudflare/pages-plugin-vercel-og` | Replace OG image generation. `@cloudflare/pages-plugin-vercel-og` is a near drop-in replacement. |
| `@vercel/analytics` | 1 | Attention | Cloudflare Web Analytics | Remove the package and its `<Analytics />` component. Add the Cloudflare Web Analytics JS snippet to `<head>` in the root layout. Get the snippet from the Cloudflare dashboard. |
| `@vercel/speed-insights` | 1 | Attention | None (remove) | No direct Cloudflare equivalent. Remove the package and its `<SpeedInsights />` component. Consider Cloudflare Observatory for performance monitoring. |
| `@vercel/blob` | 3 | Blocker | Cloudflare R2 | Different API. Replace `put()`, `del()`, `list()`, `head()` calls with R2 binding methods (`put()`, `delete()`, `list()`, `head()`). R2 bindings are accessed via `process.env` or platform context. |
| `@vercel/kv` | 1 | Attention | Cloudflare KV | Different API. Replace `kv.get()`, `kv.set()` with KV namespace binding methods. Add KV namespace to `wrangler.toml`. |
| `@vercel/postgres` | 3 | Blocker | Cloudflare D1 or Hyperdrive | Different API entirely. D1 uses SQLite syntax. Hyperdrive can proxy to existing Postgres. If the project uses Prisma or Drizzle, update the adapter config. |
| `@vercel/edge` | 0 | Automated | Workers Runtime | Workers natively run at edge. Remove the package — no replacement needed. |
| `@vercel/edge-config` | 1 | Attention | Cloudflare KV | Replace with KV namespace. Add `[[kv_namespaces]]` to `wrangler.toml`. |

---

## Compatibility Notes (VPS)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| App Router | 0 | Automated | Supported | Fully supported with `output: 'standalone'` |
| Pages Router | 0 | Automated | Supported | Fully supported with `output: 'standalone'` |
| API Routes | 0 | Automated | Supported | Run as part of the Node.js server process |
| Server Actions | 0 | Automated | Supported | Handled by the Node.js server |
| ISR | 1 | Attention | Partial | Works natively with file-system cache in standalone mode. Single-server only — no distributed cache invalidation. Cache lost on restart. |
| `@vercel/og` | 0 | Automated | Supported | Works as-is in Node.js environments. Uses `satori` + `@resvg/resvg-js` under the hood. No changes needed. |

### Partial

| Feature | Weight | Category | Status | Action |
|---------|--------|----------|--------|--------|
| Edge Middleware | 1 | Attention | Partial | Middleware runs in Node.js (not edge). Functionally equivalent but no geo-distributed execution. Remove any edge-only APIs if used. |
| Edge Runtime routes | 1 | Attention | Partial | Edge runtime not available on VPS. Remove `export const runtime = 'edge'` declarations — routes will run in the Node.js runtime instead. |
| `next/image` | 1 | Attention | Partial | Install `sharp` for local image optimization: `npm install sharp`. Works out of the box with standalone output. No CDN optimization — consider adding Cloudflare CDN in front. |

### Manual

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@vercel/analytics` | 1 | Attention | Plausible / Umami / PostHog | Remove the package and `<Analytics />` component. Self-host Plausible or Umami, or use any analytics provider. |
| `@vercel/speed-insights` | 1 | Attention | None (remove) | No direct equivalent. Remove the package and `<SpeedInsights />` component. Use Lighthouse CI for performance monitoring. |
| `@vercel/blob` | 1 | Attention | Local filesystem or S3 SDK | Replace with `fs` for local storage or `@aws-sdk/client-s3` for S3-compatible storage (AWS S3, MinIO, Backblaze B2). |
| `@vercel/kv` | 1 | Attention | Redis (`ioredis`) | Install Redis on the VPS. Replace `@vercel/kv` with `ioredis`. API mapping: `kv.get()` → `redis.get()`, `kv.set()` → `redis.set()`. |
| `@vercel/postgres` | 1 | Attention | PostgreSQL (`pg`) | Install PostgreSQL on the VPS or use managed Postgres. Replace `@vercel/postgres` with `pg`. Direct connection — no serverless proxy needed. If using Prisma or Drizzle, just update the connection string. |
| `@vercel/edge` | 0 | Automated | Node.js runtime | Remove the package + `export const runtime = 'edge'` declarations. Routes run in Node.js instead. |
| `@vercel/edge-config` | 1 | Attention | Redis or config file | Replace with Redis (`ioredis`) for dynamic config or a JSON config file for static config. |

## Migration Steps (Railway)

### 1. Configure standalone output

Update `next.config.js` (or `.mjs`/`.ts`) to enable standalone output mode:

```js
module.exports = {
  output: 'standalone',
};
```

This produces a self-contained `.next/standalone/` directory with all dependencies bundled. The server runs on plain Node.js — Railway's Nixpacks auto-detects it.

### 2. Remove `@vercel/*` packages

Uninstall all `@vercel/*` packages found in `package.json`:

```bash
npm uninstall @vercel/analytics @vercel/speed-insights @vercel/og @vercel/blob @vercel/kv @vercel/postgres @vercel/edge @vercel/edge-config
```

Remove their imports and usage from source files (see Compatibility Notes (Railway) for replacements).

### 3. Migrate `vercel.json` rewrites/redirects

If `vercel.json` contains `rewrites`, `redirects`, or `headers`, move them to `next.config.js` using Next.js native support:

```js
// next.config.js
module.exports = {
  output: 'standalone',
  async redirects() {
    return [
      { source: '/old-path', destination: '/new-path', permanent: true },
    ];
  },
  async rewrites() {
    return [
      { source: '/api/:path*', destination: 'https://backend.example.com/:path*' },
    ];
  },
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
        ],
      },
    ];
  },
};
```

### 4. Update `package.json` scripts

```json
{
  "scripts": {
    "start": "node .next/standalone/server.js"
  }
}
```

Keep the existing `dev`, `build`, and `lint` scripts unchanged.

### 5. Create `railway.json` (recommended)

Create `railway.json` in the project root for explicit control:

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "node .next/standalone/server.js",
    "healthcheckPath": "/",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

This is optional — Railway auto-detects Next.js via Nixpacks, but explicit config gives more control.

### 6. Handle static assets

Next.js standalone output does NOT include `public/` and `.next/static/`. Add a `postbuild` script to `package.json`:

```json
{
  "scripts": {
    "postbuild": "cp -r public .next/standalone/public && cp -r .next/static .next/standalone/.next/static"
  }
}
```

### 7. Replace Vercel data packages

Migrate Vercel SDK packages to Railway-native equivalents:
- `@vercel/kv` → `ioredis` + Railway Redis addon (`railway add --plugin redis`)
- `@vercel/postgres` → `pg` + Railway Postgres addon (`railway add --plugin postgresql`). Railway provides `DATABASE_URL` automatically.
- `@vercel/blob` → `@aws-sdk/client-s3` with S3-compatible storage, or Railway Volume for simple file storage

### 8. Migrate environment variables

Copy environment variable names from the Vercel dashboard (Settings > Environment Variables).

- Use `railway variables set KEY=VALUE` via CLI
- Or set via the Railway dashboard > Service > Variables tab
- Railway provides database connection strings automatically when addons are linked

### 9. Delete `vercel.json`

Remove `vercel.json` from the project root after migrating its contents.

---

## Compatibility Notes (Railway)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| App Router | 0 | Automated | Supported | Fully supported with `output: 'standalone'` |
| Pages Router | 0 | Automated | Supported | Fully supported with `output: 'standalone'` |
| API Routes | 0 | Automated | Supported | Run as part of the Node.js server process |
| Server Actions | 0 | Automated | Supported | Handled by the Node.js server |
| `@vercel/og` | 0 | Automated | Supported | Works as-is in Node.js environments. Uses `satori` + `@resvg/resvg-js` under the hood. No changes needed. |
| `@vercel/postgres` | 0 | Automated | Supported | Railway Postgres addon provides `DATABASE_URL` automatically. Replace `@vercel/postgres` with `pg`. If using Prisma or Drizzle, just update the connection string. |
| `@vercel/edge` | 0 | Automated | Supported | Remove the package + `export const runtime = 'edge'` declarations. Routes run in Node.js instead. |
| Preview Deployments | 0 | Automated | Supported | Railway automatically creates isolated environments for PRs. |

### Partial

| Feature | Weight | Category | Status | Action |
|---------|--------|----------|--------|--------|
| Edge Middleware | 1 | Attention | Partial | Middleware runs in Node.js (not edge). Functionally equivalent but no geo-distributed execution. Remove any edge-only APIs if used. |
| Edge Runtime routes | 1 | Attention | Partial | Edge runtime not available on Railway. Remove `export const runtime = 'edge'` declarations — routes will run in the Node.js runtime instead. |
| ISR | 1 | Attention | Partial | Works natively with file-system cache in standalone mode. Cache lost on redeploy (ephemeral filesystem). For persistent cache, use Railway Redis addon. |
| `next/image` | 1 | Attention | Partial | Install `sharp` for local image optimization: `npm install sharp`. Works out of the box with standalone output. No CDN optimization — consider adding Cloudflare CDN in front. |

### Manual

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@vercel/analytics` | 1 | Attention | Plausible / Umami / PostHog | Remove the package and `<Analytics />` component. Self-host Plausible or Umami, or use any analytics provider. |
| `@vercel/speed-insights` | 1 | Attention | None (remove) | No direct equivalent. Remove the package and `<SpeedInsights />` component. Use Lighthouse CI for performance monitoring. |
| `@vercel/blob` | 1 | Attention | Railway Volume or S3 SDK | Replace with Railway Volume for simple file storage or `@aws-sdk/client-s3` for S3-compatible storage. |
| `@vercel/kv` | 1 | Attention | Redis (`ioredis`) | Add Redis via `railway add --plugin redis`. Replace `@vercel/kv` with `ioredis`. API mapping: `kv.get()` → `redis.get()`, `kv.set()` → `redis.set()`. |
| `@vercel/edge-config` | 1 | Attention | Redis or config file | Replace with Redis (`ioredis`) via Railway Redis addon for dynamic config, or a JSON config file for static config. |

---

## Reference URLs
- https://opennext.js.org/cloudflare
- https://developers.cloudflare.com/pages/framework-guide/nextjs/
- llms.txt: https://nextjs.org/docs/llms.txt
