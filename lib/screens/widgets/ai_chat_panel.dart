import 'dart:async';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat_messageai.dart';
import '../../models/worker.dart';
import '../../services/ai_chat_service.dart';
import '../../services/firebase_service.dart';
import '../worker_detail_screen.dart';

enum TtsState { playing, stopped }

class AiChatPanel extends StatefulWidget {
  final VoidCallback onClose;
  final AiChatService aiChatService;

  const AiChatPanel({
    super.key,
    required this.onClose,
    required this.aiChatService,
  });

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();

  late FlutterTts _flutterTts;
  TtsState _ttsState = TtsState.stopped;
  bool _isSoundEnabled = true;
  String? _currentlyPlayingId;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  Uint8List? _pickedImageBytes;
  String? _pickedImageMimeType;

  static const List<String> _suggestedPrompts = [
    "Find me a plumber near me",
    "የላቀ ኤሌክትሪሻን ማን ነው?",
    "What's the price for a carpenter?",
    "Show me all available cleaners",
    "Yematir alebet plumber man new?",
    "ያሉትን ክሊነሮች አሳየኝ",
  ];

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _textController.addListener(() {
      if (mounted) setState(() {});
    });

    widget.aiChatService
        .initializePersonalizedChat()
        .then((_) {
          if (mounted && _messages.isEmpty) {
            final welcomeMessage = ChatMessage(
              text:
                  "Selam! I'm 'Min Atu', your personal AI assistant. How can I help you today? 😊~Selam! I'm 'Min Atu', your personal AI assistant. How can I help you today?~",
              messageType: MessageType.bot,
            );
            // MODIFIED: Removed automatic playback for the initial welcome message.
            // User can manually play it if they wish.
            setState(() => _messages.add(welcomeMessage));
          }
        })
        .catchError((e) {
          print("Error initializing chat: $e");
          if (mounted && _messages.isEmpty) {
            setState(() {
              _messages.add(
                ChatMessage(
                  text:
                      "I couldn't get set up properly, but I'm still here to help! Ask me anything.",
                  messageType: MessageType.error,
                ),
              );
            });
          }
        });
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _ttsState = TtsState.playing);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _ttsState = TtsState.stopped;
          _currentlyPlayingId = null;
        });
      }
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _ttsState = TtsState.stopped;
          _currentlyPlayingId = null;
        });
      }
      print("TTS Error: $msg");
    });
    await _setVoice();
  }

  Future<void> _setVoice() async {
    try {
      await _flutterTts.setLanguage("am-ET");
      var voices = await _flutterTts.getVoices;
      if (voices is List) {
        var amharicVoices = (voices as List).where((v) {
          return v is Map && v['locale'] == "am-ET";
        }).toList();
        if (amharicVoices.isEmpty) {
          await _flutterTts.setLanguage("en-US");
        }
      }
    } catch (e) {
      await _flutterTts.setLanguage("en-US");
    }
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  String _extractSpokenText(String rawText) {
    final match = RegExp(r'~(.*?)~', dotAll: true).firstMatch(rawText);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return rawText
        .replaceAll(RegExp(r'\[([^\]]+)\]\(worker:\/\/([^\)]+)\)'), ' ')
        .replaceAll(RegExp(r'~.*~', dotAll: true), '')
        .trim();
  }

  Future<void> _speak(ChatMessage message) async {
    if (_ttsState == TtsState.playing) await _stop();
    final speakableText = _extractSpokenText(message.text);
    if (speakableText.isNotEmpty) {
      if (mounted) {
        setState(() => _currentlyPlayingId = message.id);
      }
      await _flutterTts.speak(speakableText);
    }
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _ttsState = TtsState.stopped;
        _currentlyPlayingId = null;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _sendMessage({String? prefilledText}) async {
    // 1. Guard against re-entry if a message is already being processed.
    if (_isLoading) return;

    final text = prefilledText ?? _textController.text.trim();
    if (text.isEmpty && _pickedImageBytes == null) return;

    // --- Key Change to Prevent Double-Sending ---
    // We group all initial UI changes into a single, more "atomic" setState call.

    // First, store the message content in local variables, as we will clear the
    // state variables that hold the input content.
    final String messageText = text;
    final Uint8List? imageBytes = _pickedImageBytes;
    final String? imageMimeType = _pickedImageMimeType;

    // Now, update the UI in a single, immediate step.
    setState(() {
      // Set loading to true to disable inputs on the next screen paint.
      _isLoading = true;

      // Add the user's message to the chat list.
      _messages.add(
        ChatMessage(
          text: messageText,
          messageType: MessageType.user,
          imageBytes: imageBytes,
        ),
      );

      // Add the bot's placeholder message right away to prevent multiple setState calls.
      _messages.add(ChatMessage(text: "", messageType: MessageType.bot));

      // Clear the image preview from the input area.
      _pickedImageBytes = null;
      _pickedImageMimeType = null;
    });

    // Clear the text controller *after* setState has captured its value.
    _textController.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();
    await _stop();

    // Build the content for the API call using our local variables.
    final content = _buildContent(messageText, imageBytes, imageMimeType);

    try {
      final stream = widget.aiChatService.sendMessageStream(content);
      String fullResponseText = "";
      await for (final chunk in stream) {
        if (chunk.text != null) {
          fullResponseText += chunk.text!;
          if (mounted) {
            setState(() {
              // Update the last message (the bot's placeholder) with the new text.
              _messages.last.text = fullResponseText;
            });
          }
          _scrollToBottom();
        }
      }
    } catch (e) {
      print("Gemini Stream Error: $e");
      if (mounted) {
        setState(() {
          _messages.last.text = "Sorry, an error occurred: ${e.toString()}";
        });
      }
    } finally {
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Content _buildContent(String text, Uint8List? imageBytes, String? mimeType) {
    if (imageBytes != null && mimeType != null) {
      return Content.multi([
        TextPart(text.isEmpty ? "Analyze this image." : text),
        DataPart(mimeType, imageBytes),
      ]);
    } else {
      return Content.text(text);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (mounted) {
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageMimeType = pickedFile.mimeType ?? 'image/jpeg';
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onMarkdownTapLink(String text, String? href, String title) async {
    if (href != null && href.startsWith('worker://')) {
      final workerId = href.replaceFirst('worker://', '');
      await _stop();
      final Worker? worker = await _firebaseService.getWorkerById(workerId);
      if (worker != null && mounted) {
        widget.onClose();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkerDetailScreen(worker: worker),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomLeft: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(-5, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(theme),
              Expanded(
                child: _messages.length <= 1 && !_isLoading
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_messages.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: _buildMessageBubble(
                                _messages.first,
                                theme,
                              ),
                            ),
                          Expanded(child: _buildSuggestedPrompts(theme)),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _messages.length) {
                            return _buildMessageBubble(_messages[index], theme);
                          } else {
                            return _buildTypingIndicator(theme);
                          }
                        },
                      ),
              ),
              _buildTextInput(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Text(
            "AI Command Center",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isSoundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
            ),
            onPressed: () {
              setState(() {
                _isSoundEnabled = !_isSoundEnabled;
                if (!_isSoundEnabled) {
                  _stop();
                }
              });
            },
            tooltip: "Toggle Sound",
            splashRadius: 20,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: widget.onClose,
            tooltip: "Close",
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts(ThemeData theme) {
    return FadeIn(
      delay: const Duration(milliseconds: 200),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _suggestedPrompts
                .map(
                  (prompt) => ActionChip(
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                    avatar: Icon(
                      Icons.quickreply_outlined,
                      size: 18,
                      color: theme.colorScheme.secondary,
                    ),
                    label: Text(prompt),
                    onPressed: () => _sendMessage(prefilledText: prompt),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final isUser = message.messageType == MessageType.user;
    return FadeInUp(
      from: 20,
      duration: const Duration(milliseconds: 400),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: isUser
            ? _buildSimpleUserBubble(message, theme)
            : _buildBotMessage(message, theme),
      ),
    );
  }

  Widget _buildSimpleUserBubble(ChatMessage message, ThemeData theme) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.imageBytes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(message.imageBytes!, fit: BoxFit.cover),
              ),
            ),
          if (message.text.isNotEmpty)
            MarkdownBody(
              data: message.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBotMessage(ChatMessage message, ThemeData theme) {
    final isError = message.messageType == MessageType.error;
    final isPlaying =
        _currentlyPlayingId == message.id && _ttsState == TtsState.playing;

    String visibleText = message.text.replaceAll(
      RegExp(r'~.*~', dotAll: true),
      '',
    );

    final pattern = RegExp(r'\[([^\]]+)\]\(worker:\/\/([^\)]+)\)');
    final List<String> parts = visibleText.split(pattern);
    final List<Match> matches = pattern.allMatches(visibleText).toList();
    final List<Widget> children = [];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].trim().isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            child: MarkdownBody(
              data: parts[i].trim(),
              onTapLink: _onMarkdownTapLink,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyMedium?.copyWith(
                  color: isError
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onSurface,
                ),
                a: TextStyle(
                  color: theme.colorScheme.secondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        );
      }
      if (i < matches.length) {
        final match = matches[i];
        final displayName = match.group(1)!;
        final workerId = match.group(2)!;
        children.add(_buildWorkerCard(workerId, displayName, theme));
      }
    }

    final bgColor = isError
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.surface;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.isNotEmpty
                  ? children
                  : [const SizedBox.shrink()],
            ),
          ),
          if (!isError &&
              _isSoundEnabled) // Only show button if sound is enabled globally
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline_rounded,
              ),
              onPressed: () {
                if (isPlaying) {
                  _stop();
                } else {
                  _speak(message);
                }
              },
              color: theme.colorScheme.secondary,
              splashRadius: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(
    String workerId,
    String displayName,
    ThemeData theme,
  ) {
    return FutureBuilder<Worker?>(
      future: _firebaseService.getWorkerById(workerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildTypingIndicator(theme);
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final worker = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: TouchableCardWrapper(
            onTap: () => _onMarkdownTapLink(
              displayName,
              'worker://$workerId',
              displayName,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      backgroundImage: worker.profileImage != null
                          ? CachedNetworkImageProvider(worker.profileImage!)
                          : null,
                      child: worker.profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 28,
                              color: theme.colorScheme.onSecondaryContainer,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.name ?? 'Unnamed Worker',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            worker.profession ?? 'No profession listed',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.secondary,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children:
              [
                    ...List.generate(
                      3,
                      (index) => FadeIn(
                        delay: Duration(milliseconds: 200 * index),
                        child: Bounce(
                          infinite: true,
                          delay: Duration(milliseconds: 200 * index),
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: theme.iconTheme.color?.withOpacity(
                              0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]
                  .expand((widget) => [widget, const SizedBox(width: 6)])
                  .toList()
                ..removeLast(),
        ),
      ),
    );
  }

  Widget _buildTextInput(ThemeData theme) {
    bool hasContent =
        _textController.text.isNotEmpty || _pickedImageBytes != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_pickedImageBytes != null) _buildImagePreview(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  onPressed: _isLoading ? null : _pickImage,
                  color: theme.iconTheme.color?.withOpacity(0.7),
                  tooltip: "Attach Image",
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Ask or describe...",
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const ValueKey('send_button'),
                  icon: const Icon(Icons.send_rounded),
                  onPressed: (_isLoading || !hasContent) ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: theme.colorScheme.primary
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return FadeIn(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 40, right: 40),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _pickedImageBytes!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
              onPressed: () => setState(
                () => {_pickedImageBytes = null, _pickedImageMimeType = null},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// This custom widget remains unchanged.
class TouchableCardWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const TouchableCardWrapper({
    Key? key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  }) : super(key: key);

  @override
  _TouchableCardWrapperState createState() => _TouchableCardWrapperState();
}

class _TouchableCardWrapperState extends State<TouchableCardWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      widget.onTap();
    });
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}
