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
    required this.currentUserId,
    this.initialPeerId,
    this.initialPeerName,
  });

  final String displayName;
  final String currentUserId;
  final String? initialPeerId;
  final String? initialPeerName;

  @override
  State<StreamHubScreen> createState() => _StreamHubScreenState();
}

class _StreamHubScreenState extends State<StreamHubScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _tokenRequestTimeout = Duration(seconds: 6);
  static const Duration _chatRequestTimeout = Duration(seconds: 10);
  static const Duration _feedRequestTimeout = Duration(seconds: 10);

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
  late final sc.StreamMessageInputController _messageInputController;
  late final TextEditingController _localMessageController;
  sc.StreamChatClient? _chatClient;
  sc.Channel? _globalChannel;
  sc.StreamChannelListController? _channelListController;
  sc.StreamChannelListController? _directMessageController;
  sc.Channel? _selectedChannel;
  sf.StreamFeedsClient? _feedsClient;
  StreamSubscription<sf.FeedState>? _feedSubscription;

  bool _isLoading = true;
  bool _isFeedLoading = true;
  bool _useLocalChatFallback = false;
  String? _chatError;
  String? _feedError;
  List<sf.ActivityData> _activities = <sf.ActivityData>[];
  final List<_LocalChatMessage> _localMessages = <_LocalChatMessage>[
    _LocalChatMessage(
      text: 'Chat local activo. Configura Stream para volver al chat online.',
      isMine: false,
      sentAt: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _messageInputController = sc.StreamMessageInputController();
    _localMessageController = TextEditingController();
    _initializeStream();
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    _tabController.dispose();
    _messageInputController.dispose();
    _localMessageController.dispose();
    _channelListController?.dispose();
    _directMessageController?.dispose();
    _chatClient?.disconnectUser();
    _feedsClient?.disconnect();
    super.dispose();
  }

  Future<void> _retryInitializeStream() async {
    _feedSubscription?.cancel();
    _feedSubscription = null;

    _channelListController?.dispose();
    _channelListController = null;
    _directMessageController?.dispose();
    _directMessageController = null;
    _globalChannel = null;
    _selectedChannel = null;

    await _chatClient?.disconnectUser();
    _chatClient = null;

    await _feedsClient?.disconnect();
    _feedsClient = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isFeedLoading = true;
      _useLocalChatFallback = false;
      _chatError = null;
      _feedError = null;
      _activities = <sf.ActivityData>[];
    });

    await _initializeStream();
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

    final String userId = widget.currentUserId;

    sc.StreamChatClient? chatClient;
    sc.StreamChannelListController? controller;
    sc.StreamChannelListController? directMessageController;
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
    } else if (resolvedTokenServerUrl.isNotEmpty) {
      // When token server URL is configured, avoid falling back to stale static tokens.
      effectiveChatToken = '';
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
          'No se obtuvo un JWT válido. Configura backend de tokens y pasa --dart-define=STREAM_TOKEN_SERVER_URL=http://10.0.2.2:8787 (emulador) o usa STREAM_CHAT_USER_TOKEN válido.',
        );
      }

      await chatClient
          .connectUser(
            sc.User(id: userId, name: widget.displayName),
            effectiveChatToken,
          )
          .timeout(_chatRequestTimeout);

      final sc.Channel globalChannel = chatClient.channel(
        'messaging',
        id: 'flutterdevs',
        extraData: <String, Object>{
          'name': 'Chat global Syncro',
        },
      );
      await globalChannel.watch().timeout(_chatRequestTimeout);
      _globalChannel = globalChannel;
      // Always keep global chat selected as baseline so the screen doesn't crash
      // if channel list or DM setup fails later due permissions.
      _selectedChannel = globalChannel;
      try {
        await _sendBootstrapMessage(globalChannel);
      } catch (_) {
        // Ignore bootstrap message errors; channel can still be used normally.
      }

      try {
        final sc.Filter filter = sc.Filter.and(<sc.Filter>[
          sc.Filter.equal('type', 'messaging'),
          sc.Filter.in_('members', <Object>[userId]),
        ]);

        final sc.SortOrder<sc.ChannelState> sort =
            <sc.SortOption<sc.ChannelState>>[
              const sc.SortOption<sc.ChannelState>.desc('last_message_at'),
            ];

        await chatClient
            .queryChannelsOnline(
              filter: filter,
              sort: sort,
            )
            .timeout(_chatRequestTimeout);

        controller = sc.StreamChannelListController(
          client: chatClient,
          filter: filter,
          channelStateSort: sort,
        );
        await controller.doInitialLoad().timeout(_chatRequestTimeout);

        final sc.Filter directMessageFilter = sc.Filter.and(<sc.Filter>[
          sc.Filter.equal('type', 'messaging'),
          sc.Filter.in_('members', <Object>[userId]),
          sc.Filter.equal('is_direct_message', true),
        ]);
        directMessageController = sc.StreamChannelListController(
          client: chatClient,
          filter: directMessageFilter,
          channelStateSort: sort,
        );
        await directMessageController
            .doInitialLoad()
            .timeout(_chatRequestTimeout);
      } catch (_) {
        // Keep chat usable even when channel-list queries are rejected.
        controller = null;
        directMessageController = null;
      }

      final String peerId = (widget.initialPeerId ?? '').trim();
      if (peerId.isNotEmpty && peerId != userId) {
        final List<String> members = <String>[userId, peerId]..sort();
        final String channelId = 'dm_${members.join('_')}';
        try {
          final sc.Channel dmChannel = chatClient.channel(
            'messaging',
            id: channelId,
            extraData: <String, Object>{
              'name': widget.initialPeerName?.trim().isNotEmpty == true
                  ? 'Chat con ${widget.initialPeerName}'
                  : 'Chat directo',
              'members': members,
              'is_direct_message': true,
            },
          );
          await dmChannel.watch().timeout(_chatRequestTimeout);
          _selectedChannel = dmChannel;
        } catch (_) {
          // Fallback to global if peer user is not provisioned in Stream.
          _selectedChannel = globalChannel;
        }
      }
    } catch (error) {
      chatError =
          'No se pudo abrir el chat de Stream. Verifica STREAM_TOKEN_SERVER_URL (actual: ${resolvedTokenServerUrl.isEmpty ? 'no configurada' : resolvedTokenServerUrl}) o pasa STREAM_CHAT_USER_TOKEN por dart-define. En local: stream_token_server necesita STREAM_API_KEY y STREAM_API_SECRET en .env antes de npm start. Error: $error';
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
      await feedsClient.connect().timeout(_feedRequestTimeout);

      feed = feedsClient.feedFromQuery(
        sf.FeedQuery(
          fid: sf.FeedId(group: _streamFeedGroup, id: _streamFeedId),
          activityLimit: 20,
          watch: true,
        ),
      );

        final sf.Result<sf.FeedData> feedResult =
          await feed.getOrCreate().timeout(_feedRequestTimeout);
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
      _directMessageController = directMessageController;
      _feedsClient = feedsClient;
      _activities = feed?.state.activities ?? <sf.ActivityData>[];
      _chatError = chatError;
      _feedError = feedError;
      _useLocalChatFallback = chatError != null;
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
    if (_useLocalChatFallback) {
      return _buildLocalChatFallback();
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_chatClient == null || (_channelListController == null && _selectedChannel == null)) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.chat_bubble_outline),
              SizedBox(width: 8),
              Text('Chat global'),
            ],
          ),
        ),
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
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.chat_bubble_outline),
              SizedBox(width: 8),
              Text('Chat global'),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'Feed'),
              Tab(text: 'Chat global'),
              Tab(text: 'Chat privado'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            _buildFeedTab(),
            _buildChatTab(),
            _buildPrivateChatTab(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLocalChatFallback() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat local (sin Stream)'),
      ),
      body: Column(
        children: <Widget>[
          if (_chatError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.amber.withValues(alpha: 0.15),
              child: Text(
                _chatError!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _localMessages.length,
              itemBuilder: (BuildContext context, int index) {
                final _LocalChatMessage message = _localMessages[index];
                return Align(
                  alignment: message.isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: message.isMine
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _localMessageController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                      ),
                      onSubmitted: (_) => _sendLocalMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendLocalMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendLocalMessage() {
    final String text = _localMessageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      _localMessages.add(
        _LocalChatMessage(
          text: text,
          isMine: true,
          sentAt: DateTime.now(),
        ),
      );
      _localMessageController.clear();
    });
  }

  Widget _buildPrivateChatTab() {
    final sc.StreamChannelListController? directController =
        _directMessageController;

    if (directController == null) {
      return const Center(
        child: Text('No hay chats privados disponibles ahora mismo.'),
      );
    }

    return sc.StreamChannelListView(
      controller: directController,
      emptyBuilder: (_) => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Todavia no tienes chats privados. Añade amigos y abre un chat desde su perfil.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      onChannelTap: (sc.Channel tapped) {
        setState(() {
          _selectedChannel = tapped;
        });
        _tabController.animateTo(1);
      },
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

  Widget _buildChatTab() {
    final sc.Channel? channel = _selectedChannel;

    if (channel == null) {
      if (_channelListController == null) {
        return const Center(
          child: Text('No hay canales disponibles en este momento.'),
        );
      }
      return sc.StreamChannelListView(
        controller: _channelListController!,
        onChannelTap: (sc.Channel tapped) {
          setState(() {
            _selectedChannel = tapped;
          });
        },
      );
    }

    return sc.StreamChannel(
      channel: channel,
      child: Column(
        children: <Widget>[
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListTile(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedChannel = _globalChannel;
                  });
                },
              ),
              title: Text(channel.name ?? 'Canal'),
            ),
          ),
          Expanded(
            child: sc.StreamMessageListView(
              messageBuilder: (
                BuildContext context,
                sc.MessageDetails details,
                List<sc.Message> messages,
                sc.StreamMessageWidget defaultMessageWidget,
              ) {
                return defaultMessageWidget.copyWith(
                  onMessageLongPress: (sc.Message message) {
                    _showMessageQuickActions(context, message);
                  },
                  onReactionsTap: (sc.Message message) {
                    _handleReactionsTap(context, message);
                  },
                );
              },
            ),
          ),
          sc.StreamMessageInput(
            messageInputController: _messageInputController,
          ),
        ],
      ),
    );
  }

  void _showMessageQuickActions(
    BuildContext context,
    sc.Message message,
  ) {
    final sc.Channel channel = sc.StreamChannel.of(context).channel;
    showModalBottomSheet<void>(
      useRootNavigator: false,
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final List<(String emoji, String reactionType)> reactions =
            <(String emoji, String reactionType)>[
          ('👍', 'like'),
          ('❤️', 'love'),
          ('😂', 'haha'),
          ('😮', 'wow'),
          ('😢', 'sad'),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Acciones del mensaje',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reactions.map(((String, String) item) {
                    return ActionChip(
                      label: Text(item.$1),
                      onPressed: () async {
                        await channel.sendReaction(
                          message,
                          item.$2,
                        );
                        if (!sheetContext.mounted) {
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.reply),
                  title: const Text('Responder a este mensaje'),
                  onTap: () {
                    _messageInputController.quotedMessage = message;
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleReactionsTap(
    BuildContext context,
    sc.Message message,
  ) {
    final List<sc.Reaction> latestReactions =
        message.latestReactions ?? <sc.Reaction>[];
    final List<sc.Reaction> ownReactions =
        message.ownReactions ?? <sc.Reaction>[];
    final Map<String, int> counts = <String, int>{
      for (final MapEntry<String, sc.ReactionGroup> entry
        in (message.reactionGroups ?? <String, sc.ReactionGroup>{})
          .entries)
      entry.key: entry.value.count,
    };
    final Set<String> reactionTypes = <String>{
      ...counts.keys,
      ...latestReactions.map((sc.Reaction reaction) => reaction.type),
      ...ownReactions.map((sc.Reaction reaction) => reaction.type),
    };

    if (reactionTypes.isEmpty) {
      return;
    }

    final sc.Channel channel = sc.StreamChannel.of(context).channel;

    showModalBottomSheet<void>(
      useRootNavigator: false,
      context: context,
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
                  'Reacciones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reactionTypes.map((String type) {
                    sc.Reaction? ownReaction;
                    for (final sc.Reaction reaction in ownReactions) {
                      if (reaction.type == type) {
                        ownReaction = reaction;
                        break;
                      }
                    }

                    final int count = counts[type] ?? 0;
                    final bool hasOwnReaction = ownReaction != null;

                    return FilterChip(
                      selected: hasOwnReaction,
                      label: Text('${_emojiForReaction(type)} $count'),
                      onSelected: (_) async {
                        if (ownReaction != null) {
                          await channel.deleteReaction(message, ownReaction);
                        } else {
                          await channel.sendReaction(message, type);
                        }
                        if (!sheetContext.mounted) {
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _emojiForReaction(String type) {
    return switch (type) {
      'like' => '👍',
      'love' => '❤️',
      'haha' => '😂',
      'wow' => '😮',
      'sad' => '😢',
      _ => '⭐',
    };
  }

  Widget _buildSetupHelp(String primaryError) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(primaryError),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _retryInitializeStream,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar conexion de Stream'),
        ),
        const SizedBox(height: 12),
        const Text('Ejemplo de ejecución (emulador Android):'),
        const SizedBox(height: 6),
        const SelectableText(
          '1) En stream_token_server crea .env con STREAM_API_KEY y STREAM_API_SECRET\n'
          '2) Ejecuta: npm install && npm start\n'
          '3) Ejecuta Flutter con:\n\n'
          'flutter run -d emulator-5554 '
          '--dart-define=STREAM_API_KEY=tu_api_key '
          '--dart-define=STREAM_TOKEN_SERVER_URL=http://10.0.2.2:8787 '
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
      ).timeout(_tokenRequestTimeout);

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

class _LocalChatMessage {
  _LocalChatMessage({
    required this.text,
    required this.isMine,
    required this.sentAt,
  });

  final String text;
  final bool isMine;
  final DateTime sentAt;
}
