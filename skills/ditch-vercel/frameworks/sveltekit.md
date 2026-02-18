# SvelteKit — Vercel to Cloudflare Migration

## Detection

**package.json:** `@sveltejs/kit` in `dependencies` or `devDependencies`

**Config files:** `svelte.config.js`

**Vercel adapter indicator:** `@sveltejs/adapter-vercel` in `dependencies` or `devDependencies`

---

## Migration Steps

### 1. Uninstall Vercel adapter

```bash
npm uninstall @sveltejs/adapter-vercel
```

### 2. Install Cloudflare adapter

```bash
npm install -D @sveltejs/adapter-cloudflare
```

### 3. Update `svelte.config.js`

Replace the Vercel adapter with the Cloudflare adapter:

**Before:**
```js
import adapter from '@sveltejs/adapter-vercel';

export default {
  kit: {
    adapter: adapter(),
  },
};
```

**After:**
```js
import adapter from '@sveltejs/adapter-cloudflare';

export default {
  kit: {
    adapter: adapter(),
  },
};
```

### 4. Create `wrangler.toml`

Create `wrangler.toml` in the project root. Derive `name` from `package.json` `name`:

```toml
name = "<project-name-from-package.json>"
compatibility_date = "2024-09-23"
compatibility_flags = ["nodejs_compat"]

[assets]
directory = ".svelte-kit/cloudflare"
```

### 5. Update `package.json` scripts

```json
{
  "scripts": {
    "deploy": "npm run build && wrangler pages deploy .svelte-kit/cloudflare",
    "preview": "npm run build && wrangler pages dev .svelte-kit/cloudflare"
  }
}
```

Keep the existing `dev`, `build`, and `check` scripts unchanged.

### 6. Access Cloudflare platform bindings

In server-side code (`+page.server.ts`, `+server.ts`, hooks), access Cloudflare bindings via the `platform` object:

```ts
// +page.server.ts
export async function load({ platform }) {
  const value = await platform.env.MY_KV.get('key');
  return { value };
}
```

For type safety, update `src/app.d.ts`:

```ts
declare global {
  namespace App {
    interface Platform {
      env: {
        MY_KV: KVNamespace;
        MY_R2: R2Bucket;
        MY_D1: D1Database;
      };
    }
  }
}

export {};
```

### 7. Migrate `vercel.json` config

If `vercel.json` has rewrites/redirects/headers:
- **Redirects:** Create a `static/_redirects` file (format: `from to statusCode`)
- **Headers:** Create a `static/_headers` file (format: `[path]\n  Header-Name: value`)
- **Rewrites:** Create entries in `static/_redirects` with status `200`

### 8. Delete `vercel.json`

Remove `vercel.json` from the project root.

---

## Compatibility Notes

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| SSR | 0 | Automated | Supported | Official `@sveltejs/adapter-cloudflare` is well-maintained by the SvelteKit team. |
| Prerendering | 0 | Automated | Supported | Static pages are generated at build time. Works unchanged. |
| API routes (`+server.ts`) | 0 | Automated | Supported | Run as Cloudflare Workers. |
| Form actions | 0 | Automated | Supported | Work unchanged in Workers runtime. |
| Hooks (`hooks.server.ts`) | 0 | Automated | Supported | Run in the Worker. Access `event.platform.env` for bindings. |
| Load functions | 0 | Automated | Supported | Both universal and server load functions work. |
| Streaming | 0 | Automated | Supported | Works natively in Workers. |

### Partial

| Feature | Weight | Category | Status | Action |
|---------|--------|----------|--------|--------|
| Node.js APIs | 1 | Attention | Partial | Workers runtime has limited Node.js compat. Use `nodejs_compat` flag in `wrangler.toml`. File system APIs (`fs`) are NOT available. |
| `$env/static/private` | 1 | Attention | Partial | Works, but environment variables must be set in the Cloudflare dashboard or `wrangler.toml` `[vars]` section. `.env` files work only in local dev via `wrangler dev`. |
| Image optimization | 1 | Attention | Partial | No built-in equivalent to Vercel's image optimization. Use Cloudflare Image Transforms (requires compatible plan) or an external image service. |

### Manual

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@vercel/analytics` | 1 | Attention | Cloudflare Web Analytics | Remove the package. Add Cloudflare Web Analytics JS snippet to `src/app.html` `<head>`. |
| `@vercel/speed-insights` | 1 | Attention | None (remove) | No direct equivalent. Remove the package and component. |
| `@vercel/blob` | 3 | Blocker | Cloudflare R2 | Different API. Access R2 via `platform.env.BUCKET_NAME` in server load functions and API routes. |
| `@vercel/kv` | 1 | Attention | Cloudflare KV | Different API. Access KV via `platform.env.KV_NAMESPACE`. Add KV binding to `wrangler.toml`. |
| `@vercel/postgres` | 3 | Blocker | Cloudflare D1 or Hyperdrive | D1 uses SQLite. Hyperdrive proxies existing Postgres. Access via `platform.env`. |
| Edge config (`@vercel/edge-config`) | 1 | Attention | Cloudflare KV | Replace with KV namespace for key-value configuration data. |

## Reference URLs
- https://svelte.dev/docs/kit/adapter-cloudflare
- https://developers.cloudflare.com/pages/framework-guide/deploy-a-svelte-kit-site/
- llms.txt: https://svelte.dev/llms.txt
