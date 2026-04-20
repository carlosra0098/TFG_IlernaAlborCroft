import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncro_flutter/features/stream/stream_hub_screen.dart';
import 'package:syncro_flutter/services/firebase_bootstrap.dart';
import 'package:syncro_flutter/services/igdb_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initializeAndSeed();
  runApp(const SyncroApp());
}

enum MainTab { home, buscar, mensajes, tienda, perfil }

enum AccessibilityMode { tea, tdah }

enum Neurodivergence { tea, tdah, otra }

enum SensoryIntensity { baja, media, alta }

enum NotificationMode { importantes, todas, ninguna }

enum ThemePalette { suave, neon, rosaOscuro, verde, clara }

enum FontPreference { sistema, legible, serif, monoespaciada }

enum ProfileGamesView { favoritos, proximos }

enum SearchScope { todo, juegos, usuarios, guias }

enum CatalogViewMode { lista, reticula }

class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.displayName,
    this.avatar = '🎮',
    this.avatarBytes,
    this.profileStatus = 'En línea',
    this.age = 18,
    this.neurodivergence = Neurodivergence.tea,
    this.fontScale = 1.0,
    this.accessibilityMode = AccessibilityMode.tea,
    this.softColors = true,
    this.noAnimations = false,
    this.legibleFont = false,
    this.themePalette = ThemePalette.suave,
    this.fontPreference = FontPreference.sistema,
    this.notificationMode = NotificationMode.importantes,
    this.onboardingCompleted = true,
    this.catalogViewMode = CatalogViewMode.lista,
    List<String>? sensoryFilterTags,
    this.showSensoryWarnings = true,
    this.emergencyGrayscale = false,
  }) : sensoryFilterTags = sensoryFilterTags ?? <String>[];

  final int id;
  final String email;
  final String password;
  final String displayName;
  final String avatar;
  final Uint8List? avatarBytes;
  final String profileStatus;
  final int age;
  final Neurodivergence neurodivergence;
  final double fontScale;
  final AccessibilityMode accessibilityMode;
  final bool softColors;
  final bool noAnimations;
  final bool legibleFont;
  final ThemePalette themePalette;
  final FontPreference fontPreference;
  final NotificationMode notificationMode;
  final bool onboardingCompleted;
  final CatalogViewMode catalogViewMode;
  final List<String> sensoryFilterTags;
  final bool showSensoryWarnings;
  final bool? emergencyGrayscale;

  UserModel copyWith({
    String? displayName,
    String? avatar,
    Uint8List? avatarBytes,
    bool clearAvatarBytes = false,
    String? profileStatus,
    int? age,
    Neurodivergence? neurodivergence,
    double? fontScale,
    AccessibilityMode? accessibilityMode,
    bool? softColors,
    bool? noAnimations,
    bool? legibleFont,
    ThemePalette? themePalette,
    FontPreference? fontPreference,
    NotificationMode? notificationMode,
    bool? onboardingCompleted,
    CatalogViewMode? catalogViewMode,
    List<String>? sensoryFilterTags,
    bool? showSensoryWarnings,
    bool? emergencyGrayscale,
  }) {
    return UserModel(
      id: id,
      email: email,
      password: password,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      avatarBytes: clearAvatarBytes ? null : (avatarBytes ?? this.avatarBytes),
      profileStatus: profileStatus ?? this.profileStatus,
      age: age ?? this.age,
      neurodivergence: neurodivergence ?? this.neurodivergence,
      fontScale: fontScale ?? this.fontScale,
      accessibilityMode: accessibilityMode ?? this.accessibilityMode,
      softColors: softColors ?? this.softColors,
      noAnimations: noAnimations ?? this.noAnimations,
      legibleFont: legibleFont ?? this.legibleFont,
      themePalette: themePalette ?? this.themePalette,
      fontPreference: fontPreference ?? this.fontPreference,
      notificationMode: notificationMode ?? this.notificationMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      catalogViewMode: catalogViewMode ?? this.catalogViewMode,
      sensoryFilterTags: sensoryFilterTags ?? this.sensoryFilterTags,
      showSensoryWarnings: showSensoryWarnings ?? this.showSensoryWarnings,
      emergencyGrayscale:
          emergencyGrayscale ?? (this.emergencyGrayscale == true),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'password': password,
      'displayName': displayName,
      'avatar': avatar,
      'avatarBytes': avatarBytes != null ? base64Encode(avatarBytes!) : null,
      'profileStatus': profileStatus,
      'age': age,
      'neurodivergence': neurodivergence.name,
      'fontScale': fontScale,
      'accessibilityMode': accessibilityMode.name,
      'softColors': softColors,
      'noAnimations': noAnimations,
      'legibleFont': legibleFont,
      'themePalette': themePalette.name,
      'fontPreference': fontPreference.name,
      'notificationMode': notificationMode.name,
      'onboardingCompleted': onboardingCompleted,
      'catalogViewMode': catalogViewMode.name,
      'sensoryFilterTags': sensoryFilterTags,
      'showSensoryWarnings': showSensoryWarnings,
      'emergencyGrayscale': emergencyGrayscale == true,
    };
  }

  static UserModel fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      password: json['password'] as String,
      displayName: json['displayName'] as String? ?? 'Usuario',
      avatar: json['avatar'] as String? ?? '🎮',
      avatarBytes: json['avatarBytes'] != null
          ? base64Decode(json['avatarBytes'] as String)
          : null,
      profileStatus: json['profileStatus'] as String? ?? 'En línea',
      age: (json['age'] as int?) ?? 18,
      neurodivergence: Neurodivergence.values.byName(
        json['neurodivergence'] as String? ?? 'tea',
      ),
      fontScale: json['fontScale'] as double? ?? 1.0,
      accessibilityMode: AccessibilityMode.values.byName(
        json['accessibilityMode'] as String? ?? 'tea',
      ),
      softColors: json['softColors'] as bool? ?? true,
      noAnimations: json['noAnimations'] as bool? ?? false,
      legibleFont: json['legibleFont'] as bool? ?? false,
      themePalette: ThemePalette.values.byName(
        json['themePalette'] as String? ?? 'suave',
      ),
      fontPreference: FontPreference.values.byName(
        json['fontPreference'] as String? ?? 'sistema',
      ),
      notificationMode: NotificationMode.values.byName(
        json['notificationMode'] as String? ?? 'importantes',
      ),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? true,
      catalogViewMode: CatalogViewMode.values.byName(
        json['catalogViewMode'] as String? ?? 'lista',
      ),
      sensoryFilterTags:
          (json['sensoryFilterTags'] as List<dynamic>? ?? <dynamic>[])
              .whereType<String>()
              .toList(),
      showSensoryWarnings: json['showSensoryWarnings'] as bool? ?? true,
      emergencyGrayscale: json['emergencyGrayscale'] as bool? ?? false,
    );
  }
}

class GameModel {
  GameModel({
    required this.id,
    required this.name,
    required this.genre,
    required this.imageUrl,
    required this.sensoryIntensity,
    required this.description,
    List<String>? sensoryTags,
    Map<String, List<String>>? sensoryWarnings,
  }) : sensoryTags = sensoryTags ?? <String>[],
       sensoryWarnings = sensoryWarnings ?? <String, List<String>>{};

  final int id;
  final String name;
  final String genre;
  final String imageUrl;
  final SensoryIntensity sensoryIntensity;
  final String description;
  final List<String> sensoryTags;
  final Map<String, List<String>> sensoryWarnings;
}

class PostModel {
  PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.likes = 0,
    List<String>? comments,
    Set<int>? likedBy,
  }) : comments = comments ?? <String>[],
       likedBy = likedBy ?? <int>{};

  final int id;
  final String title;
  final String content;
  int likes;
  final List<String> comments;
  final Set<int> likedBy;
}

class CommunityGuideModel {
  CommunityGuideModel({
    required this.id,
    required this.gameId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final int gameId;
  final int authorId;
  final String authorName;
  final String title;
  final String content;
  final DateTime createdAt;
}

class TaskModel {
  TaskModel({
    required this.id,
    required this.title,
    required this.type,
    this.isDone = false,
  });

  final int id;
  final String title;
  final DailyMissionType type;
  bool isDone;
}

enum DailyMissionType { readGuide, favoriteGame, consciousBreak }

class CosmeticItemModel {
  CosmeticItemModel({
    required this.id,
    required this.gameName,
    required this.cosmeticName,
    required this.price,
    required this.imageUrl,
  });

  final int id;
  final String gameName;
  final String cosmeticName;
  final int price;
  final String imageUrl;
}

class LibraryGameUi {
  LibraryGameUi({
    required this.game,
    required this.isFavorite,
    required this.isUpcoming,
    required this.isPlayingNow,
    required this.recommendationTag,
  });

  final GameModel game;
  final bool isFavorite;
  final bool isUpcoming;
  final bool isPlayingNow;
  final String? recommendationTag;
}

class TimerUiState {
  TimerUiState({
    this.remainingSeconds = 25 * 60,
    this.isRunning = false,
    this.isWorkSession = true,
    this.showBreakReminder = false,
  });

  int remainingSeconds;
  bool isRunning;
  bool isWorkSession;
  bool showBreakReminder;
}

class AuthUiState {
  AuthUiState({
    this.email = '',
    this.password = '',
    this.displayName = '',
    this.isRegisterMode = false,
    this.isLoading = false,
    this.errorMessage,
  });

  String email;
  String password;
  String displayName;
  bool isRegisterMode;
  bool isLoading;
  String? errorMessage;
}

class SyncroApp extends StatelessWidget {
  const SyncroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Syncro Flutter',
      themeMode: ThemeMode.dark,
      darkTheme: _buildTheme(
        themePalette: ThemePalette.suave,
        fontPreference: FontPreference.sistema,
      ),
      home: const SyncroRoot(),
    );
  }

  ThemeData _buildTheme({
    required ThemePalette themePalette,
    required FontPreference fontPreference,
  }) {
    final ColorScheme scheme = switch (themePalette) {
      ThemePalette.suave => const ColorScheme.dark(
        primary: Color(0xFF40F9FF),
        onPrimary: Color(0xFF001014),
        secondary: Color(0xFFB388FF),
        tertiary: Color(0xFFFF5CF2),
        surface: Color(0xFF151024),
        surfaceContainerHighest: Color(0xFF1D1630),
        onSurfaceVariant: Color(0xFFE5D9FF),
      ),
      ThemePalette.neon => const ColorScheme.dark(
        primary: Color(0xFF00F5FF),
        onPrimary: Color(0xFF001316),
        secondary: Color(0xFF9D4DFF),
        tertiary: Color(0xFFFF2CF0),
        surface: Color(0xFF11091D),
        surfaceContainerHighest: Color(0xFF1A1230),
        onSurfaceVariant: Color(0xFFE9DBFF),
      ),
      ThemePalette.rosaOscuro => ColorScheme.fromSeed(
        seedColor: const Color(0xFFC2185B),
        brightness: Brightness.dark,
      ),
      ThemePalette.verde => ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: Brightness.dark,
      ),
      ThemePalette.clara => ColorScheme.fromSeed(
        seedColor: const Color(0xFF42A5F5),
        brightness: Brightness.light,
      ),
    };

    final String? fontFamily = switch (fontPreference) {
      FontPreference.sistema => null,
      FontPreference.legible => 'Roboto',
      FontPreference.serif => 'serif',
      FontPreference.monoespaciada => 'monospace',
    };

    final bool lightTheme = scheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: lightTheme
          ? scheme.surface
          : const Color(0xFF090411),
      textTheme: ThemeData.dark(
        useMaterial3: true,
      ).textTheme.apply(fontFamily: fontFamily),
    );
  }
}

class SyncroRoot extends StatefulWidget {
  const SyncroRoot({super.key});

  @override
  State<SyncroRoot> createState() => _SyncroRootState();
}

class _SyncroRootState extends State<SyncroRoot> {
  final AuthUiState _auth = AuthUiState();
  final TextEditingController _redeemCodeController = TextEditingController();
  final Random _random = Random();

  UserModel? _currentUser;
  MainTab _activeTab = MainTab.home;
  String _searchQuery = '';
  SearchScope _searchScope = SearchScope.todo;
  SensoryIntensity? _selectedIntensity;
  final Set<String> _selectedSensoryTags = <String>{};
  bool _showLibraryFilters = false;
  CatalogViewMode _catalogViewMode = CatalogViewMode.lista;
  ProfileGamesView _profileGamesView = ProfileGamesView.favoritos;
  final TimerUiState _timer = TimerUiState();
  SharedPreferences? _prefs;

  final List<UserModel> _users = <UserModel>[];
  final List<GameModel> _games = <GameModel>[];
  final List<PostModel> _posts = <PostModel>[];
  final List<String> _groups = <String>[];
  final Map<int, Map<int, bool>> _favoriteByUser = <int, Map<int, bool>>{};
  final Map<int, Map<int, bool>> _upcomingByUser = <int, Map<int, bool>>{};
  final Map<int, Map<int, bool>> _playingByUser = <int, Map<int, bool>>{};
  final Map<int, List<TaskModel>> _tasksByUser = <int, List<TaskModel>>{};
  final Map<int, int> _coinsByUser = <int, int>{};
  final Map<int, DateTime> _dailyMissionDateByUser = <int, DateTime>{};
  final Map<int, Set<int>> _ownedCosmeticsByUser = <int, Set<int>>{};
  final Map<int, int> _focusSecondsByUser = <int, int>{};
  final Map<int, int> _breakSecondsByUser = <int, int>{};
  final Map<int, Map<String, int>> _purchaseCodesByUser =
      <int, Map<String, int>>{};
  final Map<int, Set<String>> _redeemedCodesByUser = <int, Set<String>>{};
  final Map<int, String> _lastGeneratedCodeByUser = <int, String>{};
  final Map<int, Set<int>> _friendsByUser = <int, Set<int>>{};
  final Map<int, Set<String>> _friendEmailsByUser = <int, Set<String>>{};
  final Map<int, Set<int>> _blockedUsersByUser = <int, Set<int>>{};
  final Map<int, Set<int>> _reportedUsersByUser = <int, Set<int>>{};
  final Map<int, Set<int>> _reportedGuidesByUser = <int, Set<int>>{};
  final Map<int, List<String>> _searchHistoryByUser = <int, List<String>>{};
  final Map<int, bool> _dailyMissionsLoadedByUser = <int, bool>{};
  final List<CommunityGuideModel> _communityGuides = <CommunityGuideModel>[];
  final List<IgdbGameDto> _igdbResults = <IgdbGameDto>[];
  Timer? _igdbSearchDebounce;
  Timer? _userSearchDebounce;
  bool _isIgdbLoading = false;
  String? _igdbErrorMessage;
  String _lastIgdbQuery = '';
  int _igdbRequestSequence = 0;
  int _activeIgdbRequestId = 0;
  Neurodivergence _onboardingNeuro = Neurodivergence.tea;
  int _onboardingAge = 18;
  final Set<int> _onboardingFavoriteGameIds = <int>{};
  String _onboardingGameQuery = '';
  int _taskIdCounter = 1;
  int _guideIdCounter = 1;
  int _secondsSinceBreakReminder = 0;
  int _workDurationMinutes = 25;
  int _breakDurationMinutes = 5;
  bool _isPomodoroPromptOpen = false;
  Timer? _ticker;

  final List<CosmeticItemModel> _shopItems = <CosmeticItemModel>[
    CosmeticItemModel(
      id: 1,
      gameName: 'Minecraft',
      cosmeticName: 'Skin Neon Creeper',
      price: 40,
      imageUrl:
          'https://images.unsplash.com/photo-1614294148960-9aa740632a87?auto=format&fit=crop&w=500&q=80',
    ),
    CosmeticItemModel(
      id: 2,
      gameName: 'Valorant',
      cosmeticName: 'Spray Syncro Core',
      price: 30,
      imageUrl:
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=500&q=80',
    ),
    CosmeticItemModel(
      id: 3,
      gameName: 'Rocket League',
      cosmeticName: 'Ruedas Aurora',
      price: 35,
      imageUrl:
          'https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&w=500&q=80',
    ),
    CosmeticItemModel(
      id: 4,
      gameName: 'Stardew Valley',
      cosmeticName: 'Sombrero Pixel Flor',
      price: 20,
      imageUrl:
          'https://images.unsplash.com/photo-1472457897821-70d3819a0e24?auto=format&fit=crop&w=500&q=80',
    ),
    CosmeticItemModel(
      id: 5,
      gameName: 'Fortnite',
      cosmeticName: 'Mochila Holográfica',
      price: 45,
      imageUrl:
          'https://images.unsplash.com/photo-1511882150382-421056c89033?auto=format&fit=crop&w=500&q=80',
    ),
    CosmeticItemModel(
      id: 6,
      gameName: 'League of Legends',
      cosmeticName: 'Icono Emblema Syncro',
      price: 25,
      imageUrl:
          'https://images.unsplash.com/photo-1551103782-8ab07afd45c1?auto=format&fit=crop&w=500&q=80',
    ),
  ];

  final List<Map<String, String>> _news = const <Map<String, String>>[
    {
      'title': 'Nuevo parche competitivo mejora el matchmaking',
      'source': 'Syncro News',
      'summary':
          'Ajustes de emparejamiento y menor latencia en partidas igualadas.',
    },
    {
      'title': 'Tendencia 2026: mas juegos con modos accesibles',
      'source': 'Gaming Today',
      'summary':
          'Mas estudios anaden presets cognitivos y controles de estimulos.',
    },
    {
      'title': 'Eventos cooperativos de primavera ya disponibles',
      'source': 'Gamer Hub',
      'summary':
          'Misiones semanales en titulos co-op con recompensas cosmeticas.',
    },
  ];

