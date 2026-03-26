import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const SyncroApp());
}

enum MainTab { perfil, buscar, tienda, opciones, chat, misJuegos }

enum AccessibilityMode { tea, tdah }

enum SensoryIntensity { baja, media, alta }

enum NotificationMode { importantes, todas, ninguna }

class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.displayName,
    this.avatar = '🎮',
    this.accessibilityMode = AccessibilityMode.tea,
    this.softColors = true,
    this.noAnimations = false,
    this.legibleFont = false,
    this.notificationMode = NotificationMode.importantes,
  });

  final int id;
  final String email;
  final String password;
  final String displayName;
  final String avatar;
  final AccessibilityMode accessibilityMode;
  final bool softColors;
  final bool noAnimations;
  final bool legibleFont;
  final NotificationMode notificationMode;

  UserModel copyWith({
    AccessibilityMode? accessibilityMode,
    bool? softColors,
    bool? noAnimations,
    bool? legibleFont,
    NotificationMode? notificationMode,
  }) {
    return UserModel(
      id: id,
      email: email,
      password: password,
      displayName: displayName,
      avatar: avatar,
      accessibilityMode: accessibilityMode ?? this.accessibilityMode,
      softColors: softColors ?? this.softColors,
      noAnimations: noAnimations ?? this.noAnimations,
      legibleFont: legibleFont ?? this.legibleFont,
      notificationMode: notificationMode ?? this.notificationMode,
    );
  }
}

class GameModel {
  GameModel({
    required this.id,
    required this.name,
    required this.genre,
    required this.sensoryIntensity,
    required this.description,
  });

  final int id;
  final String name;
  final String genre;
  final SensoryIntensity sensoryIntensity;
  final String description;
}

class PostModel {
  PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.likes = 0,
    List<String>? comments,
    Set<int>? likedBy,
  })  : comments = comments ?? <String>[],
        likedBy = likedBy ?? <int>{};

  final int id;
  final String title;
  final String content;
  int likes;
  final List<String> comments;
  final Set<int> likedBy;
}

class TaskModel {
  TaskModel({required this.id, required this.title, required this.type, this.isDone = false});

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
  });

  final int id;
  final String gameName;
  final String cosmeticName;
  final int price;
}

class LibraryGameUi {
  LibraryGameUi({
    required this.game,
    required this.isFavorite,
    required this.isPlayingNow,
    required this.recommendationTag,
  });

