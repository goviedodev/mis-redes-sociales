#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

export PORT="${PORT:-4000}"
export TZ="America/Santiago"

LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "0.0.0.0")

echo "Preparing database migrations..."
mix ecto.create --quiet
mix ecto.migrate --quiet

echo "Starting Mis Redes Sociales on 0.0.0.0:${PORT} (LAN: http://${LOCAL_IP}:${PORT})"
exec mix phx.server
