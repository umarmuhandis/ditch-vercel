# Next.js — Vercel to Cloudflare Migration

## Detection

**package.json:** `next` in `dependencies` or `devDependencies`

**Config files:** `next.config.js`, `next.config.mjs`, `next.config.ts`

**Router detection:**
- **App Router:** `app/` directory exists (with `layout.tsx`/`layout.js` and `page.tsx`/`page.js` files)
- **Pages Router:** `pages/` directory exists (with `_app.tsx`/`_app.js` and `_document.tsx`/`_document.js`)
- **Both:** Some projects use both — App Router is primary, Pages Router for legacy routes

---

## Migration Steps

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

## Compatibility Notes

### Supported (works with OpenNext on Cloudflare)

| Feature | Status | Notes |
|---------|--------|-------|
| App Router | Supported | Fully supported via OpenNext |
| Pages Router | Supported | Fully supported via OpenNext |
| API Routes | Supported | Run as Cloudflare Workers |
| Edge Middleware | Supported | Runs on Cloudflare edge via OpenNext |
| Edge Runtime routes | Supported | Native on Cloudflare Workers |
| Server Actions | Supported | Handled by OpenNext worker |
| ISR | Supported | Via OpenNext's cache handler with Cloudflare KV |

### Partial (works with caveats)

| Feature | Status | Action |
|---------|--------|--------|
| `next/image` | Partial | Works with OpenNext. Uses Cloudflare Image Resizing (requires a plan that supports it). Alternative: use a custom image loader (e.g., `unpic`, `cloudinary`, or `imgix`). |
| Bundle size > 25MB | Partial | Cloudflare Workers have a 25MB compressed size limit for the worker script. If the bundle exceeds this, it is a **potential blocker**. Mitigation: code-split aggressively, move large deps to client-side, use dynamic imports. |

### Manual (requires code changes)

| Feature | Replacement | Action |
|---------|-------------|--------|
| `@vercel/og` | `satori` + Workers or `@cloudflare/pages-plugin-vercel-og` | Replace OG image generation. `@cloudflare/pages-plugin-vercel-og` is a near drop-in replacement. |
| `@vercel/analytics` | Cloudflare Web Analytics | Remove the package and its `<Analytics />` component. Add the Cloudflare Web Analytics JS snippet to `<head>` in the root layout. Get the snippet from the Cloudflare dashboard. |
| `@vercel/speed-insights` | None (remove) | No direct Cloudflare equivalent. Remove the package and its `<SpeedInsights />` component. Consider Cloudflare Observatory for performance monitoring. |
| `@vercel/blob` | Cloudflare R2 | Different API. Replace `put()`, `del()`, `list()`, `head()` calls with R2 binding methods (`put()`, `delete()`, `list()`, `head()`). R2 bindings are accessed via `process.env` or platform context. |
| `@vercel/kv` | Cloudflare KV | Different API. Replace `kv.get()`, `kv.set()` with KV namespace binding methods. Add KV namespace to `wrangler.toml`. |
| `@vercel/postgres` | Cloudflare D1 or Hyperdrive | Different API entirely. D1 uses SQLite syntax. Hyperdrive can proxy to existing Postgres. If the project uses Prisma or Drizzle, update the adapter config. |
