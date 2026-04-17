import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
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

enum SensoryIntensity { baja, media, alta }

enum NotificationMode { importantes, todas, ninguna }

enum ThemePalette { suave, neon, rosaOscuro, verde, clara }

enum FontPreference { sistema, legible, serif, monoespaciada }

enum ProfileGamesView { favoritos, proximos }

enum SearchScope { todo, juegos, usuarios, guias }

class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.displayName,
    this.avatar = '🎮',
    this.avatarBytes,
    this.profileStatus = 'En línea',
    this.fontScale = 1.0,
    this.accessibilityMode = AccessibilityMode.tea,
    this.softColors = true,
    this.noAnimations = false,
    this.legibleFont = false,
    this.themePalette = ThemePalette.suave,
    this.fontPreference = FontPreference.sistema,
    this.notificationMode = NotificationMode.importantes,
  });

  final int id;
  final String email;
  final String password;
  final String displayName;
  final String avatar;
  final Uint8List? avatarBytes;
  final String profileStatus;
  final double fontScale;
  final AccessibilityMode accessibilityMode;
  final bool softColors;
  final bool noAnimations;
  final bool legibleFont;
  final ThemePalette themePalette;
  final FontPreference fontPreference;
  final NotificationMode notificationMode;

  UserModel copyWith({
    String? displayName,
    String? avatar,
    Uint8List? avatarBytes,
    bool clearAvatarBytes = false,
    String? profileStatus,
    double? fontScale,
    AccessibilityMode? accessibilityMode,
    bool? softColors,
    bool? noAnimations,
    bool? legibleFont,
    ThemePalette? themePalette,
    FontPreference? fontPreference,
    NotificationMode? notificationMode,
  }) {
    return UserModel(
      id: id,
      email: email,
      password: password,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      avatarBytes: clearAvatarBytes ? null : (avatarBytes ?? this.avatarBytes),
      profileStatus: profileStatus ?? this.profileStatus,
      fontScale: fontScale ?? this.fontScale,
      accessibilityMode: accessibilityMode ?? this.accessibilityMode,
      softColors: softColors ?? this.softColors,
      noAnimations: noAnimations ?? this.noAnimations,
      legibleFont: legibleFont ?? this.legibleFont,
      themePalette: themePalette ?? this.themePalette,
      fontPreference: fontPreference ?? this.fontPreference,
      notificationMode: notificationMode ?? this.notificationMode,
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
      'fontScale': fontScale,
      'accessibilityMode': accessibilityMode.name,
      'softColors': softColors,
      'noAnimations': noAnimations,
      'legibleFont': legibleFont,
      'themePalette': themePalette.name,
      'fontPreference': fontPreference.name,
      'notificationMode': notificationMode.name,
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
  });

  final int id;
  final String name;
  final String genre;
  final String imageUrl;
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
      home: const SyncroSplashGate(),
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

class SyncroSplashGate extends StatefulWidget {
  const SyncroSplashGate({super.key});

  @override
  State<SyncroSplashGate> createState() => _SyncroSplashGateState();
}

class _SyncroSplashGateState extends State<SyncroSplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final AudioPlayer _splashAudio;
  bool _showMain = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _splashAudio = AudioPlayer()..setVolume(0.22);
    _playSplashSound();
    _goToMain();
  }

  Future<void> _playSplashSound() async {
    try {
      await _splashAudio.play(AssetSource('audio/syncro_open.wav'));
    } catch (_) {
      // Ignore audio failures to avoid blocking splash flow on unsupported devices.
    }
  }

  Future<void> _goToMain() async {
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) {
      return;
    }
    setState(() {
      _showMain = true;
    });
  }

  @override
  void dispose() {
    _splashAudio.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(animation),
            child: child,
          ),
        );
      },
      child: _showMain
          ? const SyncroRoot(key: ValueKey<String>('main'))
          : _SyncroOpeningSplash(
              key: const ValueKey<String>('splash'),
              animation: _controller,
            ),
    );
  }
}

