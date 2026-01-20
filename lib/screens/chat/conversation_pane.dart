import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:audio_waveforms/audio_waveforms.dart' as audio_waveforms;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../jobs/quick_job_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../models/chat_message.dart';
import '../../models/job.dart';
import '../../models/user.dart' as AppUser;
import '../../models/worker.dart';
import '../../services/ai_chat_service.dart';
import '../../services/app_string.dart';
import '../../services/firebase_service.dart';
import '../chat_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../worker_detail_screen.dart';

const String AI_USER_ID = 'min-atu-ai-assistant';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  const ImageViewerScreen({super.key, required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime timestamp;
  const _DateDivider({required this.timestamp});

  String _formatDate(DateTime date, AppStrings appStrings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) return appStrings.convoDateToday;
    if (messageDay == yesterday) return appStrings.convoDateYesterday;
    if (now.difference(messageDay).inDays < 7) {
      return DateFormat.EEEE().format(date);
    }
    return DateFormat.yMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _formatDate(timestamp, appStrings),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

// --- MAIN CONVERSATION PANE WIDGET ---
class ConversationPane extends StatefulWidget {
  final String otherUserId;
  const ConversationPane({super.key, required this.otherUserId});

  @override
  State<ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends State<ConversationPane> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseService _firebaseService = FirebaseService();
  final String? _currentUserId = FirebaseService().getCurrentUser()?.uid;
  final Uuid _uuid = const Uuid();

  late final bool _isAiChat;
  final AiChatService _aiChatService = AiChatService();
  bool _isAiInitialized = false;
  final List<ChatMessage> _aiMessages = [];
  bool _isAiLoading = false;
  Uint8List? _pickedImageBytesForAi;

  AppUser.AppUser? _currentUser;
  AppUser.AppUser? _otherUser;
  String? _chatRoomId;
  bool _showScrollToBottomButton = false;
  Timer? _typingTimer;
  ChatMessage? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    _isAiChat = widget.otherUserId == AI_USER_ID;

    // Add lifecycle observer to track app state changes
    WidgetsBinding.instance.addObserver(this);

    // Set user presence to online when entering chat
    if (!_isAiChat) {
      _setUserOnline();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_isAiChat) {
          _initializeAiChat();
        } else {
          _initializeHumanChat();
        }
      }
    });

    _scrollController.addListener(_scrollListener);
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _setTypingStatus(false);
    _typingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    
    // Set user presence to offline when leaving chat
    if (!_isAiChat) {
      _setUserOffline();
    }
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }

  // Handle app lifecycle changes for presence management
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAiChat) return; // Skip for AI chat
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        _setUserOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background
        _setUserOffline();
        break;
    }
  }

  // Set current user's presence to online
  Future<void> _setUserOnline() async {
    if (_currentUserId == null) return;
    try {
      await _firebaseService.updateUserPresence('online');
      debugPrint("✅ User presence set to ONLINE");
    } catch (e) {
      debugPrint("❌ Error setting user online: $e");
    }
  }

  // Set current user's presence to offline
  Future<void> _setUserOffline() async {
    if (_currentUserId == null) return;
    try {
      await _firebaseService.updateUserPresence('offline');
      debugPrint("✅ User presence set to OFFLINE");
    } catch (e) {
      debugPrint("❌ Error setting user offline: $e");
    }
  }

  Future<void> _initializeAiChat() async {
    final appStrings = AppLocalizations.of(context)!;
    setState(() => _isAiLoading = true);
    await _firebaseService.getCurrentUserProfile().then((user) {
      if (mounted) setState(() => _currentUser = user);
    });

    await _aiChatService
        .initializePersonalizedChat()
        .then((_) {
          if (mounted) {
            setState(() {
              _isAiInitialized = true;
              _aiMessages.add(
                ChatMessage(
                  id: _uuid.v4(),
                  senderId: AI_USER_ID,
                  receiverId: _currentUserId!,
                  message: appStrings.convoAiWelcome,
                  timestamp: DateTime.now(),
                ),
              );
              _isAiLoading = false;
            });
          }
        })
        .catchError((e) {
          debugPrint("AI Initialization Failed: $e");
          if (mounted) {
            setState(() {
              _aiMessages.add(
                ChatMessage(
                  id: _uuid.v4(),
                  senderId: AI_USER_ID,
                  receiverId: _currentUserId!,
                  message: appStrings.convoAiErrorInit,
                  timestamp: DateTime.now(),
                  messageType: 'error',
                ),
              );
              _isAiLoading = false;
            });
          }
        });
  }

  Future<void> _initializeHumanChat() async {
    if (_currentUserId == null) return;
    _chatRoomId = _getChatRoomId(_currentUserId, widget.otherUserId);

    final results = await Future.wait([
      _firebaseService.getUser(_currentUserId),
      _firebaseService.getUser(widget.otherUserId),
    ]);

    if (mounted) {
      setState(() {
        _currentUser = results[0];
        _otherUser = results[1];
      });
    }
  }

  void _onTextChanged() {
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
    if (!_isAiChat) {
      _setTypingStatus(true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _setTypingStatus(false);
      });
    }
    if (mounted) setState(() {});
  }

  void _scrollListener() {
    if (_scrollController.position.pixels > 300 && !_showScrollToBottomButton) {
      setState(() => _showScrollToBottomButton = true);
    } else if (_scrollController.position.pixels <= 300 &&
        _showScrollToBottomButton) {
      setState(() => _showScrollToBottomButton = false);
    }
  }

  Future<void> _sendMessage(ChatMessage message) async {
    if (_chatRoomId == null) return;
    final appStrings = AppLocalizations.of(context)!;

    _messageController.clear();
    _setTypingStatus(false);
    _typingTimer?.cancel();
    FocusScope.of(context).unfocus();
    if (mounted) setState(() => _replyingToMessage = null);

    final messageData = message.toJson();
    final chatRoomRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId);
    final messagesRef = chatRoomRef.collection('messages');

    String lastMessageContent = message.message;
    switch (message.messageType) {
      case 'image':
        lastMessageContent = appStrings.chatListLastMsgPhoto;
        break;
      case 'audio':
        lastMessageContent = appStrings.chatListLastMsgVoice;
        break;
      case 'file':
        lastMessageContent = appStrings.convoLastMsgAttachment;
        break;
      case 'job_proposal':
        lastMessageContent = appStrings.convoLastMsgJobProposal;
        break;
    }

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.set(messagesRef.doc(message.id), messageData);
      batch.set(chatRoomRef, {
        'participants': [_currentUserId, widget.otherUserId],
        'lastMessage': lastMessageContent,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId,
        'participantDetails': {
          _currentUserId!: {
            'uid': _currentUser?.uid,
            'name': _currentUser?.name,
            'profileImage': _currentUser?.profileImage,
          },
          widget.otherUserId: {
            'uid': _otherUser?.uid,
            'name': _otherUser?.name,
            'profileImage': _otherUser?.profileImage,
          },
        },
      }, SetOptions(merge: true));
      await batch.commit();

      await _firebaseService.createNotification(
        userId: widget.otherUserId,
        title: appStrings.convoNewMessageNotifTitle(
          _currentUser?.name ?? appStrings.convoNewMessageNotifTitleDefault,
        ),
        body: lastMessageContent,
        type: 'message_received',
        data: {
          'chatRoomId': _chatRoomId,
          'senderId': _currentUserId,
          'senderName': _currentUser?.name,
          'senderImageUrl': _currentUser?.profileImage,
        },
      );
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  Future<void> _handleSendPressed() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _pickedImageBytesForAi == null) ||
        _currentUserId == null) {
      return;
    }

    if (_isAiChat) {
      await _handleAiQuery(text, imageBytes: _pickedImageBytesForAi);
      setState(() {
        _pickedImageBytesForAi = null;
      });
    } else {
      final appStrings = AppLocalizations.of(context)!;
      final replyMessage = _replyingToMessage;
      final newMessage = ChatMessage(
        id: _uuid.v4(),
        senderId: _currentUserId,
        receiverId: widget.otherUserId,
        message: text,
        timestamp: DateTime.now(),
        messageType: 'text',
        reactions: {},
        data: {},
        replyToMessageId: replyMessage?.id,
        replyToMessageText: replyMessage?.message,
        replyToSenderName: replyMessage?.senderId == _currentUserId
            ? appStrings.convoReplyToYou
            : _otherUser?.name,
        replyToMessageType: replyMessage?.messageType,
      );
      await _sendMessage(newMessage);
    }
  }

  Future<void> _handleAiQuery(String query, {Uint8List? imageBytes}) async {
    final appStrings = AppLocalizations.of(context)!;
    if (!_isAiInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings.convoAiStillInitializing)),
      );
      return;
    }

    _messageController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _aiMessages.add(
        ChatMessage(
          id: _uuid.v4(),
          senderId: _currentUserId!,
          receiverId: AI_USER_ID,
          message: query,
          timestamp: DateTime.now(),
          data: imageBytes != null ? {'image_bytes': imageBytes} : null,
        ),
      );
      _isAiLoading = true;
    });
    _scrollToBottom();

    try {
      final content = [
        if (query.isNotEmpty) TextPart(query),
        if (imageBytes != null) DataPart('image/jpeg', imageBytes),
      ];

      final stream = _aiChatService.sendMessageStream(Content.multi(content));
      String fullResponse = "";
      final botMessageId = _uuid.v4();

      setState(() {
        _aiMessages.add(
          ChatMessage(
            id: botMessageId,
            senderId: AI_USER_ID,
            receiverId: _currentUserId!,
            message: "",
            timestamp: DateTime.now(),
          ),
        );
      });

      await for (final chunk in stream) {
        if (chunk.text != null) {
          fullResponse += chunk.text!;
          if (mounted) {
            setState(() {
              final index = _aiMessages.indexWhere((m) => m.id == botMessageId);
              if (index != -1) {
                _aiMessages[index] = _aiMessages[index].copyWith(
                  message: fullResponse,
                );
              }
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint("Error querying AI: $e");
      setState(() {
        _aiMessages.add(
          ChatMessage(
            id: _uuid.v4(),
            senderId: AI_USER_ID,
            receiverId: _currentUserId!,
            message: appStrings.convoAiErrorThinking,
            timestamp: DateTime.now(),
            messageType: 'error',
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _handleFileUpload(file_picker.PlatformFile platformFile) async {
    if (_currentUserId == null) return;
    final appStrings = AppLocalizations.of(context)!;

    if (_isAiChat) {
      final bytes = kIsWeb
          ? platformFile.bytes
          : await File(platformFile.path!).readAsBytes();
      final image = img.decodeImage(bytes!);
      if (image == null) return;
      final jpegBytes = Uint8List.fromList(img.encodeJpg(image, quality: 85));
      setState(() {
        _pickedImageBytesForAi = jpegBytes;
      });
      return;
    }

    final fileUrl = await _firebaseService.uploadJobAttachment(
      platformFile: platformFile,
      userId: _currentUserId,
    );

    if (fileUrl != null) {
      final isImage = [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
      ].any((ext) => platformFile.name.toLowerCase().endsWith(ext));
      final isAudio = [
        'm4a',
        'aac',
        'mp3',
        'wav',
        'ogg',
      ].any((ext) => platformFile.name.toLowerCase().endsWith(ext));
      String messageType = isImage ? 'image' : (isAudio ? 'audio' : 'file');

      final newMessage = ChatMessage(
        id: _uuid.v4(),
        senderId: _currentUserId,
        receiverId: widget.otherUserId,
        message: fileUrl,
        timestamp: DateTime.now(),
        messageType: messageType,
        reactions: {},
        data: (isImage || isAudio)
            ? {}
            : {'fileName': platformFile.name, 'fileSize': platformFile.size},
      );
      _sendMessage(newMessage);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appStrings.convoErrorFileUpload)),
        );
      }
    }
  }

  Future<void> _deleteMessageForMe(String messageId) async {
    final appStrings = AppLocalizations.of(context)!;
    // NOTE: For 'Delete for Me' in a real app, you would typically add the message ID
    // to a local list or database of 'hidden messages' and filter the StreamBuilder
    // results to exclude that message ID for the current user.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(appStrings.convoMsgDeletedForMe)));
  }

  Future<void> _deleteMessageForEveryone(ChatMessage message) async {
    if (_chatRoomId == null) return;
    final appStrings = AppLocalizations.of(context)!;
    final timeSinceSent = DateTime.now().difference(message.timestamp);
    if (timeSinceSent.inMinutes > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appStrings.convoErrorDeleteForEveryoneTimeLimit),
        ),
      );
      return;
    }
    try {
      // Deleting from Firestore triggers stream refresh for both users
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages')
          .doc(message.id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings.convoMsgDeletedForEveryone)),
      );
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  Future<void> _clearChatHistory() async {
    if (_chatRoomId == null || !mounted) return;
    final appStrings = AppLocalizations.of(context)!;
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .get();
    if (messagesSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings.convoErrorChatAlreadyEmpty)),
      );
      return;
    }
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    try {
      await batch.commit();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appStrings.convoMsgChatCleared)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appStrings.convoErrorClearChat)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isAiChat ? _buildAiChatList() : _buildHumanChatList(),
          ),
          if (!_isAiChat) _buildTypingIndicator(),
          MessageInputComposer(
            controller: _messageController,
            onSend: _handleSendPressed,
            onAttachment: _handleFileUpload,
            replyingTo: _replyingToMessage,
            onCancelReply: () => setState(() => _replyingToMessage = null),
            onAudioFile: _handleFileUpload,
            isAiChat: _isAiChat,
            pickedImageBytesForAi: _pickedImageBytesForAi,
            onClearAiImage: () => setState(() => _pickedImageBytesForAi = null),
            otherUserName: _otherUser?.name,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final appStrings = AppLocalizations.of(context)!;
    if (_isAiChat) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              appStrings.convoAiAppBarTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_otherUser == null) {
      return AppBar(title: Text(appStrings.convoAppBarLoading));
    }
    final hasImage = _otherUser?.profileImage?.isNotEmpty ?? false;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _navigateBack,
      ),
      title: GestureDetector(
        onTap: _navigateToUserProfile,
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: hasImage
                    ? CachedNetworkImageProvider(_otherUser!.profileImage!)
                    : null,
                child: !hasImage
                    ? Text(
                        _otherUser!.name.isNotEmpty
                            ? _otherUser!.name[0].toUpperCase()
                            : '?',
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otherUser!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _firebaseService.streamUserPresence(
                        widget.otherUserId,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData ||
                            snapshot.data?.data() == null) {
                          return Text(
                            appStrings.convoUserStatusOffline,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        }
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final status = data['status'] as String?;
                        final lastSeen = data['last_seen'] as Timestamp?;

                        if (status == 'online') {
                          return Text(
                            appStrings.convoUserStatusOnline,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade400,
                            ),
                          );
                        } else {
                          return Text(
                            lastSeen != null
                                ? appStrings.convoUserStatusLastSeen(
                                    timeago.format(lastSeen.toDate()),
                                  )
                                : appStrings.convoUserStatusOffline,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _makePhoneCall,
          icon: const Icon(Icons.call_outlined),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'clear_chat') {
              _clearChatHistory();
            } else if (value == 'view_profile') {
              _navigateToUserProfile();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'view_profile',
              child: Text(appStrings.convoMenuViewProfile),
            ),
            PopupMenuItem<String>(
              value: 'clear_chat',
              child: Text(appStrings.convoMenuClearChat),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToUserProfile() async {
    final String userIdToNavigate = widget.otherUserId;
    final appStrings = AppLocalizations.of(context)!;

    if (userIdToNavigate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings.convoErrorProfileIdMissing)),
      );
      return;
    }

    try {
      final workerProfile = await _firebaseService.getWorkerById(
        userIdToNavigate,
      );

      if (mounted) Navigator.pop(context);

      if (workerProfile != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerDetailScreen(worker: workerProfile),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appStrings.convoErrorProfileLoad)),
        );
      }
    } catch (e) {
      debugPrint("🔥 An error occurred during navigation: $e");
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appStrings.convoErrorGeneric)));
    }
  }

  Future<void> _makePhoneCall() async {
    final appStrings = AppLocalizations.of(context)!;
    if (_otherUser == null || _otherUser!.phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings.convoErrorPhoneNotAvailable)),
      );
      return;
    }
    final Uri phoneCallUri = Uri(scheme: 'tel', path: _otherUser!.phoneNumber);
    if (await canLaunchUrl(phoneCallUri)) {
      await launchUrl(phoneCallUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appStrings.convoErrorPhoneLaunch(_otherUser!.phoneNumber),
          ),
        ),
      );
    }
  }

  Widget _buildAiChatList() {
    if (_isAiLoading && _aiMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayMessages = _aiMessages.toList();

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      itemCount: displayMessages.length + (_isAiLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isAiLoading && index == 0) {
          return Align(
            alignment: Alignment.centerLeft,
            child: _TypingIndicatorBubble(),
          );
        }
        final messageIndex = _isAiLoading ? index - 1 : index;
        final message = displayMessages.reversed.toList()[messageIndex];

        return MessageBubble(
          message: message,
          isMe: message.senderId == _currentUserId,
          chatRoomId: 'ai-chat',
          isLastInGroup: true,
          onReply: () {},
          onDeleteForMe: () {},
          onDeleteForEveryone: () {},
        );
      },
    );
  }

  Widget _buildHumanChatList() {
    if (_chatRoomId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final appStrings = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text(appStrings.convoEmptyHumanChat));
        }
        final messagesDocs = snapshot.data!.docs;
        _markMessagesAsRead(messagesDocs);
        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 12.0,
              ),
              reverse: true,
              itemCount: messagesDocs.length,
              itemBuilder: (context, index) {
                final data = messagesDocs[index].data() as Map<String, dynamic>;
                data['id'] = messagesDocs[index].id;
                final message = ChatMessage.fromJson(data);
                final prevMessage = (index < messagesDocs.length - 1)
                    ? ChatMessage.fromJson(
                        messagesDocs[index + 1].data() as Map<String, dynamic>,
                      )
                    : null;
                final bool showDateDivider =
                    (index == messagesDocs.length - 1) ||
                    (message.timestamp
                            .difference(prevMessage!.timestamp)
                            .inDays
                            .abs() >
                        0);
                final nextMessage = (index > 0)
                    ? ChatMessage.fromJson(
                        messagesDocs[index - 1].data() as Map<String, dynamic>,
                      )
                    : null;
                final isLastInGroup =
                    nextMessage == null ||
                    nextMessage.senderId != message.senderId ||
                    message.timestamp
                            .difference(nextMessage.timestamp)
                            .inMinutes >
                        5;

                return Column(
                  children: [
                    if (showDateDivider)
                      _DateDivider(timestamp: message.timestamp),
                    // SwipeTo enables the slide-to-reply functionality
                    SwipeTo(
                      onRightSwipe: (details) {
                        HapticFeedback.lightImpact();
                        setState(() => _replyingToMessage = message);
                      },
                      child: MessageBubble(
                        message: message,
                        isMe: message.senderId == _currentUserId,
                        chatRoomId: _chatRoomId!,
                        isLastInGroup: isLastInGroup,
                        onReply: () =>
                            setState(() => _replyingToMessage = message),
                        onDeleteForMe: () => _deleteMessageForMe(message.id),
                        onDeleteForEveryone: () =>
                            _deleteMessageForEveryone(message),
                        otherUserProfileImage: _otherUser?.profileImage,
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_showScrollToBottomButton)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'chat_scroll_fab',
                  onPressed: () => _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                  child: const Icon(Icons.arrow_downward, size: 20),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    if (_chatRoomId == null) return const SizedBox.shrink();
    final appStrings = AppLocalizations.of(context)!;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatRoomId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final typing = data?['typing'] as Map<String, dynamic>?;

        if (typing?[widget.otherUserId] == true) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
            child: Row(
              children: [
                FadeIn(
                  child: Text(
                    appStrings.convoTypingIndicator(
                      _otherUser?.name ??
                          appStrings.convoTypingIndicatorDefault,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _markMessagesAsRead(List<QueryDocumentSnapshot> docs) {
    final batch = FirebaseFirestore.instance.batch();
    int unreadCount = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;
      if (data['senderId'] == widget.otherUserId && data['isRead'] == false) {
        batch.update(doc.reference, {'isRead': true});
        unreadCount++;
      }
    }
    if (unreadCount > 0) {
      batch.commit().catchError((error) {
        debugPrint("Error marking messages as read: $error");
      });
    }
  }

  String _getChatRoomId(String userId1, String userId2) {
    if (userId1.hashCode <= userId2.hashCode) {
      return '${userId1}_$userId2';
    } else {
      return '${userId2}_$userId1';
    }
  }

  void _navigateBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (context) => const UnifiedChatScreen()),
      );
    }
  }

  Future<void> _setTypingStatus(bool isTyping) async {
    if (_chatRoomId == null || _currentUserId == null) return;
    try {
      await FirebaseFirestore.instance.collection('chats').doc(_chatRoomId).set(
        {
          'typing': {_currentUserId: isTyping},
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("Error setting typing status: $e");
    }
  }
}

// =======================================================================
// === Message Bubbles & Content Widgets
// =======================================================================

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String chatRoomId;
  final bool isLastInGroup;
  final VoidCallback onReply;
  final VoidCallback onDeleteForMe;
  final VoidCallback onDeleteForEveryone;
  final String? otherUserProfileImage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.chatRoomId,
    required this.isLastInGroup,
    required this.onReply,
    required this.onDeleteForMe,
    required this.onDeleteForEveryone,
    this.otherUserProfileImage,
  });

  Future<void> _onReaction(String emoji) async {
    if (chatRoomId == 'ai-chat') return;
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(message.id);
    final currentUserId = FirebaseService().getCurrentUser()?.uid;
    if (currentUserId == null) return;
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(messageRef);
      if (!docSnapshot.exists) return;
      final reactions = Map<String, String>.from(
        docSnapshot.data()?['reactions'] as Map? ?? {},
      );
      if (reactions[currentUserId] == emoji) {
        reactions.remove(currentUserId);
      } else {
        reactions[currentUserId] = emoji;
      }
      transaction.update(messageRef, {'reactions': reactions});
    });
  }

  void _showMessageActions(BuildContext context) {
    if (chatRoomId == 'ai-chat') return;
    final appStrings = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['👍', '❤️', '😂', '😮', '😢', '🙏']
                        .map(
                          (emoji) => InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _onReaction(emoji);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.reply_outlined),
                  title: Text(appStrings.convoActionReply),
                  onTap: () {
                    Navigator.pop(context);
                    onReply();
                  },
                ),
                if (message.messageType == 'text')
                  ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: Text(appStrings.convoActionCopy),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.message));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(appStrings.convoMsgCopied)),
                      );
                    },
                  ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    appStrings.convoActionDeleteForMe,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDeleteForMe();
                  },
                ),
                if (isMe)
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      appStrings.convoActionDeleteForEveryone,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onDeleteForEveryone();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAiBubble = message.senderId == AI_USER_ID;

    final bubbleColor = isMe
        ? theme.colorScheme.primaryContainer
        : (isAiBubble
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerHighest);

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && isLastInGroup) _buildAvatar(theme, isAiBubble),
            GestureDetector(
              onLongPress: () => _showMessageActions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                margin: EdgeInsets.only(
                  top: 4,
                  bottom: 2,
                  left: isMe ? 0 : (isLastInGroup ? 8 : 46),
                  right: isMe ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isMe
                        ? const Radius.circular(18)
                        : (isLastInGroup
                              ? const Radius.circular(4)
                              : const Radius.circular(18)),
                    bottomRight: isMe
                        ? (isLastInGroup
                              ? const Radius.circular(4)
                              : const Radius.circular(18))
                        : const Radius.circular(18),
                  ),
                ),
                child: MessageContent(message: message, isMe: isMe),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 2,
            right: isMe ? 12 : 0,
            left: isMe ? 0 : 54,
          ),
          child: _buildTimestampAndStatus(
            theme,
            metaColor: theme.textTheme.bodySmall!.color!,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildAvatar(ThemeData theme, bool isAiBubble) {
    final hasImage = otherUserProfileImage?.isNotEmpty ?? false;
    return CircleAvatar(
      radius: 14,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: hasImage
          ? CachedNetworkImageProvider(otherUserProfileImage!)
          : null,
      child: isAiBubble
          ? Icon(
              Icons.auto_awesome,
              size: 16,
              color: theme.colorScheme.secondary,
            )
          : (!hasImage
                ? Text(
                    "?",
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  )
                : null),
    );
  }

  Widget _buildTimestampAndStatus(ThemeData theme, {required Color metaColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          DateFormat.jm().format(message.timestamp),
          style: TextStyle(fontSize: 11, color: metaColor),
        ),
        if (isMe) const SizedBox(width: 4),
        if (isMe)
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 14,
            color: message.isRead ? Colors.lightBlue.shade300 : metaColor,
          ),
      ],
    );
  }
}

class MessageContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const MessageContent({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAiBubble = message.senderId == AI_USER_ID;

    final textColor = isMe
        ? theme.colorScheme.onPrimaryContainer
        : (isAiBubble
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onSurface);

    final metaColor =
        (isMe
                ? theme.colorScheme.onPrimaryContainer
                : (isAiBubble
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurface))
            .withOpacity(0.7);

    Widget timestampWidget = Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat.jm().format(message.timestamp),
            style: TextStyle(fontSize: 11, color: metaColor),
          ),
          if (isMe) const SizedBox(width: 4),
          if (isMe)
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 14,
              color: message.isRead ? Colors.lightBlue.shade300 : metaColor,
            ),
        ],
      ),
    );

    switch (message.messageType) {
      case 'image':
        return ImageMessageContent(
          imageUrl: message.message,
          timestampWidget: timestampWidget,
          isAiImage: message.data?['image_bytes'] != null,
          imageBytes: message.data?['image_bytes'],
        );
      case 'audio':
        return AudioWaveformPlayer(
          audioUrl: message.message,
          isMe: isMe,
          timestampWidget: timestampWidget,
        );
      case 'file':
        return FileMessageContent(
          fileUrl: message.message,
          data: message.data ?? {},
          isMe: isMe,
          timestampWidget: timestampWidget,
        );
      case 'job_proposal':
        return JobCardMessageContent(
          jobId: message.data?['jobId'],
          isMe: isMe,
          timestampWidget: timestampWidget,
        );
      default:
        final jsonRegex = RegExp(r'```json\s*(\{.*?\})\s*```', dotAll: true);
        final jsonMatch = jsonRegex.firstMatch(message.message);
        final introText = message.message.split("```json").first.trim();

        if (isAiBubble && jsonMatch != null) {
          try {
            final structuredData = jsonDecode(jsonMatch.group(1)!);
            return AiStructuredContent(
              introText: introText,
              structuredData: structuredData,
              timestampWidget: timestampWidget,
            );
          } catch (e) {
            debugPrint("Failed to parse AI JSON: $e");
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              MarkdownBody(
                data: message.message,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 16, color: textColor),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class ImageMessageContent extends StatelessWidget {
  final String? imageUrl;
  final Widget timestampWidget;
  final bool isAiImage;
  final Uint8List? imageBytes;

  const ImageMessageContent({
    super.key,
    this.imageUrl,
    required this.timestampWidget,
    this.isAiImage = false,
    this.imageBytes,
  });
  @override
  Widget build(BuildContext context) {
    final hasRemoteUrl = imageUrl?.isNotEmpty ?? false;

    Widget imageWidget;
    if (isAiImage && imageBytes != null) {
      imageWidget = Image.memory(imageBytes!, fit: BoxFit.cover);
    } else if (hasRemoteUrl) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (c, u) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white, width: 220, height: 220),
        ),
      );
    } else {
      imageWidget = Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image),
      );
    }

    return GestureDetector(
      onTap: hasRemoteUrl
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewerScreen(imageUrl: imageUrl!),
              ),
            )
          : null,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                  maxWidth: 250,
                ),
                child: imageWidget,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 11),
                child: timestampWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AudioWaveformPlayer extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final Widget timestampWidget;
  const AudioWaveformPlayer({
    super.key,
    required this.audioUrl,
    required this.isMe,
    required this.timestampWidget,
  });

  @override
  State<AudioWaveformPlayer> createState() => _AudioWaveformPlayerState();
}

