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
    this.embedded = false,
  });

  final String displayName;
  final String currentUserId;
  final String? initialPeerId;
  final String? initialPeerName;
  final bool embedded;

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
  static const String _commandsHelpText =
      'Comandos disponibles en el chat global:\n'
      '/comandos, /ayuda, /help -> muestra esta ayuda\n'
      '/hola -> envia un saludo rapido\n'
      '/giphy <texto> -> comparte una busqueda de GIFs';

  late final TabController _tabController;
  late final TextEditingController _plainMessageController;
  sc.StreamChatClient? _chatClient;
  sc.Channel? _globalChannel;
  sc.StreamChannelListController? _channelListController;
  sc.StreamChannelListController? _directMessageController;
  sc.Channel? _selectedChannel;
  sc.Channel? _selectedPrivateChannel;
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
    _plainMessageController = TextEditingController();
    _initializeStream();
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    _tabController.dispose();
    _plainMessageController.dispose();
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
    _selectedPrivateChannel = null;

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
          'No se obtuvo un JWT válido. Publica el backend de tokens y pasa --dart-define=STREAM_TOKEN_SERVER_URL=https://tu-backend o usa STREAM_CHAT_USER_TOKEN válido.',
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
        final List<String> members = <String>[userId, peerId];
        final String channelId = 'dm_${userId}_$peerId';
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
          _selectedPrivateChannel = dmChannel;
          _tabController.index = 1;
        } catch (_) {
          // If peer user is missing in Stream, create a private local channel
          // for the current user so the UI still opens private chat instead of global.
          try {
            final sc.Channel localPrivateChannel = chatClient.channel(
              'messaging',
              id: channelId,
              extraData: <String, Object>{
                'name': widget.initialPeerName?.trim().isNotEmpty == true
                    ? 'Chat con ${widget.initialPeerName}'
                    : 'Chat privado',
                'members': <String>[userId],
                'is_direct_message': true,
                'private_peer_id': peerId,
              },
            );
            await localPrivateChannel.watch().timeout(_chatRequestTimeout);
            _selectedPrivateChannel = localPrivateChannel;
            _tabController.index = 1;
          } catch (_) {
            _selectedChannel = globalChannel;
          }
        }
      }
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
      if (widget.embedded) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_chatClient == null || (_channelListController == null && _selectedChannel == null)) {
      if (widget.embedded) {
        return _buildSetupHelp(_chatError ?? 'No se pudo inicializar Stream Chat.');
      }
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

    final Widget hubContent = Column(
      children: <Widget>[
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'Chat global'),
              Tab(text: 'Chat privado'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              _buildChatTab(),
              _buildPrivateChatTab(),
            ],
          ),
        ),
      ],
    );

    return sc.StreamChat(
      client: _chatClient!,
      child: sc.StreamChatTheme(
        data: sc.StreamChatThemeData.fromTheme(Theme.of(context)),
        child: widget.embedded
            ? hubContent
            : Scaffold(
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
                body: hubContent,
              ),
      ),
    );
  }

  Widget _buildPrivateChatTab() {
    final sc.StreamChannelListController? directController =
        _directMessageController;

    final sc.Channel? privateChannel = _selectedPrivateChannel;
    if (privateChannel != null) {
      return _buildConversationView(
        channel: privateChannel,
        onBackPressed: () {
          setState(() {
            _selectedPrivateChannel = null;
          });
        },
        onDeleteConversation: () => _deletePrivateConversation(privateChannel),
      );
    }

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
          _selectedPrivateChannel = tapped;
        });
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
    final sc.Channel? channel = _selectedChannel ?? _globalChannel;

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

    return _buildConversationView(
      channel: channel,
      onBackPressed: () {
        setState(() {
          _selectedChannel = _globalChannel;
        });
      },
      showGlobalCommands: _globalChannel != null && channel.cid == _globalChannel!.cid,
    );
  }

  Widget _buildConversationView({
    required sc.Channel channel,
    required VoidCallback onBackPressed,
    bool showGlobalCommands = false,
    Future<void> Function()? onDeleteConversation,
  }) {

    return sc.StreamChannel(
      channel: channel,
      child: Column(
        children: <Widget>[
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListTile(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackPressed,
              ),
              title: Text(channel.name ?? 'Canal'),
              trailing: onDeleteConversation == null
                  ? null
                  : IconButton(
                      tooltip: 'Borrar conversación',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        unawaited(onDeleteConversation());
                      },
                    ),
            ),
          ),
          if (showGlobalCommands)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.terminal),
                  title: const Text('Comandos del chat global'),
                  subtitle: const Text(
                    '/comandos, /ayuda, /help\n/hola\n/giphy <texto>',
                  ),
                ),
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _plainMessageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _sendCurrentMessage(channel),
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCurrentMessage(sc.Channel channel) async {
    final String text = _plainMessageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final bool isCommandProcessed = await _handleChatCommand(channel, text);
    if (isCommandProcessed) {
      if (!mounted) {
        return;
      }
      _plainMessageController.clear();
      return;
    }

    await channel.sendMessage(sc.Message(text: text));
    if (!mounted) {
      return;
    }
    _plainMessageController.clear();
  }

  Future<bool> _handleChatCommand(sc.Channel channel, String text) async {
    final String normalized = text.trim().toLowerCase();

    if (normalized == '/comandos' || normalized == '/ayuda' || normalized == '/help') {
      await channel.sendMessage(
        sc.Message(
          text: _commandsHelpText,
          extraData: const <String, Object>{
            'kind': 'commands_help',
          },
        ),
      );
      return true;
    }

    if (normalized == '/hola') {
      await channel.sendMessage(
        sc.Message(text: 'Hola a todos! 👋'),
      );
      return true;
    }

    if (normalized.startsWith('/giphy')) {
      final String query = text.substring('/giphy'.length).trim();
      if (query.isEmpty) {
        await channel.sendMessage(
          sc.Message(text: 'Uso: /giphy <texto>. Ejemplo: /giphy cat gamer'),
        );
        return true;
      }

      final String encodedQuery = Uri.encodeQueryComponent(query);
      await channel.sendMessage(
        sc.Message(
          text:
              'GIF sugerido para "$query": https://tenor.com/search/$encodedQuery-gifs',
        ),
      );
      return true;
    }

    return false;
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
                        if (!mounted) {
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
                    final String targetName =
                        message.user?.name?.trim().isNotEmpty == true
                        ? message.user!.name!
                        : 'usuario';
                    _plainMessageController.text = '@$targetName ';
                    _plainMessageController.selection =
                        TextSelection.fromPosition(
                      TextPosition(offset: _plainMessageController.text.length),
                    );
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
    final Map<String, int> counts =
        message.reactionCounts ?? <String, int>{};
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
                        if (!mounted) {
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

  Future<void> _deletePrivateConversation(sc.Channel channel) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Borrar conversación'),
          content: const Text(
            'Se eliminará el historial del chat privado para esta cuenta. ¿Continuar?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await channel.truncate();
    } catch (_) {
      // Continue with hide even if truncate is not permitted.
    }

    try {
      await channel.hide(clearHistory: true);
    } catch (_) {
      // Ignore hide failures; UI fallback below still deselects current channel.
    }

    await _directMessageController?.doInitialLoad();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedPrivateChannel = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversación privada eliminada.')),
    );
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
      'Bienvenido al chat global de Syncro.\n'
      'Escribe /comandos para ver los comandos disponibles.';

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
