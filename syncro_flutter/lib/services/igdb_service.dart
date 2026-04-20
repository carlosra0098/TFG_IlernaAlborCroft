import 'dart:async';
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
  static const Duration _requestTimeout = Duration(seconds: 16);
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

    final List<String> proxyCandidates = _buildCandidateProxyUrls();
    if (proxyCandidates.isEmpty) {
      throw ArgumentError(
        'IGDB_PROXY_URL o STREAM_TOKEN_SERVER_URL no configurada para modo release.',
      );
    }

    Object? lastNetworkError;
    for (final String proxy in proxyCandidates) {
      try {
        final http.Response response = await _postSearchRequest(
          proxyBaseUrl: proxy,
          normalizedQuery: normalizedQuery,
          limit: limit,
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          final String rawBody = response.body.trim();
          String backendMessage = '';
          if (rawBody.isNotEmpty) {
            try {
              final Map<String, dynamic> decodedError =
                  jsonDecode(rawBody) as Map<String, dynamic>;
              final String error =
                  (decodedError['error'] as String?)?.trim() ?? '';
              final String details =
                  (decodedError['details'] as String?)?.trim() ?? '';
              backendMessage = '$error ${details}'.trim();
            } catch (_) {
              backendMessage = rawBody;
            }
          }
          throw StateError(
            'IGDB backend respondió ${response.statusCode}. ${backendMessage.isEmpty ? 'Revisa stream_token_server y credenciales IGDB.' : backendMessage}',
          );
        }

        final Map<String, dynamic> decoded =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> items =
            decoded['games'] as List<dynamic>? ?? <dynamic>[];

        return items
            .whereType<Map<String, dynamic>>()
            .map(IgdbGameDto.fromJson)
            .where((IgdbGameDto game) => game.igdbId > 0)
            .toList();
      } on TimeoutException catch (error) {
        lastNetworkError = error;
      } catch (error) {
        final String message = error.toString().toLowerCase();
        final bool looksLikeNetworkIssue =
            message.contains('socket') ||
            message.contains('connection') ||
            message.contains('failed host lookup') ||
            message.contains('connection refused') ||
            message.contains('network is unreachable');
        if (!looksLikeNetworkIssue) {
          rethrow;
        }
        lastNetworkError = error;
      }
    }

    throw TimeoutException(
      'IGDB no respondió a tiempo en ninguno de los endpoints locales. Último error: ${lastNetworkError ?? 'sin detalle'}',
      _requestTimeout,
    );
  }

  static Future<http.Response> _postSearchRequest({
    required String proxyBaseUrl,
    required String normalizedQuery,
    required int limit,
  }) {
    final Uri uri = Uri.parse('$proxyBaseUrl/igdb/search');
    return http
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
        .timeout(_requestTimeout);
  }

  static List<String> _buildCandidateProxyUrls() {
    final String preferred = resolveProxyUrl();
    final List<String> candidates = <String>[];

    void add(String value) {
      final String normalized = _normalizeBaseUrl(value);
      if (normalized.isNotEmpty && !candidates.contains(normalized)) {
        candidates.add(normalized);
      }
    }

    if (preferred.isNotEmpty) {
      add(preferred);
    }

    if (!kReleaseMode && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      add('http://10.0.2.2:8787');
      add('http://127.0.0.1:8787');
      add('http://localhost:8787');
    }

    return candidates;
  }

  static String _normalizeBaseUrl(String value) {
    String normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