  final GameModel game;
  final bool isFavorite;
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
      darkTheme: _buildTheme(softColors: true, legibleFont: false),
      home: const SyncroRoot(),
    );
  }

  ThemeData _buildTheme({required bool softColors, required bool legibleFont}) {
    final ColorScheme scheme = softColors
        ? const ColorScheme.dark(
            primary: Color(0xFF40F9FF),
            onPrimary: Color(0xFF001014),
            secondary: Color(0xFFB388FF),
            tertiary: Color(0xFFFF5CF2),
            surface: Color(0xFF151024),
            surfaceContainerHighest: Color(0xFF1D1630),
            onSurfaceVariant: Color(0xFFE5D9FF),
          )
        : const ColorScheme.dark(
            primary: Color(0xFF00F5FF),
            onPrimary: Color(0xFF001316),
            secondary: Color(0xFF9D4DFF),
            tertiary: Color(0xFFFF2CF0),
            surface: Color(0xFF11091D),
            surfaceContainerHighest: Color(0xFF1A1230),
            onSurfaceVariant: Color(0xFFE9DBFF),
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF090411),
      textTheme: ThemeData.dark(useMaterial3: true).textTheme.apply(
            fontFamily: legibleFont ? 'Roboto' : null,
          ),
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

  UserModel? _currentUser;
  MainTab _activeTab = MainTab.perfil;
  String _searchQuery = '';
  SensoryIntensity? _selectedIntensity;
  final TimerUiState _timer = TimerUiState();

  final List<UserModel> _users = <UserModel>[];
  final List<GameModel> _games = <GameModel>[];
  final List<PostModel> _posts = <PostModel>[];
  final List<String> _groups = <String>[];
  final Map<int, Map<int, bool>> _favoriteByUser = <int, Map<int, bool>>{};
  final Map<int, Map<int, bool>> _playingByUser = <int, Map<int, bool>>{};
  final Map<int, List<TaskModel>> _tasksByUser = <int, List<TaskModel>>{};
  final Map<int, int> _coinsByUser = <int, int>{};
  final Map<int, DateTime> _dailyMissionDateByUser = <int, DateTime>{};
  final Map<int, Set<int>> _ownedCosmeticsByUser = <int, Set<int>>{};
  int _taskIdCounter = 1;
  int _secondsSinceBreakReminder = 0;
  Timer? _ticker;

  final List<CosmeticItemModel> _shopItems = <CosmeticItemModel>[
    CosmeticItemModel(id: 1, gameName: 'Minecraft', cosmeticName: 'Skin Neon Creeper', price: 40),
    CosmeticItemModel(id: 2, gameName: 'Valorant', cosmeticName: 'Spray Syncro Core', price: 30),
    CosmeticItemModel(id: 3, gameName: 'Rocket League', cosmeticName: 'Ruedas Aurora', price: 35),
    CosmeticItemModel(id: 4, gameName: 'Stardew Valley', cosmeticName: 'Sombrero Pixel Flor', price: 20),
    CosmeticItemModel(id: 5, gameName: 'Fortnite', cosmeticName: 'Mochila Holográfica', price: 45),
    CosmeticItemModel(id: 6, gameName: 'League of Legends', cosmeticName: 'Icono Emblema Syncro', price: 25),
  ];

  final List<Map<String, String>> _friends = const <Map<String, String>>[
    {'name': 'Alex', 'status': 'En linea', 'avatar': '🕹️'},
    {'name': 'Nora', 'status': 'Jugando Valorant', 'avatar': '🎯'},
    {'name': 'Dani', 'status': 'Ausente', 'avatar': '🐉'},
    {'name': 'Maya', 'status': 'En Stardew Valley', 'avatar': '🌱'},
    {'name': 'Leo', 'status': 'En linea', 'avatar': '⚔️'},
  ];

  final List<Map<String, String>> _news = const <Map<String, String>>[
    {
      'title': 'Nuevo parche competitivo mejora el matchmaking',
      'source': 'Syncro News',
      'summary': 'Ajustes de emparejamiento y menor latencia en partidas igualadas.'
    },
    {
      'title': 'Tendencia 2026: mas juegos con modos accesibles',
      'source': 'Gaming Today',
      'summary': 'Mas estudios anaden presets cognitivos y controles de estimulos.'
    },
    {
      'title': 'Eventos cooperativos de primavera ya disponibles',
      'source': 'Gamer Hub',
      'summary': 'Misiones semanales en titulos co-op con recompensas cosmeticas.'
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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickTimer();
      _tickBreakReminder();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
      'Fortnite'
    ];
    final List<String> genres = <String>['RPG', 'Accion', 'Aventura', 'Estrategia', 'Shooter', 'Simulacion'];

    for (int id = 1; id <= 40; id++) {
      final SensoryIntensity intensity = switch (id % 3) {
        0 => SensoryIntensity.baja,
        1 => SensoryIntensity.media,
        _ => SensoryIntensity.alta,
      };
      _games.add(
        GameModel(
          id: id,
          name: id <= featured.length ? featured[id - 1] : 'Juego $id',
          genre: genres[id % genres.length],
          sensoryIntensity: intensity,
          description: 'Experiencia ${_intensityName(intensity).toLowerCase()} con enfoque accesible.',
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
        content: 'Usa ciclos de 25/5 y baja intensidad visual en menus con mucho movimiento.',
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
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = _currentUser;

    return AnimatedTheme(
      data: SyncroApp()._buildTheme(
        softColors: user?.softColors ?? true,
        legibleFont: user?.legibleFont ?? false,
      ),
      duration: const Duration(milliseconds: 250),
      child: user == null ? _buildAuthScreen() : _buildMainScreen(user),
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
            colors: <Color>[Color(0xFF07020F), Color(0xFF120A26), Color(0xFF090411)],
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
                    Text('SYNCRO', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 8),
                    Text(
                      'Plataforma gaming social con accesibilidad neurodivergente',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                      Text(_auth.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                        child: Text(_auth.isRegisterMode ? 'Crear cuenta' : 'Entrar'),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  Widget _buildMainScreen(UserModel user) {
    final List<LibraryGameUi> allLibraryGames = _buildLibraryGames(user, applyFilters: false);
    final List<LibraryGameUi> filteredLibraryGames = _buildLibraryGames(user, applyFilters: true);
    final List<LibraryGameUi> recentGames = _buildRecentGamesForUser(user);
    final List<LibraryGameUi> myGames = allLibraryGames.where((LibraryGameUi game) => game.isFavorite || game.isPlayingNow).toList();
    final List<String> favoriteNames = allLibraryGames.where((LibraryGameUi game) => game.isFavorite).take(3).map((LibraryGameUi game) => game.game.name).toList();
    final int coins = _coinsByUser[user.id] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Syncro', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            Text(user.displayName, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text('🪙 $coins  ·  ${_timer.isWorkSession ? 'Trabajo' : 'Descanso'}: ${_formatSeconds(_timer.remainingSeconds)}'),
            ),
          ),
          IconButton(
            onPressed: _startPausePomodoro,
            icon: Icon(_timer.isRunning ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _activeTab.index,
        onDestinationSelected: (int index) => setState(() => _activeTab = MainTab.values[index]),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Tienda'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Opciones'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.sports_esports), label: 'Mis Juegos'),
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
                  title: const Text('Recordatorio: toma un descanso de 5 minutos'),
                  trailing: TextButton(onPressed: _dismissBreakReminder, child: const Text('Hecho')),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: switch (_activeTab) {
                MainTab.perfil => _buildHomeScreen(user, recentGames),
                MainTab.buscar => _buildLibraryScreen(user, filteredLibraryGames),
                MainTab.tienda => _buildStoreScreen(user),
                MainTab.opciones => _buildOptionsScreen(user),
                MainTab.chat => _buildSocialScreen(user, favoriteNames),
                MainTab.misJuegos => _buildMyGamesScreen(myGames),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(UserModel user, List<LibraryGameUi> recentGames) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Bienvenido, ${user.displayName}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Tu centro gamer neon: juega, conecta y descubre novedades cada dia.'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    FilledButton(onPressed: () => setState(() => _activeTab = MainTab.buscar), child: const Text('Buscar juegos')),
                    OutlinedButton(onPressed: () => setState(() => _activeTab = MainTab.misJuegos), child: const Text('Mis juegos')),
                    OutlinedButton(onPressed: () => setState(() => _activeTab = MainTab.tienda), child: const Text('Ir a tienda')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Cuenta', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Puedes eliminar tu cuenta y todos tus datos locales de esta app.'),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _confirmDeleteAccount,
                  child: const Text('Borrar cuenta'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Ultimos juegos que has jugado', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 290,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          height: 82,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: <Color>[
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
                                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(gameUi.game.genre, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        const SizedBox(height: 8),
                        Text(gameUi.game.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('${gameUi.game.genre} - ${_intensityName(gameUi.game.sensoryIntensity).toLowerCase()}'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            if (gameUi.isPlayingNow) const Chip(label: Text('En guia')),
                            if (gameUi.isFavorite) const Chip(label: Text('Favorito')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            IconButton(
                              onPressed: () => _toggleFavorite(gameUi.game.id),
                              icon: Icon(gameUi.isFavorite ? Icons.favorite : Icons.favorite_border),
                            ),
                            FilledButton(
                              onPressed: () => _toggleGuideForGame(gameUi.game, focusSearchOnEnable: true),
                              child: Text(gameUi.isPlayingNow ? 'Quitar guia' : 'Ver guia'),
                            ),
                          ],
                        ),
                      ],
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
            itemCount: _friends.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, String> friend = _friends[index];
              return SizedBox(
                width: 190,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('${friend['avatar']} ${friend['name']}', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(friend['status'] ?? ''),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text('Noticias del mundo gamer', style: Theme.of(context).textTheme.titleMedium),
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
                    Text(item['title'] ?? '', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(item['summary'] ?? ''),
                    const SizedBox(height: 4),
                    Text(item['source'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        TextField(
          decoration: const InputDecoration(labelText: 'Buscar juego por nombre'),
          onChanged: (String value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: <Widget>[
            FilterChip(
              selected: _selectedIntensity == null,
              label: const Text('Todos'),
              onSelected: (_) => setState(() => _selectedIntensity = null),
            ),
            for (final SensoryIntensity intensity in SensoryIntensity.values)
              FilterChip(
                selected: _selectedIntensity == intensity,
                label: Text(_intensityName(intensity)),
                onSelected: (_) => setState(() => _selectedIntensity = intensity),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Catalogo: ${games.length} juegos'),
        const SizedBox(height: 8),
        ...games.map(
          (LibraryGameUi gameUi) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                title: Text(gameUi.game.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${gameUi.game.genre} - Intensidad ${_intensityName(gameUi.game.sensoryIntensity).toLowerCase()}'),
                    Text(gameUi.game.description),
                    if (gameUi.recommendationTag != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Chip(label: Text(gameUi.recommendationTag!)),
                      ),
                  ],
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: <Widget>[
                    IconButton(
                      onPressed: () => _toggleFavorite(gameUi.game.id),
                      icon: Icon(gameUi.isFavorite ? Icons.favorite : Icons.favorite_border),
                    ),
                    IconButton(
                      onPressed: () => _toggleGuideForGame(gameUi.game, focusSearchOnEnable: true),
                      icon: Icon(gameUi.isPlayingNow ? Icons.bookmark_remove : Icons.menu_book),
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

  Widget _buildMyGamesScreen(List<LibraryGameUi> games) {
    final List<LibraryGameUi> sortedGames = List<LibraryGameUi>.from(games)
      ..sort((LibraryGameUi a, LibraryGameUi b) => (b.isPlayingNow ? 1 : 0).compareTo(a.isPlayingNow ? 1 : 0));

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        Text('Mis Juegos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (sortedGames.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Todavia no has marcado juegos.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => setState(() => _activeTab = MainTab.buscar),
                    child: const Text('Ir a Buscar'),
                  ),
                ],
              ),
            ),
          )
        else
          ...sortedGames.map(
            (LibraryGameUi gameUi) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  title: Text(gameUi.game.name),
                  subtitle: Text('${gameUi.game.genre} - ${_intensityName(gameUi.game.sensoryIntensity).toLowerCase()}'),
                  trailing: Wrap(
                    spacing: 4,
                    children: <Widget>[
                      IconButton(
                        onPressed: () => _toggleFavorite(gameUi.game.id),
                        icon: Icon(gameUi.isFavorite ? Icons.favorite : Icons.favorite_border),
                      ),
                      IconButton(
                        onPressed: () => _toggleGuideForGame(gameUi.game, focusSearchOnEnable: true),
                        icon: Icon(gameUi.isPlayingNow ? Icons.bookmark_remove : Icons.menu_book),
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

  Widget _buildOptionsScreen(UserModel user) {
    final List<TaskModel> tasks = _tasksByUser[user.id] ?? <TaskModel>[];
    final int coins = _coinsByUser[user.id] ?? 0;

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Pomodoro', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_formatSeconds(_timer.remainingSeconds), style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(_timer.isWorkSession ? 'Sesion de foco' : 'Sesion de descanso'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    FilledButton(onPressed: _startPausePomodoro, child: Text(_timer.isRunning ? 'Pausar' : 'Iniciar')),
                    OutlinedButton(onPressed: _resetPomodoro, child: const Text('Reiniciar')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Misiones diarias', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Completa una misión para ganar 10 monedas Syncro. Saldo actual: $coins'),
                const SizedBox(height: 8),
                ...tasks.map(
                  (TaskModel task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: <Widget>[
                            Icon(task.isDone ? Icons.check_circle : Icons.radio_button_unchecked),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(task.title),
                                  Text(
                                    task.isDone
                                        ? 'Completada'
                                        : 'Se completa automáticamente al realizar la acción',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: task.isDone ? null : () => _goToMissionAction(task.type),
                              child: Text(_missionActionLabel(task.type)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Icon(Icons.refresh),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Las misiones se renuevan cada día automáticamente al entrar en tu cuenta.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Perfil de accesibilidad', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    FilterChip(
                      selected: user.accessibilityMode == AccessibilityMode.tea,
                      onSelected: (_) => _updateCurrentUser((UserModel base) => base.copyWith(accessibilityMode: AccessibilityMode.tea)),
                      label: const Text('Modo TEA'),
                    ),
                    FilterChip(
                      selected: user.accessibilityMode == AccessibilityMode.tdah,
                      onSelected: (_) => _updateCurrentUser((UserModel base) => base.copyWith(accessibilityMode: AccessibilityMode.tdah)),
                      label: const Text('Modo TDAH'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Ajustes visuales', style: Theme.of(context).textTheme.titleMedium),
                SwitchListTile(
                  value: user.softColors,
                  title: const Text('Colores suaves'),
                  onChanged: (bool value) => _updateCurrentUser((UserModel base) => base.copyWith(softColors: value)),
                ),
                SwitchListTile(
                  value: user.noAnimations,
                  title: const Text('Sin animaciones'),
                  onChanged: (bool value) => _updateCurrentUser((UserModel base) => base.copyWith(noAnimations: value)),
                ),
                SwitchListTile(
                  value: user.legibleFont,
                  title: const Text('Fuente legible'),
                  onChanged: (bool value) => _updateCurrentUser((UserModel base) => base.copyWith(legibleFont: value)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Notificaciones', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    FilterChip(
                      selected: user.notificationMode == NotificationMode.importantes,
                      onSelected: (_) => _updateCurrentUser((UserModel base) => base.copyWith(notificationMode: NotificationMode.importantes)),
                      label: const Text('Importantes'),
                    ),
                    FilterChip(
                      selected: user.notificationMode == NotificationMode.todas,
                      onSelected: (_) => _updateCurrentUser((UserModel base) => base.copyWith(notificationMode: NotificationMode.todas)),
                      label: const Text('Todas'),
                    ),
                    FilterChip(
                      selected: user.notificationMode == NotificationMode.ninguna,
                      onSelected: (_) => _updateCurrentUser((UserModel base) => base.copyWith(notificationMode: NotificationMode.ninguna)),
                      label: const Text('Ninguna'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _logout,
          child: const Text('Cerrar sesion'),
        ),
      ],
    );
  }

  Widget _buildStoreScreen(UserModel user) {
    final int coins = _coinsByUser[user.id] ?? 0;
    final Set<int> owned = _ownedCosmeticsByUser[user.id] ?? <int>{};

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Tienda de cosméticos', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('Saldo disponible: 🪙 $coins monedas Syncro'),
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
              child: ListTile(
                title: Text(item.cosmeticName),
                subtitle: Text('${item.gameName} · Precio: ${item.price} monedas'),
                trailing: isOwned
                    ? const Chip(label: Text('Comprado'))
                    : FilledButton(
                        onPressed: canBuy ? () => _buyCosmetic(item) : null,
                        child: const Text('Comprar'),
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSocialScreen(UserModel user, List<String> favoriteGames) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Perfil publico', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('Avatar: ${user.avatar}'),
                Text('Nombre: ${user.displayName}'),
                Text('Juegos favoritos: ${favoriteGames.isEmpty ? 'Sin favoritos aun' : favoriteGames.join(', ')}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Grupos tematicos (solo lectura)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                ..._groups.map((String group) => Text('- $group')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ..._posts.map(
          (PostModel post) {
            final bool liked = post.likedBy.contains(user.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(post.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(post.content),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () => _toggleLike(post.id),
                            icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
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
                                onPressed: () => _addTemplateComment(post.id, template),
                              ),
                            )
                            .toList(),
                      ),
                      if (post.comments.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        ...post.comments.map((String comment) => Text('- $comment')),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<LibraryGameUi> _buildLibraryGames(UserModel user, {required bool applyFilters}) {
    final Map<int, bool> favorites = _favoriteByUser[user.id] ?? <int, bool>{};
    final Map<int, bool> playing = _playingByUser[user.id] ?? <int, bool>{};

    return _games
        .where((GameModel game) {
          final bool queryMatch = !applyFilters || _searchQuery.trim().isEmpty || game.name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
          final bool intensityMatch = !applyFilters || _selectedIntensity == null || game.sensoryIntensity == _selectedIntensity;
          return queryMatch && intensityMatch;
        })
        .map((GameModel game) {
          final String? recommendationTag = switch (user.accessibilityMode) {
            AccessibilityMode.tea => game.sensoryIntensity == SensoryIntensity.baja ? 'Recomendado TEA' : null,
            AccessibilityMode.tdah => game.sensoryIntensity != SensoryIntensity.baja ? 'Recomendado TDAH' : null,
          };
          return LibraryGameUi(
            game: game,
            isFavorite: favorites[game.id] == true,
            isPlayingNow: playing[game.id] == true,
            recommendationTag: recommendationTag,
          );
        })
        .toList();
  }

  List<LibraryGameUi> _buildRecentGamesForUser(UserModel user) {
    final Map<int, bool> favorites = _favoriteByUser[user.id] ?? <int, bool>{};
    final Map<int, bool> playing = _playingByUser[user.id] ?? <int, bool>{};

    final List<(int, LibraryGameUi)> indexedGames = _games.asMap().entries.map((MapEntry<int, GameModel> entry) {
      final GameModel game = entry.value;
      return (
        entry.key,
        LibraryGameUi(
          game: game,
          isFavorite: favorites[game.id] == true,
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

    return indexedGames.take(12).map(((int, LibraryGameUi) item) => item.$2).toList();
  }

  void _submitAuth() {
    setState(() {
      _auth.isLoading = true;
      _auth.errorMessage = null;
    });

    Future<void>.delayed(const Duration(milliseconds: 300), () {
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
            _auth.errorMessage = 'Introduce email/usuario y una contrasena de minimo 6 caracteres';
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
          id: _users.length + 1,
          email: email,
          password: password,
          displayName: displayName.isEmpty ? email.split('@').first : displayName,
        );
        _users.add(user);
        _ensureDefaultTasks(user.id);
        _ensureDailyMissionState(user.id);
        _ensureUserEconomy(user.id);
        _enterWithUser(user);
      } else {
        final UserModel? user = _users.where((UserModel u) => u.email == email).cast<UserModel?>().firstWhere(
              (UserModel? u) => u != null,
              orElse: () => null,
            );
        if (user == null) {
          setState(() {
            _auth.isLoading = false;
            _auth.errorMessage = 'Usuario no encontrado. Crea una cuenta primero';
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
        _enterWithUser(user);
      }
    });
  }

  void _loginDemo() {
    final UserModel user = _users.firstWhere((UserModel u) => u.email == 'demo');
    _ensureDefaultTasks(user.id);
    _ensureDailyMissionState(user.id);
    _ensureUserEconomy(user.id);
    _enterWithUser(user);
  }

  void _enterWithUser(UserModel user) {
    setState(() {
      _currentUser = user;
      _auth.isLoading = false;
      _auth.errorMessage = null;
      _auth.email = '';
      _auth.password = '';
      _auth.displayName = '';
      _auth.isRegisterMode = false;
    });
  }

  void _logout() {
    setState(() {
      _currentUser = null;
      _activeTab = MainTab.perfil;
      _searchQuery = '';
      _selectedIntensity = null;
      _timer.remainingSeconds = 25 * 60;
      _timer.isRunning = false;
      _timer.isWorkSession = true;
      _timer.showBreakReminder = false;
      _secondsSinceBreakReminder = 0;
    });
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
          content: const Text('Esta acción eliminará tu cuenta, misiones, monedas y cosméticos guardados localmente. ¿Continuar?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton.tonal(onPressed: () => Navigator.of(context).pop(true), child: const Text('Borrar')),
          ],
        );
      },
    );

    if (accepted != true || !mounted) {
      return;
    }

    final int userId = current.id;
    setState(() {
      _users.removeWhere((UserModel user) => user.id == userId);
      _favoriteByUser.remove(userId);
      _playingByUser.remove(userId);
      _tasksByUser.remove(userId);
      _coinsByUser.remove(userId);
      _dailyMissionDateByUser.remove(userId);
      _ownedCosmeticsByUser.remove(userId);
      _currentUser = null;
      _activeTab = MainTab.perfil;
      _searchQuery = '';
      _selectedIntensity = null;
      _timer.remainingSeconds = 25 * 60;
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Misión completada: +10 monedas Syncro')),
    );
  }

  String _missionActionLabel(DailyMissionType type) {
    return switch (type) {
      DailyMissionType.readGuide => 'Ir a Buscar',
      DailyMissionType.favoriteGame => 'Ir a Buscar',
      DailyMissionType.consciousBreak => 'Ver Pomodoro',
    };
  }

  void _goToMissionAction(DailyMissionType type) {
    setState(() {
      switch (type) {
        case DailyMissionType.readGuide:
          _activeTab = MainTab.buscar;
          break;
        case DailyMissionType.favoriteGame:
          _activeTab = MainTab.buscar;
          break;
        case DailyMissionType.consciousBreak:
          _activeTab = MainTab.opciones;
          break;
      }
    });

    final String message = switch (type) {
      DailyMissionType.readGuide => 'Pulsa "Ver guía" en cualquier juego para completar esta misión.',
      DailyMissionType.favoriteGame => 'Marca un juego con el icono de favorito para completar esta misión.',
      DailyMissionType.consciousBreak => 'Completa un descanso y pulsa "Hecho" en el recordatorio para finalizarla.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  void _buyCosmetic(CosmeticItemModel item) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

    final int coins = _coinsByUser[user.id] ?? 0;
    final Set<int> owned = _ownedCosmeticsByUser.putIfAbsent(user.id, () => <int>{});
    if (owned.contains(item.id) || coins < item.price) {
      return;
    }

    setState(() {
      _coinsByUser[user.id] = coins - item.price;
      owned.add(item.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Has comprado ${item.cosmeticName}')),
    );
  }

  void _toggleFavorite(int gameId) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }
    final Map<int, bool> favorites = _favoriteByUser.putIfAbsent(user.id, () => <int, bool>{});
    setState(() {
      favorites[gameId] = !(favorites[gameId] ?? false);
    });
    if (favorites[gameId] == true) {
      _completeMissionForCurrentUser(DailyMissionType.favoriteGame);
    }
  }

  void _toggleGuideForGame(GameModel game, {bool focusSearchOnEnable = false}) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }
    final Map<int, bool> playing = _playingByUser.putIfAbsent(user.id, () => <int, bool>{});
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
          _searchQuery = game.name;
          _selectedIntensity = game.sensoryIntensity;
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
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime? savedDate = _dailyMissionDateByUser[userId];
    if (savedDate == null || !_isSameDay(savedDate, today)) {
      _tasksByUser[userId] = _buildDailyMissions();
      _dailyMissionDateByUser[userId] = today;
    }
  }

  void _ensureUserEconomy(int userId) {
    _coinsByUser.putIfAbsent(userId, () => 0);
    _ownedCosmeticsByUser.putIfAbsent(userId, () => <int>{});
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
    final int index = _users.indexWhere((UserModel item) => item.id == current.id);
    if (index == -1) {
      return;
    }
    final UserModel updated = transform(current);
    setState(() {
      _users[index] = updated;
      _currentUser = updated;
    });
  }

  void _startPausePomodoro() {
    setState(() {
      _timer.isRunning = !_timer.isRunning;
    });
  }

  void _resetPomodoro() {
    setState(() {
      _timer.remainingSeconds = _timer.isWorkSession ? 25 * 60 : 5 * 60;
      _timer.isRunning = false;
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
    if (!_timer.isRunning || !mounted) {
      return;
    }

    setState(() {
      final int next = _timer.remainingSeconds - 1;
      if (next <= 0) {
        _timer.isWorkSession = !_timer.isWorkSession;
        _timer.remainingSeconds = _timer.isWorkSession ? 25 * 60 : 5 * 60;
      } else {
        _timer.remainingSeconds = next;
      }
    });
  }

  void _tickBreakReminder() {
    final UserModel? user = _currentUser;
    if (user == null || user.notificationMode == NotificationMode.ninguna || !mounted) {
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
}
