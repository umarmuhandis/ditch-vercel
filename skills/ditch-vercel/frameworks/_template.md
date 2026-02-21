# [Framework Name] — Vercel Migration

## Detection

<!-- How the skill identifies this framework during Phase 1 scanning. -->

**package.json:** `<package-name>` in `dependencies` or `devDependencies`

**Config files:** `<framework>.config.js`, `<framework>.config.mjs`, `<framework>.config.ts`

<!-- Optional: variant detection (e.g. App Router vs Pages Router for Next.js) -->

---

## Migration Steps (Cloudflare)

<!-- Numbered steps to migrate from Vercel to Cloudflare. Each step should include:
     - A clear heading (### N. Description)
     - Exact package names and install commands
     - Code blocks with config file contents (use <placeholder> markers for project-specific values)
     - Any file paths that need to be created or modified
-->

### 1. Install the Cloudflare adapter

```bash
npm install -D <adapter-package>
```

### 2. Create `wrangler.toml`

```toml
name = "<project-name-from-package.json>"
compatibility_date = "<today's date in YYYY-MM-DD format>"
compatibility_flags = ["nodejs_compat"]
```

### 3. Update framework config

<!-- Show the exact config changes needed -->

### 4. Update `package.json` scripts

```json
{
  "scripts": {
    "build": "<framework-build-command>",
    "deploy": "<deploy-command>",
    "preview": "<preview-command>"
  }
}
```

### 5. Remove Vercel dependencies

```bash
npm remove @vercel/analytics @vercel/speed-insights
```

<!-- Add more steps as needed. Remove `vercel.json` if present. -->

---

## Migration Steps (VPS)

<!-- Numbered steps to migrate from Vercel to a VPS (Node.js + PM2 + Nginx). Each step should include:
     - Exact package names and install commands
     - Config changes for standalone/server output
     - PM2 ecosystem config with correct entry point
     - Any file paths that need to be created or modified
-->

### 1. Configure for standalone output

<!-- Show the config change to enable server/standalone output mode -->

### 2. Update `package.json` scripts

```json
{
  "scripts": {
    "build": "<framework-build-command>",
    "start": "node <entry-point>"
  }
}
```

### 3. Create PM2 ecosystem config

```javascript
module.exports = {
  apps: [{
    name: '<project-name>',
    script: '<entry-point>',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
    },
  }],
};
```

### 4. Remove Vercel dependencies

```bash
npm remove @vercel/analytics @vercel/speed-insights
```

<!-- Add more steps as needed -->

---

## Compatibility Notes (Cloudflare)

<!-- Three subsections: Supported, Partial, Manual.
     Each table row must include Weight, Category, and Status.

     Weight values:
       0 = Automated (ditch-vercel handles entirely)
       1 = Attention (works but needs minor manual adjustment)
       3 = Blocker (significant effort, may prevent migration)

     Category values: Automated, Attention, Blocker
     Status values: Supported, Partial, Manual
-->

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| Example feature | 0 | Automated | Supported | Handled by the adapter automatically |

### Partial (works with caveats)

| Feature | Weight | Category | Status | Action |
|---------|--------|----------|--------|--------|
| Example feature | 1 | Attention | Partial | Description of what the developer needs to do |

### Manual (requires code changes)

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@vercel/analytics` | 1 | Attention | Cloudflare Web Analytics | Remove package and component, add Cloudflare snippet |

---

## Compatibility Notes (VPS)

<!-- Same structure as Cloudflare compatibility notes above.
     VPS typically has fewer blockers since it runs full Node.js.
-->

### Supported

| Feature | Weight | Category | Status | Notes |
|---------|--------|----------|--------|-------|
| Example feature | 0 | Automated | Supported | Works natively in Node.js |

### Partial

| Feature | Weight | Category | Status | Action |
|---------|--------|----------|--------|--------|
| Example feature | 1 | Attention | Partial | Description of what the developer needs to do |

### Manual

| Feature | Weight | Category | Replacement | Action |
|---------|--------|----------|-------------|--------|
| `@vercel/analytics` | 1 | Attention | Plausible / Umami / PostHog | Remove package and component, use alternative |

## Reference URLs

<!-- List official documentation URLs for this framework's deployment/migration.
     Prefix machine-readable LLM doc indexes with "llms.txt:" — the skill prefers these
     for doc verification in Phase 3-pre.
-->
- https://example.com/docs/deployment
- llms.txt: https://example.com/docs/llms.txt
