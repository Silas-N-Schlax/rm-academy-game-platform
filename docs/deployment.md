# Deployment (Fly.io)

The app runs in production on Fly.io as `rm-academy-game-platform`, region `iad`. This doc covers
the infrastructure shape and the non-obvious gotchas hit getting it running — see `fly.toml` and
the `Dockerfile` for the actual configuration.

## Infrastructure

- **Web**: one `shared-cpu-1x` / 512MB machine, scaled to zero when idle (`min_machines_running =
  0`, `auto_stop_machines`/`auto_start_machines` in `fly.toml`). An open websocket (Turbo Stream)
  connection counts as active traffic and prevents the machine from stopping mid-game; it only
  sleeps when every tab is closed. First request after a sleep pays a cold-boot delay.
- **Postgres**: a single-node (no HA), always-on Fly Postgres app, attached via `fly postgres
  attach`, which sets `DATABASE_URL` automatically. Database machines are not scaled to zero here —
  Fly does support autostart for Postgres, but that risks the app and DB cold-booting
  simultaneously on the first request after idle, which was judged too fragile for this app.
- **Redis**: an Upstash-backed instance (`fly redis create`, pay-as-you-go plan), used *only* for
  ActionCable's pub/sub in production (`config/cable.yml`) — not for GoodJob, which stays
  Postgres-backed. Provisioned specifically because the mentor's guidance for this project requires
  a real Redis backend rather than Rails' Postgres-backed Solid Cable. `REDIS_URL` is not attached
  automatically the way `DATABASE_URL` is — it has to be set manually: `fly secrets set
  REDIS_URL="<connection string from 'fly redis status'>"`.
- **Background jobs**: GoodJob runs in-process (`config.good_job.execution_mode = :async` in
  `config/environments/production.rb`) rather than as a separate worker machine, so a second
  always-on machine isn't needed just for the hourly `ArchiveGameJob` cron. Trade-off: that cron
  only fires while the web machine happens to be awake — if nobody's playing during a given hour,
  it just runs on the next wake-up instead.

## Secrets

- `DATABASE_URL` — set automatically by `fly postgres attach`.
- `REDIS_URL` — must be set manually (see above).
- `RAILS_MASTER_KEY` — `fly secrets set RAILS_MASTER_KEY=$(cat config/master.key)`, run locally so
  the key value never leaves your machine.

## Gotchas hit getting this working

- **The Dockerfile never installed Node/Yarn.** This app uses `jsbundling-rails` + esbuild +
  Yarn Berry (see `package.json`'s `packageManager` field and `.yarnrc.yml`'s `yarnPath`), but the
  Dockerfile's `build` stage only installed Ruby-related `apt` packages — a leftover from before
  `jsbundling-rails` was added to the project. Fixed by installing Node via `node-build` and
  running `corepack enable`, which resolves to the exact Yarn version already vendored in
  `.yarn/releases/` with no extra network fetch for Yarn itself.
- **The container can't bind port 80.** The final image runs as a non-root user (`USER 1000:1000`),
  and Linux reserves ports below 1024 for root. Thruster's `HTTP_PORT` (default `80`) is set to
  `8080` via `fly.toml`'s `[env]` block, and `internal_port` is matched to `8080` in the same file.
- **`config.ssl_options`'s health-check exclusion must stay uncommented.** Fly's internal health
  checker hits `/up` over plain HTTP (TLS terminates at Fly's edge, not the machine), so
  `config.force_ssl`'s redirect-to-HTTPS would otherwise turn every health check into a 301 instead
  of a 200, and Fly would consider the machine permanently unhealthy.

## Known gaps (deliberately deferred)

- No SMTP configured — password-reset emails silently fail in the background (GoodJob job errors
  out, no crash, but no email is actually sent).
- `/good_job` (mounted in `config/routes.rb`) has no authentication — anyone with the URL can view
  queue internals and retry/discard jobs. Left as-is for now; revisit if this app is exposed beyond
  low-stakes assignment use.
