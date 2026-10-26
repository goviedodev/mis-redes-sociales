## Context
A mobile-first Spanish-language web app to save, categorize, and attach files to social network links (YouTube, Facebook, Instagram, TikTok) for personal reference on a home network server.
Stack: Elixir 1.18.2 (OTP 27), Phoenix 1.8.4 (LiveView), Ash Framework (`ash_sqlite` + SQLite), Tailwind CSS + DaisyUI, internal Elixir scheduler with `tzdata` (`America/Santiago`), local `artifacts/` storage, Docker Compose.
Expensive decisions: none (single-user PIN access, Spanish-only, installable PWA without offline sync).

## Backlog
1. As a user, I want to unlock the app by clicking a 4-digit phone-style PIN pad (`8751`), so that only I can access my saved links.
2. As a user, I want to save a social network link with its category, link type, URL, and short description and see it in my saved links list, so that I can keep track of content I want to revisit. Requires: #1
3. As a user, I want to include an optional subcategory and long description when saving a link and view its full details, so that I can record complete notes about how to use that content. Requires: #2
4. As a user, I want to upload an optional artifact file (such as a PDF) to a link and open or download it later, so that I can keep supporting documents alongside the video or post. Requires: #2
5. As a user, I want to filter my saved links by category, subcategory, or link type, so that I can quickly find specific links as my collection grows. Requires: #3
6. As a user, I want to edit or delete a saved link, so that I can fix mistakes or remove outdated links. Requires: #2
7. As a user, I want to switch between 3 visual themes, so that I can read and use the app comfortably in different lighting conditions. Requires: #1
8. As a user, I want to install the web app on my phone or computer as a PWA, so that I can launch it directly from my home screen like a native app. Requires: #1
9. As a user, I want my database to be automatically backed up every day at 1:00 AM (`America/Santiago`), so that I never lose my saved collection. Requires: #2
10. As a user, I want to run the complete application with Docker Compose, so that it runs reliably on my Asus home network computer with persistent database and artifacts. Requires: #2
