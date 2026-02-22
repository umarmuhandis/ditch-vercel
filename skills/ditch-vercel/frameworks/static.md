# Static Site — Vercel Migration

## Detection

**package.json:** None of the known framework packages (`next`, `astro`, `@remix-run/react`, `@sveltejs/kit`, `nuxt`) found in `dependencies` or `devDependencies`

**Indicators:**
- HTML/CSS/JS files in the project root or a subdirectory
- May have a build script (e.g., using Webpack, Vite, Parcel, Gulp, or plain copy)
- May be a plain HTML site with no `package.json` at all

**Output directory detection (check in order):**
1. If `package.json` has a `build` script, inspect it for output directory hints
2. Check for common output directories: `dist/`, `build/`, `out/`, `public/`, `_site/`
3. If no build step and HTML files are at the project root, the root directory itself is the output

---

## Migration Steps (Cloudflare)

### 1. Determine the output directory

Identify where the built/static files live. Common patterns:

| Tool/Setup | Typical output dir |
|------------|-------------------|
| Vite | `dist/` |
| Create React App | `build/` |
| Webpack | `dist/` or `build/` |
| Parcel | `dist/` |
| Hugo | `public/` |
| Jekyll | `_site/` |
| Eleventy (11ty) | `_site/` |
| Plain HTML (no build) | `.` (project root) |

### 2. Create `wrangler.toml`

Create `wrangler.toml` in the project root. Derive `name` from `package.json` `name` (or directory name if no `package.json`):

```toml
name = "<project-name>"
compatibility_date = "<today's date in YYYY-MM-DD format>"

[assets]
directory = "<output-dir>"
```

No `compatibility_flags` needed for static-only sites (no Workers).

### 3. Migrate `vercel.json` headers

If `vercel.json` has a `headers` array, create a `_headers` file in the output directory:

**vercel.json format:**
```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-Content-Type-Options", "value": "nosniff" }
      ]
    }
  ]
}
```

**`_headers` file format (place in output directory root):**
```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
```

Path mapping from `vercel.json` `source` to `_headers`:
- `"/(.*)"` or `"/**"` becomes `/*`
- `"/api/(.*)"` becomes `/api/*`
- Exact paths stay the same: `"/index.html"` stays `/index.html`

### 4. Migrate `vercel.json` redirects

If `vercel.json` has a `redirects` array, create a `_redirects` file in the output directory:

**vercel.json format:**
```json
{
  "redirects": [
    { "source": "/old", "destination": "/new", "permanent": true },
    { "source": "/blog/:slug", "destination": "/posts/:slug", "statusCode": 301 }
  ]
}
```

**`_redirects` file format (place in output directory root):**
```
/old /new 301
/blog/:slug /posts/:slug 301
```

Status code mapping:
- `"permanent": true` or `"statusCode": 301` becomes `301`
- `"permanent": false` or `"statusCode": 302` becomes `302`
- Default (no status specified) is `302`

### 5. Migrate `vercel.json` rewrites (SPA fallback)

If `vercel.json` has a `rewrites` array (common for SPAs), add to `_redirects` with status `200`:

