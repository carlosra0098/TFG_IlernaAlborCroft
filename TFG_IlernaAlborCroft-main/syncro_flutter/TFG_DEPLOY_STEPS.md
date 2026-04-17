# TFG Deploy Steps (Render + Firebase Hosting)

Sigue este orden exacto para tener la app online y Stream funcionando fuera de local.

## 0) Requisitos

- Cuenta de Render
- Cuenta de Firebase (proyecto `syncro-1f9a6`)
- `flutter`, `firebase-tools`, `git` instalados

## 1) Publicar backend de tokens (Render)

1. Sube el repo a GitHub (si no esta ya).
2. En Render: New + Blueprint.
3. Selecciona tu repo; Render detectara `render.yaml` en la raiz.
4. En el servicio `syncro-stream-token-server`, configura variables:
   - `STREAM_API_KEY`
   - `STREAM_API_SECRET`
   - `IGDB_CLIENT_ID`
   - `IGDB_CLIENT_SECRET`
5. Deploy.
6. Copia la URL publica (ejemplo):
   - `https://syncro-stream-token-server.onrender.com`

Comprobacion rapida (PowerShell):

```powershell
Invoke-RestMethod -Method Get -Uri 'https://TU_URL_ONRENDER/health' | ConvertTo-Json
```

Debe devolver:

```json
{"ok":true}
```

Comprobacion token:

```powershell
$body = @{ userId = 'super-band-9'; name = 'Super Band' } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri 'https://TU_URL_ONRENDER/stream/token' -ContentType 'application/json' -Body $body | ConvertTo-Json -Depth 5
```

Debe devolver un `token` JWT (3 partes separadas por puntos).

## 2) Build web de Flutter apuntando a Render

Desde `syncro_flutter/`:

```powershell
flutter clean
flutter pub get
flutter build web `
  --release `
  --dart-define=STREAM_API_KEY=j5tkkdvknj3p `
  --dart-define=STREAM_TOKEN_SERVER_URL=https://TU_URL_ONRENDER `
   --dart-define=IGDB_PROXY_URL=https://TU_URL_ONRENDER `
  --dart-define=STREAM_FEED_GROUP=timeline `
  --dart-define=STREAM_FEED_ID=gaming
```

## 3) Publicar frontend en Firebase Hosting

Desde `syncro_flutter/`:

```powershell
firebase login
firebase deploy --only hosting
```

Firebase ya queda configurado en:

- `firebase.json` (hosting + rewrites SPA)
- `.firebaserc` (proyecto default)

## 4) Checklist de validacion para la defensa

1. Abre la URL de Firebase Hosting.
2. Inicia sesion en la app.
3. Ve a Stream Hub.
4. Comprueba que aparece el canal `flutterdevs`.
5. Entra al canal y envia un mensaje.

## 5) Plan B si Render entra en sleep justo antes del TFG

1. Abre primero `https://TU_URL_ONRENDER/health` en el navegador.
2. Espera respuesta `ok:true`.
3. Luego abre la app en Firebase Hosting.

Asi evitas el primer timeout por cold start.
