import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:syncro_flutter/firebase_options.dart';

class FirebaseBootstrap {
  static bool _isReady = false;
  static String? _lastError;

  static bool get isReady => _isReady || Firebase.apps.isNotEmpty;
  static String? get lastError => _lastError;

  static Future<void> initializeAndSeed() async {
    try {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (error) {
          final String message = error.toString();
          if (!message.contains('duplicate-app')) {
            rethrow;
          }
        }
      }

      _isReady = true;
      _lastError = null;

      try {
        await _seedDatabaseIfNeeded();
      } catch (seedError, seedStack) {
        _lastError = 'Seed warning: $seedError';
        debugPrint('Firebase seed warning: $seedError');
        debugPrint('$seedStack');
      }
    } catch (error, stackTrace) {
      _isReady = Firebase.apps.isNotEmpty;
      _lastError = error.toString();
      debugPrint('Firebase init skipped: $error');
      debugPrint('$stackTrace');
    }
  }

  static Future<void> _seedDatabaseIfNeeded() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference<Map<String, dynamic>> seedDoc = firestore
        .collection('_meta')
        .doc('seed_v1');

    final DocumentSnapshot<Map<String, dynamic>> currentSeed =
        await seedDoc.get();
    if (currentSeed.exists) {
      await _ensureSensoryMetadataInGames(firestore);
      return;
    }

    final WriteBatch batch = firestore.batch();

    batch.set(firestore.collection('users').doc('demo'), <String, dynamic>{
      'email': 'demo',
      'password': 'demo123',
      'displayName': 'Demo Player',
      'avatar': '⚡',
      'profileStatus': 'En linea',
      'fontScale': 1.0,
      'accessibilityMode': 'tea',
      'softColors': true,
      'noAnimations': false,
      'legibleFont': false,
      'themePalette': 'suave',
      'fontPreference': 'sistema',
      'notificationMode': 'importantes',
      'sensoryFilterTags': <String>[],
      'showSensoryWarnings': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final List<String> featured = <String>[
      'Minecraft',
      'Stardew Valley',
      'The Legend of Zelda',
      'Celeste',
      'Hollow Knight',
      'Terraria',
      'Hades',
      'Animal Crossing',
      'Rocket League',
      'Valorant',
      'League of Legends',
    ];

    final List<String> genres = <String>[
      'RPG',
      'Accion',
      'Aventura',
      'Estrategia',
      'Shooter',
      'Simulacion',
    ];

    for (int id = 1; id <= featured.length; id++) {
      final String intensity = switch (id % 3) {
        0 => 'baja',
        1 => 'media',
        _ => 'alta',
      };

      batch.set(
        firestore.collection('games').doc(id.toString()),
        <String, dynamic>{
          'id': id,
          'name': featured[id - 1],
          'genre': genres[id % genres.length],
          'sensoryIntensity': intensity,
          'description':
              'Experiencia ${intensity.toLowerCase()} con enfoque accesible.',
          'sensoryTags': _defaultSensoryTagsForIntensity(intensity),
          'sensoryWarnings': _defaultSensoryWarningsForIntensity(intensity),
        },
      );
    }

    final List<Map<String, dynamic>> posts = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'title': 'Guia rapida para sesiones sin saturacion',
        'content':
            'Usa ciclos de 25/5 y baja intensidad visual en menus con mucho movimiento.',
        'likes': 0,
        'comments': <String>[],
        'likedBy': <String>[],
      },
      <String, dynamic>{
        'id': 2,
        'title': 'Config recomendada para Modo TEA',
        'content': 'Estructura fija, colores suaves y notificaciones minimas.',
        'likes': 0,
        'comments': <String>[],
        'likedBy': <String>[],
      },
      <String, dynamic>{
        'id': 3,
        'title': 'Config recomendada para Modo TDAH',
        'content':
            'Interfaz minimalista, tareas micro y recordatorios breves.',
        'likes': 0,
        'comments': <String>[],
        'likedBy': <String>[],
      },
    ];

    for (final Map<String, dynamic> post in posts) {
      batch.set(
        firestore.collection('posts').doc((post['id'] as int).toString()),
        post,
      );
    }

    final List<String> groups = <String>[
      'RPG Tranquilo: Debates narrativos sin spoilers agresivos',
      'Shooters con Estrategia: Consejos para jugar a tu ritmo',
      'Co-op Casual: Partidas de bajo estres',
      'Indies Inclusivos: Recomendaciones accesibles',
    ];

    for (int i = 0; i < groups.length; i++) {
      batch.set(
        firestore.collection('groups').doc((i + 1).toString()),
        <String, dynamic>{
          'id': i + 1,
          'name': groups[i],
        },
      );
    }

    final List<Map<String, dynamic>> shopItems = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'gameName': 'Minecraft',
        'cosmeticName': 'Skin Neon Creeper',
        'price': 40,
        'imageUrl':
            'https://images.unsplash.com/photo-1614294148960-9aa740632a87?auto=format&fit=crop&w=500&q=80',
      },
      <String, dynamic>{
        'id': 2,
        'gameName': 'Valorant',
        'cosmeticName': 'Spray Syncro Core',
        'price': 30,
        'imageUrl':
            'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=500&q=80',
      },
      <String, dynamic>{
        'id': 3,
        'gameName': 'Rocket League',
        'cosmeticName': 'Ruedas Aurora',
        'price': 35,
        'imageUrl':
            'https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&w=500&q=80',
      },
      <String, dynamic>{
        'id': 4,
        'gameName': 'Stardew Valley',
        'cosmeticName': 'Sombrero Pixel Flor',
        'price': 20,
        'imageUrl':
            'https://images.unsplash.com/photo-1472457897821-70d3819a0e24?auto=format&fit=crop&w=500&q=80',
      },
      <String, dynamic>{
        'id': 5,
        'gameName': 'Fortnite',
        'cosmeticName': 'Mochila Holografica',
        'price': 45,
        'imageUrl':
            'https://images.unsplash.com/photo-1511882150382-421056c89033?auto=format&fit=crop&w=500&q=80',
      },
      <String, dynamic>{
        'id': 6,
        'gameName': 'League of Legends',
        'cosmeticName': 'Icono Emblema Syncro',
        'price': 25,
        'imageUrl':
            'https://images.unsplash.com/photo-1551103782-8ab07afd45c1?auto=format&fit=crop&w=500&q=80',
      },
    ];

    for (final Map<String, dynamic> item in shopItems) {
      batch.set(
        firestore.collection('shop_items').doc((item['id'] as int).toString()),
        item,
      );
    }

    batch.set(seedDoc, <String, dynamic>{
      'version': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static Future<void> _ensureSensoryMetadataInGames(
    FirebaseFirestore firestore,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await firestore.collection('games').get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final WriteBatch batch = firestore.batch();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      final Map<String, dynamic> data = doc.data();
      final String intensity = (data['sensoryIntensity'] as String?) ?? 'media';
      final Map<String, dynamic> patch = <String, dynamic>{};

      if (data['sensoryTags'] == null) {
        patch['sensoryTags'] = _defaultSensoryTagsForIntensity(intensity);
      }
      if (data['sensoryWarnings'] == null) {
        patch['sensoryWarnings'] = _defaultSensoryWarningsForIntensity(intensity);
      }

      if (patch.isNotEmpty) {
        batch.set(doc.reference, patch, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  static List<String> _defaultSensoryTagsForIntensity(String intensity) {
    return switch (intensity) {
      'baja' => <String>['ritmo_lento', 'audio_suave'],
      'alta' => <String>['accion_rapida', 'estimulos_altos'],
      _ => <String>['ritmo_medio', 'estimulos_moderados'],
    };
  }

  static Map<String, List<String>> _defaultSensoryWarningsForIntensity(
    String intensity,
  ) {
    return switch (intensity) {
      'baja' => <String, List<String>>{
        'tea': <String>['Puede incluir diálogos extensos.'],
        'tdah': <String>['Ritmo pausado, puede requerir pausas activas.'],
      },
      'alta' => <String, List<String>>{
        'tea': <String>['Alta estimulación visual/sonora. Ajusta brillo y volumen.'],
        'tdah': <String>['Acción intensa sostenida, usa sesiones cortas.'],
      },
      _ => <String, List<String>>{
        'tea': <String>['Transiciones y sonidos moderados.'],
        'tdah': <String>['Puede alternar entre momentos tranquilos e intensos.'],
      },
    };
  }
}
