# VPS (Virtual Private Server) — Target Platform Knowledge

## Platform Overview

- **Runtime:** Native Node.js (LTS) on Linux. Apps run as long-lived processes — no cold starts, no serverless limitations.
- **Process Manager:** PM2 (recommended) — clustering, zero-downtime reloads, log management, auto-restart on crash. Alternative: systemd for OS-native process management.
- **Reverse Proxy:** Nginx (recommended) — handles TLS termination, static asset serving, gzip, WebSocket proxying. Alternative: Caddy (automatic HTTPS, simpler config).
- **SSL:** Let's Encrypt via Certbot (Nginx) or automatic (Caddy).
- **Best for:** Full control, no vendor lock-in, predictable pricing, unrestricted Node.js APIs, direct database connections.

---

## Scoring

Each feature has a weight used to calculate migration complexity:

| Weight | Category | Meaning |
|--------|----------|---------|
| 0 | Automated | ditch-vercel handles this entirely |
| 1 | Attention | Works but needs minor manual adjustment |
| 3 | Blocker | Significant effort, may prevent migration |

**Traffic light score** (sum of weights for detected features):
- 🟢 GREEN (0-2): ~1-2 hours — mostly automated
- 🟡 YELLOW (3-6): ~3-5 hours — several manual steps
- 🔴 RED (7+): ~1-2 days — significant refactoring or blockers

---

## Compatibility Matrix

Mapping of Vercel features to VPS equivalents. Use this to generate the compatibility report in Phase 2.

| Vercel Feature | VPS Equivalent | Weight | Category | Status | Notes |
|---|---|---|---|---|---|
| Serverless Functions | Native Node.js server | 0 | Automated | Supported | Framework runs as a standard Node.js process. No function isolation — all routes served by one process. |
| Edge Middleware | Node.js middleware | 0 | Automated | Supported | Runs as standard server-side middleware. No geo-distributed execution, but functionally equivalent. |
| Image Optimization | `sharp` (self-hosted) | 1 | Attention | Partial | Install `sharp` for local image optimization. Works out of the box with most frameworks. No CDN optimization — consider adding Cloudflare CDN (free tier) in front. |
| ISR | Framework-native caching | 1 | Attention | Partial | Next.js ISR works natively with file-system cache in standalone mode. Other frameworks use their own caching strategies. Single-server only — no distributed cache. Cache lost on restart. |
| Cron Jobs | crontab or `node-cron` | 1 | Attention | Partial | Use system `crontab` for simple schedules, or `node-cron` package for in-process scheduling. Different setup from `vercel.json` crons. |
| Environment Variables | `.env` files + PM2/systemd | 0 | Automated | Supported | Use `.env` files (loaded by framework or `dotenv`). For PM2: `ecosystem.config.js` `env` section. For systemd: `EnvironmentFile=` directive. |
| Preview Deployments | — | 3 | Blocker | Manual | No built-in equivalent. Requires manual setup (separate branch deployments, Docker Compose per branch, or a tool like Coolify/Dokku). |
| Vercel Analytics | Plausible / Umami | 1 | Attention | Partial | Remove `@vercel/analytics`. Self-host Plausible or Umami, or use any third-party analytics provider. |
| Vercel Speed Insights | — | 1 | Attention | Manual | No direct equivalent. Remove `@vercel/speed-insights`. Use Lighthouse CI or custom RUM for performance monitoring. |
| `@vercel/og` | Works as-is (or `satori` directly) | 0 | Automated | Supported | `@vercel/og` uses `satori` + `@resvg/resvg-js` under the hood. Works natively in Node.js environments. Optionally replace with `satori` directly for fewer dependencies. |
| `@vercel/blob` | Local filesystem or S3-compatible | 1 | Attention | Partial | For simple use: local filesystem storage via `fs`. For production: use S3-compatible storage (AWS S3, MinIO, Backblaze B2) via `@aws-sdk/client-s3`. |
| `@vercel/kv` | Redis (`ioredis`) | 1 | Attention | Partial | Install Redis on the VPS or use managed Redis. Replace `@vercel/kv` with `ioredis`. API mapping: `kv.get()` → `redis.get()`, `kv.set()` → `redis.set()`. |
| `@vercel/postgres` | Direct PostgreSQL (`pg`) | 1 | Attention | Partial | Install PostgreSQL on the VPS or use managed Postgres. Replace `@vercel/postgres` with `pg`. Direct connection — no serverless proxy needed. If using Prisma/Drizzle, just update the connection string. |
| `@vercel/edge` | Node.js runtime | 0 | Automated | Supported | Remove package + `export const runtime = 'edge'` declarations. |
| `@vercel/edge-config` | Redis or config file | 1 | Attention | Partial | Replace with Redis (dynamic) or JSON config file (static). |
| Monorepo | Standard deployment | 0 | Automated | Supported | Build the target app, deploy the output directory. No special configuration needed. |
| Rewrites | Nginx config or framework-native | 0 | Automated | Supported | Move from `vercel.json` to framework-native config or Nginx `location` blocks. |
| Redirects | Nginx config or framework-native | 0 | Automated | Supported | Move from `vercel.json` to framework-native config or Nginx `rewrite` directives. |
| Headers | Nginx config or framework-native | 0 | Automated | Supported | Move from `vercel.json` to framework-native config or Nginx `add_header` directives. |