class _SyncroOpeningSplash extends StatelessWidget {
  const _SyncroOpeningSplash({
    super.key,
    required this.animation,
  });

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final Animation<double> logoScale = Tween<double>(
      begin: 0.74,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.05, 0.55, curve: Curves.easeOutBack),
      ),
    );
    final Animation<double> logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    final Animation<double> subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );
    final Animation<double> pulse = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.45, 1.0, curve: Curves.linear),
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF05010A),
              Color(0xFF110726),
              Color(0xFF1B0A33),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -120,
              left: -90,
              child: _GlowBlob(
                size: 290,
                color: const Color(0x553CD8FF),
                animation: animation,
              ),
            ),
            Positioned(
              bottom: -140,
              right: -70,
              child: _GlowBlob(
                size: 330,
                color: const Color(0x66FF4AC2),
                animation: animation,
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  return Transform.scale(
                    scale: logoScale.value * pulse.value,
                    child: Opacity(
                      opacity: logoFade.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: const Color(0x33FFFFFF),
                        border: Border.all(color: const Color(0x66FFFFFF)),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x6637EEFF),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _SyncroCatGamepadLogo(
                        size: 92,
                        animation: animation,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SYNCRO',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: subtitleFade,
                      child: Text(
                        'Conectando partidas con calma y foco',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFD4C7F2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncroCatGamepadLogo extends StatelessWidget {
  const _SyncroCatGamepadLogo({
    required this.size,
    required this.animation,
  });

  final double size;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, _) {
        final double bob = sin(animation.value * pi * 6) * 1.6;
        final double earWiggle = sin(animation.value * pi * 8) * 0.08;
        final double tailWag = sin(animation.value * pi * 5) * 0.10;
        final bool blink = animation.value > 0.78 && animation.value < 0.84;

        return Transform.translate(
          offset: Offset(0, bob),
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CatMascotPainter(
                blink: blink,
                earWiggle: earWiggle,
                tailWag: tailWag,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CatMascotPainter extends CustomPainter {
  _CatMascotPainter({
    required this.blink,
    required this.earWiggle,
    required this.tailWag,
  });

  final bool blink;
  final double earWiggle;
  final double tailWag;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2 + 2);

    void drawEar({required double dx, required bool left}) {
      final Paint earPaint = Paint()..color = const Color(0xFFFDF8FF);
      final Paint earStroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFE8DEF7);
      final Paint innerPaint = Paint()..color = const Color(0xFFF1D9E4);

      final Path ear = Path()
        ..moveTo(center.dx + dx, center.dy - 52)
        ..quadraticBezierTo(
          center.dx + dx + (left ? -11 : 11),
          center.dy - 31,
          center.dx + dx + (left ? -2 : 2),
          center.dy - 18,
        )
        ..quadraticBezierTo(
          center.dx + dx + (left ? 10 : -10),
          center.dy - 30,
          center.dx + dx,
          center.dy - 52,
        )
        ..close();

      final Path inner = Path()
        ..moveTo(center.dx + dx, center.dy - 46)
        ..quadraticBezierTo(
          center.dx + dx + (left ? -7 : 7),
          center.dy - 32,
          center.dx + dx + (left ? -1 : 1),
          center.dy - 24,
        )
        ..quadraticBezierTo(
          center.dx + dx + (left ? 5 : -5),
          center.dy - 31,
          center.dx + dx,
          center.dy - 46,
        )
        ..close();

      canvas.save();
      canvas.translate(center.dx + dx, center.dy - 34);
      canvas.rotate(left ? (-0.42 + earWiggle) : (0.42 - earWiggle));
      canvas.translate(-(center.dx + dx), -(center.dy - 34));
      canvas.drawPath(ear, earPaint);
      canvas.drawPath(ear, earStroke);
      canvas.drawPath(inner, innerPaint);
      canvas.restore();
    }

    // Headset band.
    final Paint bandPaint = Paint()
      ..color = const Color(0xFF24172E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx, center.dy - 8), radius: 34),
      pi,
      pi,
      false,
      bandPaint,
    );

    // Earcups.
    final Paint earcupPaint = Paint()..color = const Color(0xFF3B2B4D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - 42, center.dy - 5), width: 18, height: 28),
        const Radius.circular(9),
      ),
      earcupPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 42, center.dy - 5), width: 18, height: 28),
        const Radius.circular(9),
      ),
      earcupPaint,
    );

    // Tail.
    final Paint tailPaint = Paint()
      ..color = const Color(0xFFF9F6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final Path tail = Path()
      ..moveTo(center.dx + 30, center.dy + 28)
      ..quadraticBezierTo(
        center.dx + 50 + tailWag * 18,
        center.dy + 16,
        center.dx + 42 + tailWag * 12,
        center.dy - 4,
      )
      ..quadraticBezierTo(center.dx + 30, center.dy + 4, center.dx + 28, center.dy + 18);
    canvas.drawPath(tail, tailPaint);

    // Head.
    final Rect headRect = Rect.fromCenter(center: Offset(center.dx, center.dy - 6), width: 72, height: 68);
    canvas.drawOval(headRect, Paint()..color = const Color(0xFFFDFBFF));
    canvas.drawOval(
      headRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFE8DFF4),
    );

    drawEar(dx: -24, left: true);
    drawEar(dx: 24, left: false);

    // Fur tufts.
    final Paint tuftPaint = Paint()..color = const Color(0xFFF5EFFA);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 30, center.dy - 20), width: 12, height: 10), tuftPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 30, center.dy - 20), width: 12, height: 10), tuftPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - 34), width: 10, height: 8), tuftPaint);

    // Eyes.
    final double eyeScale = blink ? 0.18 : 1.0;
    void drawEye(Offset p) {
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.scale(1.0, eyeScale);
      canvas.translate(-p.dx, -p.dy);
      canvas.drawOval(Rect.fromCenter(center: p, width: 16, height: 18), Paint()..color = const Color(0xFF3C2B47));
      canvas.drawOval(Rect.fromCenter(center: Offset(p.dx - 2, p.dy - 2), width: 5, height: 5), Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawOval(Rect.fromCenter(center: Offset(p.dx + 2, p.dy + 3), width: 2.2, height: 2.2), Paint()..color = const Color(0xFFE9D7F8));
      canvas.restore();
    }

    drawEye(Offset(center.dx - 16, center.dy - 2));
    drawEye(Offset(center.dx + 16, center.dy - 2));

    // Nose and mouth.
    final Path nose = Path()
      ..moveTo(center.dx, center.dy + 9)
      ..lineTo(center.dx - 3, center.dy + 13)
      ..lineTo(center.dx + 3, center.dy + 13)
      ..close();
    canvas.drawPath(nose, Paint()..color = const Color(0xFFF0A9BE));
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 13), width: 12, height: 8),
      0,
      pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF5A415A),
    );

    // Whiskers.
    final Paint whiskerPaint = Paint()
      ..color = const Color(0xFFCBBEDC)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 17, center.dy + 9), Offset(center.dx - 32, center.dy + 5), whiskerPaint);
    canvas.drawLine(Offset(center.dx - 17, center.dy + 13), Offset(center.dx - 31, center.dy + 13), whiskerPaint);
    canvas.drawLine(Offset(center.dx - 17, center.dy + 17), Offset(center.dx - 30, center.dy + 20), whiskerPaint);
    canvas.drawLine(Offset(center.dx + 17, center.dy + 9), Offset(center.dx + 32, center.dy + 5), whiskerPaint);
    canvas.drawLine(Offset(center.dx + 17, center.dy + 13), Offset(center.dx + 31, center.dy + 13), whiskerPaint);
    canvas.drawLine(Offset(center.dx + 17, center.dy + 17), Offset(center.dx + 30, center.dy + 20), whiskerPaint);

    // Paws.
    final Paint pawPaint = Paint()..color = const Color(0xFFF8F3FF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - 24, center.dy + 38), width: 14, height: 16),
        const Radius.circular(8),
      ),
      pawPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 24, center.dy + 38), width: 14, height: 16),
        const Radius.circular(8),
      ),
      pawPaint,
    );

    // Controller.
    final Rect padRect = Rect.fromCenter(center: Offset(center.dx, center.dy + 52), width: 82, height: 32);
    final Paint padPaint = Paint()..color = const Color(0xFF3C2B5E);
    canvas.drawRRect(RRect.fromRectAndRadius(padRect, const Radius.circular(16)), padPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(padRect, const Radius.circular(16)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF98F4FF),
    );

    final Paint dPadPaint = Paint()..color = const Color(0xFFEDE6FA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - 24, center.dy + 52), width: 14, height: 14),
        const Radius.circular(3),
      ),
      dPadPaint,
    );
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 24, center.dy + 52), width: 18, height: 4), dPadPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - 24, center.dy + 52), width: 4, height: 18), dPadPaint);

    final List<Color> buttonColors = <Color>[
      const Color(0xFF7CE9FF),
      const Color(0xFFFFA0C8),
      const Color(0xFFFFD06B),
      const Color(0xFF9DF56B),
    ];
    final List<Offset> buttonOffsets = <Offset>[
      Offset(center.dx + 20, center.dy + 45),
      Offset(center.dx + 28, center.dy + 52),
      Offset(center.dx + 20, center.dy + 59),
      Offset(center.dx + 12, center.dy + 52),
    ];
    for (int i = 0; i < buttonOffsets.length; i++) {
      canvas.drawCircle(buttonOffsets[i], 3.3, Paint()..color = buttonColors[i]);
    }

    canvas.drawCircle(Offset(center.dx - 5, center.dy + 52), 4.6, Paint()..color = const Color(0xFF1E1728));
    canvas.drawCircle(Offset(center.dx + 5, center.dy + 52), 4.6, Paint()..color = const Color(0xFF1E1728));
    canvas.drawCircle(Offset(center.dx - 5, center.dy + 52), 1.7, Paint()..color = const Color(0xFFBDEAFF));
    canvas.drawCircle(Offset(center.dx + 5, center.dy + 52), 1.7, Paint()..color = const Color(0xFFBDEAFF));

    final Paint micPaint = Paint()
      ..color = const Color(0xFF24172E)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx + 34, center.dy + 4), Offset(center.dx + 42, center.dy + 10), micPaint);
    canvas.drawCircle(Offset(center.dx + 45, center.dy + 12), 2.4, Paint()..color = const Color(0xFF24172E));
  }

  @override
  bool shouldRepaint(covariant _CatMascotPainter oldDelegate) {
    return blink != oldDelegate.blink ||
        earWiggle != oldDelegate.earWiggle ||
        tailWag != oldDelegate.tailWag;
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.color,
    required this.animation,
  });

  final double size;
  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, _) {
        final double opacity = 0.5 + (sin(animation.value * pi * 2) * 0.2);
        return Opacity(
          opacity: opacity.clamp(0.25, 0.8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color,
                  blurRadius: 70,
                  spreadRadius: 18,
                ),
              ],
            ),
          ),
        );
      },
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
  final List<CommunityGuideModel> _communityGuides = <CommunityGuideModel>[];
  final List<IgdbGameDto> _igdbResults = <IgdbGameDto>[];
  Timer? _igdbSearchDebounce;
  bool _isIgdbLoading = false;
  String? _igdbErrorMessage;
  String _lastIgdbQuery = '';
  int _taskIdCounter = 1;
  int _guideIdCounter = 1;
  int _secondsSinceBreakReminder = 0;
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
    _loadPreferences();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickTimer();
      _tickBreakReminder();
    });
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs != null) {
      final String? savedUserJson = _prefs!.getString('last_user_prefs');
      if (savedUserJson == null && !mounted) {
        return;
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _igdbSearchDebounce?.cancel();
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
    for (int id = 1; id <= 40; id++) {
      final SensoryIntensity intensity = switch (id % 3) {
        0 => SensoryIntensity.baja,
        1 => SensoryIntensity.media,
        _ => SensoryIntensity.alta,
      };
      final String gameName = id <= featured.length ? featured[id - 1] : 'Juego $id';
      _games.add(
        GameModel(
          id: id,
          name: gameName,
          genre: genres[id % genres.length],
          imageUrl: _imageForGameName(gameName),
          sensoryIntensity: intensity,
          description:
              'Experiencia ${_intensityName(intensity).toLowerCase()} con enfoque accesible.',
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
        child: user == null ? _buildAuthScreen() : _buildMainScreen(user),
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
    final List<String> favoriteNames = allLibraryGames
        .where((LibraryGameUi game) => game.isFavorite)
        .take(3)
        .map((LibraryGameUi game) => game.game.name)
        .toList();
    final int coins = _coinsByUser[user.id] ?? 0;

    return Scaffold(
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
            label: 'Mensajes',
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
                MainTab.mensajes => _buildSocialScreen(user, favoriteNames),
                MainTab.tienda => _buildStoreScreen(user),
                MainTab.perfil => _buildOptionsScreen(user),
              },
            ),
          ),
        ],
      ),
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
                      child: const Text('Mensajes'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _activeTab = MainTab.tienda),
                      child: const Text('Ir a tienda'),
                    ),
                    OutlinedButton(
                      onPressed: _openFirebaseInspector,
                      child: const Text('Verificar Firebase'),
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
                                onPressed: () => _toggleGuideForGame(
                                  gameUi.game,
                                  focusSearchOnEnable: true,
                                ),
                                child: Text(
                                  gameUi.isPlayingNow
                                      ? 'Quitar guia'
                                      : 'Ver guia',
                                ),
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
    final String normalizedQuery = _searchQuery.trim().toLowerCase();
    final bool showGames =
        _searchScope == SearchScope.todo || _searchScope == SearchScope.juegos;
    final bool showUsers =
        _searchScope == SearchScope.todo ||
        _searchScope == SearchScope.usuarios;
    final bool showGuides =
        _searchScope == SearchScope.todo || _searchScope == SearchScope.guias;

    final List<UserModel> userMatches = normalizedQuery.isEmpty
        ? <UserModel>[]
        : _users
              .where(
                (UserModel item) =>
                    item.id != user.id &&
                    (item.displayName.toLowerCase().contains(normalizedQuery) ||
                        item.email.toLowerCase().contains(normalizedQuery)),
              )
              .take(8)
              .toList();
    final List<CommunityGuideModel> guideMatches = normalizedQuery.isEmpty
      ? <CommunityGuideModel>[]
        : _communityGuides
              .where(
                (CommunityGuideModel guide) =>
                    _gameNameForId(
                      guide.gameId,
                    ).toLowerCase().contains(normalizedQuery) ||
                    guide.authorName.toLowerCase().contains(normalizedQuery) ||
                    guide.content.toLowerCase().contains(normalizedQuery),
              )
              .take(8)
              .toList();

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: <Widget>[
        TextField(
          decoration: const InputDecoration(
            labelText: 'Buscar juegos, usuarios o guías',
          ),
          onChanged: _onSearchQueryChanged,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              selected: _searchScope == SearchScope.todo,
              label: const Text('Todo'),
              onSelected: (_) =>
                  setState(() => _searchScope = SearchScope.todo),
            ),
            ChoiceChip(
              selected: _searchScope == SearchScope.juegos,
              label: const Text('Juegos'),
              onSelected: (_) =>
                  setState(() => _searchScope = SearchScope.juegos),
            ),
            ChoiceChip(
              selected: _searchScope == SearchScope.usuarios,
              label: const Text('Usuarios'),
              onSelected: (_) =>
                  setState(() => _searchScope = SearchScope.usuarios),
            ),
            ChoiceChip(
              selected: _searchScope == SearchScope.guias,
              label: const Text('Guías'),
              onSelected: (_) =>
                  setState(() => _searchScope = SearchScope.guias),
            ),
          ],
        ),
        if (showGames) const SizedBox(height: 10),
        if (showGames)
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
                  onSelected: (_) =>
                      setState(() => _selectedIntensity = intensity),
                ),
            ],
          ),
        if (showGames) const SizedBox(height: 10),
        if (showGames) Text('Catalogo: ${games.length} juegos'),
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
        if (showGames)
          ...games.map(
            (LibraryGameUi gameUi) => Padding(
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
                              gameUi.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                            ),
                            label: Text(
                              gameUi.isFavorite
                                  ? 'Quitar favorito'
                                  : 'Favorito',
                            ),
                            onPressed: () => _toggleFavorite(gameUi.game.id),
                          ),
                          ActionChip(
                            avatar: Icon(
                              gameUi.isUpcoming
                                  ? Icons.playlist_add_check_circle
                                  : Icons.playlist_add_circle_outlined,
                              size: 18,
                            ),
                            label: Text(
                              gameUi.isUpcoming
                                  ? 'Quitar próximos'
                                  : 'Próximos',
                            ),
                            onPressed: () => _toggleUpcoming(gameUi.game.id),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.menu_book_outlined, size: 18),
                            label: Text(
                              gameUi.isPlayingNow ? 'Quitar guía' : 'Ver guía',
                            ),
                            onPressed: () => _toggleGuideForGame(
                              gameUi.game,
                              focusSearchOnEnable: true,
                            ),
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
            ),
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
                  child: ListTile(
                    leading: _buildUserAvatar(match),
                    title: Text(match.displayName),
                    subtitle: Text(match.profileStatus),
                    trailing: Wrap(
                      spacing: 8,
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
                    trailing: FilledButton.tonal(
                      onPressed: () => _openCommunityGuideDetail(guide),
                      child: const Text('Ver'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  void _onSearchQueryChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _queueIgdbSearch(value);
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
      if (!mounted || _lastIgdbQuery != query) {
        return;
      }
      setState(() {
        _igdbResults
          ..clear()
          ..addAll(results);
        _isIgdbLoading = false;
      });
    } on TimeoutException {
      if (!mounted || _lastIgdbQuery != query) {
        return;
      }
      setState(() {
        _igdbResults.clear();
        _isIgdbLoading = false;
        _igdbErrorMessage =
            'IGDB tardó demasiado en responder. Comprueba que el backend esté encendido.';
      });
    } catch (error) {
      if (!mounted || _lastIgdbQuery != query) {
        return;
      }
      setState(() {
        _igdbResults.clear();
        _isIgdbLoading = false;
        _igdbErrorMessage =
            'IGDB no disponible ahora mismo. Puedes seguir usando el catálogo local.';
      });
    }
  }

  void _addIgdbGameToCatalog(IgdbGameDto item) {
    final String normalized = item.name.trim().toLowerCase();
    if (_games.any((GameModel game) => game.name.trim().toLowerCase() == normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} ya existe en tu catálogo.')),
      );
      return;
    }

    final SensoryIntensity inferredIntensity = (item.rating ?? 60) >= 75
        ? SensoryIntensity.media
        : SensoryIntensity.baja;
    final String imageUrl = (item.coverUrl ?? '').trim().isNotEmpty
        ? item.coverUrl!.trim()
        : _imageForGameName(item.name);

    setState(() {
      _games.insert(
        0,
        GameModel(
          id: _nextGameId(),
          name: item.name.trim(),
          genre: item.genre.trim().isEmpty ? 'General' : item.genre.trim(),
          imageUrl: imageUrl,
          sensoryIntensity: inferredIntensity,
          description: item.summary.trim().isEmpty
              ? 'Importado desde IGDB.'
              : item.summary.trim(),
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} añadido al catálogo.')),
    );
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
    final List<CommunityGuideModel> guides = <CommunityGuideModel>[
      ..._communityGuides,
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
                                        child: FilledButton.tonal(
                                          onPressed: () =>
                                              _openCommunityGuideDetail(guide),
                                          child: const Text('Ver completa'),
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

    _completeMissionForCurrentUser(DailyMissionType.readGuide);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guía publicada en comunidad.')),
    );
  }

  Future<void> _openCommunityGuideDetail(CommunityGuideModel guide) async {
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

  String _streamUserIdFromUser(UserModel user) => 'user_${user.id}';

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
    return _users.where((UserModel item) => ids.contains(item.id)).toList();
  }

  bool _isFriendWithCurrentUser(UserModel other) {
    final UserModel? user = _currentUser;
    if (user == null || user.id == other.id) {
      return false;
    }
    final Set<int> ids = _friendsByUser[user.id] ?? <int>{};
    return ids.contains(other.id);
  }

  void _toggleFriend(UserModel other) {
    final UserModel? user = _currentUser;
    if (user == null || user.id == other.id) {
      return;
    }

    setState(() {
      final Set<int> mine = _friendsByUser.putIfAbsent(user.id, () => <int>{});
      final Set<int> theirs = _friendsByUser.putIfAbsent(other.id, () => <int>{});
      if (mine.contains(other.id)) {
        mine.remove(other.id);
        theirs.remove(user.id);
      } else {
        mine.add(other.id);
        theirs.add(user.id);
      }
    });
  }

  void _openDirectMessageWithUser(UserModel peer) {
    final UserModel? user = _currentUser;
    if (user == null) {
      return;
    }

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
          return queryMatch && intensityMatch;
        })
        .map((GameModel game) {
          final String recommendationTag = switch (game.sensoryIntensity) {
            SensoryIntensity.baja => 'Recomendado para TEA',
            SensoryIntensity.media => 'Recomendado para TEA y TDAH',
            SensoryIntensity.alta => 'Recomendado para TDAH',
          };
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
        );
        _users.add(user);
        _ensureDefaultTasks(user.id);
        _ensureDailyMissionState(user.id);
        _ensureUserEconomy(user.id);
        await _upsertUserInFirebase(user);
        _enterWithUser(user);
      } else {
        if (email.isEmpty || password.isEmpty) {
          setState(() {
            _auth.isLoading = false;
            _auth.errorMessage =
                'Introduce email/usuario y contrasena para iniciar sesion';
          });
          return;
        }

        UserModel? user = _users
            .where((UserModel u) => u.email == email)
            .cast<UserModel?>()
            .firstWhere((UserModel? u) => u != null, orElse: () => null);

        user ??= await _findUserInFirebase(email: email, password: password);

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
        if (!_users.any((UserModel u) => u.email == user!.email)) {
          _users.add(user);
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
    _saveUserPreferences(user);
    unawaited(_upsertUserInFirebase(user));
  }

  void _logout() {
    setState(() {
      _currentUser = null;
      _activeTab = MainTab.home;
      _searchQuery = '';
      _selectedIntensity = null;
      _timer.remainingSeconds = 25 * 60;
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
      for (final Set<int> ids in _friendsByUser.values) {
        ids.remove(userId);
      }
      _currentUser = null;
      _activeTab = MainTab.home;
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
          _timer.remainingSeconds = 5 * 60;
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
    _upcomingByUser.putIfAbsent(userId, () => <int, bool>{});
    _focusSecondsByUser.putIfAbsent(userId, () => 0);
    _breakSecondsByUser.putIfAbsent(userId, () => 0);
    _friendsByUser.putIfAbsent(userId, () => <int>{});
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
          'fontScale': user.fontScale,
          'accessibilityMode': user.accessibilityMode.name,
          'softColors': user.softColors,
          'noAnimations': user.noAnimations,
          'legibleFont': user.legibleFont,
          'themePalette': user.themePalette.name,
          'fontPreference': user.fontPreference.name,
          'notificationMode': user.notificationMode.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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

    return UserModel(
      id: (data['id'] as int?) ?? _nextUserId(),
      email: (data['email'] as String?) ?? email,
      password: storedPassword,
      displayName: (data['displayName'] as String?) ?? email.split('@').first,
      avatar: (data['avatar'] as String?) ?? '🎮',
      avatarBytes: (data['avatarBytes'] as String?) != null
          ? base64Decode(data['avatarBytes'] as String)
          : null,
      profileStatus: (data['profileStatus'] as String?) ?? 'En línea',
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

  void _applyAccessibilityPreset(AccessibilityMode mode) {
    _updateCurrentUser((UserModel base) {
      if (mode == AccessibilityMode.tea) {
        return base.copyWith(
          accessibilityMode: AccessibilityMode.tea,
          softColors: true,
          noAnimations: true,
          legibleFont: true,
          themePalette: ThemePalette.suave,
          fontPreference: FontPreference.legible,
          fontScale: 1.0,
          notificationMode: NotificationMode.importantes,
        );
      }

      return base.copyWith(
        accessibilityMode: AccessibilityMode.tdah,
        softColors: false,
        noAnimations: false,
        legibleFont: false,
        themePalette: ThemePalette.neon,
        fontPreference: FontPreference.sistema,
        fontScale: 1.08,
        notificationMode: NotificationMode.todas,
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

  void _resetPomodoro() {
    setState(() {
      _timer.isRunning = false;
      _timer.remainingSeconds = _timer.isWorkSession ? 25 * 60 : 5 * 60;
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
        _timer.isWorkSession = !_timer.isWorkSession;
        _timer.remainingSeconds = _timer.isWorkSession ? 25 * 60 : 5 * 60;
        SystemSound.play(SystemSoundType.alert);
      } else {
        _timer.remainingSeconds = next;
      }
    });
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
