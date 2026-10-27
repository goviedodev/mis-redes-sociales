# LEARNINGS.md — Aprendizajes Técnicos y Arquitectónicos

Este documento registra hallazgos críticos, errores sutiles de producción y patrones probados en **Mis Redes Sociales** (Phoenix 1.8 + LiveView + Docker + Cloudflare Tunnel). Consúltalo antes de tocar configuración de PWA, assets estáticos, Service Workers o despliegues en `asus`.

---

## 1. Instalación PWA Real en Phoenix LiveView (`MIX_ENV=prod`)

### 1.1 El bug silencioso de `~p` + `phx.digest` que rompe el Manifest con 404 en producción

- **Síntoma:** En desarrollo (`MIX_ENV=dev`) la PWA parece configurada correctamente, pero en producción (`MIX_ENV=prod` dentro del contenedor Docker), Chrome muestra **"No se puede instalar la app"** o sólo crea un acceso directo con el ícono de Chrome en lugar de compilar e instalar el WebAPK nativo.
- **Causa raíz:**
  1. Usar `~p"/manifest.json"` o `~p"/manifest.webmanifest"` en `root.html.heex` hace que Phoenix, al tener activado `cache_static_manifest: "priv/static/cache_manifest.json"` en `config/prod.exs`, reescriba el `href` en el HTML renderizado con el hash de `mix phx.digest` (ej. `/manifest-7a8e8db8f339ba57562ec82a3ee25e66.json?vsn=d`).
  2. `Plug.Static` en `endpoint.ex` filtra archivos de raíz usando `only: MisRedesSocialesWeb.static_paths()` (coincidencia exacta de nombre). Como `manifest-<hash>.json` no coincide con `manifest.json`, `Plug.Static` rechaza la petición y Phoenix devuelve **HTTP 404 Not Found**.
  3. Chrome descarga el manifest, recibe 404 (`manifest-empty` en DevTools Protocol) y deshabilita silenciosamente la instalación PWA.
- **Solución obligatoria:**
  1. En `lib/mis_redes_sociales_web/components/layouts/root.html.heex`, referenciar el manifiesto **siempre con un string literal** (sin `~p`):
     ```heex
     <link rel="manifest" href="/manifest.json" />
     ```
  2. En `lib/mis_redes_sociales_web/endpoint.ex`, agregar `only_matching` en `Plug.Static` además de `only: MisRedesSocialesWeb.static_paths()`:
     ```elixir
     plug Plug.Static,
       at: "/",
       from: :mis_redes_sociales,
       gzip: not code_reloading?,
       only: MisRedesSocialesWeb.static_paths(),
       only_matching: ~w(favicon robots manifest service-worker sw),
       raise_on_missing_only: code_reloading?
     ```

---

### 1.2 Contexto Seguro (`https://`) obligatorio para PWA

- **Regla de Chrome/Android:** Los Service Workers y el evento `beforeinstallprompt` **nunca** se activan sobre orígenes inseguros como IPs de red local por HTTP (`http://192.168.100.x:4000`). Únicamente funcionan en:
  - `https://` con certificado válido (ej. `https://redesgo.sevenit.cl` vía Cloudflare Tunnel).
  - `http://localhost` o `http://127.0.0.1` en el mismo dispositivo.

---

### 1.3 Service Worker compatible con Phoenix LiveView (`/service-worker.js`)

Un Service Worker genérico de SPA rompe Phoenix LiveView si cachea el HTML inicial o intercepta el WebSocket. Nuestro `priv/static/service-worker.js` sigue tres reglas estrictas:

1. **Ignorar `/live` y peticiones no-GET:**
   ```javascript
   if (event.request.method !== "GET" || event.request.url.includes("/live")) {
     return;
   }
   ```
   Si el Service Worker intercepta `/live/websocket`, rompe el canal persistente de LiveView.
