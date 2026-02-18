# Remix — Vercel to Cloudflare Migration

## Detection

**package.json:** `@remix-run/react` in `dependencies`

**Vercel-specific packages:** `@remix-run/vercel` or `@vercel/remix` in `dependencies` or `devDependencies`

**Config files:** `remix.config.js` (Remix v1/v2 classic), or Remix Vite plugin in `vite.config.ts` (Remix v2+ with Vite)

**Version detection:**
- Remix v2+ with Vite: `@remix-run/dev` in deps AND `vite.config.ts` exists with `@remix-run/dev/vite-plugin`
- Remix v1/v2 classic: `remix.config.js` exists

---

## Migration Steps

### 1. Uninstall Vercel packages

```bash
npm uninstall @remix-run/vercel @vercel/remix @remix-run/serve
```

### 2. Install Cloudflare packages

```bash
npm install @remix-run/cloudflare
npm install -D @remix-run/dev wrangler
```

If using Remix v2+ with Vite, also install:

```bash
npm install @remix-run/cloudflare-pages
```

### 3. Update config

**Remix v2+ with Vite (`vite.config.ts`):**

```ts
import { vitePlugin as remix } from '@remix-run/dev';
import { cloudflareDevProxy } from '@remix-run/dev/vite/cloudflare';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [
    cloudflareDevProxy(),
    remix(),
  ],
});
```

**Remix v1/v2 classic (`remix.config.js`):**

```js
/** @type {import('@remix-run/dev').AppConfig} */
module.exports = {
  server: './server.ts',
  serverBuildPath: 'functions/[[path]].js',
  serverConditions: ['workerd', 'worker', 'browser'],
  serverDependenciesToBundle: 'all',
  serverMainFields: ['browser', 'module', 'main'],
  serverMinify: true,
  serverModuleFormat: 'esm',
  serverPlatform: 'neutral',
};
```

### 4. Update `entry.server.tsx`

Replace the entry server with Cloudflare-compatible version:

```tsx
import type { EntryContext } from '@remix-run/cloudflare';
import { RemixServer } from '@remix-run/react';
import { isbot } from 'isbot';
import { renderToReadableStream } from 'react-dom/server';

export default async function handleRequest(
  request: Request,
  responseStatusCode: number,
  responseHeaders: Headers,
  remixContext: EntryContext
) {
  const body = await renderToReadableStream(
    <RemixServer context={remixContext} url={request.url} />,
    {
      signal: request.signal,
      onError(error: unknown) {
        console.error(error);
        responseStatusCode = 500;
      },
    }
  );

  if (isbot(request.headers.get('user-agent'))) {
    await body.allReady;
  }

  responseHeaders.set('Content-Type', 'text/html');
  return new Response(body, {
    headers: responseHeaders,
    status: responseStatusCode,
  });
}
```

### 5. Update loader/action context types

Replace Vercel types with Cloudflare types in loader/action functions:

**Before:**
```ts
import type { LoaderFunctionArgs } from '@remix-run/vercel';
// or: import type { LoaderFunctionArgs } from '@vercel/remix';
```

**After:**
```ts
import type { LoaderFunctionArgs } from '@remix-run/cloudflare';
```

Grep for all imports from `@remix-run/vercel`, `@vercel/remix`, or `@remix-run/node` and replace with `@remix-run/cloudflare`.

### 6. Create `wrangler.toml`

Create `wrangler.toml` in the project root. Derive `name` from `package.json` `name`:

```toml
name = "<project-name-from-package.json>"
compatibility_date = "2024-09-23"
compatibility_flags = ["nodejs_compat"]

[site]
bucket = "./build/client"
```

### 7. Update `package.json` scripts

```json
{
  "scripts": {
    "deploy": "remix vite:build && wrangler pages deploy build/client",
    "preview": "remix vite:build && wrangler pages dev build/client"
  }
}
```

### 8. Delete `vercel.json`

Remove `vercel.json` from the project root.

---

## Compatibility Notes

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| Loaders / Actions | 0 | Automated | Supported | Run as Cloudflare Workers. Access Cloudflare bindings via `context.cloudflare.env`. |
| Route modules | 0 | Automated | Supported | File-based routing works identically. |
| Nested routes | 0 | Automated | Supported | Works unchanged. |
| Error boundaries | 0 | Automated | Supported | Works unchanged. |
| Streaming | 0 | Automated | Supported | `renderToReadableStream` is native to Workers. |
| `fetch` API | 0 | Automated | Supported | Native in Workers runtime. |

### Partial

| Feature | Weight | Category | Status | Action |
|---------|--------|----------|--------|--------|
| Session storage | 1 | Attention | Partial | Replace `createCookieSessionStorage` from `@remix-run/node` with the one from `@remix-run/cloudflare`. For non-cookie storage, use Cloudflare KV or D1 as the backing store. |
| Node.js APIs | 1 | Attention | Partial | Workers runtime has limited Node.js compat. Use `nodejs_compat` flag. File system APIs (`fs`) are NOT available. |
| `crypto` / `node:crypto` | 1 | Attention | Partial | Workers has Web Crypto API natively. Some `node:crypto` functions work with `nodejs_compat`. |

### Manual

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@vercel/analytics` | 1 | Attention | Cloudflare Web Analytics | Remove the package. Add Cloudflare Web Analytics snippet to root template. |
| `@vercel/speed-insights` | 1 | Attention | None (remove) | No direct equivalent. Remove the package and component. |
| `@vercel/blob` | 3 | Blocker | Cloudflare R2 | Different API. Access R2 via `context.cloudflare.env.BUCKET_NAME` in loaders/actions. |
| `@vercel/kv` | 1 | Attention | Cloudflare KV | Different API. Access KV via `context.cloudflare.env.KV_NAMESPACE` in loaders/actions. |
| `@vercel/postgres` | 3 | Blocker | Cloudflare D1 or Hyperdrive | D1 uses SQLite. Hyperdrive proxies existing Postgres. Access via `context.cloudflare.env`. |

## Reference URLs
- https://remix.run/docs/en/main/guides/templates
- https://developers.cloudflare.com/pages/framework-guide/deploy-a-remix-site/
