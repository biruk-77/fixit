// lib/ui/panels/ai_chat_panel.dart

import 'dart:convert'; // <-- FIX: Added for jsonDecode
import 'dart:ui'; // <-- FIX: Added for ImageFilter
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img; // For fixing image decoding errors
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
    "Show my unread notifications",
    "What's the price for a carpenter?",
    "Show me all available cleaners",
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
            setState(() => _messages.add(welcomeMessage));
          }
        })
        .catchError((e) {
          print("Error initializing chat: $e");
          if (mounted && _messages.isEmpty) {
            setState(
              () => _messages.add(
                ChatMessage(
                  text: "I couldn't get set up, but I'm still here to help!",
                  messageType: MessageType.error,
                ),
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // --- TTS & MESSAGE HANDLING ---

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    _flutterTts.setStartHandler(
      () => mounted ? setState(() => _ttsState = TtsState.playing) : null,
    );
    _flutterTts.setCompletionHandler(
      () => mounted
          ? setState(() {
              _ttsState = TtsState.stopped;
              _currentlyPlayingId = null;
            })
          : null,
    );
    _flutterTts.setErrorHandler(
      (msg) => mounted
          ? setState(() {
              print("TTS Error: $msg");
              _ttsState = TtsState.stopped;
              _currentlyPlayingId = null;
            })
          : null,
    );
    await _setVoice();
  }

  Future<void> _setVoice() async {
    try {
      await _flutterTts.setLanguage("am-ET");
    } catch (e) {
      await _flutterTts.setLanguage("en-US");
    }
    await _flutterTts.setSpeechRate(0.5);
  }

  String _extractSpokenText(String rawText) {
    final match = RegExp(r'~(.*?)~', dotAll: true).firstMatch(rawText);
    return match?.group(1)?.trim() ??
        rawText
            .replaceAll(RegExp(r'```json.*?```', dotAll: true), '')
            .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), ' ')
            .trim();
  }

  Future<void> _speak(ChatMessage message) async {
    if (_ttsState == TtsState.playing) await _stop();
    final speakableText = _extractSpokenText(message.text);
    if (speakableText.isNotEmpty) {
      if (mounted) setState(() => _currentlyPlayingId = message.id);
      await _flutterTts.speak(speakableText);
    }
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    if (mounted)
      setState(() {
        _ttsState = TtsState.stopped;
        _currentlyPlayingId = null;
      });
  }

  // ### FIX: COMBINED AND ROBUST SEND MESSAGE FUNCTION ###
  Future<void> _sendMessage({String? prefilledText}) async {
    if (_isLoading) return;
    final text = prefilledText ?? _textController.text.trim();
    if (text.isEmpty && _pickedImageBytes == null) return;

    final messageText = text;
    final imageBytes = _pickedImageBytes;
    final mimeType = _pickedImageMimeType;

    int botMessageIndex = -1;

    setState(() {
      _isLoading = true;
      _messages.add(
        ChatMessage(
          text: messageText,
          messageType: MessageType.user,
          imageBytes: imageBytes,
        ),
      );
      // Add a placeholder message and store its index
      _messages.add(ChatMessage(text: "", messageType: MessageType.bot));
      botMessageIndex = _messages.length - 1;

      _pickedImageBytes = null;
      _pickedImageMimeType = null;
    });

    _textController.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();
    await _stop();

    final content = _buildContent(messageText, imageBytes, mimeType);

    try {
      final stream = widget.aiChatService.sendMessageStream(content);
      String fullResponseText = "";
      String lastDisplayedText = ""; // Tracker for deduplication

      await for (final chunk in stream) {
        if (chunk.text != null) {
          fullResponseText += chunk.text!;
          // Only update UI if the new full text is different from what's displayed
          if (fullResponseText != lastDisplayedText && mounted) {
            setState(() {
              _messages[botMessageIndex] = ChatMessage(
                text: fullResponseText,
                messageType: MessageType.bot,
              );
              lastDisplayedText = fullResponseText;
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[botMessageIndex] = ChatMessage(
            text: "Sorry, an error occurred: ${e.toString()}",
            messageType: MessageType.error,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  // ### FIX: ADDED IMAGE RE-ENCODING TO PREVENT CRASHES ###
  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    // Decode and re-encode as JPEG to standardize the format
    final image = img.decodeImage(bytes);
    if (image == null) {
      print("Failed to decode picked image");
      return;
    }
    final jpegBytes = img.encodeJpg(image, quality: 85);

    if (mounted) {
      setState(() {
        _pickedImageBytes = jpegBytes;
        _pickedImageMimeType = 'image/jpeg'; // Always JPEG now
      });
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

  void _onWorkerCardTapped(String workerId) async {
    if (workerId.isEmpty) return;
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

  // --- WIDGET BUILDERS ---

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
                child: _messages.isEmpty
                    ? _buildSuggestedPrompts(theme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _messages.length)
                            return _buildMessageBubble(_messages[index], theme);
                          return _buildTypingIndicator(theme);
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
    // ... no changes
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
            onPressed: () => setState(() {
              _isSoundEnabled = !_isSoundEnabled;
              if (!_isSoundEnabled) _stop();
            }),
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
    // ... no changes
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildMessageBubble(_messages.first, theme),
          ),
        Expanded(
          child: FadeIn(
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
                          backgroundColor: theme.colorScheme.surface
                              .withOpacity(0.8),
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
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    // ... no changes
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
    // ... no changes
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

  // ### FIX: ROBUST BOT MESSAGE PARSING ###
  Widget _buildBotMessage(ChatMessage message, ThemeData theme) {
    final isError = message.messageType == MessageType.error;
    final isPlaying =
        _currentlyPlayingId == message.id && _ttsState == TtsState.playing;

    final jsonRegex = RegExp(r'```json\s*(\{.*?\})\s*```', dotAll: true);
    final jsonMatch = jsonRegex.firstMatch(message.text);

    // Get the raw text, before any JSON blocks
    final rawIntroText = message.text.split("```json").first.trim();

    // ### FIX: Extract only the displayable text (the part before '~') ###
    final introText = rawIntroText.split('~').first.trim();

    Map<String, dynamic>? structuredData;
    if (jsonMatch != null) {
      try {
        structuredData = jsonDecode(jsonMatch.group(1)!);
      } catch (e) {
        print("JSON Decode Error: $e");
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro Text (if any)
        if (introText.isNotEmpty)
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isError
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.zero,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MarkdownBody(
                    data:
                        introText, // This now correctly shows only the display text
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        color: isError
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                if (!isError && _isSoundEnabled)
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline_rounded,
                    ),
                    onPressed: () => isPlaying ? _stop() : _speak(message),
                    color: theme.colorScheme.secondary,
                    splashRadius: 20,
                  ),
              ],
            ),
          ),
        // Structured Data (Cards)
        if (structuredData != null)
          _buildStructuredContent(structuredData, theme),
      ],
    );
  }

  // ### FIX: RENDER STRUCTURED JSON DATA ###
  Widget _buildStructuredContent(Map<String, dynamic> data, ThemeData theme) {
    switch (data['type']) {
      case 'worker_list':
        final workers = (data['workers'] as List? ?? [])
            .map((w) => w as Map<String, dynamic>)
            .toList();
        return Column(
          children: workers
              .map((workerData) => _buildWorkerCard(workerData, theme))
              .toList(),
        );
      case 'notification_list':
        final notifications = (data['notifications'] as List? ?? [])
            .map((n) => n as Map<String, dynamic>)
            .toList();
        return Column(
          children: notifications
              .map(
                (notificationData) =>
                    _buildNotificationCard(notificationData, theme),
              )
              .toList(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ### FIX: BUILD WORKER CARD FROM JSON DATA ###
  Widget _buildWorkerCard(Map<String, dynamic> workerData, ThemeData theme) {
    final workerId = workerData['id'] ?? '';
    final name = workerData['name'] ?? 'Unnamed Worker';
    final profession = workerData['profession'] ?? 'No profession';
    final rating = (workerData['rating'] as num? ?? 0.0).toDouble();
    final location = workerData['location'] ?? 'Not specified';
    final imageUrl = workerData['profileImageUrl'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TouchableCardWrapper(
        onTap: () => _onWorkerCardTapped(workerId),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.secondaryContainer,
                backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImageProvider(imageUrl)
                    : null,
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? Icon(
                        Icons.person,
                        size: 30,
                        color: theme.colorScheme.onSecondaryContainer,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profession,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on,
                          color: theme.colorScheme.secondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.secondary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    ThemeData theme,
  ) {
    // ... no changes
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? 'No details';
    final timestampStr = notification['timestamp'] as String?;
    final time = timestampStr != null
        ? DateFormat.jm().format(DateTime.parse(timestampStr).toLocal())
        : '';
    final type = notification['type'] as String? ?? '';

    final iconData = _getIconForType(type);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TouchableCardWrapper(
        onTap: () {
          // TODO: Implement navigation to job detail or other relevant screen
          print("Tapped notification: $title");
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconData.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: iconData.color.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(iconData.icon, color: iconData.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(time, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  ({IconData icon, Color color}) _getIconForType(String type) {
    if (type.contains('job_request'))
      return (icon: Icons.work_outline, color: Colors.blue);
    if (type.contains('job_accepted'))
      return (icon: Icons.check_circle_outline, color: Colors.green);
    if (type.contains('job_rejected'))
      return (icon: Icons.cancel_outlined, color: Colors.redAccent);
    if (type.contains('job_completed'))
      return (icon: Icons.task_alt, color: Colors.purple);
    if (type.contains('job_started'))
      return (icon: Icons.directions_run, color: Colors.orange);
    if (type.contains('message'))
      return (icon: Icons.message_outlined, color: Colors.teal);
    return (icon: Icons.notifications_active_outlined, color: Colors.blueGrey);
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    // ... no changes
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
          children: List.generate(
            3,
            (index) => FadeIn(
              delay: Duration(milliseconds: 200 * index),
              child: Bounce(
                infinite: true,
                delay: Duration(milliseconds: 200 * index),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: theme.iconTheme.color?.withOpacity(0.4),
                ),
              ),
            ),
          ).expand((w) => [w, const SizedBox(width: 6)]).toList()..removeLast(),
        ),
      ),
    );
  }

  Widget _buildTextInput(ThemeData theme) {
    // ... no changes
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
    // ... no changes
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

class TouchableCardWrapper extends StatefulWidget {
  // ... no changes
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
  // ... no changes
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
    _controller.reverse().then((_) => widget.onTap());
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
