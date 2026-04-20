# TFG Ilerna - Syncro Flutter

Aplicacion principal del TFG desarrollada en Flutter, con integracion de Firebase, Stream Chat y proxy IGDB.

## Contenido del repositorio

- syncro_flutter/: app Flutter multiplataforma.
- syncro_flutter/stream_token_server/: backend Node.js para tokens de Stream y proxy IGDB.
- render.yaml: configuracion de despliegue del servidor en Render.

## Stack tecnico

- Flutter + Dart
- Firebase (Auth/Firestore segun configuracion del proyecto)
- Stream Chat
- Node.js + Express (token server)

## Funcionalidades principales

- Login y registro de usuario
- Perfil y economia de monedas
- Busqueda de juegos y guias
- Gestion social: amigos, chat global y chat privado
- Guías de comunidad (crear, ver, reportar, bloquear autor)
- Misiones diarias y pomodoro
- Persistencia de datos en Firebase

## Requisitos previos

- Flutter SDK instalado y en PATH
- Android Studio + Android SDK + emulador (si pruebas en Android)
- Node.js 18+ para stream_token_server
- Proyecto Firebase configurado en syncro_flutter/firebase_options.dart
- Credenciales de Stream e IGDB para el token server

## Ejecucion local

### 1) App Flutter

Desde la raiz del repositorio:

```powershell
cd syncro_flutter
flutter pub get
flutter run -d emulator-5554
```

Si no usas ese emulador concreto, cambia el device id segun flutter devices.

### 2) Token server (Stream + IGDB)

En otra terminal:

```powershell
cd syncro_flutter/stream_token_server
npm install
npm start
```

El servidor queda en http://localhost:8787.

Endpoints relevantes:

- POST /stream/token
- POST /igdb/search
- GET /health

## Verificacion rapida

```powershell
cd syncro_flutter
flutter analyze
flutter test
```

## Estructura recomendada para revision

- syncro_flutter/lib/main.dart: logica principal de la app
- syncro_flutter/lib/features/stream/stream_hub_screen.dart: experiencia de chat
- syncro_flutter/lib/services/: servicios de Firebase e IGDB
- syncro_flutter/stream_token_server/server.js: backend de tokens y proxy

## Despliegue

- Servidor: Render (ver render.yaml)
- App Flutter: Android/iOS/Web segun build objetivo

## Documentacion adicional

- syncro_flutter/README.md
- syncro_flutter/FIREBASE_SETUP.md
- syncro_flutter/DEPLOY_ONLINE_TFG.md
- syncro_flutter/TFG_DEPLOY_STEPS.md

## Nota

Si falla chat privado por usuarios inexistentes en Stream, verifica que el token server este levantado y accesible desde la app.