---

## Known Limitations

- **No automatic scaling.** VPS has fixed resources. Scale vertically (bigger VPS) or horizontally (load balancer + multiple VPS). PM2 cluster mode uses all CPU cores on a single machine.
- **No built-in CDN.** Static assets served from a single location. Mitigation: add Cloudflare CDN (free tier) in front of the VPS for caching and global distribution.
- **No automatic SSL.** Must set up Let's Encrypt with Certbot (Nginx) or use Caddy (automatic HTTPS). Renewal must be configured (`certbot renew` via cron).
- **No zero-downtime deployments out of the box.** PM2 supports `pm2 reload` for zero-downtime restarts of Node.js processes. Full CI/CD pipeline requires manual setup (GitHub Actions, GitLab CI, etc.).
- **No preview deployments.** Branch-based preview deploys require manual infrastructure or a tool like Coolify, Dokku, or CapRover.
- **No serverless auto-sleep.** The Node.js process runs 24/7 whether handling requests or not. You pay for the VPS regardless of traffic.
- **Memory/CPU limited by VPS plan.** Monitor with `pm2 monit` or external monitoring (e.g., Grafana, Datadog). Upgrade the VPS plan if resources are insufficient.
- **Server maintenance is your responsibility.** OS updates, security patches, Node.js version management, firewall configuration, and backups are all manual.

---

## Configuration Templates

### PM2 `ecosystem.config.js`

```js
module.exports = {
  apps: [{
    name: '<project-name>',
    script: '<entry-point>',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
    },
  }],
};
```

The `<entry-point>` varies per framework — see framework knowledge files for the exact value.

### Nginx Server Block (reverse proxy for Node.js apps)

```nginx
server {
    listen 80;
    server_name <domain>;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

After creating the file at `/etc/nginx/sites-available/<project-name>`, symlink to `sites-enabled` and reload Nginx.

### Nginx Server Block (static sites — no Node.js)

```nginx
server {
    listen 80;
    server_name <domain>;
    root /var/www/<project-name>/<output-dir>;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

The `try_files` fallback to `/index.html` enables SPA client-side routing. Remove it for multi-page static sites.

### systemd Service Unit (alternative to PM2)

```ini
[Unit]
Description=<project-name>
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/<project-name>
ExecStart=/usr/bin/node <entry-point>
Restart=on-failure
EnvironmentFile=/var/www/<project-name>/.env

[Install]
WantedBy=multi-user.target
```

Place at `/etc/systemd/system/<project-name>.service`. Run `sudo systemctl daemon-reload` after creating.

---

## Essential Commands

| Action | Command |
|--------|---------|
| Start app (PM2) | `pm2 start ecosystem.config.js` |
| Stop app (PM2) | `pm2 stop <project-name>` |
| Restart app (zero-downtime) | `pm2 reload <project-name>` |
| View logs (PM2) | `pm2 logs <project-name>` |
| Monitor (PM2) | `pm2 monit` |
| Save PM2 process list | `pm2 save` |
| Auto-start on boot (PM2) | `pm2 startup` |
| Test Nginx config | `sudo nginx -t` |
| Reload Nginx | `sudo systemctl reload nginx` |
| SSL setup (Certbot) | `sudo certbot --nginx -d <domain>` |
| Start systemd service | `sudo systemctl start <project-name>` |
| Enable auto-start (systemd) | `sudo systemctl enable <project-name>` |

---

## Docker Alternative

For containerized deployment, use this base Dockerfile template:

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/<build-output> ./<build-output>
COPY --from=builder /app/package*.json ./
RUN npm ci --production
EXPOSE 3000
CMD ["node", "<entry-point>"]
```

The `<build-output>` and `<entry-point>` vary per framework — see framework knowledge files for exact values.

Docker is documented as an alternative, not the primary migration path. The main migration steps use bare-metal PM2 + Nginx.

## Reference URLs
- https://pm2.keymetrics.io/docs/usage/quick-start/
- https://nginx.org/en/docs/beginners_guide.html
- https://certbot.eff.org/instructions
- https://nodejs.org/en/docs/guides/nodejs-docker-webapp
