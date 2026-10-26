# Project Environment & Deployment Reference

This document is the single source of truth for the **development** and **production** environments of `mis-redes-sociales`.

## 1. Environments Overview

| Environment | Host | OS / Hardware | Access | Role |
|-------------|------|---------------|--------|------|
| **Development** | `pop-os` (local machine) | Linux `pop-os` (`x86_64`) | Local workspace: `/home/goviedo/proyectos/mis-redes-sociales` | Active coding, TDD (`mix test`, `mix precommit`), local Phoenix dev server |
| **Production** | `asus` (`192.168.100.14`) | Home network server | `ssh asus` (User: `goviedo`, Key: `~/.ssh/id_asus`, Port: `22`), Path: `$HOME/servicios/mis-redes-sociales/` | Docker Compose production deployment, persistent SQLite database, daily 1:00 AM backups, and `artifacts/` storage |

---

## 2. Development Environment (`pop-os` — Local Host)

### Toolchain
- **Elixir:** `1.18.2` (compiled with Erlang/OTP 27)
- **Erlang/OTP:** `27` (`erts-15.2.2`)
- **Phoenix Installer (`phx.new`):** `v1.8.4` (App runs Phoenix `~> 1.8.4`, LiveView `~> 1.1.0`)
- **Data Layer:** Ash Framework (`ash ~> 3.0`, `ash_sqlite ~> 0.2`, `ash_phoenix ~> 2.0`) with SQLite3 (`ecto_sqlite3`)
- **Timezone:** `America/Santiago` via `tzdata`

### Common Commands
- **Setup project:** `mix setup`
- **Run dev server (bound to `0.0.0.0:4000` for LAN access):** `./run.sh` (or `mix phx.server`)
- **Run tests:** `mix test`
- **Quality gate before commit:** `mix precommit` (compiles with `--warnings-as-errors`, unlocks unused deps, formats, and runs tests)

### Local Paths
- **Dev SQLite DB:** `mis_redes_sociales_dev.db` (configured in `config/dev.exs`)
- **Test SQLite DB:** `mis_redes_sociales_test.db` (configured in `config/test.exs`)
- **Uploaded Artifacts:** `artifacts/` inside the project root
- **Database Backups:** `backups/` (or configured backup path)

---

## 3. Production Environment (`asus` — Home Network Server)

### Connection Details
- **SSH Alias:** `ssh asus`
- **IP Address:** `192.168.100.14`
- **User:** `goviedo`
- **SSH Key:** `~/.ssh/id_asus`
- **Production Project Directory:** `$HOME/servicios/mis-redes-sociales/` (`/home/goviedo/servicios/mis-redes-sociales/`)

### Deployment Architecture
- **Runtime:** Docker & `docker-compose.yml` (located in `$HOME/servicios/mis-redes-sociales/`)
- **Timezone:** `TZ=America/Santiago`
- **Persistent Volumes (mounted from `$HOME/servicios/mis-redes-sociales/` on `asus`):**
  1. **SQLite Database directory** — persists the production SQLite database across container restarts and image rebuilds.
  2. **`$HOME/servicios/mis-redes-sociales/artifacts/`** — persists uploaded PDFs and supporting files attached to saved links.
  3. **`$HOME/servicios/mis-redes-sociales/backups/`** — stores the daily automated SQLite backups triggered every day at **1:00 AM (`America/Santiago`)**.

### Production Deployment Workflow
1. Ensure all tests and checks pass locally on `pop-os` via `mix precommit`.
2. Commit and push changes to `origin` (`https://github.com/goviedodev/mis-redes-sociales.git`) following the `git-workflow` skill.
3. Connect to `asus` (`ssh asus`), navigate to `$HOME/servicios/mis-redes-sociales/` (cloning into `$HOME/servicios/mis-redes-sociales/` on first deploy), pull the latest `main` branch, and run:
   ```bash
   cd $HOME/servicios/mis-redes-sociales
   git pull origin main
   docker compose up -d --build
   ```
4. Verify container health and logs:
   ```bash
   docker compose ps
   docker compose logs -f
   ```