  final List<String> _commentTemplates = const <String>[
    'Guia util!',
    'Gracias por compartir',
    'Me ayudo mucho',
  ];

  @override
  void initState() {
    super.initState();
    _seedInitialData();
    unawaited(_syncGamesFromFirebase());
    unawaited(_syncCommunityGuidesFromFirebase());
    unawaited(_removePlaceholderGamesEverywhere());
    _loadPreferences();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickTimer();
      _tickBreakReminder();
    });
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    final UserModel? user = _currentUser;
    if (user != null) {
      setState(() {
        _restoreSearchHistoryFromPrefs(user.id);
        _ensureDailyMissionState(user.id);
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _igdbSearchDebounce?.cancel();
    _userSearchDebounce?.cancel();
    _redeemCodeController.dispose();
    super.dispose();
  }

  void _seedInitialData() {
    _users.add(
      UserModel(
        id: 1,
        email: 'demo',
        password: 'demo123',
        displayName: 'Demo Player',
        avatar: '⚡',
      ),
    );
    _users.addAll(<UserModel>[
      UserModel(
        id: 2,
        email: 'alex@syncro.dev',
        password: 'demo123',
        displayName: 'Alex',
        avatar: '🕹️',
        profileStatus: 'En linea',
      ),
      UserModel(
        id: 3,
        email: 'nora@syncro.dev',
        password: 'demo123',
        displayName: 'Nora',
        avatar: '🎯',
        profileStatus: 'Jugando Valorant',
      ),
      UserModel(
        id: 4,
        email: 'maya@syncro.dev',
        password: 'demo123',
        displayName: 'Maya',
        avatar: '🌱',
        profileStatus: 'En Stardew Valley',
      ),
    ]);
    _friendsByUser[1] = <int>{2, 3};
    _friendsByUser[2] = <int>{1};
    _friendsByUser[3] = <int>{1};

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
      'Fortnite',
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
      final SensoryIntensity intensity = switch (id % 3) {
        0 => SensoryIntensity.baja,
        1 => SensoryIntensity.media,
        _ => SensoryIntensity.alta,
      };
      final String gameName = featured[id - 1];
      _games.add(
        GameModel(
          id: id,
          name: gameName,
          genre: genres[id % genres.length],
          imageUrl: _imageForGameName(gameName),
          sensoryIntensity: intensity,
          description:
              'Experiencia ${_intensityName(intensity).toLowerCase()} con enfoque accesible.',
          sensoryTags: _defaultSensoryTagsForIntensity(intensity),
          sensoryWarnings: _defaultSensoryWarningsForIntensity(intensity),
        ),
      );
    }

    _groups.addAll(<String>[
      'RPG Tranquilo: Debates narrativos sin spoilers agresivos',
      'Shooters con Estrategia: Consejos para jugar a tu ritmo',
      'Co-op Casual: Partidas de bajo estres',
      'Indies Inclusivos: Recomendaciones accesibles',
    ]);

    _posts.addAll(<PostModel>[
      PostModel(
        id: 1,
        title: 'Guia rapida para sesiones sin saturacion',
        content:
            'Usa ciclos de 25/5 y baja intensidad visual en menus con mucho movimiento.',
      ),
      PostModel(
        id: 2,
        title: 'Config recomendada para Modo TEA',
        content: 'Estructura fija, colores suaves y notificaciones minimas.',
      ),
      PostModel(
        id: 3,
        title: 'Config recomendada para Modo TDAH',
        content: 'Interfaz minimalista, tareas micro y recordatorios breves.',
      ),
    ]);

    final UserModel demoUser = _users.firstWhere(
      (UserModel user) => user.email == 'demo',
    );
    _communityGuides.addAll(<CommunityGuideModel>[
      CommunityGuideModel(
        id: _guideIdCounter++,
        gameId: 1,
        authorId: demoUser.id,
        authorName: demoUser.displayName,
        title: 'Guía base para empezar sin saturación',
        content:
            'Empieza con dificultad normal y reduce partículas para jugar con menos sobrecarga visual.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      CommunityGuideModel(
        id: _guideIdCounter++,
        gameId: 10,
        authorId: 3,
        authorName: 'Nora',
        title: 'Rutina corta para Valorant',
        content:
            'En Valorant, usa 2 partidas cortas y descansa 5 minutos entre cada una para mantener foco.',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = _currentUser;
    final double uiTextScale = (user?.fontScale ?? 1.0).clamp(0.85, 1.4);

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(uiTextScale)),
      child: AnimatedTheme(
        data: SyncroApp()._buildTheme(
          themePalette: user?.themePalette ?? ThemePalette.suave,
          fontPreference: user?.fontPreference ?? FontPreference.sistema,
        ),
        duration: (user?.noAnimations ?? false)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        child: user == null
            ? _buildAuthScreen()
            : (user.onboardingCompleted
                  ? _buildMainScreen(user)
                  : _buildOnboardingScreen(user)),
      ),
    );
  }

  Widget _buildAuthScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF07020F),
              Color(0xFF120A26),
              Color(0xFF090411),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'SYNCRO',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Plataforma gaming social con accesibilidad neurodivergente',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          selected: !_auth.isRegisterMode,
                          label: const Text('Entrar'),
                          onSelected: (_) => setState(() {
                            _auth.isRegisterMode = false;
                            _auth.errorMessage = null;
                          }),
                        ),
                        ChoiceChip(
                          selected: _auth.isRegisterMode,
                          label: const Text('Crear cuenta'),
                          onSelected: (_) => setState(() {
                            _auth.isRegisterMode = true;
                            _auth.errorMessage = null;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !_auth.isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Email o usuario',
                        prefixIcon: Icon(Icons.email),
                      ),
                      onChanged: (String value) => _auth.email = value,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      enabled: !_auth.isLoading,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contrasena',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      onChanged: (String value) => _auth.password = value,
                    ),
                    if (_auth.isRegisterMode) ...<Widget>[
                      const SizedBox(height: 10),
                      TextField(
                        enabled: !_auth.isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Nombre visible',
                          prefixIcon: Icon(Icons.person),
                        ),
                        onChanged: (String value) => _auth.displayName = value,
                      ),
                    ],
                    if (_auth.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        _auth.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_auth.isLoading) ...<Widget>[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _auth.isLoading ? null : _submitAuth,
                        child: Text(
                          _auth.isRegisterMode ? 'Crear cuenta' : 'Entrar',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _auth.isLoading ? null : _loginDemo,
                        child: const Text('Entrar con cuenta demo'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Demo: usuario demo - contrasena demo123',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingScreen(UserModel user) {
    final ThemeData theme = Theme.of(context);
    final List<GameModel> visibleGames = _games
        .where(
          (GameModel game) =>
              _onboardingGameQuery.trim().isEmpty ||
              game.name.toLowerCase().contains(
                _onboardingGameQuery.trim().toLowerCase(),
              ),
        )
        .take(18)
        .toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Configura tu experiencia'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text(
            'Bienvenido, ${user.displayName}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Para personalizar Syncro, elige tu neurodivergencia, edad y 3 juegos favoritos.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Neurodivergencia',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('TEA'),
                        selected: _onboardingNeuro == Neurodivergence.tea,
                        onSelected: (_) => setState(
                          () => _onboardingNeuro = Neurodivergence.tea,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('TDAH'),
                        selected: _onboardingNeuro == Neurodivergence.tdah,
                        onSelected: (_) => setState(
                          () => _onboardingNeuro = Neurodivergence.tdah,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Otra'),
                        selected: _onboardingNeuro == Neurodivergence.otra,
                        onSelected: (_) => setState(
                          () => _onboardingNeuro = Neurodivergence.otra,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Edad: $_onboardingAge años'),
                  Slider(
                    min: 8,
                    max: 60,
                    divisions: 52,
                    label: '$_onboardingAge',
                    value: _onboardingAge.toDouble(),
                    onChanged: (double value) {
                      setState(() {
                        _onboardingAge = value.round();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Elige 3 juegos favoritos (${_onboardingFavoriteGameIds.length}/3)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar juegos (catálogo e IGDB)',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (String value) {
                      setState(() {
                        _onboardingGameQuery = value;
                      });
                      _queueIgdbSearch(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_onboardingFavoriteGameIds.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _onboardingFavoriteGameIds.map((int gameId) {
                        final GameModel? game = _games
                            .cast<GameModel?>()
                            .firstWhere(
                              (GameModel? item) => item?.id == gameId,
                              orElse: () => null,
                            );
                        if (game == null) {
                          return const SizedBox.shrink();
                        }
                        return InputChip(
                          selected: true,
                          label: Text(game.name),
                          onDeleted: () => _toggleOnboardingFavorite(game.id),
                        );
                      }).toList(),
                    ),
                  if (_onboardingFavoriteGameIds.isNotEmpty)
                    const SizedBox(height: 10),
                  Text(
                    'Sugeridos del catálogo',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  ...visibleGames.map(
                    (GameModel game) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _onboardingFavoriteGameIds.contains(game.id),
                      onChanged: (_) => _toggleOnboardingFavorite(game.id),
                      title: Text(game.name),
                      subtitle: Text('${game.genre} · ${_intensityName(game.sensoryIntensity)}'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Resultados IGDB', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  if (_isIgdbLoading)
                    const LinearProgressIndicator()
                  else if (_igdbErrorMessage != null)
                    Text(_igdbErrorMessage!)
                  else if (_igdbResults.isNotEmpty)
                    ..._igdbResults.take(6).map((IgdbGameDto item) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        subtitle: Text(item.genre.isEmpty ? 'General' : item.genre),
                        trailing: OutlinedButton(
                          onPressed: () {
                            final int? gameId = _addIgdbGameToCatalog(item);
                            if (gameId != null) {
                              _toggleOnboardingFavorite(gameId);
                            }
                          },
                          child: const Text('Añadir'),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _completeOnboarding,
            child: const Text('Guardar y continuar'),
          ),
        ],
      ),
    );
  }

  void _toggleOnboardingFavorite(int gameId) {
    final bool isSelected = _onboardingFavoriteGameIds.contains(gameId);
    if (!isSelected && _onboardingFavoriteGameIds.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes elegir exactamente 3 juegos. Quita uno para cambiarlo.'),
        ),
      );
      return;
    }
    setState(() {
      if (isSelected) {
        _onboardingFavoriteGameIds.remove(gameId);
      } else {
        _onboardingFavoriteGameIds.add(gameId);
      }
    });
  }

  void _initializeOnboardingState(UserModel user) {
    if (!mounted) {
      return;
    }
    setState(() {
      _onboardingNeuro = user.neurodivergence;
      _onboardingAge = user.age.clamp(8, 60);
      _onboardingGameQuery = '';
      _onboardingFavoriteGameIds
        ..clear()
        ..addAll(
          (_favoriteByUser[user.id] ?? <int, bool>{}).entries
              .where((MapEntry<int, bool> entry) => entry.value)
              .map((MapEntry<int, bool> entry) => entry.key)
              .take(3),
        );
    });
    _queueIgdbSearch('');
  }

  void _completeOnboarding() {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }
    if (_onboardingFavoriteGameIds.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona exactamente 3 juegos favoritos para continuar.'),
        ),
      );
      return;
    }

    final Map<int, bool> favorites = _favoriteByUser.putIfAbsent(
      user.id,
      () => <int, bool>{},
    );
    favorites.removeWhere((int _, bool __) => true);
    for (final int gameId in _onboardingFavoriteGameIds) {
      favorites[gameId] = true;
    }

    _updateCurrentUser((UserModel base) {
      final UserModel adapted = _buildAdaptiveUserProfile(
        base: base,
        neurodivergence: _onboardingNeuro,
        age: _onboardingAge,
      );
      return adapted.copyWith(onboardingCompleted: true);
    });

    setState(() {
      _activeTab = MainTab.home;
    });
  }

  Widget _buildMainScreen(UserModel user) {
    final List<LibraryGameUi> allLibraryGames = _buildLibraryGames(
      user,
      applyFilters: false,
    );
    final List<LibraryGameUi> filteredLibraryGames = _buildLibraryGames(
      user,
      applyFilters: true,
    );
    final List<LibraryGameUi> recentGames = _buildRecentGamesForUser(user);
    final int coins = _coinsByUser[user.id] ?? 0;

    final Widget baseScaffold = Scaffold(
      drawer: _activeTab == MainTab.perfil
          ? _buildProfileMenuDrawer(user)
          : null,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Syncro',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '🪙 $coins  ·  ${_timer.isWorkSession ? 'Trabajo' : 'Descanso'}: ${_formatSeconds(_timer.remainingSeconds)}',
              ),
            ),
          ),
          IconButton(
            onPressed: _showAddPomodoroTimeDialog,
            icon: const Icon(Icons.add_alarm),
            tooltip: 'Añadir tiempo',
          ),
          IconButton(
            onPressed: _startPausePomodoro,
            icon: Icon(_timer.isRunning ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _activeTab.index,
        onDestinationSelected: (int index) =>
            setState(() => _activeTab = MainTab.values[index]),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Tienda'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_timer.showBreakReminder)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: ListTile(
                  title: const Text(
                    'Recordatorio: toma un descanso de 5 minutos',
                  ),
                  trailing: TextButton(
                    onPressed: _dismissBreakReminder,
                    child: const Text('Hecho'),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: switch (_activeTab) {
                MainTab.home => _buildHomeScreen(user, recentGames),
                MainTab.buscar => _buildLibraryScreen(
                  user,
                  filteredLibraryGames,
                ),
                MainTab.mensajes => StreamHubScreen(
                  displayName: user.displayName,
                  currentUserId: _streamUserIdFromUser(user),
                ),
                MainTab.tienda => _buildStoreScreen(user),
                MainTab.perfil => _buildOptionsScreen(user),
              },
            ),
          ),
        ],
      ),
    );

    final bool emergencyModeEnabled = user.emergencyGrayscale == true;

    if (!emergencyModeEnabled) {
      return baseScaffold;
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: baseScaffold,
    );
  }

  Widget _buildHomeScreen(UserModel user, List<LibraryGameUi> recentGames) {
    final List<UserModel> friends = _friendsForUser(user);

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bienvenido, ${user.displayName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu centro gamer neon: juega, conecta y descubre novedades cada dia.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    FilledButton(
                      onPressed: () =>
                          setState(() => _activeTab = MainTab.buscar),
                      child: const Text('Buscar juegos'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _activeTab = MainTab.mensajes),
                      child: const Text('Chat'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _activeTab = MainTab.tienda),
                      child: const Text('Ir a tienda'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ultimos juegos que has jugado',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 350,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentGames.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final LibraryGameUi gameUi = recentGames[index];
              return SizedBox(
                width: 250,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildNetworkImage(
                              gameUi.game.imageUrl,
                              width: double.infinity,
                              height: 120,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            gameUi.game.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${gameUi.game.genre} - ${_intensityName(gameUi.game.sensoryIntensity).toLowerCase()}',
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: <Widget>[
                              if (gameUi.isPlayingNow)
                                const Chip(label: Text('En guia')),
                              if (gameUi.isFavorite)
                                const Chip(label: Text('Favorito')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              IconButton(
                                onPressed: () => _toggleFavorite(gameUi.game.id),
                                icon: Icon(
                                  gameUi.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                              ),
                              IconButton(
                                tooltip: gameUi.isUpcoming
                                    ? 'Quitar de Próximos juegos'
                                    : 'Añadir a Próximos juegos',
                                onPressed: () => _toggleUpcoming(gameUi.game.id),
                                icon: Icon(
                                  gameUi.isUpcoming
                                      ? Icons.playlist_add_check_circle
                                      : Icons.playlist_add_circle_outlined,
                                ),
                              ),
                              FilledButton(
                                onPressed: gameUi.isPlayingNow
                                    ? null
                                    : () => _toggleGuideForGame(
                                          gameUi.game,
                                          focusSearchOnEnable: true,
                                        ),
                                child: const Text('Ver guia'),
                              ),
                              OutlinedButton(
                                onPressed: gameUi.isPlayingNow
                                    ? () => _toggleGuideForGame(gameUi.game)
                                    : null,
                                child: const Text('Quitar guia'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text('Tus amigos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: friends.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final UserModel friend = friends[index];
              return SizedBox(
                width: 190,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${friend.avatar} ${friend.displayName}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(friend.profileStatus),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Noticias del mundo gamer',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._news.map(
          (Map<String, String> item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item['title'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(item['summary'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      item['source'] ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryScreen(UserModel user, List<LibraryGameUi> games) {
    final String normalizedQuery = _normalizeTextForSearch(_searchQuery);
    final List<String> searchHistory =
      _searchHistoryByUser[user.id] ?? <String>[];
    final bool showGames =
        _searchScope == SearchScope.todo || _searchScope == SearchScope.juegos;
    final bool showUsers =
        _searchScope == SearchScope.todo ||
        _searchScope == SearchScope.usuarios;
    final bool showGuides =
        _searchScope == SearchScope.todo || _searchScope == SearchScope.guias;
    final Set<int> blockedIds = _blockedUsersByUser[user.id] ?? <int>{};

    final List<UserModel> userMatches = normalizedQuery.isEmpty
        ? <UserModel>[]
        : _users
              .where(
                (UserModel item) =>
                    item.id != user.id &&
                  !blockedIds.contains(item.id) &&
                    (_normalizeTextForSearch(item.displayName).contains(normalizedQuery) ||
                        _normalizeTextForSearch(item.email).contains(normalizedQuery)),
              )
              .take(8)
              .toList();
    final List<CommunityGuideModel> guideMatches = normalizedQuery.isEmpty
      ? <CommunityGuideModel>[]
        : _communityGuides
              .where(
                (CommunityGuideModel guide) =>
                    !blockedIds.contains(guide.authorId) &&
                    (_gameNameForId(
                      guide.gameId,
                    ).toLowerCase().contains(normalizedQuery) ||
                    guide.authorName.toLowerCase().contains(normalizedQuery) ||
                    guide.content.toLowerCase().contains(normalizedQuery)),
              )
              .take(8)
              .toList();
    final List<String> availableSensoryTags = _games
        .expand((GameModel game) => game.sensoryTags)
        .toSet()
        .toList()
      ..sort();

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        TextField(
          decoration: const InputDecoration(
            labelText: 'Buscar juegos, usuarios o guías',
          ),
          onChanged: _onSearchQueryChanged,
        ),
        if (normalizedQuery.isEmpty && searchHistory.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text(
                'Historial reciente',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchHistoryByUser[user.id] = <String>[];
                  });
                  _persistSearchHistory(user.id);
                },
                child: const Text('Limpiar'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searchHistory
                .take(8)
                .map(
                  (String item) => ActionChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(item),
                    onPressed: () {
                      setState(() {
                        _searchQuery = item;
                      });
                      _queueUserSearch(item);
                      _queueIgdbSearch(item);
                    },
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showLibraryFilters = !_showLibraryFilters;
                });
              },
              icon: Icon(
                _showLibraryFilters
                    ? Icons.expand_less
                    : Icons.expand_more,
              ),
              label: Text(_showLibraryFilters ? 'Ocultar filtros' : 'Mostrar filtros'),
            ),
            const SizedBox(width: 10),
            if (showGames) Expanded(child: Text('Catalogo: ${games.length} juegos')),
          ],
        ),
        if (_showLibraryFilters) const SizedBox(height: 10),
        if (_showLibraryFilters)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Ámbito de búsqueda', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      ChoiceChip(
                        selected: _searchScope == SearchScope.todo,
                        label: const Text('Todo'),
                        onSelected: (_) {
                          setState(() => _searchScope = SearchScope.todo);
                          _queueUserSearch(_searchQuery);
                        },
                      ),
                      ChoiceChip(
                        selected: _searchScope == SearchScope.juegos,
                        label: const Text('Juegos'),
                        onSelected: (_) {
                          setState(() => _searchScope = SearchScope.juegos);
                          _queueUserSearch(_searchQuery);
                        },
                      ),
                      ChoiceChip(
                        selected: _searchScope == SearchScope.usuarios,
                        label: const Text('Usuarios'),
                        onSelected: (_) {
                          setState(() => _searchScope = SearchScope.usuarios);
                          _queueUserSearch(_searchQuery);
                        },
                      ),
                      ChoiceChip(
                        selected: _searchScope == SearchScope.guias,
                        label: const Text('Guías'),
                        onSelected: (_) {
                          setState(() => _searchScope = SearchScope.guias);
                          _queueUserSearch(_searchQuery);
                        },
                      ),
                    ],
                  ),
                  if (showGames) ...<Widget>[
                    const SizedBox(height: 12),
                    Text('Intensidad sensorial', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        FilterChip(
                          selected: _selectedIntensity == null,
                          label: const Text('Todos'),
                          onSelected: (_) =>
                              setState(() => _selectedIntensity = null),
                        ),
                        for (final SensoryIntensity intensity in SensoryIntensity.values)
                          FilterChip(
                            selected: _selectedIntensity == intensity,
                            label: Text(_intensityName(intensity)),
                            onSelected: (_) =>
                                setState(() => _selectedIntensity = intensity),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Etiquetas sensoriales', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final String tag in availableSensoryTags)
                          FilterChip(
                            selected: _selectedSensoryTags.contains(tag),
                            label: Text(tag.replaceAll('_', ' ')),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSensoryTags.add(tag);
                                } else {
                                  _selectedSensoryTags.remove(tag);
                                }
                              });
                              _updateCurrentUser(
                                (UserModel base) => base.copyWith(
                                  sensoryFilterTags: _selectedSensoryTags.toList(),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Vista del catálogo', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<CatalogViewMode>(
                      segments: const <ButtonSegment<CatalogViewMode>>[
                        ButtonSegment<CatalogViewMode>(
                          value: CatalogViewMode.lista,
                          icon: Icon(Icons.view_list),
                          label: Text('Lista'),
                        ),
                        ButtonSegment<CatalogViewMode>(
                          value: CatalogViewMode.reticula,
                          icon: Icon(Icons.grid_view),
                          label: Text('Retícula'),
                        ),
                      ],
                      selected: <CatalogViewMode>{_catalogViewMode},
                      onSelectionChanged: (Set<CatalogViewMode> selected) {
                        if (selected.isEmpty) {
                          return;
                        }
                        _updateCurrentUser(
                          (UserModel base) =>
                              base.copyWith(catalogViewMode: selected.first),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (showGames && normalizedQuery.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Resultados IGDB',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          if (_isIgdbLoading)
            const LinearProgressIndicator()
          else if (_igdbErrorMessage != null)
            Text(
              _igdbErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (_igdbResults.isEmpty)
            const Text('Sin resultados IGDB para esta búsqueda.')
          else
            ..._igdbResults.take(6).map(
              (IgdbGameDto item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if ((item.coverUrl ?? '').isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildNetworkImage(
                              item.coverUrl!,
                              width: double.infinity,
                              height: 130,
                            ),
                          ),
                        if ((item.coverUrl ?? '').isNotEmpty)
                          const SizedBox(height: 8),
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.genre}${item.rating != null ? ' · ${item.rating!.toStringAsFixed(1)}' : ''}',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: () => _addIgdbGameToCatalog(item),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Añadir al catálogo'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
        if (showGames) const SizedBox(height: 8),
        if (showGames && _catalogViewMode == CatalogViewMode.lista)
          ...games.map(
            (LibraryGameUi gameUi) => _buildLibraryGameListCard(user, gameUi),
          ),
        if (showGames && _catalogViewMode == CatalogViewMode.reticula)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: games.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.67,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (BuildContext context, int index) {
              return _buildLibraryGameGridCard(user, games[index]);
            },
          ),
        if (normalizedQuery.isNotEmpty) ...<Widget>[
          if (showUsers) const SizedBox(height: 12),
          if (showUsers)
            Text('Usuarios', style: Theme.of(context).textTheme.titleMedium),
          if (showUsers) const SizedBox(height: 8),
          if (showUsers && userMatches.isEmpty)
            const Text('Sin usuarios que coincidan con tu búsqueda.')
          else if (showUsers)
            ...userMatches.map(
              (UserModel match) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _buildUserAvatar(match),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    match.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    match.profileStatus,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Acciones de usuario',
                              onSelected: (String action) {
                                if (action == 'report') {
                                  unawaited(
                                    _reportUser(
                                      targetUserId: match.id,
                                      targetDisplayName: match.displayName,
                                    ),
                                  );
                                  return;
                                }
                                if (action == 'block') {
                                  unawaited(
                                    _toggleBlockUser(
                                      targetUserId: match.id,
                                      targetDisplayName: match.displayName,
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (_) {
                                final bool isBlocked = _isBlockedByCurrentUser(
                                  match.id,
                                );
                                return <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'report',
                                    child: Text('Reportar usuario'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'block',
                                    child: Text(
                                      isBlocked
                                          ? 'Desbloquear usuario'
                                          : 'Bloquear usuario',
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilledButton.tonal(
                              onPressed: () => _toggleFriend(match),
                              child: Text(
                                _isFriendWithCurrentUser(match)
                                    ? 'Quitar amigo'
                                    : 'Añadir amigo',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isFriendWithCurrentUser(match)
                                  ? () => _openDirectMessageWithUser(match)
                                  : null,
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Chat'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (showGuides) const SizedBox(height: 12),
          if (showGuides)
            Text('Guías', style: Theme.of(context).textTheme.titleMedium),
          if (showGuides) const SizedBox(height: 8),
          if (showGuides && guideMatches.isEmpty)
            const Text('Sin guías que coincidan con tu búsqueda.')
          else if (showGuides)
            ...guideMatches.map(
              (CommunityGuideModel guide) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(guide.title),
                    subtitle: Text(
                      '${_gameNameForId(guide.gameId)} · ${guide.authorName}: ${guide.content}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        FilledButton.tonal(
                          onPressed: () => _openCommunityGuideDetail(guide),
                          child: const Text('Ver'),
                        ),
                        if (guide.authorId != user.id)
                          PopupMenuButton<String>(
                            tooltip: 'Acciones de guía',
                            onSelected: (String action) {
                              if (action == 'report_guide') {
                                unawaited(_reportGuide(guide));
                                return;
                              }
                              if (action == 'block_author') {
                                unawaited(
                                  _toggleBlockUser(
                                    targetUserId: guide.authorId,
                                    targetDisplayName: guide.authorName,
                                  ),
                                );
                              }
                            },
                            itemBuilder: (_) => const <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'report_guide',
                                child: Text('Reportar guía'),
                              ),
                              PopupMenuItem<String>(
                                value: 'block_author',
                                child: Text('Bloquear autor'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildLibraryGameListCard(UserModel user, LibraryGameUi gameUi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildNetworkImage(
                  gameUi.game.imageUrl,
                  width: double.infinity,
                  height: 170,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                gameUi.game.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${gameUi.game.genre} - Intensidad ${_intensityName(gameUi.game.sensoryIntensity).toLowerCase()}',
              ),
              const SizedBox(height: 4),
              Text(
                gameUi.game.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (user.showSensoryWarnings &&
                  _sensoryWarningsForUser(user, gameUi.game).isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Advertencia sensorial (${user.neurodivergence.name.toUpperCase()})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      ..._sensoryWarningsForUser(user, gameUi.game).map(
                        (String warning) => Text('• $warning'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Chip(
                label: Text(gameUi.recommendationTag ?? 'Recomendado para todos'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(
                    avatar: Icon(
                      gameUi.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                    ),
                    label: Text(gameUi.isFavorite ? 'Quitar favorito' : 'Favorito'),
                    onPressed: () => _toggleFavorite(gameUi.game.id),
                  ),
                  ActionChip(
                    avatar: Icon(
                      gameUi.isUpcoming
                          ? Icons.playlist_add_check_circle
                          : Icons.playlist_add_circle_outlined,
                      size: 18,
                    ),
                    label: Text(gameUi.isUpcoming ? 'Quitar próximos' : 'Próximos'),
                    onPressed: () => _toggleUpcoming(gameUi.game.id),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Ver guía'),
                    onPressed: gameUi.isPlayingNow
                        ? null
                        : () => _toggleGuideForGame(
                              gameUi.game,
                              focusSearchOnEnable: true,
                            ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.menu_book, size: 18),
                    label: const Text('Quitar guía'),
                    onPressed: gameUi.isPlayingNow
                        ? () => _toggleGuideForGame(gameUi.game)
                        : null,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Añadir guía'),
                    onPressed: () => _showAddGuideDialog(gameUi.game),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.groups_2_outlined, size: 18),
                    label: const Text('Guías comunidad'),
                    onPressed: _openCommunityGuides,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryGameGridCard(UserModel user, LibraryGameUi gameUi) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggleFavorite(gameUi.game.id),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildNetworkImage(
                    gameUi.game.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                gameUi.game.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                _intensityName(gameUi.game.sensoryIntensity),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Icon(
                    gameUi.isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      gameUi.isFavorite ? 'Favorito' : 'Tocar para favorito',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchQueryChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _recordSearchQuery(value);
    _queueIgdbSearch(value);
    _queueUserSearch(value);
  }

  void _queueUserSearch(String rawQuery) {
    _userSearchDebounce?.cancel();

    final String query = rawQuery.trim();
    final bool shouldSearchUsers =
        _searchScope == SearchScope.todo || _searchScope == SearchScope.usuarios;

    if (!shouldSearchUsers || query.length < 2) {
      return;
    }

    _userSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_syncUsersFromFirebaseByQuery(query));
    });
  }

  int _stableIdFromEmail(String email) {
    int hash = 17;
    for (final int codeUnit in email.trim().toLowerCase().codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x3fffffff;
    }
    return 100000000 + hash;
  }

  int _resolveUserIdFromData(Map<String, dynamic> data, String email) {
    final dynamic rawId = data['id'];
    if (rawId is int && rawId > 0) {
      return rawId;
    }
    if (rawId is num && rawId.toInt() > 0) {
      return rawId.toInt();
    }
    if (rawId is String) {
      final int? parsed = int.tryParse(rawId);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return _stableIdFromEmail(email);
  }

  Set<int> _parseIdSet(dynamic rawValue) {
    return (rawValue as List<dynamic>? ?? <dynamic>[])
        .map((dynamic value) {
          if (value is num) {
            return value.toInt();
          }
          if (value is String) {
            return int.tryParse(value) ?? -1;
          }
          return -1;
        })
        .where((int value) => value > 0)
        .toSet();
  }

  Set<int> _parseFriendIdsFromData(Map<String, dynamic> data) {
    final Set<int> ids = _parseIdSet(data['friendUserIds']);
    final List<String> emails =
        (data['friendUserEmails'] as List<dynamic>? ?? <dynamic>[])
            .whereType<String>()
            .map((String value) => value.trim().toLowerCase())
            .where((String value) => value.isNotEmpty)
            .toList();

    final int resolvedId = _resolveUserIdFromData(
      data,
      ((data['email'] as String?) ?? '').toLowerCase(),
    );
    _friendEmailsByUser[resolvedId] = emails.toSet();

    for (final String email in emails) {
      final UserModel? knownUser = _users.cast<UserModel?>().firstWhere(
        (UserModel? item) =>
            item != null && item.email.toLowerCase() == email,
        orElse: () => null,
      );
      ids.add(knownUser?.id ?? _stableIdFromEmail(email));
    }

    return ids;
  }

  List<String> _friendEmailsForUserId(int userId) {
    final Set<int> friendIds = _friendsByUser[userId] ?? <int>{};
    final Set<String> emails = <String>{
      ...?_friendEmailsByUser[userId],
    };
    for (final int friendId in friendIds) {
      final UserModel? friend = _users.cast<UserModel?>().firstWhere(
        (UserModel? item) => item != null && item.id == friendId,
        orElse: () => null,
      );
      if (friend == null) {
        continue;
      }
      final String normalized = friend.email.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      emails.add(normalized);
    }
    final List<String> sorted = emails.toList()..sort();
    return sorted;
  }

        String _normalizeTextForSearch(String value) {
          return value
          .trim()
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('à', 'a')
          .replaceAll('ä', 'a')
          .replaceAll('â', 'a')
          .replaceAll('é', 'e')
          .replaceAll('è', 'e')
          .replaceAll('ë', 'e')
          .replaceAll('ê', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ì', 'i')
          .replaceAll('ï', 'i')
          .replaceAll('î', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ò', 'o')
          .replaceAll('ö', 'o')
          .replaceAll('ô', 'o')
          .replaceAll('ú', 'u')
          .replaceAll('ù', 'u')
          .replaceAll('ü', 'u')
          .replaceAll('û', 'u')
          .replaceAll('ñ', 'n');
        }

  Future<void> _syncUsersFromFirebaseByQuery(String rawQuery) async {
    if (!FirebaseBootstrap.isReady) {
      return;
    }

    final String query = _normalizeTextForSearch(rawQuery);
    if (query.length < 2) {
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('users').limit(1000).get();

      final List<UserModel> matchedUsers = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final Map<String, dynamic> data = doc.data();

            final String email =
                ((data['email'] as String?) ?? doc.id).toLowerCase();
            final String displayName =
                (data['displayName'] as String?) ?? email.split('@').first;
            final int resolvedId = _resolveUserIdFromData(data, email);

            _friendsByUser[resolvedId] = _parseFriendIdsFromData(data);

            return UserModel(
              id: resolvedId,
              email: email,
              password: (data['password'] as String?) ?? '',
              displayName: displayName,
              avatar: (data['avatar'] as String?) ?? '🎮',
              avatarBytes: (data['avatarBytes'] as String?) != null
                  ? base64Decode(data['avatarBytes'] as String)
                  : null,
              profileStatus: (data['profileStatus'] as String?) ?? 'En línea',
              age: (data['age'] as int?) ?? 18,
              neurodivergence: Neurodivergence.values.byName(
                (data['neurodivergence'] as String?) ?? 'tea',
              ),
              fontScale: (data['fontScale'] as num?)?.toDouble() ?? 1.0,
              accessibilityMode: AccessibilityMode.values.byName(
                (data['accessibilityMode'] as String?) ?? 'tea',
              ),
              softColors: (data['softColors'] as bool?) ?? true,
              noAnimations: (data['noAnimations'] as bool?) ?? false,
              legibleFont: (data['legibleFont'] as bool?) ?? false,
              themePalette: ThemePalette.values.byName(
                (data['themePalette'] as String?) ?? 'suave',
              ),
              fontPreference: FontPreference.values.byName(
                (data['fontPreference'] as String?) ?? 'sistema',
              ),
              notificationMode: NotificationMode.values.byName(
                (data['notificationMode'] as String?) ?? 'importantes',
              ),
              onboardingCompleted:
                  (data['onboardingCompleted'] as bool?) ?? true,
              catalogViewMode: CatalogViewMode.values.byName(
                (data['catalogViewMode'] as String?) ?? 'lista',
              ),
              sensoryFilterTags:
                  (data['sensoryFilterTags'] as List<dynamic>? ?? <dynamic>[])
                      .whereType<String>()
                      .toList(),
              showSensoryWarnings:
                  (data['showSensoryWarnings'] as bool?) ?? true,
                emergencyGrayscale:
                  (data['emergencyGrayscale'] as bool?) ?? false,
            );
          })
          .where((UserModel user) {
            return _normalizeTextForSearch(user.displayName).contains(query) ||
                _normalizeTextForSearch(user.email).contains(query);
          })
          .toList();

      if (!mounted || matchedUsers.isEmpty) {
        return;
      }

      setState(() {
        for (final UserModel user in matchedUsers) {
          final int existingIndex = _users.indexWhere(
            (UserModel existing) =>
                existing.email.toLowerCase() == user.email.toLowerCase(),
          );
          if (existingIndex == -1) {
            _users.add(user);
          } else {
            _users[existingIndex] = user;
          }
        }
      });
    } catch (_) {
      // Keep local user list if Firestore lookup fails.
    }
  }

  Future<void> _syncAllUsersFromFirebase() async {
    if (!FirebaseBootstrap.isReady) {
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('users').limit(1000).get();

      if (!mounted || snapshot.docs.isEmpty) {
        return;
      }

      final List<UserModel> fetchedUsers = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final Map<String, dynamic> data = doc.data();

            final String email =
                ((data['email'] as String?) ?? doc.id).toLowerCase();
            final String displayName =
                (data['displayName'] as String?) ?? email.split('@').first;
            final int resolvedId = _resolveUserIdFromData(data, email);

            _friendsByUser[resolvedId] = _parseFriendIdsFromData(data);

            return UserModel(
              id: resolvedId,
              email: email,
              password: (data['password'] as String?) ?? '',
              displayName: displayName,
              avatar: (data['avatar'] as String?) ?? '🎮',
              avatarBytes: (data['avatarBytes'] as String?) != null
                  ? base64Decode(data['avatarBytes'] as String)
                  : null,
              profileStatus: (data['profileStatus'] as String?) ?? 'En línea',
              age: (data['age'] as int?) ?? 18,
              neurodivergence: Neurodivergence.values.byName(
                (data['neurodivergence'] as String?) ?? 'tea',
              ),
              fontScale: (data['fontScale'] as num?)?.toDouble() ?? 1.0,
              accessibilityMode: AccessibilityMode.values.byName(
                (data['accessibilityMode'] as String?) ?? 'tea',
              ),
              softColors: (data['softColors'] as bool?) ?? true,
              noAnimations: (data['noAnimations'] as bool?) ?? false,
              legibleFont: (data['legibleFont'] as bool?) ?? false,
              themePalette: ThemePalette.values.byName(
                (data['themePalette'] as String?) ?? 'suave',
              ),
              fontPreference: FontPreference.values.byName(
                (data['fontPreference'] as String?) ?? 'sistema',
              ),
              notificationMode: NotificationMode.values.byName(
                (data['notificationMode'] as String?) ?? 'importantes',
              ),
              onboardingCompleted:
                  (data['onboardingCompleted'] as bool?) ?? true,
              catalogViewMode: CatalogViewMode.values.byName(
                (data['catalogViewMode'] as String?) ?? 'lista',
              ),
              sensoryFilterTags:
                  (data['sensoryFilterTags'] as List<dynamic>? ?? <dynamic>[])
                      .whereType<String>()
                      .toList(),
              showSensoryWarnings:
                  (data['showSensoryWarnings'] as bool?) ?? true,
              emergencyGrayscale:
                  (data['emergencyGrayscale'] as bool?) ?? false,
            );
          })
          .toList();

      setState(() {
        for (final UserModel user in fetchedUsers) {
          final int existingIndex = _users.indexWhere(
            (UserModel existing) =>
                existing.email.toLowerCase() == user.email.toLowerCase(),
          );
          if (existingIndex == -1) {
            _users.add(user);
          } else {
            _users[existingIndex] = user;
          }
        }
      });
    } catch (_) {
      // Keep local user cache if full sync fails.
    }
  }

  void _queueIgdbSearch(String rawQuery) {
    final String query = rawQuery.trim();
    final bool shouldSearch =
        _searchScope == SearchScope.todo || _searchScope == SearchScope.juegos;

    _igdbSearchDebounce?.cancel();

    if (!shouldSearch || query.length < 2) {
      if (!mounted) {
        return;
      }
      _activeIgdbRequestId = ++_igdbRequestSequence;
      setState(() {
        _lastIgdbQuery = query;
        _isIgdbLoading = false;
        _igdbErrorMessage = null;
        _igdbResults.clear();
      });
      return;
    }

    _igdbSearchDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_searchGamesFromIgdb(query));
    });
  }

  Future<void> _searchGamesFromIgdb(String query) async {
    if (!mounted) {
      return;
    }

    final int requestId = ++_igdbRequestSequence;
    _activeIgdbRequestId = requestId;

    setState(() {
      _isIgdbLoading = true;
      _igdbErrorMessage = null;
      _lastIgdbQuery = query;
    });

    try {
      final List<IgdbGameDto> results = await IgdbService.searchGames(
        query: query,
        limit: 12,
      );
      if (!mounted || _activeIgdbRequestId != requestId) {
        return;
      }
      setState(() {
        _igdbResults
          ..clear()
          ..addAll(results);
        _igdbErrorMessage = null;
      });
    } on TimeoutException {
      if (!mounted || _activeIgdbRequestId != requestId) {
        return;
      }
      setState(() {
        _igdbResults.clear();
        _igdbErrorMessage =
            'IGDB tardó demasiado en responder. Revisa que stream_token_server esté encendido en el puerto 8787.';
      });
    } catch (error) {
      if (!mounted || _activeIgdbRequestId != requestId) {
        return;
      }
      final String normalizedError = error.toString().toLowerCase();
      final bool looksLikeMissingIgdbCreds =
          normalizedError.contains('503') ||
          normalizedError.contains('no configurado') ||
          normalizedError.contains('credentials') ||
          normalizedError.contains('client_id') ||
          normalizedError.contains('client_secret');
      setState(() {
        _igdbResults.clear();
        _igdbErrorMessage = looksLikeMissingIgdbCreds
            ? 'IGDB no disponible: faltan credenciales en stream_token_server (.env: IGDB_CLIENT_ID, IGDB_CLIENT_SECRET).'
            : 'IGDB no disponible ahora mismo. Puedes seguir usando el catálogo local.';
      });
    } finally {
      if (!mounted || _activeIgdbRequestId != requestId) {
        return;
      }
      setState(() {
        _isIgdbLoading = false;
      });
    }
  }

  int? _addIgdbGameToCatalog(IgdbGameDto item) {
    final String normalized = item.name.trim().toLowerCase();
    final GameModel? existing = _games.cast<GameModel?>().firstWhere(
      (GameModel? game) => game?.name.trim().toLowerCase() == normalized,
      orElse: () => null,
    );
    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} ya existe en tu catálogo.')),
      );
      return existing.id;
    }

    final SensoryIntensity inferredIntensity = (item.rating ?? 60) >= 75
        ? SensoryIntensity.media
        : SensoryIntensity.baja;
    final String imageUrl = (item.coverUrl ?? '').trim().isNotEmpty
        ? item.coverUrl!.trim()
        : _imageForGameName(item.name);

    final int newId = _nextGameId();

    setState(() {
      final GameModel game = GameModel(
        id: newId,
        name: item.name.trim(),
        genre: item.genre.trim().isEmpty ? 'General' : item.genre.trim(),
        imageUrl: imageUrl,
        sensoryIntensity: inferredIntensity,
        description: item.summary.trim().isEmpty
            ? 'Importado desde IGDB.'
            : item.summary.trim(),
        sensoryTags: _defaultSensoryTagsForIntensity(inferredIntensity),
        sensoryWarnings: _defaultSensoryWarningsForIntensity(inferredIntensity),
      );
      _games.insert(0, game);
      unawaited(_upsertGameInFirebase(game));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} añadido al catálogo.')),
    );

    return newId;
  }

  List<String> _defaultSensoryTagsForIntensity(SensoryIntensity intensity) {
    return switch (intensity) {
      SensoryIntensity.baja => <String>['ritmo_lento', 'audio_suave'],
      SensoryIntensity.media => <String>['ritmo_medio', 'estimulos_moderados'],
      SensoryIntensity.alta => <String>['accion_rapida', 'estimulos_altos'],
    };
  }

  Map<String, List<String>> _defaultSensoryWarningsForIntensity(
    SensoryIntensity intensity,
  ) {
    return switch (intensity) {
      SensoryIntensity.baja => <String, List<String>>{
        'tea': <String>['Puede incluir diálogos extensos.'],
        'tdah': <String>['Ritmo pausado, puede requerir pausas activas.'],
      },
      SensoryIntensity.media => <String, List<String>>{
        'tea': <String>['Transiciones y sonidos moderados.'],
        'tdah': <String>['Puede alternar entre momentos tranquilos e intensos.'],
      },
      SensoryIntensity.alta => <String, List<String>>{
        'tea': <String>['Alta estimulación visual/sonora. Ajusta brillo y volumen.'],
        'tdah': <String>['Acción intensa sostenida, usa sesiones cortas.'],
      },
    };
  }

  Widget _buildOptionsScreen(UserModel user) {
    final List<UserModel> friends = _friendsForUser(user);
    final int friendCount = friends.length;
    final List<LibraryGameUi> games = _buildLibraryGames(
      user,
      applyFilters: false,
    );
    final List<LibraryGameUi> favoriteGames = games
        .where((LibraryGameUi gameUi) => gameUi.isFavorite)
        .toList();
    final List<LibraryGameUi> upcomingGames = games
        .where((LibraryGameUi gameUi) => gameUi.isUpcoming)
        .toList();
    final List<LibraryGameUi> gamesToShow =
        _profileGamesView == ProfileGamesView.favoritos
        ? favoriteGames
        : upcomingGames;

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: <Widget>[
                  _buildUserAvatar(user, radius: 34),
                  const SizedBox(height: 10),
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.profileStatus,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _changeCurrentUserPhotoFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Cambiar foto desde galeria'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _removeCurrentUserPhoto,
            icon: const Icon(Icons.hide_image_outlined),
            label: const Text('Quitar foto'),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Amigos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: friends.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final UserModel friend = friends[index];
                      return Chip(
                        avatar: _buildUserAvatar(friend),
                        label: Text('${friend.displayName} · ${friend.profileStatus}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showFriendsBottomSheet(user),
            icon: const Icon(Icons.group_outlined),
            label: Text('Ver mis amigos ($friendCount)'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _showEditProfileDialog(user),
            child: const Text('Editar perfil'),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Lista de juegos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      selected: _profileGamesView == ProfileGamesView.favoritos,
                      label: const Text('Mis juegos favoritos'),
                      onSelected: (_) => setState(
                        () => _profileGamesView = ProfileGamesView.favoritos,
                      ),
                    ),
                    ChoiceChip(
                      selected: _profileGamesView == ProfileGamesView.proximos,
                      label: const Text('Próximos juegos'),
                      onSelected: (_) => setState(
                        () => _profileGamesView = ProfileGamesView.proximos,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (gamesToShow.isEmpty)
                  Text(
                    _profileGamesView == ProfileGamesView.favoritos
                        ? 'Aún no tienes juegos favoritos.'
                        : 'No hay próximos juegos para mostrar.',
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gamesToShow.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.95,
                        ),
                    itemBuilder: (BuildContext context, int index) {
                      final LibraryGameUi gameUi = gamesToShow[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildNetworkImage(
                                  gameUi.game.imageUrl,
                                  width: double.infinity,
                                  height: 72,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 38,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.45),
                                      Theme.of(context).colorScheme.tertiary
                                          .withValues(alpha: 0.45),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  gameUi.game.genre,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              Text(
                                gameUi.game.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const Spacer(),
                              Row(
                                children: <Widget>[
                                  if (gameUi.isFavorite)
                                    const Icon(Icons.favorite, size: 16),
                                  if (gameUi.isFavorite)
                                    const SizedBox(width: 4),
                                  if (gameUi.isUpcoming)
                                    const Icon(Icons.event_available, size: 16),
                                  if (gameUi.isUpcoming)
                                    const SizedBox(width: 4),
                                  if (gameUi.isPlayingNow)
                                    const Icon(Icons.menu_book, size: 16),
                                  if (gameUi.isPlayingNow)
                                    const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _intensityName(
                                        gameUi.game.sensoryIntensity,
                                      ),
                                      textAlign: TextAlign.end,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditProfileDialog(UserModel user) async {
    final TextEditingController nameController = TextEditingController(
      text: user.displayName,
    );
    final TextEditingController statusController = TextEditingController(
      text: user.profileStatus,
    );
    final TextEditingController avatarController = TextEditingController(
      text: user.avatar,
    );
    Uint8List? selectedBytes = user.avatarBytes;
    String selectedAvatar = user.avatar;
    final List<String> presetAvatars = <String>[
      '🎮',
      '🕹️',
      '🎯',
      '🐉',
      '🌱',
      '⚔️',
      '🚀',
      '🔥',
    ];

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar perfil'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder:
                  (
                    BuildContext context,
                    void Function(void Function()) setModalState,
                  ) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de usuario',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: statusController,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: avatarController,
                                decoration: const InputDecoration(
                                  labelText: 'Avatar (emoji)',
                                ),
                                onChanged: (String value) {
                                  setModalState(() {
                                    selectedAvatar = value.trim().isEmpty
                                        ? user.avatar
                                        : value.trim();
                                    selectedBytes = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final Uint8List? bytes =
                                    await _pickProfileImageFromGallery();
                                if (bytes != null) {
                                  setModalState(() {
                                    selectedBytes = bytes;
                                  });
                                }
                              },
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Galería'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Opciones predeterminadas',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: presetAvatars
                              .map(
                                (String item) => ChoiceChip(
                                  selected:
                                      selectedBytes == null &&
                                      selectedAvatar == item,
                                  label: Text(item),
                                  onSelected: (_) {
                                    setModalState(() {
                                      selectedAvatar = item;
                                      avatarController.text = item;
                                      selectedBytes = null;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    );
                  },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (save != true) {
      return;
    }

    final String newName = nameController.text.trim();
    final String newStatus = statusController.text.trim();
    final String newAvatar = avatarController.text.trim();
    final bool clearAvatarBytes = user.avatarBytes != null && selectedBytes == null;

    _updateCurrentUser(
      (UserModel base) => base.copyWith(
        displayName: newName.isEmpty ? base.displayName : newName,
        profileStatus: newStatus.isEmpty ? 'Sin estado' : newStatus,
        avatar: newAvatar.isEmpty ? selectedAvatar : newAvatar,
        avatarBytes: selectedBytes,
        clearAvatarBytes: clearAvatarBytes,
      ),
    );
  }

  Future<Uint8List?> _pickProfileImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 600,
    );
    if (file == null) {
      return null;
    }
    return file.readAsBytes();
  }
  Future<void> _changeCurrentUserPhotoFromGallery() async {
    final Uint8List? bytes = await _pickProfileImageFromGallery();
    if (bytes == null || !mounted) {
      return;
    }

    _updateCurrentUser(
      (UserModel base) => base.copyWith(
        avatarBytes: bytes,
      ),
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto de perfil actualizada.')),
    );
  }

  void _removeCurrentUserPhoto() {
    final UserModel? current = _currentUser;
    if (current == null || current.avatarBytes == null) {
      return;
    }

    final String fallbackAvatar = current.avatar.trim().isEmpty
        ? '🎮'
        : current.avatar.trim();
    _updateCurrentUser(
      (UserModel base) => base.copyWith(
        avatar: fallbackAvatar,
        clearAvatarBytes: true,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Volviste al avatar emoji.')),
    );
  }

  void _showFriendsBottomSheet(UserModel user) {
    final List<UserModel> friends = _friendsForUser(user);

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Mis amigos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: friends.isEmpty
                      ? const Center(
                          child: Text(
                            'Aún no tienes amigos. Búscalos en la pestaña Buscar.',
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: friends.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final UserModel friend = friends[index];
                            return ListTile(
                              leading: _buildUserAvatar(friend),
                              title: Text(friend.displayName),
                              subtitle: Text(friend.profileStatus),
                              trailing: IconButton(
                                tooltip: 'Abrir chat',
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  _openDirectMessageWithUser(friend);
                                },
                                icon: const Icon(Icons.chat_bubble_outline),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(UserModel user, {double radius = 18}) {
    if (user.avatarBytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(user.avatarBytes!),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: Text(user.avatar, style: TextStyle(fontSize: radius * 0.8)),
    );
  }

  Widget _buildProfileMenuDrawer(UserModel user) {
    final List<TaskModel> tasks = _tasksByUser[user.id] ?? <TaskModel>[];
    final int focusSeconds = _focusSecondsByUser[user.id] ?? 0;
    final int breakSeconds = _breakSecondsByUser[user.id] ?? 0;
    final double safeFontScale = user.fontScale.clamp(0.85, 1.4).toDouble();
    final bool emergencyModeEnabled = user.emergencyGrayscale == true;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            children: <Widget>[
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _buildUserAvatar(user, radius: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  user.displayName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.black),
                                ),
                                Text(
                                  user.profileStatus,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar menú',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Modo saturación',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emergencyModeEnabled
                            ? 'La app está en escala de grises para reducir estímulos.'
                            : 'Activa escala de grises inmediata para bajar la carga visual.',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onError,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                          ),
                          onPressed: _toggleEmergencyMode,
                          icon: const Icon(Icons.warning_amber_rounded),
                          label: Text(
                            emergencyModeEnabled
                                ? 'BOTON DE EMERGENCIA · DESACTIVAR'
                                : 'BOTON DE EMERGENCIA',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Misiones',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...tasks.map(
                        (TaskModel task) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                task.isDone
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(task.title)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _openMissionsScreen,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Abrir panel de misiones'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Cronómetro',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _timer.isWorkSession
                            ? 'Modo actual: Trabajo'
                            : 'Modo actual: Descanso',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSeconds(_timer.remainingSeconds),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _startPausePomodoro,
                              icon: Icon(
                                _timer.isRunning
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                _timer.isRunning ? 'Pausar' : 'Iniciar',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _resetPomodoro,
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('Reiniciar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAddPomodoroTimeDialog,
                          icon: const Icon(Icons.add_alarm),
                          label: const Text('Añadir tiempo al temporizador'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Accesibilidad',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          FilterChip(
                            selected:
                                user.accessibilityMode == AccessibilityMode.tea,
                            onSelected: (_) => _applyAccessibilityPreset(
                              AccessibilityMode.tea,
                            ),
                            label: const Text('Modo TEA'),
                          ),
                          FilterChip(
                            selected:
                                user.accessibilityMode ==
                                AccessibilityMode.tdah,
                            onSelected: (_) => _applyAccessibilityPreset(
                              AccessibilityMode.tdah,
                            ),
                            label: const Text('Modo TDAH'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _accessibilityProfileDescription(
                          user.accessibilityMode,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value:
                            user.notificationMode != NotificationMode.ninguna,
                        title: const Text('Notificaciones activas'),
                        onChanged: (bool value) => _updateCurrentUser(
                          (UserModel base) => base.copyWith(
                            notificationMode: value
                                ? NotificationMode.importantes
                                : NotificationMode.ninguna,
                          ),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: user.showSensoryWarnings,
                        title: const Text('Mostrar advertencias sensoriales'),
                        subtitle: const Text('Basadas en TEA/TDAH según tu perfil.'),
                        onChanged: (bool value) => _updateCurrentUser(
                          (UserModel base) =>
                              base.copyWith(showSensoryWarnings: value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Tema',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Define la paleta de colores de toda la interfaz.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ThemePalette.values
                            .map(
                              (ThemePalette palette) => ChoiceChip(
                                selected: user.themePalette == palette,
                                label: Text(_themePaletteLabel(palette)),
                                onSelected: (_) => _updateCurrentUser(
                                  (UserModel base) => base.copyWith(
                                    themePalette: palette,
                                    softColors: palette == ThemePalette.suave,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Tipografía',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige fuente, tamaño y animaciones de lectura.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: FontPreference.values
                            .map(
                              (FontPreference font) => ChoiceChip(
                                selected: user.fontPreference == font,
                                label: Text(_fontPreferenceLabel(font)),
                                onSelected: (_) => _updateCurrentUser(
                                  (UserModel base) => base.copyWith(
                                    fontPreference: font,
                                    legibleFont: font == FontPreference.legible,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tamaño de letra'),
                        subtitle: Slider(
                          value: safeFontScale,
                          min: 0.85,
                          max: 1.4,
                          divisions: 11,
                          label: safeFontScale.toStringAsFixed(2),
                          onChanged: (double value) => _updateCurrentUser(
                            (UserModel base) => base.copyWith(
                              fontScale: value.clamp(0.85, 1.4),
                            ),
                          ),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: user.noAnimations,
                        title: const Text('Quitar animaciones'),
                        onChanged: (bool value) => _updateCurrentUser(
                          (UserModel base) =>
                              base.copyWith(noAnimations: value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Estadísticas rápidas',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          Chip(
                            avatar: const Icon(
                              Icons.center_focus_strong,
                              size: 16,
                            ),
                            label: Text(_formatSeconds(focusSeconds)),
                          ),
                          Chip(
                            avatar: const Icon(Icons.free_breakfast, size: 16),
                            label: Text(_formatSeconds(breakSeconds)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Borrar cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleEmergencyMode() {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

    final bool nextValue = !(user.emergencyGrayscale == true);
    _updateCurrentUser(
      (UserModel base) => base.copyWith(emergencyGrayscale: nextValue),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextValue
              ? 'Modo emergencia activado: escala de grises aplicada.'
              : 'Modo emergencia desactivado: colores restaurados.',
        ),
      ),
    );
  }

  Future<void> _openMissionsScreen() async {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

    Navigator.of(context).pop();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Misiones diarias')),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMissionsScreen(user),
            ),
          );
        },
      ),
    );
  }

  void _openCommunityGuides() {
    final UserModel? current = _currentUser;
    if (current == null) {
      return;
    }

    final Set<int> blockedIds = _blockedUsersByUser[current.id] ?? <int>{};
    final List<CommunityGuideModel> guides = <CommunityGuideModel>[
      ..._communityGuides.where(
        (CommunityGuideModel guide) => !blockedIds.contains(guide.authorId),
      ),
    ]..sort((CommunityGuideModel a, CommunityGuideModel b) {
        return b.createdAt.compareTo(a.createdAt);
      });

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Guías de la comunidad',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Todas las guías publicadas por usuarios (${guides.length})',
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: guides.isEmpty
                        ? const Center(
                            child: Text('Aún no hay guías publicadas.'),
                          )
                        : ListView.separated(
                            itemCount: guides.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (BuildContext context, int index) {
                              final CommunityGuideModel guide = guides[index];
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        guide.title,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _gameNameForId(guide.gameId),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Por ${guide.authorName} · ${_formatGuideDate(guide.createdAt)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        guide.content,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            FilledButton.tonal(
                                              onPressed: () =>
                                                  _openCommunityGuideDetail(guide),
                                              child: const Text('Ver completa'),
                                            ),
                                            if (guide.authorId != current.id)
                                              PopupMenuButton<String>(
                                                onSelected: (String action) {
                                                  if (action == 'report') {
                                                    unawaited(_reportGuide(guide));
                                                    return;
                                                  }
                                                  if (action == 'block') {
                                                    unawaited(
                                                      _toggleBlockUser(
                                                        targetUserId: guide.authorId,
                                                        targetDisplayName:
                                                            guide.authorName,
                                                      ),
                                                    );
                                                  }
                                                },
                                                itemBuilder: (_) =>
                                                    const <PopupMenuEntry<String>>[
                                                      PopupMenuItem<String>(
                                                        value: 'report',
                                                        child: Text('Reportar guía'),
                                                      ),
                                                      PopupMenuItem<String>(
                                                        value: 'block',
                                                        child: Text('Bloquear autor'),
                                                      ),
                                                    ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddGuideDialog(GameModel game) async {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Añadir guía · ${game.name}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: titleController,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Título de la guía',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Escribe aquí tu guía para ayudar a otros jugadores...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Publicar guía'),
            ),
          ],
        );
      },
    );

    if (save != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    final String title = titleController.text.trim();
    final String content = contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade un título a la guía.')),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La guía no puede estar vacía.')),
      );
      return;
    }

    setState(() {
      _communityGuides.insert(
        0,
        CommunityGuideModel(
          id: _guideIdCounter++,
          gameId: game.id,
          authorId: user.id,
          authorName: user.displayName,
          title: title,
          content: content,
          createdAt: DateTime.now(),
        ),
      );
      _playingByUser.putIfAbsent(user.id, () => <int, bool>{})[game.id] = true;
    });
    final CommunityGuideModel newGuide = _communityGuides.first;
    unawaited(_upsertCommunityGuideInFirebase(newGuide));

    _completeMissionForCurrentUser(DailyMissionType.readGuide);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guía publicada en comunidad.')),
    );
  }

  Future<void> _openCommunityGuideDetail(CommunityGuideModel guide) async {
    final UserModel? current = _currentUser;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(guide.title),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _gameNameForId(guide.gameId),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Por ${guide.authorName} · ${_formatGuideDate(guide.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(guide.content),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            if (current != null && guide.authorId != current.id)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(_reportGuide(guide));
                },
                icon: const Icon(Icons.flag_outlined),
                label: Text(
                  _isGuideReportedByCurrentUser(guide.id)
                      ? 'Guía reportada'
                      : 'Reportar guía',
                ),
              ),
            if (current != null && guide.authorId != current.id)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(
                    _toggleBlockUser(
                      targetUserId: guide.authorId,
                      targetDisplayName: guide.authorName,
                    ),
                  );
                },
                icon: const Icon(Icons.block),
                label: Text(
                  _isBlockedByCurrentUser(guide.authorId)
                      ? 'Desbloquear autor'
                      : 'Bloquear autor',
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNetworkImage(
    String imageUrl, {
    required double width,
    required double height,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.videogame_asset_outlined),
      ),
      loadingBuilder: (_, Widget child, ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  String _streamUserIdFromUser(UserModel user) {
    final String email = user.email.trim().toLowerCase();
    final String safe = email.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    if (safe.isNotEmpty) {
      return 'u_$safe';
    }
    return 'user_${user.id}';
  }

  String _gameNameForId(int gameId) {
    final GameModel? game = _games.cast<GameModel?>().firstWhere(
      (GameModel? game) => game != null && game.id == gameId,
      orElse: () => null,
    );
    return game?.name ?? 'Juego $gameId';
  }

  String _formatGuideDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  String _imageForGameName(String gameName) {
    const Map<String, String> coversByName = <String, String>{
      'Minecraft':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co8fu7.jpg',
      'Stardew Valley':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co5n7e.jpg',
      'The Legend of Zelda':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co3p2d.jpg',
      'Celeste':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co3p8d.jpg',
      'Hollow Knight':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co1rgi.jpg',
      'Terraria':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co14pf.jpg',
      'Hades':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co2eeu.jpg',
      'Animal Crossing':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co2ed3.jpg',
      'Rocket League':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co5w4m.jpg',
      'Valorant':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co2h6f.jpg',
      'League of Legends':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co49wj.jpg',
      'Fortnite':
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co1uaf.jpg',
    };

    final String? cover = coversByName[gameName];
    if (cover != null) {
      return cover;
    }

    final String encodedName = Uri.encodeComponent(gameName);
    return 'https://placehold.co/1024x576/0f172a/e2e8f0.png?text=$encodedName';
  }

  List<UserModel> _friendsForUser(UserModel user) {
    final Set<int> ids = _friendsByUser[user.id] ?? <int>{};
    final Set<String> emails = _friendEmailsByUser[user.id] ?? <String>{};
    return _users.where((UserModel item) {
      return ids.contains(item.id) ||
          emails.contains(item.email.trim().toLowerCase());
    }).toList();
  }

  bool _isBlockedByCurrentUser(int otherUserId) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return false;
    }
    return (_blockedUsersByUser[user.id] ?? <int>{}).contains(otherUserId);
  }

  bool _isGuideReportedByCurrentUser(int guideId) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return false;
    }
    return (_reportedGuidesByUser[user.id] ?? <int>{}).contains(guideId);
  }

  bool _isFriendWithCurrentUser(UserModel other) {
    final UserModel? user = _currentUser;
    if (user == null || user.id == other.id) {
      return false;
    }
    final Set<int> ids = _friendsByUser[user.id] ?? <int>{};
    final Set<String> emails = _friendEmailsByUser[user.id] ?? <String>{};
    return ids.contains(other.id) ||
        emails.contains(other.email.trim().toLowerCase());
  }

  void _toggleFriend(UserModel other) {
    final UserModel? user = _currentUser;
    if (user == null || user.id == other.id) {
      return;
    }

    setState(() {
      final Set<int> mine = _friendsByUser.putIfAbsent(user.id, () => <int>{});
      final Set<int> theirs = _friendsByUser.putIfAbsent(other.id, () => <int>{});
      final Set<String> mineEmails =
          _friendEmailsByUser.putIfAbsent(user.id, () => <String>{});
      final Set<String> theirEmails =
          _friendEmailsByUser.putIfAbsent(other.id, () => <String>{});
      final String myEmail = user.email.trim().toLowerCase();
      final String otherEmail = other.email.trim().toLowerCase();
      if (mine.contains(other.id)) {
        mine.remove(other.id);
        theirs.remove(user.id);
        mineEmails.remove(otherEmail);
        theirEmails.remove(myEmail);
      } else {
        mine.add(other.id);
        theirs.add(user.id);
        if (otherEmail.isNotEmpty) {
          mineEmails.add(otherEmail);
        }
        if (myEmail.isNotEmpty) {
          theirEmails.add(myEmail);
        }
      }
    });

    unawaited(_upsertUserInFirebase(user));
    unawaited(_upsertUserInFirebase(other));
  }

  String _resolveStreamTokenServerUrl() {
    const String configured = String.fromEnvironment(
      'STREAM_TOKEN_SERVER_URL',
      defaultValue: '',
    );
    if (configured.trim().isNotEmpty) {
      return configured.trim();
    }
    return 'http://10.0.2.2:8787';
  }

  Future<void> _provisionStreamUser(UserModel user) async {
    final String baseUrl = _resolveStreamTokenServerUrl();
    if (baseUrl.isEmpty) {
      return;
    }

    try {
      final Uri uri = Uri.parse('$baseUrl/stream/token');
      await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'userId': _streamUserIdFromUser(user),
              'name': user.displayName,
            }),
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      // Ignore provisioning failures; StreamHub has user-facing fallback.
    }
  }

  Future<void> _openDirectMessageWithUser(UserModel peer) async {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

    if (_isBlockedByCurrentUser(peer.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No puedes abrir chat con ${peer.displayName} porque está bloqueado.',
          ),
        ),
      );
      return;
    }

    await _provisionStreamUser(user);
    await _provisionStreamUser(peer);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StreamHubScreen(
          displayName: user.displayName,
          currentUserId: _streamUserIdFromUser(user),
          initialPeerId: _streamUserIdFromUser(peer),
          initialPeerName: peer.displayName,
        ),
      ),
    );
  }

  Future<void> _toggleBlockUser({
    required int targetUserId,
    required String targetDisplayName,
  }) async {
    final UserModel? current = _currentUser;
    if (current == null || current.id == targetUserId || targetUserId <= 0) {
      return;
    }

    final Set<int> blocked = _blockedUsersByUser.putIfAbsent(
      current.id,
      () => <int>{},
    );

    final bool wasBlocked = blocked.contains(targetUserId);
    setState(() {
      if (wasBlocked) {
        blocked.remove(targetUserId);
      } else {
        blocked.add(targetUserId);
        _friendsByUser[current.id]?.remove(targetUserId);
        _friendsByUser[targetUserId]?.remove(current.id);
      }
    });

    await _upsertUserInFirebase(current);

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasBlocked
              ? 'Usuario desbloqueado: $targetDisplayName'
              : 'Usuario bloqueado: $targetDisplayName',
        ),
      ),
    );
  }

  Future<void> _reportUser({
    required int targetUserId,
    required String targetDisplayName,
  }) async {
    final UserModel? current = _currentUser;
    if (current == null || current.id == targetUserId || targetUserId <= 0) {
      return;
    }

    final Set<int> reported = _reportedUsersByUser.putIfAbsent(
      current.id,
      () => <int>{},
    );
    if (reported.contains(targetUserId)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ya has reportado a $targetDisplayName.')),
      );
      return;
    }

    setState(() {
      reported.add(targetUserId);
    });

    await _upsertUserInFirebase(current);
    if (FirebaseBootstrap.isReady) {
      await FirebaseFirestore.instance
          .collection('user_reports')
          .doc('${current.id}_$targetUserId')
          .set(<String, dynamic>{
            'reporterId': current.id,
            'targetUserId': targetUserId,
            'targetDisplayName': targetDisplayName,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reporte enviado para $targetDisplayName.')),
    );
  }

  Future<void> _reportGuide(CommunityGuideModel guide) async {
    final UserModel? current = _currentUser;
    if (current == null || guide.authorId == current.id) {
      return;
    }

    final Set<int> reported = _reportedGuidesByUser.putIfAbsent(
      current.id,
      () => <int>{},
    );
    if (reported.contains(guide.id)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya has reportado esta guía.')),
      );
      return;
    }

    setState(() {
      reported.add(guide.id);
    });

    await _upsertUserInFirebase(current);
    if (FirebaseBootstrap.isReady) {
      await FirebaseFirestore.instance
          .collection('guide_reports')
          .doc('${current.id}_${guide.id}')
          .set(<String, dynamic>{
            'reporterId': current.id,
            'guideId': guide.id,
            'authorId': guide.authorId,
            'authorName': guide.authorName,
            'guideTitle': guide.title,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('community_guides')
          .doc(guide.id.toString())
          .set(<String, dynamic>{
            'reportCount': FieldValue.increment(1),
            'reportedBy': FieldValue.arrayUnion(<int>[current.id]),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte de guía enviado.')),
    );
  }

  Widget _buildMissionsScreen(UserModel user) {
    final List<TaskModel> tasks = _tasksByUser[user.id] ?? <TaskModel>[];
    final int coins = _coinsByUser[user.id] ?? 0;
    final int completed = tasks.where((TaskModel task) => task.isDone).length;

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Progreso: $completed/${tasks.length} completadas'),
                const SizedBox(height: 4),
                Text('Saldo actual: 🪙 $coins monedas Syncro'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...tasks.map(
          (TaskModel task) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          task.isDone
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(task.title)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            task.isDone ? 'Completada' : 'Pendiente',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: task.isDone
                              ? null
                              : () => _goToMissionAction(
                                  task.type,
                                  fromMissionsScreen: true,
                                ),
                          child: Text(_missionActionLabel(task.type)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreScreen(UserModel user) {
    final int coins = _coinsByUser[user.id] ?? 0;
    final Set<int> owned = _ownedCosmeticsByUser[user.id] ?? <int>{};
    final String? latestCode = _lastGeneratedCodeByUser[user.id];

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tienda de cosméticos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text('Saldo disponible: 🪙 $coins monedas Syncro'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Canjear código',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                if (latestCode != null)
                  SelectableText('Último código generado: $latestCode'),
                if (latestCode != null) const SizedBox(height: 8),
                TextField(
                  controller: _redeemCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código de canje',
                    hintText: 'SYNCRO-2-4821',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _redeemShopCode,
                    icon: const Icon(Icons.redeem),
                    label: const Text('Canjear'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ..._shopItems.map((CosmeticItemModel item) {
          final bool isOwned = owned.contains(item.id);
          final bool canBuy = !isOwned && coins >= item.price;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    height: 150,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined),
                              ),
                            );
                          },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.cosmeticName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.gameName} · Precio: ${item.price} monedas',
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            if (isOwned)
                              const Chip(label: Text('Comprado'))
                            else
                              FilledButton(
                                onPressed: canBuy
                                    ? () => _buyCosmetic(item)
                                    : null,
                                child: const Text('Comprar'),
                              ),
                            OutlinedButton.icon(
                              onPressed: isOwned
                                  ? () => _generateRedeemCode(item)
                                  : null,
                              icon: const Icon(Icons.qr_code_2_outlined),
                              label: const Text('Generar código'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSocialScreen(UserModel user, List<String> favoriteGames) {
    final List<UserModel> friends = _friendsForUser(user);

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Perfil publico',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text('Avatar: ${user.avatar}'),
                Text('Nombre: ${user.displayName}'),
                Text('Amigos: ${friends.length}'),
                Text(
                  'Juegos favoritos: ${favoriteGames.isEmpty ? 'Sin favoritos aun' : favoriteGames.join(', ')}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Grupos tematicos (solo lectura)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                ..._groups.map((String group) => Text('- $group')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Accesos rápidos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () => _showFriendsBottomSheet(user),
                      icon: const Icon(Icons.group_outlined),
                      label: const Text('Ver amigos'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _activeTab = MainTab.buscar),
                      icon: const Icon(Icons.person_search),
                      label: const Text('Buscar amigos'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Stream API',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chat en tiempo real y feed gaming con Stream.',
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            StreamHubScreen(
                              displayName: user.displayName,
                              currentUserId: _streamUserIdFromUser(user),
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.stream),
                  label: const Text('Abrir Stream Hub'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ..._posts.map((PostModel post) {
          final bool liked = post.likedBy.contains(user.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(post.content),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => _toggleLike(post.id),
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                          ),
                          label: Text('${post.likes} me gusta'),
                        ),
                        const SizedBox(width: 8),
                        Text('Comentarios: ${post.comments.length}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _commentTemplates
                          .map(
                            (String template) => ActionChip(
                              label: Text(template),
                              onPressed: () =>
                                  _addTemplateComment(post.id, template),
                            ),
                          )
                          .toList(),
                    ),
                    if (post.comments.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      ...post.comments.map(
                        (String comment) => Text('- $comment'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  List<LibraryGameUi> _buildLibraryGames(
    UserModel user, {
    required bool applyFilters,
  }) {
    final Map<int, bool> favorites = _favoriteByUser[user.id] ?? <int, bool>{};
    final Map<int, bool> upcoming = _upcomingByUser[user.id] ?? <int, bool>{};
    final Map<int, bool> playing = _playingByUser[user.id] ?? <int, bool>{};
    final Set<int> favoriteIds = favorites.entries
        .where((MapEntry<int, bool> entry) => entry.value)
        .map((MapEntry<int, bool> entry) => entry.key)
        .toSet();
    final Set<String> favoriteGenres = _games
        .where((GameModel game) => favoriteIds.contains(game.id))
        .map((GameModel game) => game.genre.toLowerCase())
        .toSet();

    return _games
        .where((GameModel game) {
          final bool shouldFilterByGameQuery =
              _searchScope == SearchScope.todo ||
              _searchScope == SearchScope.juegos;
          final bool queryMatch =
              !applyFilters ||
              !shouldFilterByGameQuery ||
              _searchQuery.trim().isEmpty ||
              game.name.toLowerCase().contains(
                _searchQuery.trim().toLowerCase(),
              );
          final bool intensityMatch =
              !applyFilters ||
              _selectedIntensity == null ||
              game.sensoryIntensity == _selectedIntensity;
            final bool sensoryTagMatch =
              !applyFilters ||
              _selectedSensoryTags.isEmpty ||
              _selectedSensoryTags.every(game.sensoryTags.contains);
            return queryMatch && intensityMatch && sensoryTagMatch;
        })
        .map((GameModel game) {
          final int recommendationScore =
              _recommendationScoreForUser(
                user: user,
                game: game,
                favoriteIds: favoriteIds,
                favoriteGenres: favoriteGenres,
              );
          final String recommendationTag;
          if (favoriteIds.contains(game.id)) {
            recommendationTag = 'Tu favorito base para recomendaciones';
          } else if (recommendationScore >= 3) {
            recommendationTag = 'Recomendado para ti (perfil + favoritos)';
          } else if (recommendationScore >= 1) {
            recommendationTag = 'Podría gustarte por tu perfil';
          } else {
            recommendationTag = switch (game.sensoryIntensity) {
              SensoryIntensity.baja => 'Baja carga sensorial',
              SensoryIntensity.media => 'Carga sensorial equilibrada',
              SensoryIntensity.alta => 'Alta estimulación',
            };
          }
          return LibraryGameUi(
            game: game,
            isFavorite: favorites[game.id] == true,
            isUpcoming: upcoming[game.id] == true,
            isPlayingNow: playing[game.id] == true,
            recommendationTag: recommendationTag,
          );
        })
        .toList();
  }

  List<String> _sensoryWarningsForUser(UserModel user, GameModel game) {
    final String key = switch (user.neurodivergence) {
      Neurodivergence.tea => 'tea',
      Neurodivergence.tdah => 'tdah',
      Neurodivergence.otra => 'tea',
    };
    return game.sensoryWarnings[key] ?? <String>[];
  }

  int _recommendationScoreForUser({
    required UserModel user,
    required GameModel game,
    required Set<int> favoriteIds,
    required Set<String> favoriteGenres,
  }) {
    int score = 0;

    if (favoriteGenres.contains(game.genre.toLowerCase())) {
      score += 2;
    }

    switch (user.neurodivergence) {
      case Neurodivergence.tea:
        if (game.sensoryIntensity == SensoryIntensity.baja) {
          score += 2;
        } else if (game.sensoryIntensity == SensoryIntensity.media) {
          score += 1;
        } else {
          score -= 1;
        }
        break;
      case Neurodivergence.tdah:
        if (game.sensoryIntensity == SensoryIntensity.alta) {
          score += 2;
        } else if (game.sensoryIntensity == SensoryIntensity.media) {
          score += 1;
        }
        break;
      case Neurodivergence.otra:
        if (game.sensoryIntensity == SensoryIntensity.media) {
          score += 2;
        } else if (game.sensoryIntensity == SensoryIntensity.baja) {
          score += 1;
        }
        break;
    }

    if (user.age <= 12 && game.sensoryIntensity == SensoryIntensity.alta) {
      score -= 2;
    } else if (user.age <= 17 && game.sensoryIntensity == SensoryIntensity.alta) {
      score -= 1;
    }

    if (favoriteIds.contains(game.id)) {
      score += 4;
    }

    return score;
  }

  List<LibraryGameUi> _buildRecentGamesForUser(UserModel user) {
    final Map<int, bool> favorites = _favoriteByUser[user.id] ?? <int, bool>{};
    final Map<int, bool> upcoming = _upcomingByUser[user.id] ?? <int, bool>{};
    final Map<int, bool> playing = _playingByUser[user.id] ?? <int, bool>{};

    final List<(int, LibraryGameUi)> indexedGames = _games.asMap().entries.map((
      MapEntry<int, GameModel> entry,
    ) {
      final GameModel game = entry.value;
      return (
        entry.key,
        LibraryGameUi(
          game: game,
          isFavorite: favorites[game.id] == true,
          isUpcoming: upcoming[game.id] == true,
          isPlayingNow: playing[game.id] == true,
          recommendationTag: null,
        ),
      );
    }).toList();

    int priority(LibraryGameUi gameUi) {
      if (gameUi.isPlayingNow) {
        return 2;
      }
      if (gameUi.isFavorite) {
        return 1;
      }
      return 0;
    }

    indexedGames.sort((a, b) {
      final int byPriority = priority(b.$2).compareTo(priority(a.$2));
      if (byPriority != 0) {
        return byPriority;
      }
      return a.$1.compareTo(b.$1);
    });

    return indexedGames
        .take(12)
        .map(((int, LibraryGameUi) item) => item.$2)
        .toList();
  }

  void _submitAuth() {
    setState(() {
      _auth.isLoading = true;
      _auth.errorMessage = null;
    });

    Future<void>.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) {
        return;
      }

      final String email = _auth.email.trim().toLowerCase();
      final String password = _auth.password;
      final String displayName = _auth.displayName.trim();

      if (_auth.isRegisterMode) {
        if (email.isEmpty || password.length < 6) {
          setState(() {
            _auth.isLoading = false;
            _auth.errorMessage =
                'Introduce email/usuario y una contrasena de minimo 6 caracteres';
          });
          return;
        }
        if (_users.any((UserModel u) => u.email == email)) {
          setState(() {
            _auth.isLoading = false;
            _auth.errorMessage = 'Este email ya esta registrado';
          });
          return;
        }

        final UserModel user = UserModel(
          id: _nextUserId(),
          email: email,
          password: password,
          displayName: displayName.isEmpty
              ? email.split('@').first
              : displayName,
          onboardingCompleted: false,
        );
        _users.add(user);
        _ensureDefaultTasks(user.id);
        _ensureDailyMissionState(user.id);
        _ensureUserEconomy(user.id);
        await _upsertUserInFirebase(user);
        _enterWithUser(user, forceOnboarding: true);
      } else {
        UserModel? user = await _findUserInFirebase(
          email: email,
          password: password,
        );

        user ??= _users
            .where((UserModel u) => u.email == email)
            .cast<UserModel?>()
            .firstWhere((UserModel? u) => u != null, orElse: () => null);

        if (user == null) {
          setState(() {
            _auth.isLoading = false;
            _auth.errorMessage =
                'Usuario no encontrado. Crea una cuenta primero';
          });
          return;
        }
        if (user.password != password) {
          setState(() {
            _auth.isLoading = false;
            _auth.errorMessage = 'Contrasena incorrecta';
          });
          return;
        }
        _ensureDefaultTasks(user.id);
        _ensureDailyMissionState(user.id);
        _ensureUserEconomy(user.id);
        final int existingIndex = _users.indexWhere(
          (UserModel u) => u.email.toLowerCase() == user!.email.toLowerCase(),
        );
        if (existingIndex == -1) {
          _users.add(user);
        } else {
          _users[existingIndex] = user;
        }
        _enterWithUser(user);
      }
    });
  }

  void _loginDemo() {
    final UserModel user = _users.firstWhere(
      (UserModel u) => u.email == 'demo',
    );
    _ensureDefaultTasks(user.id);
    _ensureDailyMissionState(user.id);
    _ensureUserEconomy(user.id);
    _enterWithUser(user);
  }

  void _enterWithUser(UserModel user, {bool forceOnboarding = false}) {
    final bool shouldShowOnboarding = forceOnboarding || !user.onboardingCompleted;
    setState(() {
      _currentUser = user;
      _catalogViewMode = user.catalogViewMode;
      _auth.isLoading = false;
      _auth.errorMessage = null;
      _auth.email = '';
      _auth.password = '';
      _auth.displayName = '';
      _auth.isRegisterMode = false;
      _selectedSensoryTags
        ..clear()
        ..addAll(user.sensoryFilterTags);
      _restoreSearchHistoryFromPrefs(user.id);
      _ensureDailyMissionState(user.id);
    });
    if (shouldShowOnboarding) {
      _initializeOnboardingState(user);
    }
    _saveUserPreferences(user);
    unawaited(_hydrateAndPersistUserOnEnter(user));
    unawaited(_syncAllUsersFromFirebase());
  }

  void _logout() {
    setState(() {
      _currentUser = null;
      _catalogViewMode = CatalogViewMode.lista;
      _activeTab = MainTab.home;
      _searchQuery = '';
      _selectedIntensity = null;
      _selectedSensoryTags.clear();
      _timer.remainingSeconds = _workDurationMinutes * 60;
      _timer.isRunning = false;
      _timer.isWorkSession = true;
      _timer.showBreakReminder = false;
      _secondsSinceBreakReminder = 0;
    });
    _prefs?.remove('last_user_prefs');
  }

  Future<void> _confirmDeleteAccount() async {
    final UserModel? current = _currentUser;
    if (current == null) {
      return;
    }

    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Borrar cuenta'),
          content: const Text(
            'Esta acción eliminará tu cuenta, misiones, monedas y cosméticos guardados localmente. ¿Continuar?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    if (accepted != true || !mounted) {
      return;
    }

    final int userId = current.id;
    unawaited(_deleteUserInFirebase(current));
    setState(() {
      _users.removeWhere((UserModel user) => user.id == userId);
      _favoriteByUser.remove(userId);
      _upcomingByUser.remove(userId);
      _playingByUser.remove(userId);
      _tasksByUser.remove(userId);
      _coinsByUser.remove(userId);
      _dailyMissionDateByUser.remove(userId);
      _ownedCosmeticsByUser.remove(userId);
      _focusSecondsByUser.remove(userId);
      _breakSecondsByUser.remove(userId);
      _friendsByUser.remove(userId);
      _blockedUsersByUser.remove(userId);
      _reportedUsersByUser.remove(userId);
      _reportedGuidesByUser.remove(userId);
      for (final Set<int> ids in _friendsByUser.values) {
        ids.remove(userId);
      }
      for (final Set<int> ids in _blockedUsersByUser.values) {
        ids.remove(userId);
      }
      for (final Set<int> ids in _reportedUsersByUser.values) {
        ids.remove(userId);
      }
      _currentUser = null;
      _activeTab = MainTab.home;
      _searchQuery = '';
      _selectedIntensity = null;
      _timer.remainingSeconds = _workDurationMinutes * 60;
      _timer.isRunning = false;
      _timer.isWorkSession = true;
      _timer.showBreakReminder = false;
      _secondsSinceBreakReminder = 0;
    });
  }

  void _completeDailyMission(TaskModel task) {
    final UserModel? user = _currentUser;
    if (user == null || task.isDone) {
      return;
    }

    setState(() {
      task.isDone = true;
      _coinsByUser[user.id] = (_coinsByUser[user.id] ?? 0) + 10;
    });
    _persistDailyMissionState(user.id);
    unawaited(_upsertUserInFirebase(user));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Misión completada: +10 monedas Syncro')),
    );
  }

  void _completeMissionForCurrentUser(DailyMissionType type) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

    final List<TaskModel> tasks = _tasksByUser[user.id] ?? <TaskModel>[];
    final TaskModel? mission = tasks.cast<TaskModel?>().firstWhere(
      (TaskModel? task) => task != null && task.type == type,
      orElse: () => null,
    );
    if (mission == null || mission.isDone) {
      return;
    }

    _completeDailyMission(mission);
  }

  String _missionActionLabel(DailyMissionType type) {
    return switch (type) {
      DailyMissionType.readGuide => 'Ir a guía',
      DailyMissionType.favoriteGame => 'Ir a juegos',
      DailyMissionType.consciousBreak => 'Tomar descanso',
    };
  }

  void _goToMissionAction(
    DailyMissionType type, {
    bool fromMissionsScreen = false,
  }) {
    if (fromMissionsScreen && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    String message = '';

    setState(() {
      switch (type) {
        case DailyMissionType.readGuide:
          _activeTab = MainTab.buscar;
          message = 'Abre un juego y pulsa "Ver guía" para completarla.';
          break;
        case DailyMissionType.favoriteGame:
          _activeTab = MainTab.buscar;
          message = 'Marca un juego con ❤️ para completar la misión.';
          break;
        case DailyMissionType.consciousBreak:
          _timer.isRunning = true;
          _timer.isWorkSession = false;
          _timer.remainingSeconds = _breakDurationMinutes * 60;
          _timer.showBreakReminder = true;
          _secondsSinceBreakReminder = 0;
          _completeMissionForCurrentUser(DailyMissionType.consciousBreak);
          message = 'Descanso activado. Ya puedes retomarlo cuando quieras.';
          break;
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _buyCosmetic(CosmeticItemModel item) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

    final int coins = _coinsByUser[user.id] ?? 0;
    final Set<int> owned = _ownedCosmeticsByUser.putIfAbsent(
      user.id,
      () => <int>{},
    );
    if (owned.contains(item.id) || coins < item.price) {
      return;
    }

    setState(() {
      _coinsByUser[user.id] = coins - item.price;
      owned.add(item.id);
    });
    unawaited(_upsertUserInFirebase(user));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Has comprado ${item.cosmeticName}')),
    );
  }

  void _generateRedeemCode(CosmeticItemModel item) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

    final Set<int> owned = _ownedCosmeticsByUser[user.id] ?? <int>{};
    if (!owned.contains(item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes comprar este cosmético.')),
      );
      return;
    }

    final Map<String, int> userCodes = _purchaseCodesByUser.putIfAbsent(
      user.id,
      () => <String, int>{},
    );

    String code;
    do {
      final int suffix = 1000 + _random.nextInt(9000);
      code = 'SYNCRO-${item.id}-$suffix';
    } while (userCodes.containsKey(code));

    setState(() {
      userCodes[code] = item.id;
      _lastGeneratedCodeByUser[user.id] = code;
    });

    Clipboard.setData(ClipboardData(text: code));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código generado para ${item.cosmeticName}: $code'),
      ),
    );
  }

  void _redeemShopCode() {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

    final String code = _redeemCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un código para canjear.')),
      );
      return;
    }

    final Map<String, int> userCodes =
        _purchaseCodesByUser[user.id] ?? <String, int>{};
    final Set<String> redeemed = _redeemedCodesByUser.putIfAbsent(
      user.id,
      () => <String>{},
    );
    final int? itemId = userCodes[code];

    if (itemId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Código no válido.')));
      return;
    }

    if (redeemed.contains(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este código ya fue canjeado.')),
      );
      return;
    }

    final Set<int> owned = _ownedCosmeticsByUser.putIfAbsent(
      user.id,
      () => <int>{},
    );
    final CosmeticItemModel item = _shopItems.firstWhere(
      (CosmeticItemModel shopItem) => shopItem.id == itemId,
    );

    setState(() {
      redeemed.add(code);
      owned.add(itemId);
      _redeemCodeController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Canje completado: ${item.cosmeticName}')),
    );
  }

  void _toggleFavorite(int gameId) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }
    final Map<int, bool> favorites = _favoriteByUser.putIfAbsent(
      user.id,
      () => <int, bool>{},
    );
    setState(() {
      favorites[gameId] = !(favorites[gameId] ?? false);
    });
    if (favorites[gameId] == true) {
      _completeMissionForCurrentUser(DailyMissionType.favoriteGame);
    }
  }

  void _toggleUpcoming(int gameId) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }
    final Map<int, bool> upcoming = _upcomingByUser.putIfAbsent(
      user.id,
      () => <int, bool>{},
    );
    final bool wasUpcoming = upcoming[gameId] == true;
    setState(() {
      upcoming[gameId] = !wasUpcoming;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasUpcoming
              ? 'Juego eliminado de Próximos.'
              : 'Juego añadido a Próximos.',
        ),
      ),
    );
  }

  void _toggleGuideForGame(GameModel game, {bool focusSearchOnEnable = false}) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }
    final Map<int, bool> playing = _playingByUser.putIfAbsent(
      user.id,
      () => <int, bool>{},
    );
    final bool isPlayingNow = playing[game.id] == true;

    setState(() {
      if (isPlayingNow) {
        playing[game.id] = false;
        if (_searchQuery == game.name) {
          _searchQuery = '';
        }
        if (_selectedIntensity == game.sensoryIntensity) {
          _selectedIntensity = null;
        }
      } else {
        playing[game.id] = true;
        _completeMissionForCurrentUser(DailyMissionType.readGuide);
        if (focusSearchOnEnable) {
          _activeTab = MainTab.buscar;
          _searchScope = SearchScope.guias;
          _searchQuery = game.name;
        }
      }
    });
  }

  void _toggleLike(int postId) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }
    final PostModel post = _posts.firstWhere((PostModel p) => p.id == postId);
    setState(() {
      if (post.likedBy.remove(user.id)) {
        post.likes = post.likes > 0 ? post.likes - 1 : 0;
      } else {
        post.likedBy.add(user.id);
        post.likes += 1;
      }
    });
  }

  void _addTemplateComment(int postId, String template) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }
    final PostModel post = _posts.firstWhere((PostModel p) => p.id == postId);
    setState(() {
      post.comments.insert(0, '${user.displayName}: $template');
    });
  }

  void _ensureDefaultTasks(int userId) {
    _tasksByUser.putIfAbsent(userId, _buildDailyMissions);
  }

  void _ensureDailyMissionState(int userId) {
    if (_dailyMissionsLoadedByUser[userId] != true) {
      _restoreDailyMissionsFromPrefs(userId);
      _dailyMissionsLoadedByUser[userId] = true;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime? savedDate = _dailyMissionDateByUser[userId];
    if (savedDate == null || !_isSameDay(savedDate, today)) {
      _tasksByUser[userId] = _buildDailyMissions();
      _dailyMissionDateByUser[userId] = today;
      _persistDailyMissionState(userId);
    }
  }

  void _ensureUserEconomy(int userId) {
    _coinsByUser.putIfAbsent(userId, () => 0);
    _ownedCosmeticsByUser.putIfAbsent(userId, () => <int>{});
    _upcomingByUser.putIfAbsent(userId, () => <int, bool>{});
    _focusSecondsByUser.putIfAbsent(userId, () => 0);
    _breakSecondsByUser.putIfAbsent(userId, () => 0);
    _friendsByUser.putIfAbsent(userId, () => <int>{});
    _friendEmailsByUser.putIfAbsent(userId, () => <String>{});
    _blockedUsersByUser.putIfAbsent(userId, () => <int>{});
    _reportedUsersByUser.putIfAbsent(userId, () => <int>{});
    _reportedGuidesByUser.putIfAbsent(userId, () => <int>{});
    _searchHistoryByUser.putIfAbsent(userId, () => <String>[]);
  }

  List<TaskModel> _buildDailyMissions() {
    return <TaskModel>[
      TaskModel(
        id: _taskIdCounter++,
        title: 'Leer una guía útil (botón Ver guía)',
        type: DailyMissionType.readGuide,
      ),
      TaskModel(
        id: _taskIdCounter++,
        title: 'Marcar 1 juego como favorito',
        type: DailyMissionType.favoriteGame,
      ),
      TaskModel(
        id: _taskIdCounter++,
        title: 'Tomar un descanso consciente',
        type: DailyMissionType.consciousBreak,
      ),
    ];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _updateCurrentUser(UserModel Function(UserModel) transform) {
    final UserModel? current = _currentUser;
    if (current == null) {
      return;
    }
    final int index = _users.indexWhere(
      (UserModel item) => item.id == current.id,
    );
    if (index == -1) {
      return;
    }
    final UserModel updated = transform(current);
    setState(() {
      _users[index] = updated;
      _currentUser = updated;
      _catalogViewMode = updated.catalogViewMode;
    });
    _saveUserPreferences(updated);
    unawaited(_upsertUserInFirebase(updated));
  }

  Future<void> _upsertUserInFirebase(UserModel user) async {
    if (!FirebaseBootstrap.isReady) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.email.toLowerCase())
        .set(<String, dynamic>{
          'id': user.id,
          'email': user.email,
          'password': user.password,
          'displayName': user.displayName,
          'avatar': user.avatar,
          'avatarBytes': user.avatarBytes != null
              ? base64Encode(user.avatarBytes!)
              : null,
          'profileStatus': user.profileStatus,
            'age': user.age,
            'neurodivergence': user.neurodivergence.name,
          'fontScale': user.fontScale,
          'accessibilityMode': user.accessibilityMode.name,
          'softColors': user.softColors,
          'noAnimations': user.noAnimations,
          'legibleFont': user.legibleFont,
          'themePalette': user.themePalette.name,
          'fontPreference': user.fontPreference.name,
          'notificationMode': user.notificationMode.name,
          'coins': _coinsByUser[user.id] ?? 0,
          'friendUserIds': (_friendsByUser[user.id] ?? <int>{})
              .toList()
            ..sort(),
          'friendUserEmails': _friendEmailsForUserId(user.id),
          'blockedUserIds': (_blockedUsersByUser[user.id] ?? <int>{})
              .toList()
            ..sort(),
          'reportedUserIds': (_reportedUsersByUser[user.id] ?? <int>{})
              .toList()
            ..sort(),
          'reportedGuideIds': (_reportedGuidesByUser[user.id] ?? <int>{})
              .toList()
            ..sort(),
          'onboardingCompleted': user.onboardingCompleted,
          'catalogViewMode': user.catalogViewMode.name,
          'sensoryFilterTags': user.sensoryFilterTags,
          'showSensoryWarnings': user.showSensoryWarnings,
          'emergencyGrayscale': user.emergencyGrayscale,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _syncUserCoinsFromFirebase(UserModel user) async {
    if (!FirebaseBootstrap.isReady) {
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.email.toLowerCase())
              .get();
      if (!snapshot.exists || !mounted) {
        return;
      }
      final Map<String, dynamic>? data = snapshot.data();
      if (data == null) {
        return;
      }
      final int persistedCoins = (data['coins'] as num?)?.toInt() ?? 0;
      final Set<String> friendEmails =
          (data['friendUserEmails'] as List<dynamic>? ?? <dynamic>[])
              .whereType<String>()
              .map((String value) => value.trim().toLowerCase())
              .where((String value) => value.isNotEmpty)
              .toSet();
      setState(() {
        _coinsByUser[user.id] = persistedCoins;
        _friendsByUser[user.id] = _parseFriendIdsFromData(data);
        _friendEmailsByUser[user.id] = friendEmails;
        _blockedUsersByUser[user.id] = _parseIdSet(data['blockedUserIds']);
        _reportedUsersByUser[user.id] = _parseIdSet(data['reportedUserIds']);
        _reportedGuidesByUser[user.id] = _parseIdSet(data['reportedGuideIds']);
      });
    } catch (_) {
      // Keep local coins value if Firestore is temporarily unavailable.
    }
  }

  Future<void> _hydrateAndPersistUserOnEnter(UserModel user) async {
    await _syncUserCoinsFromFirebase(user);
    // Avoid overwriting remote relationship state during login hydration.
  }

  Future<void> _upsertGameInFirebase(GameModel game) async {
    if (!FirebaseBootstrap.isReady) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('games')
        .doc(game.id.toString())
        .set(<String, dynamic>{
          'id': game.id,
          'name': game.name,
          'genre': game.genre,
          'imageUrl': game.imageUrl,
          'sensoryIntensity': game.sensoryIntensity.name,
          'description': game.description,
          'sensoryTags': game.sensoryTags,
          'sensoryWarnings': game.sensoryWarnings,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _syncGamesFromFirebase() async {
    if (!FirebaseBootstrap.isReady) {
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('games').get();
      if (snapshot.docs.isEmpty || !mounted) {
        return;
      }

      final List<GameModel> firebaseGames = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final Map<String, dynamic> data = doc.data();
            return GameModel(
              id: (data['id'] as int?) ?? int.tryParse(doc.id) ?? _nextGameId(),
              name: (data['name'] as String?) ?? 'Juego',
              genre: (data['genre'] as String?) ?? 'General',
              imageUrl: (data['imageUrl'] as String?) ??
                  _imageForGameName((data['name'] as String?) ?? 'Juego'),
              sensoryIntensity: SensoryIntensity.values.byName(
                (data['sensoryIntensity'] as String?) ?? 'media',
              ),
              description: (data['description'] as String?) ??
                  'Experiencia accesible para distintos perfiles.',
              sensoryTags:
                  (data['sensoryTags'] as List<dynamic>? ?? <dynamic>[])
                      .whereType<String>()
                      .toList(),
              sensoryWarnings: _parseSensoryWarnings(
                data['sensoryWarnings'] as Map<String, dynamic>?,
              ),
            );
          })
          .toList();

      firebaseGames.sort((GameModel a, GameModel b) => a.id.compareTo(b.id));

      setState(() {
        _games
          ..clear()
          ..addAll(firebaseGames);
      });
      await _removePlaceholderGamesEverywhere();
    } catch (_) {
      // Keep local fallback catalog when Firestore is temporarily unavailable.
    }
  }

  Future<void> _syncCommunityGuidesFromFirebase() async {
    if (!FirebaseBootstrap.isReady) {
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('community_guides').get();

      if (snapshot.docs.isEmpty) {
        for (final CommunityGuideModel guide in _communityGuides) {
          await _upsertCommunityGuideInFirebase(guide);
        }
        return;
      }

      final List<CommunityGuideModel> guides = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final Map<String, dynamic> data = doc.data();
            final Timestamp? timestamp = data['createdAt'] as Timestamp?;
            return CommunityGuideModel(
              id: (data['id'] as int?) ?? int.tryParse(doc.id) ?? 0,
              gameId: (data['gameId'] as int?) ?? 0,
              authorId: (data['authorId'] as int?) ?? 0,
              authorName: (data['authorName'] as String?) ?? 'Usuario',
              title: (data['title'] as String?) ?? 'Guía',
              content: (data['content'] as String?) ?? '',
              createdAt: timestamp?.toDate() ?? DateTime.now(),
            );
          })
          .where((CommunityGuideModel guide) => guide.id > 0)
          .toList()
        ..sort((CommunityGuideModel a, CommunityGuideModel b) {
          return b.createdAt.compareTo(a.createdAt);
        });

      if (!mounted) {
        return;
      }

      setState(() {
        _communityGuides
          ..clear()
          ..addAll(guides);
        if (guides.isNotEmpty) {
          _guideIdCounter =
              guides.map((CommunityGuideModel guide) => guide.id).reduce(max) +
              1;
        }
      });
    } catch (_) {
      // Keep local community guides if Firestore is temporarily unavailable.
    }
  }

  Future<void> _upsertCommunityGuideInFirebase(CommunityGuideModel guide) async {
    if (!FirebaseBootstrap.isReady) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('community_guides')
        .doc(guide.id.toString())
        .set(<String, dynamic>{
          'id': guide.id,
          'gameId': guide.gameId,
          'authorId': guide.authorId,
          'authorName': guide.authorName,
          'title': guide.title,
          'content': guide.content,
          'createdAt': Timestamp.fromDate(guide.createdAt),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Map<String, List<String>> _parseSensoryWarnings(
    Map<String, dynamic>? raw,
  ) {
    if (raw == null) {
      return <String, List<String>>{};
    }
    final Map<String, List<String>> parsed = <String, List<String>>{};
    for (final MapEntry<String, dynamic> entry in raw.entries) {
      parsed[entry.key] = (entry.value as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList();
    }
    return parsed;
  }

  bool _isPlaceholderGameName(String value) {
    return RegExp(r'^juego\s+\d+$', caseSensitive: false).hasMatch(
      value.trim(),
    );
  }

  Future<void> _removePlaceholderGamesEverywhere() async {
    final Set<int> placeholderIds = _games
        .where((GameModel game) => _isPlaceholderGameName(game.name))
        .map((GameModel game) => game.id)
        .toSet();

    if (FirebaseBootstrap.isReady) {
      try {
        final QuerySnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance.collection('games').get();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in snapshot.docs) {
          final Map<String, dynamic> data = doc.data();
          final String name = (data['name'] as String?) ?? '';
          if (_isPlaceholderGameName(name)) {
            final int id =
                (data['id'] as int?) ?? int.tryParse(doc.id) ?? -1;
            if (id > 0) {
              placeholderIds.add(id);
            }
            await FirebaseFirestore.instance
                .collection('games')
                .doc(doc.id)
                .delete();
          }
        }
      } catch (_) {
        // Ignore cleanup failures to avoid blocking startup.
      }
    }

    if (placeholderIds.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _games.removeWhere((GameModel game) => placeholderIds.contains(game.id));
      _communityGuides.removeWhere(
        (CommunityGuideModel guide) => placeholderIds.contains(guide.gameId),
      );
      _onboardingFavoriteGameIds.removeWhere(placeholderIds.contains);
      for (final Map<int, bool> favorites in _favoriteByUser.values) {
        favorites.removeWhere(
          (int gameId, bool _) => placeholderIds.contains(gameId),
        );
      }
      for (final Map<int, bool> upcoming in _upcomingByUser.values) {
        upcoming.removeWhere(
          (int gameId, bool _) => placeholderIds.contains(gameId),
        );
      }
      for (final Map<int, bool> playing in _playingByUser.values) {
        playing.removeWhere(
          (int gameId, bool _) => placeholderIds.contains(gameId),
        );
      }
    });

    if (!FirebaseBootstrap.isReady) {
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> guidesSnapshot =
          await FirebaseFirestore.instance.collection('community_guides').get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in guidesSnapshot.docs) {
        final int gameId = (doc.data()['gameId'] as int?) ?? -1;
        if (placeholderIds.contains(gameId)) {
          await FirebaseFirestore.instance
              .collection('community_guides')
              .doc(doc.id)
              .delete();
        }
      }
    } catch (_) {
      // Ignore guide cleanup failures.
    }
  }

  Future<UserModel?> _findUserInFirebase({
    required String email,
    required String password,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(email.toLowerCase())
            .get();
    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      return null;
    }

    final String storedPassword = (data['password'] as String?) ?? '';
    if (storedPassword != password) {
      return null;
    }

    final int resolvedId = _resolveUserIdFromData(data, email);
    _coinsByUser[resolvedId] = (data['coins'] as num?)?.toInt() ?? 0;
    _friendsByUser[resolvedId] = _parseFriendIdsFromData(data);
    _friendEmailsByUser[resolvedId] =
      (data['friendUserEmails'] as List<dynamic>? ?? <dynamic>[])
        .whereType<String>()
        .map((String value) => value.trim().toLowerCase())
        .where((String value) => value.isNotEmpty)
        .toSet();
    _blockedUsersByUser[resolvedId] = _parseIdSet(data['blockedUserIds']);
    _reportedUsersByUser[resolvedId] = _parseIdSet(data['reportedUserIds']);
    _reportedGuidesByUser[resolvedId] = _parseIdSet(data['reportedGuideIds']);

    return UserModel(
      id: resolvedId,
      email: (data['email'] as String?) ?? email,
      password: storedPassword,
      displayName: (data['displayName'] as String?) ?? email.split('@').first,
      avatar: (data['avatar'] as String?) ?? '🎮',
      avatarBytes: (data['avatarBytes'] as String?) != null
          ? base64Decode(data['avatarBytes'] as String)
          : null,
      profileStatus: (data['profileStatus'] as String?) ?? 'En línea',
      age: (data['age'] as int?) ?? 18,
      neurodivergence: Neurodivergence.values.byName(
        (data['neurodivergence'] as String?) ?? 'tea',
      ),
      fontScale: (data['fontScale'] as num?)?.toDouble() ?? 1.0,
      accessibilityMode: AccessibilityMode.values.byName(
        (data['accessibilityMode'] as String?) ?? 'tea',
      ),
      softColors: (data['softColors'] as bool?) ?? true,
      noAnimations: (data['noAnimations'] as bool?) ?? false,
      legibleFont: (data['legibleFont'] as bool?) ?? false,
      themePalette: ThemePalette.values.byName(
        (data['themePalette'] as String?) ?? 'suave',
      ),
      fontPreference: FontPreference.values.byName(
        (data['fontPreference'] as String?) ?? 'sistema',
      ),
      notificationMode: NotificationMode.values.byName(
        (data['notificationMode'] as String?) ?? 'importantes',
      ),
      onboardingCompleted: (data['onboardingCompleted'] as bool?) ?? true,
      catalogViewMode: CatalogViewMode.values.byName(
        (data['catalogViewMode'] as String?) ?? 'lista',
      ),
      sensoryFilterTags:
          (data['sensoryFilterTags'] as List<dynamic>? ?? <dynamic>[])
              .whereType<String>()
              .toList(),
      showSensoryWarnings: (data['showSensoryWarnings'] as bool?) ?? true,
      emergencyGrayscale: (data['emergencyGrayscale'] as bool?) ?? false,
    );
  }

  Future<void> _deleteUserInFirebase(UserModel user) async {
    if (!FirebaseBootstrap.isReady) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.email.toLowerCase())
        .delete();
  }

  UserModel _buildAdaptiveUserProfile({
    required UserModel base,
    required Neurodivergence neurodivergence,
    required int age,
  }) {
    AccessibilityMode accessibilityMode = AccessibilityMode.tea;
    bool softColors = true;
    bool noAnimations = true;
    bool legibleFont = true;
    ThemePalette themePalette = ThemePalette.suave;
    FontPreference fontPreference = FontPreference.legible;
    double fontScale = 1.0;
    NotificationMode notificationMode = NotificationMode.importantes;

    if (neurodivergence == Neurodivergence.tdah) {
      accessibilityMode = AccessibilityMode.tdah;
      softColors = false;
      noAnimations = false;
      legibleFont = false;
      themePalette = ThemePalette.neon;
      fontPreference = FontPreference.sistema;
      fontScale = 1.08;
      notificationMode = NotificationMode.todas;
    } else if (neurodivergence == Neurodivergence.otra) {
      accessibilityMode = AccessibilityMode.tea;
      softColors = true;
      noAnimations = false;
      legibleFont = true;
      themePalette = ThemePalette.verde;
      fontPreference = FontPreference.legible;
      fontScale = 1.04;
      notificationMode = NotificationMode.importantes;
    }

    if (age <= 12) {
      softColors = true;
      noAnimations = true;
      legibleFont = true;
      fontPreference = FontPreference.legible;
      fontScale = max(fontScale, 1.16);
      notificationMode = NotificationMode.importantes;
    } else if (age <= 17) {
      softColors = true;
      fontScale = max(fontScale, 1.1);
      notificationMode = NotificationMode.importantes;
    }

    return base.copyWith(
      age: age,
      neurodivergence: neurodivergence,
      accessibilityMode: accessibilityMode,
      softColors: softColors,
      noAnimations: noAnimations,
      legibleFont: legibleFont,
      themePalette: themePalette,
      fontPreference: fontPreference,
      fontScale: fontScale,
      notificationMode: notificationMode,
    );
  }

  void _applyAccessibilityPreset(AccessibilityMode mode) {
    _updateCurrentUser((UserModel base) {
      final Neurodivergence neurodivergence = mode == AccessibilityMode.tdah
          ? Neurodivergence.tdah
          : Neurodivergence.tea;
      return _buildAdaptiveUserProfile(
        base: base,
        neurodivergence: neurodivergence,
        age: base.age,
      );
    });
  }

  String _accessibilityProfileDescription(AccessibilityMode mode) {
    return switch (mode) {
      AccessibilityMode.tea =>
        'TEA: colores suaves, menos animaciones, fuente legible y notificaciones importantes.',
      AccessibilityMode.tdah =>
        'TDAH: tema más dinámico, avisos completos y ritmo visual más activo.',
    };
  }

  int _nextUserId() {
    if (_users.isEmpty) {
      return 1;
    }
    return _users
            .map((UserModel user) => user.id)
            .reduce((int a, int b) => a > b ? a : b) +
        1;
  }

  int _nextGameId() {
    if (_games.isEmpty) {
      return 1;
    }
    return _games
            .map((GameModel game) => game.id)
            .reduce((int a, int b) => a > b ? a : b) +
        1;
  }

  void _startPausePomodoro() {
    final bool wasRunning = _timer.isRunning;
    setState(() {
      _timer.isRunning = !_timer.isRunning;
    });

    if (wasRunning) {
      _completeMissionForCurrentUser(DailyMissionType.consciousBreak);
    }
  }

  Future<void> _showAddPomodoroTimeDialog() async {
    final TextEditingController minutesController = TextEditingController(
      text: '5',
    );

    final int? minutesDelta = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajustar tiempo del temporizador'),
          content: TextField(
            controller: minutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutos',
              hintText: 'Ejemplo: 5',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () {
                final int? value = int.tryParse(minutesController.text.trim());
                Navigator.of(context).pop(
                  value == null ? null : -value,
                );
              },
              child: const Text('Quitar'),
            ),
            FilledButton(
              onPressed: () {
                final int? value = int.tryParse(minutesController.text.trim());
                Navigator.of(context).pop(value);
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );

    if (minutesDelta == null || minutesDelta == 0) {
      return;
    }

    setState(() {
      final int adjustedSeconds = _timer.remainingSeconds + (minutesDelta * 60);
      _timer.remainingSeconds = adjustedSeconds < 0 ? 0 : adjustedSeconds;
    });
  }

  void _resetPomodoro() {
    setState(() {
      _timer.isRunning = false;
      _timer.remainingSeconds =
          _timer.isWorkSession ? _workDurationMinutes * 60 : _breakDurationMinutes * 60;
    });
  }

  void _dismissBreakReminder() {
    setState(() {
      _timer.showBreakReminder = false;
      _secondsSinceBreakReminder = 0;
    });
    _completeMissionForCurrentUser(DailyMissionType.consciousBreak);
  }

  void _tickTimer() {
    if (!mounted) {
      return;
    }

    if (!_timer.isRunning) {
      final UserModel? user = _currentUser;
      if (user != null) {
        setState(() {
          _breakSecondsByUser[user.id] =
              (_breakSecondsByUser[user.id] ?? 0) + 1;
        });
      }
      return;
    }

    final UserModel? user = _currentUser;
    if (user != null) {
      _ensureDailyMissionState(user.id);
    }

    setState(() {
      if (user != null) {
        if (_timer.isWorkSession) {
          _focusSecondsByUser[user.id] =
              (_focusSecondsByUser[user.id] ?? 0) + 1;
        } else {
          _breakSecondsByUser[user.id] =
              (_breakSecondsByUser[user.id] ?? 0) + 1;
        }
      }

      final int next = _timer.remainingSeconds - 1;
      if (next <= 0) {
        final bool finishedWork = _timer.isWorkSession;
        _timer.isRunning = false;
        _timer.isWorkSession = !finishedWork;
        _timer.remainingSeconds =
            _timer.isWorkSession ? _workDurationMinutes * 60 : _breakDurationMinutes * 60;
        SystemSound.play(SystemSoundType.alert);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_showPomodoroCompletionPrompt(finishedWork: finishedWork));
        });
      } else {
        _timer.remainingSeconds = next;
      }
    });
  }

  Future<void> _showPomodoroCompletionPrompt({
    required bool finishedWork,
  }) async {
    if (!mounted || _isPomodoroPromptOpen) {
      return;
    }

    _isPomodoroPromptOpen = true;
    final int suggestedMinutes = finishedWork ? _breakDurationMinutes : _workDurationMinutes;
    final TextEditingController minutesController = TextEditingController(
      text: suggestedMinutes.toString(),
    );

    final bool? shouldStart = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            finishedWork
                ? 'Pomodoro terminado'
                : 'Descanso terminado',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                finishedWork
                    ? '¿Quieres iniciar un descanso ahora?'
                    : '¿Quieres iniciar otro pomodoro de trabajo?',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duración en minutos',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Iniciar'),
            ),
          ],
        );
      },
    );

    final int requestedMinutes = int.tryParse(minutesController.text.trim()) ??
        suggestedMinutes;
    final int validMinutes = requestedMinutes < 1 ? suggestedMinutes : requestedMinutes;

    if (shouldStart == true && mounted) {
      setState(() {
        if (finishedWork) {
          _breakDurationMinutes = validMinutes;
          _timer.isWorkSession = false;
          _timer.remainingSeconds = _breakDurationMinutes * 60;
        } else {
          _workDurationMinutes = validMinutes;
          _timer.isWorkSession = true;
          _timer.remainingSeconds = _workDurationMinutes * 60;
        }
        _timer.isRunning = true;
      });
    }

    _isPomodoroPromptOpen = false;
  }

  void _tickBreakReminder() {
    final UserModel? user = _currentUser;
    if (user == null ||
        user.notificationMode == NotificationMode.ninguna ||
        !mounted) {
      return;
    }
    _secondsSinceBreakReminder += 1;
    if (_secondsSinceBreakReminder >= 60 * 60) {
      setState(() {
        _timer.showBreakReminder = true;
        _secondsSinceBreakReminder = 0;
      });
    }
  }

  String _formatSeconds(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _intensityName(SensoryIntensity intensity) {
    return switch (intensity) {
      SensoryIntensity.baja => 'Baja',
      SensoryIntensity.media => 'Media',
      SensoryIntensity.alta => 'Alta',
    };
  }

  String _themePaletteLabel(ThemePalette palette) {
    return switch (palette) {
      ThemePalette.suave => 'Suave',
      ThemePalette.neon => 'Neón',
      ThemePalette.rosaOscuro => 'Rosa oscuro',
      ThemePalette.verde => 'Verde',
      ThemePalette.clara => 'Claro',
    };
  }

  String _fontPreferenceLabel(FontPreference font) {
    return switch (font) {
      FontPreference.sistema => 'Sistema',
      FontPreference.legible => 'Legible',
      FontPreference.serif => 'Serif',
      FontPreference.monoespaciada => 'Monoespaciada',
    };
  }

  Future<void> _openFirebaseInspector() async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _loadFirebaseInspectorData(),
              builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        'Error al consultar Firebase: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final Map<String, dynamic> data = snapshot.data ?? <String, dynamic>{};
                final bool seeded = data['seeded'] as bool? ?? false;
                final List<String> users = (data['users'] as List<String>? ?? <String>[]);
                final List<String> games = (data['games'] as List<String>? ?? <String>[]);
                final List<String> posts = (data['posts'] as List<String>? ?? <String>[]);

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Estado Firebase',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(seeded ? 'Seed detectado: SI' : 'Seed detectado: NO'),
                      const SizedBox(height: 12),
                      Text(
                        'Usuarios',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(users.isEmpty ? 'Sin datos' : users.join('\n')),
                      const SizedBox(height: 12),
                      Text(
                        'Juegos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(games.isEmpty ? 'Sin datos' : games.join('\n')),
                      const SizedBox(height: 12),
                      Text(
                        'Posts',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(posts.isEmpty ? 'Sin datos' : posts.join('\n')),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadFirebaseInspectorData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentSnapshot<Map<String, dynamic>> seed =
        await firestore.collection('_meta').doc('seed_v1').get();
    final QuerySnapshot<Map<String, dynamic>> usersSnap =
        await firestore.collection('users').limit(5).get();
    final QuerySnapshot<Map<String, dynamic>> gamesSnap =
        await firestore.collection('games').limit(5).get();
    final QuerySnapshot<Map<String, dynamic>> postsSnap =
        await firestore.collection('posts').limit(5).get();

    return <String, dynamic>{
      'seeded': seed.exists,
      'users': usersSnap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final String email = (doc.data()['email'] as String?) ?? doc.id;
            final String name = (doc.data()['displayName'] as String?) ?? 'Sin nombre';
            return '- $name ($email)';
          })
          .toList(),
      'games': gamesSnap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final String name = (doc.data()['name'] as String?) ?? doc.id;
            final String genre = (doc.data()['genre'] as String?) ?? 'Sin genero';
            return '- $name [$genre]';
          })
          .toList(),
      'posts': postsSnap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final String title = (doc.data()['title'] as String?) ?? doc.id;
            return '- $title';
          })
          .toList(),
    };
  }

  void _recordSearchQuery(String rawValue) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

    final String query = rawValue.trim();
    if (query.length < 2) {
      return;
    }

    final List<String> history =
        _searchHistoryByUser.putIfAbsent(user.id, () => <String>[]);
    history.removeWhere(
      (String value) => value.toLowerCase() == query.toLowerCase(),
    );
    history.insert(0, query);
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    _persistSearchHistory(user.id);
  }

  void _persistSearchHistory(int userId) {
    if (_prefs == null) {
      return;
    }
    final List<String> history = _searchHistoryByUser[userId] ?? <String>[];
    _prefs!.setString('search_history_user_$userId', jsonEncode(history));
  }

  void _restoreSearchHistoryFromPrefs(int userId) {
    if (_prefs == null) {
      return;
    }

    final String? raw = _prefs!.getString('search_history_user_$userId');
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final List<String> decoded = (jsonDecode(raw) as List<dynamic>)
          .whereType<String>()
          .map((String value) => value.trim())
          .where((String value) => value.isNotEmpty)
          .take(20)
          .toList();
      _searchHistoryByUser[userId] = decoded;
    } catch (_) {
      _searchHistoryByUser[userId] = <String>[];
    }
  }

  void _persistDailyMissionState(int userId) {
    if (_prefs == null) {
      return;
    }

    final DateTime day = _dailyMissionDateByUser[userId] ?? DateTime.now();
    final List<String> completedTypes = (_tasksByUser[userId] ?? <TaskModel>[])
        .where((TaskModel task) => task.isDone)
        .map((TaskModel task) => task.type.name)
        .toList();

    _prefs!.setString(
      'daily_missions_user_$userId',
      jsonEncode(<String, dynamic>{
        'dayKey': _formatDayKey(day),
        'completedTypes': completedTypes,
      }),
    );
  }

  void _restoreDailyMissionsFromPrefs(int userId) {
    if (_prefs == null) {
      return;
    }

    final String? raw = _prefs!.getString('daily_missions_user_$userId');
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      final String dayKey = (decoded['dayKey'] as String?) ?? '';
      final String todayKey = _formatDayKey(DateTime.now());

      if (dayKey != todayKey) {
        return;
      }

      _tasksByUser.putIfAbsent(userId, _buildDailyMissions);
      final Set<String> completed =
          (decoded['completedTypes'] as List<dynamic>? ?? <dynamic>[])
              .whereType<String>()
              .toSet();

      final List<TaskModel> tasks = _tasksByUser[userId] ?? <TaskModel>[];
      for (final TaskModel task in tasks) {
        task.isDone = completed.contains(task.type.name);
      }

      final DateTime now = DateTime.now();
      _dailyMissionDateByUser[userId] = DateTime(now.year, now.month, now.day);
    } catch (_) {
      // Ignore invalid local mission state.
    }
  }

  String _formatDayKey(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _saveUserPreferences(UserModel user) {
    if (_prefs == null) {
      return;
    }
    final String userJson = jsonEncode(user.toJson());
    _prefs!.setString('last_user_prefs', userJson);
  }

  // Método reservado para futuras cargas automáticas de preferencias
  // Future<UserModel?> _loadUserPreferences() async {
  //   final String? userJson = _prefs.getString('last_user_prefs');
  //   if (userJson == null) {
  //     return null;
  //   }
  //   try {
  //     final Map<String, dynamic> decoded = jsonDecode(userJson) as Map<String, dynamic>;
  //     return UserModel.fromJson(decoded);
  //   } catch (e) {
  //     return null;
  //   }
  // }
}
