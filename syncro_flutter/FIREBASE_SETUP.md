# Firebase Setup (Android)

La app ya incluye integración de Firebase Core + Firestore y seeding inicial.

## 1) Activar Developer Mode (Windows)

Necesario para symlinks de plugins Flutter.

1. Ejecuta: `start ms-settings:developers`
2. Activa **Developer Mode**

## 2) Crear proyecto Firebase y app Android

1. En Firebase Console, crea un proyecto.
2. Agrega una app Android con el package name:
   - `com.example.syncro_flutter`
3. Descarga `google-services.json`.
4. Copia el archivo en:
   - `android/app/google-services.json`

## 3) Crear Firestore Database

1. En Firebase Console > Firestore Database > Create database.
2. Selecciona modo desarrollo para pruebas iniciales.

## 4) Desplegar reglas e índices (opcional pero recomendado)

La configuración ya está incluida en:
- `firebase.json`
- `firestore.rules`
- `firestore.indexes.json`

Para desplegar:

```bash
firebase login
firebase use <tu-project-id>
firebase deploy --only firestore
```

## 5) Ejecutar la app

```bash
flutter run -d emulator-5554
```

En el primer arranque con Firebase configurado, la app crea y siembra automáticamente:
- `users` (usuario demo)
- `games` (40 juegos)
- `posts` (3 posts)
- `groups` (4 grupos)
- `shop_items` (6 cosméticos)
- `_meta/seed_v1` (marca de seeding)