class _AudioWaveformPlayerState extends State<AudioWaveformPlayer> {
  final audio_waveforms.PlayerController _playerController =
      audio_waveforms.PlayerController();
  bool _isPlayerReady = false;
  bool _hasError = false;
  bool _isLoading = true;
  int? _maxDurationMs;
  double _currentSpeed = 1.0;
  final List<double> _speeds = [1.0, 1.5, 2.0];
  StreamSubscription<List<double>>? _waveformSubscription;

  @override
  void initState() {
    super.initState();
    _preparePlayer();
  }

  Future<void> _preparePlayer() async {
    if (widget.audioUrl.isEmpty || !Uri.parse(widget.audioUrl).isAbsolute) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      final String pathToPlay = await _getLocalPathForAudio(widget.audioUrl);

      _waveformSubscription = _playerController.onCurrentExtractedWaveformData
          .listen((wave) async {
            if (wave.isNotEmpty && mounted && !_isPlayerReady) {
              _maxDurationMs = await _playerController.getDuration(
                audio_waveforms.DurationType.max,
              );
              if (mounted) {
                setState(() {
                  _isPlayerReady = true;
                  _isLoading = false;
                  _hasError = false;
                });
              }
              await _waveformSubscription?.cancel();
            }
          });

      await _playerController.preparePlayer(
        path: pathToPlay,
        shouldExtractWaveform: true,
        volume: 1.0,
      );
    } catch (e) {
      debugPrint("CRITICAL ERROR in _preparePlayer: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getLocalPathForAudio(String url) async {
    if (url.startsWith('http')) {
      final tempDir = await getTemporaryDirectory();
      final fileName = Uri.parse(url).pathSegments.last;
      final localPath = '${tempDir.path}/$fileName';
      final localFile = File(localPath);

      if (!await localFile.exists()) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await localFile.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception(
            'Failed to download audio file: ${response.statusCode}',
          );
        }
      }
      return localPath;
    }
    return url;
  }

  void _toggleSpeed() {
    final currentIndex = _speeds.indexOf(_currentSpeed);
    final nextIndex = (currentIndex + 1) % _speeds.length;
    final newSpeed = _speeds[nextIndex];
    _playerController.setRate(newSpeed);
    setState(() => _currentSpeed = newSpeed);
  }

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null || milliseconds < 0) return "00:00";
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _waveformSubscription?.cancel();
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = widget.isMe
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    if (_hasError) {
      return _buildErrorState(theme);
    }
    if (_isLoading || !_isPlayerReady) {
      return _buildLoadingState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ).copyWith(right: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerIcon(controller: _playerController, iconColor: colorScheme),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                audio_waveforms.AudioFileWaveforms(
                  size: const Size(double.infinity, 30.0),
                  playerController: _playerController,
                  enableSeekGesture: true,
                  waveformType: audio_waveforms.WaveformType.long,
                  playerWaveStyle: audio_waveforms.PlayerWaveStyle(
                    fixedWaveColor: colorScheme.withOpacity(0.35),
                    liveWaveColor: colorScheme,
                    spacing: 4,
                    waveThickness: 3,
                    showSeekLine: false,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      StreamBuilder<int>(
                        stream: _playerController.onCurrentDurationChanged,
                        builder: (context, snapshot) {
                          return Text(
                            _formatDuration(snapshot.data),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.withOpacity(0.7),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(_maxDurationMs),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: InkWell(
              onTap: _toggleSpeed,
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: Text(
                  '${_currentSpeed.toStringAsFixed(1)}x',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() => const Padding(
    padding: EdgeInsets.all(12.0),
    child: SizedBox(
      width: 30,
      height: 30,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _buildErrorState(ThemeData theme) {
    final appStrings = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 30),
          const SizedBox(width: 8),
          Text(
            appStrings.convoAudioPlaybackError,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}

class PlayerIcon extends StatelessWidget {
  const PlayerIcon({
    super.key,
    required this.controller,
    required this.iconColor,
  });
  final audio_waveforms.PlayerController controller;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<audio_waveforms.PlayerState>(
      stream: controller.onPlayerStateChanged,
      builder: (context, snapshot) {
        final playerState =
            snapshot.data ?? audio_waveforms.PlayerState.stopped;
        final isPlaying = playerState == audio_waveforms.PlayerState.playing;

        return IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: iconColor,
            size: 30,
          ),
          onPressed: () async {
            if (isPlaying) {
              try {
                await controller.pausePlayer();
              } on Object catch (e) {
                debugPrint('Error pausing player: $e');
              }
            } else {
              try {
                if (playerState == audio_waveforms.PlayerState.stopped) {
                  await audio_waveforms.AudioWaveformsInterface.instance.seekTo(
                    controller.playerKey,
                    0,
                  );
                  await controller.pausePlayer();
                }
                await controller.startPlayer();
              } on Object catch (e) {
                debugPrint('Error playing player: $e');
              }
            }
          },
        );
      },
    );
  }
}

class FileMessageContent extends StatelessWidget {
  final String fileUrl;
  final Map<String, dynamic> data;
  final bool isMe;
  final Widget timestampWidget;
  const FileMessageContent({
    super.key,
    required this.fileUrl,
    required this.data,
    required this.isMe,
    required this.timestampWidget,
  });
  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!;
    // FIXED: Use outlined icon and no circular background
    final fileName = data['fileName'] ?? appStrings.convoLastMsgAttachment;
    final theme = Theme.of(context);
    final color = isMe
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: () async {
        final uri = Uri.parse(fileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              color: color.withOpacity(0.8),
              size: 36,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JobCardMessageContent extends StatelessWidget {
  final String? jobId;
  final bool isMe;
  final Widget timestampWidget;
  const JobCardMessageContent({
    super.key,
    required this.jobId,
    required this.isMe,
    required this.timestampWidget,
  });

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = isMe
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    if (jobId == null) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          appStrings.convoJobProposalInvalid,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }
    return FutureBuilder<Job?>(
      future: FirebaseService().getJobById(jobId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final job = snapshot.data!;
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => JobDetailScreen(job: job)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_outline_rounded, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      appStrings.convoJobProposalTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Divider(color: color.withOpacity(0.3), height: 16),
                Text(
                  job.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appStrings.convoJobProposalBudget(
                    job.budget.toStringAsFixed(0),
                  ),
                  style: TextStyle(color: color.withOpacity(0.9)),
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.bottomRight, child: timestampWidget),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AiStructuredContent extends StatelessWidget {
  final String introText;
  final Map<String, dynamic> structuredData;
  final Widget timestampWidget;

  const AiStructuredContent({
    super.key,
    required this.introText,
    required this.structuredData,
    required this.timestampWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    final type = structuredData['type'];

    if (type == 'worker_list') {
      final workers = (structuredData['workers'] as List? ?? [])
          .map((w) => w as Map<String, dynamic>)
          .toList();
      content = Column(
        children: workers
            .map((workerData) => _buildWorkerCard(context, workerData))
            .toList(),
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (introText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: MarkdownBody(
                data: introText,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          content,
          Align(alignment: Alignment.bottomRight, child: timestampWidget),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(
    BuildContext context,
    Map<String, dynamic> workerData,
  ) {
    final theme = Theme.of(context);
    final workerId = workerData['id'] ?? '';
    final name = workerData['name'] ?? 'Unnamed';
    final profession = workerData['profession'] ?? '';
    final rating = (workerData['rating'] as num? ?? 0.0).toDouble();
    final imageUrl = workerData['profileImageUrl'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          if (workerId.isEmpty) return;
          final Worker? worker = await FirebaseService().getWorkerById(
            workerId,
          );
          if (worker != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WorkerDetailScreen(worker: worker),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImageProvider(imageUrl)
                    : null,
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(profession, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class ReplyPreviewInBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const ReplyPreviewInBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isAiBubble = message.senderId == AI_USER_ID;

    final color = isMe
        ? theme.colorScheme.onPrimary.withOpacity(0.8)
        : (isAiBubble
              ? theme.colorScheme.onSecondaryContainer.withOpacity(0.8)
              : theme.colorScheme.onSurfaceVariant);
    final nameColor = isMe
        ? theme.colorScheme.onPrimary
        : (isAiBubble
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.primary);

    String contentPreview = message.replyToMessageText ?? '';
    if (message.replyToMessageType == 'image') {
      contentPreview = appStrings.chatListLastMsgPhoto;
    }
    if (message.replyToMessageType == 'audio') {
      contentPreview = appStrings.chatListLastMsgVoice;
    }
    if (message.replyToMessageType == 'file') {
      contentPreview = appStrings.convoLastMsgAttachment;
    }
    if (message.replyToMessageType == 'job_proposal') {
      contentPreview = appStrings.convoLastMsgJobProposal;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(3, 3, 3, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(left: BorderSide(color: nameColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSenderName ?? 'Someone',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: nameColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            contentPreview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}

class ReactionsDisplay extends StatelessWidget {
  final Map<String, String> reactions;
  const ReactionsDisplay({super.key, required this.reactions});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        reactions.values.toSet().join(' '),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class MessageInputComposer extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(file_picker.PlatformFile) onAttachment;
  final Function(file_picker.PlatformFile) onAudioFile;
  final ChatMessage? replyingTo;
  final VoidCallback onCancelReply;
  final bool isAiChat;
  final Uint8List? pickedImageBytesForAi;
  final VoidCallback onClearAiImage;
  final String? otherUserName;
  final AppUser.AppUser? otherAppUser;

  const MessageInputComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttachment,
    this.replyingTo,
    required this.onCancelReply,
    required this.onAudioFile,
    required this.isAiChat,
    this.pickedImageBytesForAi,
    required this.onClearAiImage,
    this.otherUserName,
    this.otherAppUser,
  });

  @override
  State<MessageInputComposer> createState() => _MessageInputComposerState();
}

class _MessageInputComposerState extends State<MessageInputComposer> {
  bool _showAttachmentPanel = false;
  bool _isRecording = false;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  bool _isRecorderInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    if (_isRecorderInitialized) return;
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint("Microphone permission was not granted.");
        return;
      }
      await _recorder.openRecorder();
      setState(() {
        _isRecorderInitialized = true;
      });
    } catch (e) {
      debugPrint("Error initializing recorder: $e");
      setState(() {
        _isRecorderInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    if (_isRecorderInitialized) {
      _recorder.closeRecorder();
    }
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<bool> _handlePermission(Permission permission) async {
    var status = await permission.status;
    if (status.isDenied) {
      status = await permission.request();
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        final appStrings = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appStrings.convoPermissionRequired(
                permission.toString().split('.').last,
              ),
            ),
            action: SnackBarAction(
              label: appStrings.convoPermissionSettings,
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      return false;
    }
    return status.isGranted;
  }

  Future<void> _toggleRecording() async {
    if (!await _handlePermission(Permission.microphone)) return;
    final appStrings = AppLocalizations.of(context)!;

    if (!_isRecorderInitialized) {
      await _initRecorder();
      if (!_isRecorderInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appStrings.convoErrorRecorderInit)),
          );
        }
        return;
      }
    }

    if (_recorder.isRecording) {
      _recordingTimer?.cancel();
      final path = await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      if (path == null || _recordingDuration < const Duration(seconds: 1)) {
        setState(() {
          _recordingDuration = Duration.zero;
        });
        return;
      }

      final file = File(path);
      final platformFile = file_picker.PlatformFile(
        name: 'voice_message.m4a',
        path: file.path,
        size: await file.length(),
      );
      widget.onAudioFile(platformFile);
      setState(() {
        _recordingDuration = Duration.zero;
      });
    } else {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/flutter_sound_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.startRecorder(toFile: path, codec: Codec.aacMP4);
      setState(() => _isRecording = true);
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingDuration += const Duration(seconds: 1));
        }
      });
    }
  }

  Future<void> _handleJobAttachmentPressed() async {
    final appStrings = AppLocalizations.of(context)!;
    if (widget.otherAppUser != null && widget.otherAppUser is Worker) {
      final Worker worker = widget.otherAppUser as Worker;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuickJobRequestScreen(worker: worker),
        ),
      );
      // Close the attachment panel after navigation
      setState(() {
        _showAttachmentPanel = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appStrings
                .convoErrorJobRequestNotWorker, // Ensure this string exists in AppStrings
          ),
        ),
      );
    }
  }

  Future<void> _pickAndHandleImage(ImageSource source) async {
    Permission permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;
    if (!await _handlePermission(permission)) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();

      widget.onAttachment(
        file_picker.PlatformFile(
          name: image.name,
          bytes: bytes,
          size: bytes.length,
          path: kIsWeb ? null : image.path,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'no_available_camera') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No camera available on this device.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to access media: ${e.message}")),
        );
      }
    }
  }

  void _handleAttachmentPress() {
    FocusScope.of(context).unfocus();
    setState(() => _showAttachmentPanel = !_showAttachmentPanel);
  }

  void _onAttachmentSelected(Future<void> Function() action) {
    setState(() => _showAttachmentPanel = false);
    action();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = widget.controller.text.isNotEmpty;
    final hasContent = hasText || widget.pickedImageBytesForAi != null;

    return Material(
      color: theme.cardColor,
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingTo != null)
              ReplyPreview(
                message: widget.replyingTo!,
                onCancel: widget.onCancelReply,
                otherUserName: widget.otherUserName,
              ),
            if (widget.pickedImageBytesForAi != null) _buildImagePreview(),
            _buildInputArea(context, hasContent),
            if (_showAttachmentPanel) _buildAttachmentPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                widget.pickedImageBytesForAi!,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: IconButton(
                icon: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
                onPressed: widget.onClearAiImage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool hasContent) {
    final appStrings = AppLocalizations.of(context)!;
    if (_isRecording) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(Icons.mic_none, color: Colors.red.shade400),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(color: Colors.red.shade400),
            ),
            const Spacer(),
            Text(
              appStrings.convoRecording,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _toggleRecording,
              child: const Icon(Icons.send_outlined, color: Colors.blue),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: 200.ms,
              transitionBuilder: (child, animation) =>
                  RotationTransition(turns: animation, child: child),
              child: Icon(
                _showAttachmentPanel
                    ? Icons.close_rounded
                    : Icons.add_circle_outline,
                key: ValueKey(_showAttachmentPanel),
              ),
            ),
            onPressed: _handleAttachmentPress,
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: appStrings.convoMessageHint,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          const SizedBox(width: 8),
          // We use the microphone icon only when the text field is empty
          const SizedBox(width: 8),
          // We use the microphone icon only when the text field is empty
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor:
                  Colors.transparent, // Change the background color here
              foregroundColor:
                  Colors.lightGreenAccent, // Change the icon color here
            ),
            icon: Icon(hasContent ? Icons.send_rounded : Icons.mic_rounded),
            onPressed: hasContent ? widget.onSend : _toggleRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPanel() {
    final appStrings = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AttachmentButton(
            icon: Icons.photo_library_outlined,
            label: appStrings.convoAttachGallery,
            onTap: () => _onAttachmentSelected(() async {
              await _pickimage();
            }),
          ),
          _AttachmentButton(
            icon: Icons.camera_alt_outlined,
            label: appStrings.convoAttachCamera,
            onTap: () => _onAttachmentSelected(() async {
              await _pickAndHandleImage(ImageSource.camera);
            }),
          ),
          if (!widget.isAiChat)
            _AttachmentButton(
              icon: Icons.attach_file_outlined,
              label: appStrings.convoAttachDocument,
              onTap: () => _onAttachmentSelected(() async {
                final result = await file_picker.FilePicker.platform.pickFiles(
                  type: file_picker.FileType.any,
                );
                if (result != null) widget.onAttachment(result.files.single);
              }),
            ),
          if (!widget.isAiChat)
            _AttachmentButton(
              icon: Icons.work_outline,
              label: appStrings.convoAttachJob,
              onTap: () {
                _onAttachmentSelected(() async {
                  await _handleJobAttachmentPressed();
                });
              },
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.5);
  }

  Future<void> _pickimage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      widget.onAttachment(
        file_picker.PlatformFile(
          name: pickedFile.name,
          bytes: bytes,
          size: bytes.length,
          path: kIsWeb ? null : pickedFile.path,
        ),
      );
    }
  }
}

class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Changed to match the new aesthetic: no colored background, just icon
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class ReplyPreview extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onCancel;
  final String? otherUserName;

  const ReplyPreview({
    super.key,
    required this.message,
    required this.onCancel,
    this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMeReplying =
        message.senderId == FirebaseService().getCurrentUser()?.uid;
    String senderName = isMeReplying
        ? appStrings.convoReplyToYou
        : (otherUserName ?? message.senderId);

    String contentPreview = message.message;
    if (message.messageType == 'image') {
      contentPreview = appStrings.chatListLastMsgPhoto;
    }
    if (message.messageType == 'audio') {
      contentPreview = appStrings.chatListLastMsgVoice;
    }

    return Container(
      padding: const EdgeInsets.all(8.0).copyWith(left: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appStrings.convoReplyingTo(senderName),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  contentPreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
        ],
      ),
    );
  }
}

class _TypingIndicatorBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
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
    );
  }
}
