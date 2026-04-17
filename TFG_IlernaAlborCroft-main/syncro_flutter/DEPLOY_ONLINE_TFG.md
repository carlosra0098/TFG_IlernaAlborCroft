# Deploy Online (TFG) + Stream Chat

Este proyecto ya funciona en local, pero para una demo "en linea" necesitas publicar 2 piezas:

1. Frontend Flutter (Web) en hosting publico.
2. Backend de tokens de Stream en un servidor publico.

Sin backend publico de tokens, Stream Chat/Feed no puede autenticarse fuera de tu PC.

## 1) Publicar backend de tokens (Render/Railway)

Carpeta del backend:

- `stream_token_server/`

Variables de entorno obligatorias:

- `STREAM_API_KEY`
- `STREAM_API_SECRET`
- `PORT` (opcional, la plataforma suele inyectarlo)

Comandos base:

```bash
cd stream_token_server
npm install
npm start
```

Endpoints esperados:

- `GET /health` -> `{ "ok": true }`
- `POST /stream/token` con body JSON:

```json
{ "userId": "super-band-9", "name": "Super Band" }
```

Respuesta debe incluir `token` JWT de 3 partes.

## 2) Publicar Flutter Web (Firebase Hosting recomendado)

Desde `syncro_flutter/`:

```bash
flutter pub get
flutter build web \
  --dart-define=STREAM_API_KEY=tu_stream_api_key \
  --dart-define=STREAM_TOKEN_SERVER_URL=https://tu-backend-publico \
  --dart-define=STREAM_FEED_GROUP=timeline \
  --dart-define=STREAM_FEED_ID=gaming
```

Luego publica la carpeta `build/web` en tu hosting (Firebase Hosting, Netlify, Vercel, etc).

Si usas Firebase Hosting:

```bash
firebase login
firebase init hosting
firebase deploy --only hosting
```

## 3) Comprobacion rapida antes del TFG

1. Abrir URL publica de la app.
2. Ir a Stream Hub.
3. Confirmar que carga canales.
4. Entrar a `flutterdevs`.
5. Enviar mensaje de prueba.

## 4) Errores tipicos de Stream y causa real

- Error de token tipo "Compact serialization should have 3 parts":
  - Se esta usando un valor que no es JWT real.
- Error de conexion en web o movil fisico:
  - `STREAM_TOKEN_SERVER_URL` apunta a localhost/10.0.2.2.
- Feed vacio:
  - El feed existe pero no tiene actividades; no es fallo de login.

## 5) Recomendacion para la defensa

Para evitar cualquier dependencia local durante la presentacion:

- Llevar URL publica del frontend.
- Llevar URL publica del backend de tokens.
- Verificar `GET /health` en vivo antes de entrar a la demo.
