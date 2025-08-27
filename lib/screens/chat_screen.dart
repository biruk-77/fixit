// lib/screens/chat_screen.dart
// --- DEFINITIVE, ANIMATED & RESPONSIVE CHAT HUB ---

import 'package:flutter/material.dart';
import 'chat/chat_list_pane.dart';
import 'chat/conversation_pane.dart';

class UnifiedChatScreen extends StatefulWidget {
  final String? initialSelectedUserId;
  const UnifiedChatScreen({super.key, this.initialSelectedUserId});

  @override
  State<UnifiedChatScreen> createState() => _UnifiedChatScreenState();
}

class _UnifiedChatScreenState extends State<UnifiedChatScreen> {
  String? _selectedUserId;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.initialSelectedUserId;
  }

  void _onChatSelected(String userId) {
    // For wide screens, just update the state to rebuild the ConversationPane
    if (MediaQuery.of(context).size.width >= 700) {
      // Using a slightly wider breakpoint
      setState(() {
        _selectedUserId = userId;
      });
    } else {
      // For narrow screens, push a new route for the conversation
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ConversationPane(otherUserId: userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth >= 700;

        if (isWideScreen) {
          // --- WIDE SCREEN LAYOUT (TABLET/DESKTOP) ---
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 380,
                  child: ChatListPane(
                    selectedUserId: _selectedUserId,
                    onChatSelected: _onChatSelected,
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: _selectedUserId == null
                      ? const _NoChatSelectedPlaceholder()
                      : ConversationPane(
                          key: ValueKey(_selectedUserId),
                          otherUserId: _selectedUserId!,
                        ),
                ),
              ],
            ),
          );
        } else {
          // --- NARROW SCREEN LAYOUT (MOBILE) ---
          return Navigator(
            key: _navigatorKey,
            initialRoute: widget.initialSelectedUserId != null
                ? '/conversation'
                : '/',
            onGenerateRoute: (settings) {
              WidgetBuilder builder;
              String? routeName = settings.name;

              // If launching directly into a conversation from a notification
              if (routeName == '/conversation' ||
                  (routeName == '/' && widget.initialSelectedUserId != null)) {
                // Determine the user ID from either initial widget param or route arguments
                final userId =
                    widget.initialSelectedUserId ??
                    settings.arguments as String?;
                if (userId != null) {
                  builder = (context) => ConversationPane(
                    key: ValueKey(userId),
                    otherUserId: userId,
                  );
                } else {
                  // Fallback if no ID is found
                  builder = (context) => const _NoChatSelectedPlaceholder();
                }
              } else {
                // Default route: show the chat list
                builder = (context) => ChatListPane(
                  onChatSelected:
                      _onChatSelected, // This was the original location, it's correct here
                );
              }

              // --- THIS IS THE FIX ---
              // We use a custom PageRouteBuilder for a smooth slide transition.
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    builder(context),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      // Only animate if we are navigating somewhere (not the initial route)
                      if (settings.name == '/') return child;

                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;
                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                settings: settings,
              );
            },
          );
        }
      },
    );
  }
}

class _NoChatSelectedPlaceholder extends StatelessWidget {
  const _NoChatSelectedPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(), // An empty app bar for consistent layout
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              "Select a conversation",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "Your messages will appear here.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
