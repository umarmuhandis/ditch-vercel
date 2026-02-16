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
compatibility_date = "2024-09-23"
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

### 6. Delete `vercel.json`

Remove `vercel.json` from the project root after migrating its contents.

---

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

### 7. Delete `vercel.json`

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

---

## Compatibility Notes (VPS)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| App Router | 0 | Automated | Supported | Fully supported with `output: 'standalone'` |
| Pages Router | 0 | Automated | Supported | Fully supported with `output: 'standalone'` |
| API Routes | 0 | Automated | Supported | Run as part of the Node.js server process |
| Server Actions | 0 | Automated | Supported | Handled by the Node.js server |
| ISR | 0 | Automated | Supported | Works natively with file-system cache in standalone mode. Single-server only (no distributed cache). |
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