2. **Estrategia *Network First* para navegación HTML (`event.request.mode === "navigate"`):**
   - Cada documento HTML generado por Phoenix incluye un `<meta name="csrf-token" ...>` fresco vinculado a la sesión de la cookie.
   - Si el Service Worker sirviera el HTML desde caché (*Cache First*), el navegador enviaría un token CSRF viejo al conectar el WebSocket y LiveView entraría en un bucle infinito de recarga.
   - Con *Network First*, siempre se obtiene HTML con CSRF fresco cuando hay red y sólo se cae al caché cuando el dispositivo está offline.
3. **Estrategia *Stale-While-Revalidate* para assets estáticos (`css`, `js`, íconos, fuentes):**
   - Respuesta inmediata desde caché y actualización en segundo plano.

---

### 1.4 Captura de `beforeinstallprompt` y preservación del *User Gesture* en LiveView

- **Problema de condición de carrera:** Chrome dispara `window.onbeforeinstallprompt` apenas carga el DOM, muchas veces **antes** de que el WebSocket de LiveView termine su `mount` y registre los `phx-hook`.
- **Problema del *User Gesture*:** `deferredPrompt.prompt()` exige ser invocado **síncronamente** dentro del manejador de un evento `click` nativo del navegador. Si el botón usa `phx-click="instalar"` y espera respuesta del servidor por WebSocket, Chrome bloquea el diálogo porque se perdió la activación de usuario.
- **Arquitectura de doble Hook en `assets/js/app.js`:**
  1. **Captura global temprana (`globalThis.deferredPrompt`):**
     Al cargar `app.js`, un listener global guarda el evento en `globalThis.deferredPrompt` y emite `new CustomEvent("pwa:install-ready", { detail: true })`.
  2. **Hook `PWAInstall` (en el contenedor principal de la vista):**
     En su `mounted()`, revisa si `globalThis.deferredPrompt` ya existe (y además escucha el evento `pwa:install-ready`) y notifica al LiveView mediante `this.pushEvent("pwa_install_ready", { ready: true })` para que el servidor actualice `@pwa_install_ready` y renderice el botón `#pwa-install-btn`.
  3. **Hook `PWAInstallBtn` (en el botón `#pwa-install-btn`):**
     Adjunta un `addEventListener("click", ...)` nativo en el cliente que llama directamente a `globalThis.deferredPrompt.prompt()` sin pasar por el servidor, garantizando que Chrome abra el instalador nativo de la PWA.

---

### 1.5 Verificación determinista de instalabilidad PWA desde CLI (Chrome DevTools Protocol)

Para verificar sin adivinar si Chrome considera instalable una URL en producción (`https://redesgo.sevenit.cl/pin`), usa Chrome Headless con el protocolo CDP (`Page.getAppManifest` y `Page.getInstallabilityErrors`) y un `--user-data-dir` temporal (para evitar el error `in-incognito` del perfil efímero por defecto en headless):

```bash
node -e '
const { spawn } = require("child_process");
const fs = require("fs");
const dir = "/tmp/chrome-pwa-check-" + Date.now();
const chrome = spawn("google-chrome", [
  "--headless=new", "--no-sandbox", "--disable-gpu",
  "--user-data-dir=" + dir,
  "--remote-debugging-port=9230", "https://redesgo.sevenit.cl/pin"
]);
setTimeout(async () => {
  const targets = await fetch("http://127.0.0.1:9230/json/list").then(r => r.json());
  const page = targets.find(t => t.type === "page");
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let id = 1;
  const call = (method, params = {}) => new Promise(res => {
    const cid = id++;
    const handler = (ev) => {
      const msg = JSON.parse(ev.data);
      if (msg.id === cid) { ws.removeEventListener("message", handler); res(msg.result); }
    };
    ws.addEventListener("message", handler);
    ws.send(JSON.stringify({ id: cid, method, params }));
  });
  ws.onopen = async () => {
    await call("Page.enable");
    await new Promise(r => setTimeout(r, 2000));
    console.log("MANIFEST:", await call("Page.getAppManifest"));
    console.log("INSTALLABILITY:", await call("Page.getInstallabilityErrors"));
    chrome.kill();
    fs.rmSync(dir, { recursive: true, force: true });
    process.exit(0);
  };
}, 3000);
'
```

Un resultado sano debe devolver `errors: []` e `installabilityErrors: []`.
