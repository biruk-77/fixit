// lib/screens/chat/chat_list_pane.dart
// --- DEFINITIVE AESTHETIC & HIGH-PERFORMANCE VERSION ---

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/app_string.dart'; // <-- IMPORT APPSTRINGS
import '../../services/firebase_service.dart';
import 'conversation_pane.dart';
import '../home/home_layout.dart'; // We need the AI_USER_ID from conversation_pane

// This enum is simplified. The old one was too complex.
enum ChatFilter { all, unread }

class ChatListPane extends StatefulWidget {
  final String? selectedUserId;
  final ValueChanged<String> onChatSelected;
  final VoidCallback? onBack;

  const ChatListPane({
    super.key,
    this.selectedUserId,
    required this.onChatSelected,
    this.onBack,
  });

  @override
  State<ChatListPane> createState() => _ChatListPaneState();
}

class _ChatListPaneState extends State<ChatListPane> {
  final FirebaseService _firebaseService = FirebaseService();
  final String? _currentUserId = FirebaseService().getCurrentUser()?.uid;
  ChatFilter _currentFilter = ChatFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(appStrings.chatListAppBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24, color: Colors.white),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeLayout()),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110.0),
          child: Column(
            children: [_buildSearchBar(theme), _buildFilterToggle(theme)],
          ),
        ),
      ),
      body: _buildChatList(),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final appStrings = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: appStrings.chatListSearchHint,
          prefixIcon: const Icon(Icons.search_outlined, size: 20),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainer,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterToggle(ThemeData theme) {
    final appStrings = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: ToggleButtons(
          isSelected: [
            _currentFilter == ChatFilter.all,
            _currentFilter == ChatFilter.unread,
          ],
          onPressed: (index) {
            setState(() {
              _currentFilter = index == 0 ? ChatFilter.all : ChatFilter.unread;
            });
          },
          borderRadius: BorderRadius.circular(30.0),
          selectedColor: theme.colorScheme.inversePrimary,
          color: theme.colorScheme.onSurfaceVariant,
          fillColor: theme.colorScheme.primary,
          renderBorder: false,
          constraints: BoxConstraints(
            minHeight: 36.0,
            minWidth: (MediaQuery.of(context).size.width - 40) / 2,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(appStrings.chatListFilterAll),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(appStrings.chatListFilterUnread),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final appStrings = AppLocalizations.of(context)!;
    if (_currentUserId == null) {
      return Center(child: Text(appStrings.chatListPleaseLogin));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: _currentUserId)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ChatListShimmer();
        }

        List<Map<String, dynamic>> userChats =
            snapshot.data?.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList() ??
            [];

        final aiChatData = {
          'id': AI_USER_ID,
          'isAiChat': true,
          'lastMessage': appStrings.chatListAiSubtitle,
          'lastMessageTimestamp': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 365)),
          ),
          'participants': [_currentUserId, AI_USER_ID],
          'participantDetails': {
            AI_USER_ID: {
              'name': appStrings.chatListAiName,
              'profileImage': null,
            },
          },
        };

        final filteredChats = userChats.where((chatData) {
          final participantsDetails =
              chatData['participantDetails'] as Map<String, dynamic>? ?? {};
          final otherUserId = (chatData['participants'] as List).firstWhere(
            (id) => id != _currentUserId,
            orElse: () => '',
          );
          final otherUserName =
              participantsDetails[otherUserId]?['name'] as String? ??
              appStrings.chatListDefaultUserName;

          final matchesSearch = otherUserName.toLowerCase().contains(
            _searchQuery,
          );
          if (!matchesSearch) return false;

          if (_currentFilter == ChatFilter.unread) {
            final lastSenderId = chatData['lastMessageSenderId'] as String?;
            return lastSenderId != null && lastSenderId != _currentUserId;
          }

          return true;
        }).toList();

        List<Map<String, dynamic>> finalList = [];
        if (appStrings.chatListAiName.toLowerCase().contains(_searchQuery) &&
            _currentFilter != ChatFilter.unread) {
          finalList.add(aiChatData);
        }
        finalList.addAll(filteredChats);

        if (finalList.isEmpty) {
          return Center(child: Text(appStrings.chatListEmptyFiltered));
        }

        if (snapshot.data!.docs.isEmpty && _searchQuery.isEmpty) {
          return ListView(
            children: [
              _ChatListItem(
                chatData: aiChatData,
                currentUserId: _currentUserId,
                isSelected: AI_USER_ID == widget.selectedUserId,
                onTap: () => widget.onChatSelected(AI_USER_ID),
              ),
              const _EmptyChatPlaceholder(),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: finalList.length,
          itemBuilder: (context, index) {
            final chatData = finalList[index];
            final otherUserId = (chatData['participants'] as List).firstWhere(
              (id) => id != _currentUserId,
              orElse: () => '',
            );

            return _ChatListItem(
              key: ValueKey(otherUserId),
              chatData: chatData,
              currentUserId: _currentUserId,
              isSelected: otherUserId == widget.selectedUserId,
              onTap: () {
                if (otherUserId.isNotEmpty) {
                  widget.onChatSelected(otherUserId);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final Map<String, dynamic> chatData;
  final String currentUserId;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChatListItem({
    super.key,
    required this.chatData,
    required this.currentUserId,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStrings = AppLocalizations.of(context)!;
    final participants = List<String>.from(chatData['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    final bool isAiChat = chatData['isAiChat'] == true;

    final participantDetails =
        chatData['participantDetails'] as Map<String, dynamic>? ?? {};
    final otherUserData =
        participantDetails[otherUserId] as Map<String, dynamic>? ?? {};

    final String name =
        otherUserData['name'] ?? appStrings.chatListDefaultUserName;
    final String? profileImage = otherUserData['profileImage'];
    final bool hasImage = profileImage != null && profileImage.isNotEmpty;

    final lastMessage = chatData['lastMessage'] as String? ?? '...';
    final timestamp = chatData['lastMessageTimestamp'] as Timestamp?;
    final lastSenderId = chatData['lastMessageSenderId'] as String?;

    final bool isUnread =
        !isAiChat && lastSenderId != null && lastSenderId != currentUserId;

    return Material(
      color: isSelected ? const Color(0xFF4A442D) : Colors.transparent,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              _buildAvatar(
                theme,
                isAiChat,
                hasImage,
                profileImage,
                name,
                otherUserId,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildName(theme, name, isAiChat),
                    const SizedBox(height: 4),
                    _buildLastMessage(
                      context, // Pass context for appStrings
                      theme,
                      lastMessage,
                      lastSenderId,
                      isUnread,
                      otherUserId,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (timestamp != null)
                    Text(
                      _formatTimestamp(timestamp.toDate(), appStrings),
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread
                            ? const Color(0xFFD4B74F)
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (isUnread)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4B74F),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          "1",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().scale(),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildName(ThemeData theme, String name, bool isAiChat) {
    return Row(
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (isAiChat) const SizedBox(width: 8),
        if (isAiChat)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'AI',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(
    ThemeData theme,
    bool isAiChat,
    bool hasImage,
    String? profileImage,
    String name,
    String otherUserId,
  ) {
    if (isAiChat) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.auto_awesome,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      );
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: hasImage
              ? CachedNetworkImageProvider(profileImage!)
              : null,
          backgroundColor: hasImage
              ? Colors.transparent
              : const Color(0xFF4A442D),
          child: !hasImage
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseService().streamUserPresence(otherUserId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data?.data() != null) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              if (data['status'] == 'online') {
                return Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildLastMessage(
    BuildContext context, // <-- Pass context
    ThemeData theme,
    String lastMessage,
    String? lastSenderId,
    bool isUnread,
    String otherUserId,
  ) {
    final appStrings = AppLocalizations.of(context)!; // <-- Get appStrings
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(_getChatRoomId(currentUserId, otherUserId))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final typing = data['typing'] as Map<String, dynamic>?;
          if (typing?[otherUserId] == true) {
            return Text(
              appStrings.chatListTyping,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.primary,
              ),
            );
          }
        }

        final bool amSender = lastSenderId == currentUserId;
        Widget prefixWidget = amSender
            ? Text(
                appStrings.chatListYouPrefix,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              )
            : const SizedBox.shrink();

        String displayMessage = lastMessage;
        IconData? prefixIcon;
        // NOTE: The data in Firestore is still English. This is correct.
        // We check the English string from the DB and display the localized version.
        if (lastMessage == '📷 Photo') {
          displayMessage = appStrings.chatListLastMsgPhoto;
          prefixIcon = Icons.photo_camera_outlined;
        } else if (lastMessage == '🎤 Voice Message') {
          displayMessage = appStrings.chatListLastMsgVoice;
          prefixIcon = Icons.mic_none_outlined;
        }

        return Row(
          children: [
            if (amSender && prefixIcon == null) prefixWidget,
            if (prefixIcon != null)
              Icon(
                prefixIcon,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            if (prefixIcon != null) const SizedBox(width: 4),
            Expanded(
              child: Text(
                displayMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  color: isUnread
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime date, AppStrings appStrings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return DateFormat.jm().format(date);
    } else if (messageDay == yesterday) {
      return appStrings.chatListTimestampYesterday;
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  String _getChatRoomId(String userId1, String userId2) {
    if (userId1.hashCode <= userId2.hashCode) {
      return '${userId1}_$userId2';
    } else {
      return '${userId2}_$userId1';
    }
  }
}

class _ChatListShimmer extends StatelessWidget {
  const _ChatListShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainer,
      highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16.0,
                        width: 120.0,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(height: 12.0, color: Colors.white),
                    ],
                  ),
                ),
                Container(height: 12.0, width: 50, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChatPlaceholder extends StatelessWidget {
  const _EmptyChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    final appStrings = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              appStrings.chatListEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              appStrings.chatListEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
