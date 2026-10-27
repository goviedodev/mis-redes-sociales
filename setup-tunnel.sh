#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────
#  Configuracion de Cloudflare Tunnel para Mis Redes Sociales
#  Dominio por defecto: redesgo.sevenit.cl -> http://app:4000
# ──────────────────────────────────────────────────────────

if ! command -v docker &>/dev/null; then
  echo "❌ Docker no esta instalado o no esta en el PATH."
  exit 1
fi

if ! docker info &>/dev/null; then
  echo "❌ Docker no esta corriendo. Inicia el servicio Docker."
  exit 1
fi

CRED_DIR="$(cd "$(dirname "$0")" && pwd)/cloudflared"
mkdir -p "$CRED_DIR"
chmod 777 "$CRED_DIR"

TUNNEL_NAME="${TUNNEL_NAME:-mis-redes-sociales}"
DOMAIN="${DOMAIN:-redesgo.sevenit.cl}"

if [ ! -f "$CRED_DIR/cert.pem" ] && [ -d "$HOME/servicios/htmls-info/cloudflared" ]; then
  docker run --rm \
    -v "$HOME/servicios/htmls-info/cloudflared":/src:ro \
    -v "$CRED_DIR":/dst \
    alpine sh -c "if [ -f /src/cert.pem ]; then cp -f /src/cert.pem /dst/cert.pem && chown 65532:65532 /dst/cert.pem && chmod 600 /dst/cert.pem; fi"
  echo "✅ Certificado cert.pem existente copiado desde htmls-info"
fi

if [ ! -f "$CRED_DIR/cert.pem" ]; then
  echo "PASO 1: Autenticacion con Cloudflare"
  docker run -it --rm \
    -v "$CRED_DIR":/home/nonroot/.cloudflared \
    cloudflare/cloudflared:latest tunnel login
fi

echo "PASO 2: Creando o reutilizando tunnel '$TUNNEL_NAME'..."
docker run --rm \
  -v "$CRED_DIR":/home/nonroot/.cloudflared \
  cloudflare/cloudflared:latest tunnel create "$TUNNEL_NAME" || true

echo "PASO 3: Configurando DNS '$DOMAIN' -> '$TUNNEL_NAME'..."
docker run --rm \
  -v "$CRED_DIR":/home/nonroot/.cloudflared \
  cloudflare/cloudflared:latest tunnel route dns --overwrite-dns "$TUNNEL_NAME" "$DOMAIN"

TUNNEL_ID=""
NEWEST_JSON=$(ls -t "$CRED_DIR"/*.json 2>/dev/null | grep -v tunnel-credentials.json | head -1 || true)
if [ -n "$NEWEST_JSON" ]; then
  TUNNEL_ID=$(basename "$NEWEST_JSON" .json)
fi

if [ -n "$TUNNEL_ID" ]; then
  docker run --rm -v "$CRED_DIR":/creds alpine sh -c \
    "cp -f /creds/$TUNNEL_ID.json /creds/tunnel-credentials.json \
     && chown 65532:65532 /creds/tunnel-credentials.json \
     && chmod 400 /creds/tunnel-credentials.json"

  cat > "$CRED_DIR/config.yml" << YAML
# Cloudflare Tunnel - generado por setup-tunnel.sh
tunnel: ${TUNNEL_ID}
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
  - hostname: ${DOMAIN}
    service: http://app:4000
  - service: http_status:404
protocol: http2
YAML

  echo "✅ Configuracion escrita en cloudflared/config.yml para https://${DOMAIN}"
else
  echo "⚠️  No se encontro el archivo JSON de credenciales en $CRED_DIR"
  exit 1
fi
