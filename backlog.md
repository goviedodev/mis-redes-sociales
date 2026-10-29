## Context
A mobile-first Spanish-language web app to save, categorize, and attach files to social network links (YouTube, Facebook, Instagram, TikTok) for personal reference on a home network server.
Stack: Elixir 1.18.2 (OTP 27), Phoenix 1.8.4 (LiveView), Ecto (`ecto_sqlite3` + SQLite), Tailwind CSS + DaisyUI, internal Elixir scheduler with `tzdata` (`America/Santiago`), local `artifacts/` storage, Docker Compose.
Expensive decisions: none (single-user PIN access, Spanish-only, installable PWA without offline sync).
Historical backlog (completed stories #1–#19): see [backlog_history.md](./backlog_history.md).

## Backlog
1. ✅ As a user, I want the filters in the "Enlaces Guardados" tab to be collapsed inside an accordion by default and toggled via a button when I need to filter, so that the filters do not cover or obstruct my saved links list.
2. ✅ As a user, I want the link type to be automatically selected when I paste or type a URL in the "Nuevo Enlace" form based on matching the link type name in the URL (such as Instagram, Facebook, YouTube, or TikTok), so that I don't have to select the link type manually.
