import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class IgdbGameDto {
  IgdbGameDto({
    required this.igdbId,
    required this.name,
    required this.genre,
    required this.summary,
    this.rating,
    this.coverUrl,
    this.releaseDateUnix,
  });

  final int igdbId;
  final String name;
  final String genre;
  final String summary;
  final double? rating;
  final String? coverUrl;
  final int? releaseDateUnix;

  factory IgdbGameDto.fromJson(Map<String, dynamic> json) {
    return IgdbGameDto(
      igdbId: (json['igdbId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Juego IGDB',
      genre: (json['genre'] as String?)?.trim().isNotEmpty == true
          ? (json['genre'] as String).trim()
          : 'General',
      summary: (json['summary'] as String?)?.trim().isNotEmpty == true
          ? (json['summary'] as String).trim()
          : 'Importado desde IGDB.',
      rating: (json['rating'] as num?)?.toDouble(),
      coverUrl: (json['coverUrl'] as String?)?.trim(),
      releaseDateUnix: (json['releaseDateUnix'] as num?)?.toInt(),
    );
  }
}

class IgdbService {
  static const String _igdbProxyUrlFromDefine = String.fromEnvironment(
    'IGDB_PROXY_URL',
    defaultValue: '',
  );
  static const String _streamTokenServerUrlFromDefine = String.fromEnvironment(
    'STREAM_TOKEN_SERVER_URL',
    defaultValue: '',
  );

  static String resolveProxyUrl() {
    final String configured = _igdbProxyUrlFromDefine.trim();
    if (configured.isNotEmpty) {
      return _normalizeBaseUrl(configured);
    }

    final String streamBackend = _streamTokenServerUrlFromDefine.trim();
    if (streamBackend.isNotEmpty) {
      return _normalizeBaseUrl(streamBackend);
    }

    if (kReleaseMode) {
      return '';
    }

    if (kIsWeb) {
      return 'http://localhost:8787';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8787';
    }

    return 'http://localhost:8787';
  }

  static Future<List<IgdbGameDto>> searchGames({
    required String query,
    int limit = 12,
  }) async {
    final String normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return <IgdbGameDto>[];
    }

    final String proxy = resolveProxyUrl();
    if (proxy.isEmpty) {
      throw ArgumentError(
        'IGDB_PROXY_URL o STREAM_TOKEN_SERVER_URL no configurada para modo release.',
      );
    }

    final Uri uri = Uri.parse('$proxy/igdb/search');
    final http.Response response = await http
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            'query': normalizedQuery,
            'limit': limit,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'IGDB backend respondió ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> items = decoded['games'] as List<dynamic>? ?? <dynamic>[];

    return items
        .whereType<Map<String, dynamic>>()
        .map(IgdbGameDto.fromJson)
        .where((IgdbGameDto game) => game.igdbId > 0)
        .toList();
  }

  static String _normalizeBaseUrl(String value) {
    String normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