**vercel.json format:**
```json
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

**`_redirects` file format:**
```
/* /index.html 200
```

**Important:** Put rewrites AFTER redirects in the `_redirects` file. Cloudflare Pages processes rules top-to-bottom and uses the first match. Specific redirects should come before the catch-all SPA rewrite.

### 6. Update `package.json` scripts

```json
{
  "scripts": {
    "deploy": "wrangler pages deploy <output-dir>"
  }
}
```

If the project has a build step, chain it:

```json
{
  "scripts": {
    "deploy": "npm run build && wrangler pages deploy <output-dir>"
  }
}
```

### 7. Migrate environment variables

Static sites rarely need runtime env vars. If your build uses env vars (e.g. `VITE_API_URL`), set them in Cloudflare Pages build settings or pass at build time.

- **Cloudflare dashboard:** Workers/Pages > Settings > Environment Variables
- **Build-time:** Set in `wrangler.toml` under `[vars]` or pass inline: `VITE_API_URL=https://api.example.com npm run build`

### 8. Delete `vercel.json`

Remove `vercel.json` from the project root.

---

## Migration Steps (VPS)

### 1. Determine the output directory

Identify where the built/static files live (same as Cloudflare step 1):

| Tool/Setup | Typical output dir |
|------------|-------------------|
| Vite | `dist/` |
| Create React App | `build/` |
| Webpack | `dist/` or `build/` |
| Parcel | `dist/` |
| Hugo | `public/` |
| Jekyll | `_site/` |
| Eleventy (11ty) | `_site/` |
| Plain HTML (no build) | `.` (project root) |

### 2. Migrate `vercel.json` to Nginx config

If `vercel.json` has headers, redirects, or rewrites, move them to the Nginx server block.

**Redirects:**
```nginx
# vercel.json: { "source": "/old", "destination": "/new", "permanent": true }
rewrite ^/old$ /new permanent;
```

**Headers:**
```nginx
# vercel.json: { "source": "/(.*)", "headers": [{ "key": "X-Frame-Options", "value": "DENY" }] }
add_header X-Frame-Options DENY;
```

**Rewrites (SPA fallback):**
```nginx
# vercel.json: { "source": "/(.*)", "destination": "/index.html" }
location / {
    try_files $uri $uri/ /index.html;
}
```

### 3. Update `package.json` scripts

Remove any Vercel/Cloudflare deploy scripts. If there's a build step:

```json
{
  "scripts": {
    "deploy": "npm run build"
  }
}
```

### 4. Migrate environment variables

Static sites rarely need runtime env vars. If your build uses env vars (e.g. `VITE_API_URL`), set them in your CI/CD pipeline or pass at build time:

```bash
VITE_API_URL=https://api.example.com npm run build
```

### 5. Delete `vercel.json`

Remove `vercel.json` from the project root.

**Note:** Static sites on VPS do NOT need PM2 or a Node.js process. Nginx serves the files directly from the output directory. See the Nginx static site block template in [targets/vps.md](../targets/vps.md).

---

## Compatibility Notes (Cloudflare)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| Static HTML/CSS/JS | 0 | Automated | Supported | Cloudflare Pages serves static assets with zero issues. Global CDN, automatic compression, HTTP/2. |
| Custom domains | 0 | Automated | Supported | Configure in Cloudflare dashboard. Free SSL included. |
| SPA routing (client-side) | 0 | Automated | Supported | Use `/* /index.html 200` in `_redirects` for SPA fallback. |
| Custom headers | 0 | Automated | Supported | Use `_headers` file in the output directory. |
| Redirects | 0 | Automated | Supported | Use `_redirects` file in the output directory. |
| Trailing slash handling | 0 | Automated | Supported | Cloudflare Pages strips trailing slashes by default. |
| 404 pages | 0 | Automated | Supported | Place a `404.html` in the output directory root. Cloudflare Pages serves it automatically for missing routes. |
| Clean URLs | 0 | Automated | Supported | `/about.html` is served at `/about` automatically. |

### Limits

| Limit | Value | Notes |
|-------|-------|-------|
| Max file size | 25 MB per file | Individual static files cannot exceed 25 MB. |
| Max files | 20,000 files | Per deployment. |
| `_redirects` rules | 2,000 static + 100 dynamic | Dynamic rules use `:splat` or `:placeholder` syntax. |
| `_headers` rules | 100 rules | Per `_headers` file. |

### Not Applicable

Static sites do not use server-side features, so the following Vercel features are irrelevant:
- Serverless/Edge functions
- ISR
- SSR
- API routes (unless adding Cloudflare Workers separately)

---

## Compatibility Notes (VPS)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| Static HTML/CSS/JS | 0 | Automated | Supported | Nginx serves static assets directly. Gzip compression via `gzip on;` in Nginx config. |
| Custom domains | 0 | Automated | Supported | Configure in Nginx server block. SSL via Let's Encrypt + Certbot. |
| SPA routing (client-side) | 0 | Automated | Supported | Use `try_files $uri $uri/ /index.html;` in Nginx for SPA fallback. |
| Custom headers | 0 | Automated | Supported | Use `add_header` directives in Nginx config. |
| Redirects | 0 | Automated | Supported | Use `rewrite` directives in Nginx config. |
| 404 pages | 0 | Automated | Supported | Use `error_page 404 /404.html;` in Nginx config. |
| Clean URLs | 0 | Automated | Supported | Use `try_files $uri $uri.html $uri/ =404;` in Nginx config. |

### Limits

No hard limits — constrained only by VPS disk space and Nginx configuration. No file count or file size restrictions beyond what the filesystem supports.

### Not Applicable

Static sites on VPS do not use server-side features. No PM2 or Node.js process is needed — Nginx serves files directly.

## Migration Steps (Railway)

### 1. Determine the output directory

Identify where the built/static files live (same as Cloudflare/VPS step 1):

| Tool/Setup | Typical output dir |
|------------|-------------------|
| Vite | `dist/` |
| Create React App | `build/` |
| Webpack | `dist/` or `build/` |
| Parcel | `dist/` |
| Hugo | `public/` |
| Jekyll | `_site/` |
| Eleventy (11ty) | `_site/` |
| Plain HTML (no build) | `.` (project root) |

### 2. Add a static file server

Railway needs a process to serve static files. Install `serve`:

```bash
npm install serve
```

Add a start script to `package.json`:

```json
{
  "scripts": {
    "start": "npx serve <output-dir> -l 3000"
  }
}
```

Replace `<output-dir>` with the actual output directory (e.g., `dist`, `build`).

### 3. Create `railway.json` (recommended)

Create `railway.json` in the project root:

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "npx serve <output-dir> -l 3000",
    "healthcheckPath": "/",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

Replace `<output-dir>` with the actual output directory.

### 4. Migrate `vercel.json` config

If `vercel.json` has headers, redirects, or rewrites:
- **Rewrites (SPA fallback):** `serve` handles this with a `serve.json` config file:

```json
{
  "rewrites": [
    { "source": "**", "destination": "/index.html" }
  ]
}
```

Place `serve.json` in the output directory root.

- **Redirects and headers:** Use `serve.json`:

```json
{
  "redirects": [
    { "source": "/old", "destination": "/new", "type": 301 }
  ],
  "headers": [
    {
      "source": "**",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" }
      ]
    }
  ]
}
```

### 5. Migrate environment variables

Static sites rarely need runtime env vars. If your build uses env vars (e.g. `VITE_API_URL`), set them via:

- `railway variables set VITE_API_URL=https://api.example.com` via CLI
- Or set via the Railway dashboard > Service > Variables tab

### 6. Delete `vercel.json`

Remove `vercel.json` from the project root.

---

## Compatibility Notes (Railway)

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| Static HTML/CSS/JS | 0 | Automated | Supported | Railway serves static assets via `serve` or any static file server. |
| Custom domains | 0 | Automated | Supported | Configure in Railway dashboard. Free SSL included. |
| SPA routing (client-side) | 0 | Automated | Supported | Use `serve.json` with rewrite rule for SPA fallback. |
| Custom headers | 0 | Automated | Supported | Configure via `serve.json` headers. |
| Redirects | 0 | Automated | Supported | Configure via `serve.json` redirects. |
| Preview Deployments | 0 | Automated | Supported | Railway automatically creates isolated environments for PRs. |

### Limits

Railway has no hard limits on static file count or size beyond the service's disk allocation. Build time limit is 20 minutes.

### Not Applicable

Static sites do not use server-side features, so the following Vercel features are irrelevant:
- Serverless/Edge functions
- ISR
- SSR
- API routes

---

## Reference URLs
- https://developers.cloudflare.com/pages/get-started/git-integration/
