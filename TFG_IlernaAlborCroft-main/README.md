# Syncro (TFG) - Entrega Flutter

Este repositorio se entrega como proyecto Flutter.

La app está en:

- `syncro_flutter/`

## Stack usado

- Flutter + Dart para interfaz, estado y lógica de aplicación
- Sin backend externo en este repositorio
- Sin código Python de aplicación

## Ejecutar (ruta correcta)

Desde la raíz del repo:

```powershell
cd tfg/syncro_flutter
flutter pub get
flutter run
```

## Verificación rápida

```powershell
cd tfg/syncro_flutter
flutter analyze
flutter test
```

## Qué ignorar para la entrega

- `build/` (artefactos generados)
- `syncro_flutter/build/` (artefactos generados)
- Archivos de plataforma (`android/`, `ios/`, `windows/`, `linux/`, `macos/`, `web/`) son parte estándar de Flutter, no lógica de negocio adicional

La lógica principal de la app está en `syncro_flutter/lib/main.dart`.
