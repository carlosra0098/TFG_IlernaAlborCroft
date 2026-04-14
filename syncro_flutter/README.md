# Syncro Flutter

Port base de la app Kotlin/Compose a Flutter.

Estado actual de entrega: proyecto en Flutter/Dart, con lógica principal en `lib/main.dart`.

Incluye MVP funcional con:

- Login y registro local en memoria
- Acceso rapido con cuenta demo
- Bottom navigation con 5 secciones (Perfil, Buscar, Opciones, Chat, Mis Juegos)
- Biblioteca con busqueda y filtro de intensidad sensorial
- Favoritos y juegos en curso
- Social feed con likes y comentarios plantilla
- Pomodoro basico y tareas diarias
- Ajustes de accesibilidad visual y notificaciones

## Ejecutar

1. Abre una terminal en esta carpeta.
2. Ejecuta:

```bash
flutter pub get
flutter run
```

## Validar

```bash
flutter analyze
flutter test
```

## Nota de migracion

Este port replica la logica principal de UI/estado del proyecto Kotlin original,
pero usa almacenamiento en memoria para avanzar rapido.

Siguiente paso recomendado para produccion:

- Persistencia real con Isar o sqflite
- Estado con Riverpod o BLoC
- Rutas con GoRouter
