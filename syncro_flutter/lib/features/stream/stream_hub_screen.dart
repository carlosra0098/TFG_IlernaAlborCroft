import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as sc;
import 'package:stream_feeds/stream_feeds.dart' as sf;

class StreamHubScreen extends StatefulWidget {
  const StreamHubScreen({
    super.key,
    required this.displayName,
  });

  final String displayName;

  @override
  State<StreamHubScreen> createState() => _StreamHubScreenState();
}

class _StreamHubScreenState extends State<StreamHubScreen>
    with SingleTickerProviderStateMixin {
  static const String _streamApiKey = String.fromEnvironment(
    'STREAM_API_KEY',
    defaultValue: 'j5tkkdvknj3p',
  );
  static const String _streamChatUserToken = String.fromEnvironment(
    'STREAM_CHAT_USER_TOKEN',
  );
  static const String _streamFeedToken = String.fromEnvironment(
    'STREAM_FEED_USER_TOKEN',
  );
  static const String _streamTokenServerUrl = String.fromEnvironment(
    'STREAM_TOKEN_SERVER_URL',
    defaultValue: '',
  );
  static const String _streamFeedGroup = String.fromEnvironment(
    'STREAM_FEED_GROUP',
    defaultValue: 'timeline',
  );
  static const String _streamFeedId = String.fromEnvironment(
    'STREAM_FEED_ID',
    defaultValue: 'gaming',
  );

  late final TabController _tabController;
  sc.StreamChatClient? _chatClient;
  sc.StreamChannelListController? _channelListController;
  sf.StreamFeedsClient? _feedsClient;
  StreamSubscription<sf.FeedState>? _feedSubscription;

  bool _isLoading = true;
  bool _isFeedLoading = true;
  String? _chatError;
  String? _feedError;
  List<sf.ActivityData> _activities = <sf.ActivityData>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeStream();
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    _tabController.dispose();
    _channelListController?.dispose();
    _chatClient?.disconnectUser();
    _feedsClient?.disconnect();
    super.dispose();
  }

  Future<void> _initializeStream() async {
    if (_streamApiKey.isEmpty) {
      setState(() {
        _isLoading = false;
        _isFeedLoading = false;
        _chatError =
            'Falta STREAM_API_KEY. Añade --dart-define=STREAM_API_KEY=tu_clave_stream';
        _feedError =
            'Falta STREAM_API_KEY. Añade --dart-define=STREAM_API_KEY=tu_clave_stream';
      });
      return;
    }

    const String userId = 'super-band-9';

    sc.StreamChatClient? chatClient;
    sc.StreamChannelListController? controller;
    sf.StreamFeedsClient? feedsClient;
    sf.Feed? feed;
    String? chatError;
    String? feedError;
    final String resolvedTokenServerUrl = _resolveTokenServerUrl();

    String effectiveChatToken = '';
    final String? fetchedToken = await _fetchChatTokenFromBackend(
      tokenServerUrl: resolvedTokenServerUrl,
      userId: userId,
      name: widget.displayName,
    );
    if (_looksLikeJwt(fetchedToken ?? '')) {
      effectiveChatToken = fetchedToken!.trim();
    } else {
      final String tokenFromDefine = _streamChatUserToken.trim();
      if (_looksLikeJwt(tokenFromDefine)) {
        effectiveChatToken = tokenFromDefine;
      }
    }

    try {
      chatClient = sc.StreamChatClient(
        _streamApiKey,
        logLevel: sc.Level.INFO,
      );

      if (effectiveChatToken.isEmpty) {
        throw ArgumentError(
          'No se obtuvo un JWT válido. Publica el backend de tokens y pasa --dart-define=STREAM_TOKEN_SERVER_URL=https://tu-backend o usa STREAM_CHAT_USER_TOKEN válido.',
        );
      }

      await chatClient.connectUser(
        sc.User(id: userId, name: widget.displayName),
        effectiveChatToken,
      );

      final sc.Channel globalChannel = chatClient.channel(
        'messaging',
        id: 'flutterdevs',
        extraData: <String, Object>{
          'name': 'Flutter devs',
          'members': <String>[userId],
        },
      );
      await globalChannel.watch();
      await _sendBootstrapMessage(globalChannel);

      final sc.Filter filter = sc.Filter.and(<sc.Filter>[
        sc.Filter.equal('type', 'messaging'),
        sc.Filter.in_('members', <Object>[userId]),
      ]);

      final sc.SortOrder<sc.ChannelState> sort =
          <sc.SortOption<sc.ChannelState>>[
            const sc.SortOption<sc.ChannelState>.desc('last_message_at'),
          ];

      await chatClient.queryChannelsOnline(
        filter: filter,
        sort: sort,
      );

      controller = sc.StreamChannelListController(
        client: chatClient,
        filter: filter,
        channelStateSort: sort,
      );
      await controller.doInitialLoad();
    } catch (error) {
      chatError =
          'No se pudo abrir el chat de Stream con connectUser. Verifica STREAM_TOKEN_SERVER_URL (actual: ${resolvedTokenServerUrl.isEmpty ? 'no configurada' : resolvedTokenServerUrl}) o pasa STREAM_CHAT_USER_TOKEN por dart-define. Error: $error';
    }

    try {
        final String feedTokenFromDefine = _streamFeedToken.trim();
        final String effectiveFeedToken = _looksLikeJwt(feedTokenFromDefine)
          ? feedTokenFromDefine
          : effectiveChatToken;

      if (effectiveFeedToken.isEmpty) {
        throw ArgumentError(
          'Falta STREAM_FEED_USER_TOKEN y tampoco hay token de chat reusable para feed.',
        );
      }

      final sf.User feedUser = sf.User(id: userId, name: widget.displayName);
      feedsClient = sf.StreamFeedsClient(
        apiKey: _streamApiKey,
        user: feedUser,
        tokenProvider: sf.TokenProvider.static(sf.UserToken(effectiveFeedToken)),
      );
      await feedsClient.connect();

      feed = feedsClient.feedFromQuery(
        sf.FeedQuery(
          fid: sf.FeedId(group: _streamFeedGroup, id: _streamFeedId),
          activityLimit: 20,
          watch: true,
        ),
      );

      final sf.Result<sf.FeedData> feedResult = await feed.getOrCreate();
      if (feedResult.isFailure) {
        feedError = 'Feed no disponible: ${feedResult.exceptionOrNull()}';
      }
    } catch (error) {
      feedError =
          'No se pudo abrir Stream Feed. Verifica STREAM_FEED_USER_TOKEN y permisos del feed $_streamFeedGroup:$_streamFeedId. Error: $error';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _chatClient = chatClient;
      _channelListController = controller;
      _feedsClient = feedsClient;
      _activities = feed?.state.activities ?? <sf.ActivityData>[];
      _chatError = chatError;
      _feedError = feedError;
      _isLoading = false;
      _isFeedLoading = false;
    });

    if (feed != null) {
      _feedSubscription = feed.stream.listen((sf.FeedState state) {
        if (!mounted) {
          return;
        }
        setState(() {
          _activities = state.activities;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_chatClient == null || _channelListController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stream Chat + Feed')),
        body: _buildSetupHelp(
          _chatError ?? 'No se pudo inicializar Stream Chat.',
        ),
      );
    }

    return sc.StreamChat(
      client: _chatClient!,
      child: sc.StreamChatTheme(
        data: sc.StreamChatThemeData.fromTheme(Theme.of(context)),
        child: Scaffold(
        appBar: AppBar(
          title: const Text('Stream Chat + Feed'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'Chat en vivo'),
              Tab(text: 'Gaming feed'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            sc.StreamChannelListView(
              controller: _channelListController!,
              onChannelTap: (sc.Channel channel) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) {
                      return sc.StreamChatTheme(
                        data:
                            sc.StreamChatThemeData.fromTheme(Theme.of(context)),
                        child: sc.StreamChannel(
                          channel: channel,
                          child: Scaffold(
                            appBar: AppBar(
                              title: Text(channel.name ?? 'Canal'),
                            ),
                            body: const Column(
                              children: <Widget>[
                                Expanded(child: sc.StreamMessageListView()),
                                sc.StreamMessageInput(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            _buildFeedTab(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFeedTab() {
    if (_isFeedLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_feedError != null && _activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_feedError!),
      );
    }

    if (_activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No hay actividades en el feed todavía. Puedes crear actividades en Stream Dashboard o desde backend.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _activities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final sf.ActivityData activity = _activities[index];
        final String title = activity.text?.trim().isNotEmpty == true
            ? activity.text!
            : 'Actividad gaming';
        final String subtitle =
            '${activity.type} · ${activity.user.name ?? activity.user.id}';

        return Card(
          child: ListTile(
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: Text(
              '${activity.reactionCount} ❤',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetupHelp(String primaryError) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(primaryError),
        const SizedBox(height: 12),
        const Text('Ejemplo de ejecución:'),
        const SizedBox(height: 6),
        const SelectableText(
          'flutter run -d emulator-5554 '
          '--dart-define=STREAM_API_KEY=tu_api_key '
          '--dart-define=STREAM_TOKEN_SERVER_URL=https://tu-backend-token '
          '--dart-define=STREAM_FEED_GROUP=timeline '
          '--dart-define=STREAM_FEED_ID=gaming',
        ),
      ],
    );
  }

  String _resolveTokenServerUrl() {
    final String configured = _streamTokenServerUrl.trim();
    if (configured.isNotEmpty) {
      return configured;
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

  Future<void> _sendBootstrapMessage(sc.Channel channel) async {
    const String bootstrapText =
        'I told them I was pesca-pescatarian. Which is one who eats solely fish who eat other fish.';

    final bool alreadyExists = channel.state?.messages.any(
          (sc.Message message) => message.text == bootstrapText,
        ) ??
        false;

    if (alreadyExists) {
      return;
    }

    final sc.Message message = sc.Message(
      text: bootstrapText,
      extraData: <String, Object>{
        'customField': '123',
      },
    );

    await channel.sendMessage(message);
  }

  Future<String?> _fetchChatTokenFromBackend({
    required String tokenServerUrl,
    required String userId,
    required String name,
  }) async {
    if (tokenServerUrl.isEmpty) {
      return null;
    }

    try {
      final Uri uri = Uri.parse('$tokenServerUrl/stream/token');
      final http.Response response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'userId': userId,
          'name': name,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      return json['token'] as String?;
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeJwt(String value) {
    if (value.isEmpty) {
      return false;
    }
    final List<String> parts = value.split('.');
    return parts.length == 3 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty &&
        parts[2].isNotEmpty;
  }
}
