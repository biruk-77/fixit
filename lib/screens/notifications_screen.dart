import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart'; // Assuming this service exists
import 'jobs/job_detail_screen.dart'; // Assuming this screen exists

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firebaseService.markNotificationAsRead(notificationId);
      // No need to manually reload state, StreamBuilder handles it
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notification as read: $e')),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final String notificationId = notification['id'] as String;
    final bool isRead = notification['isRead'] as bool? ?? false;

    // Mark as read optimistically or after tap confirmation
    if (!isRead) {
      // Optional: Show loading or wait before navigating
      await _markAsRead(notificationId);
      // If marking takes time, you might want to delay navigation
      // or show an indicator, but often it's fast enough.
    }

    // Handle different notification types
    final notificationType = notification['type'] as String? ?? '';
    final notificationData =
        notification['data'] as Map<String, dynamic>? ?? {};

    if (notificationType.contains('job') &&
        notificationData.containsKey('jobId')) {
      final jobId = notificationData['jobId'] as String;

      try {
        // Show loading indicator while fetching job
        // (Optional, depends on desired UX)
        // showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));

        final job = await _firebaseService.getJobById(jobId);

        // if (mounted) Navigator.pop(context); // Dismiss loading indicator

        if (job != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailScreen(job: job),
            ),
          );
          // No need to call _loadNotifications here due to StreamBuilder
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job not found or has been deleted')),
          );
        }
      } catch (e) {
        // if (mounted) Navigator.pop(context); // Dismiss loading indicator if shown
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading job: $e')),
          );
        }
      }
    } else {
      // Handle other notification types or generic tap action if needed
      print("Tapped notification of type: $notificationType");
    }
  }

  // Optional: Implement delete functionality if needed
  Future<void> _deleteNotification(String notificationId) async {
    try {
      // await _firebaseService.deleteNotification(notificationId); // Add this method to your service
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Notification deleted (implement actual deletion)')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              /* Stream handles this, or implement manual trigger if needed */
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getUserNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("StreamBuilder Error: ${snapshot.error}"); // Log error
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading notifications.\nPlease try again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final notifications = snapshot.data!;

          // Use RefreshIndicator if you still want pull-to-refresh
          // Note: With Firestore streams, this might not be strictly necessary
          // unless your stream logic needs a manual trigger.
          return RefreshIndicator(
            onRefresh: () async {
              // Usually, you don't need to do anything here if the stream
              // automatically updates. If needed, trigger a specific
              // refresh action in your FirebaseService.
              print("Pull-to-refresh triggered");
              // Example: await _firebaseService.forceRefreshNotifications();
            },
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final notificationId = notification['id'] as String;
                final bool isRead = notification['isRead'] as bool? ?? false;

                return Dismissible(
                  key: Key(notificationId), // Unique key for Dismissible
                  direction:
                      DismissDirection.startToEnd, // Swipe right to dismiss
                  onDismissed: (direction) {
                    _markAsRead(notificationId);
                    // You could add another action for endToStart swipe (e.g., delete)
                    // Show a snackbar confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Notification marked as read'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            // Implement undo logic if desired (requires more state management)
                            print("Undo requested (requires implementation)");
                          },
                        ),
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.green.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.mark_email_read_outlined,
                        color: Colors.white),
                  ),
                  // Optional secondary background for swiping the other way (e.g., delete)
                  // secondaryBackground: ...,
                  child: _NotificationListItem(
                    notification: notification,
                    onTap: () => _handleNotificationTap(notification),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(
                  height: 1, indent: 80, endIndent: 16), // Add subtle divider
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined, // Use outlined icon
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You have no new notifications right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Extracted Notification List Item Widget
class _NotificationListItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationListItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String title = notification['title'] as String? ?? 'Notification';
    final String body = notification['body'] as String? ?? '';
    final bool isRead = notification['isRead'] as bool? ?? false;
    final DateTime? createdAt =
        (notification['createdAt'] as Timestamp?)?.toDate();
    final String type = notification['type'] as String? ?? '';

    final iconData = _getIconForType(type);

    return Card(
      margin: const EdgeInsets.symmetric(
          vertical: 4, horizontal: 8), // Adjusted margin
      elevation: isRead ? 1 : 2.5, // Subtle elevation difference
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Removed border - using elevation and selected state instead
        // side: isRead
        //     ? BorderSide.none
        //     : BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          // selected: !isRead, // Highlights tile if unread
          // selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.05), // Subtle highlight
          leading: CircleAvatar(
            backgroundColor: iconData.color.withOpacity(0.15),
            child: Icon(
              iconData.icon,
              color: iconData.color,
              size: 24,
            ),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                createdAt != null
                    ? DateFormat.yMMMd()
                        .add_jm()
                        .format(createdAt.toLocal()) // Use local time
                    : 'Just now',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: !isRead
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                )
              : const SizedBox(width: 10), // Keep spacing consistent
          isThreeLine: true, // Allows more space for subtitle
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        ),
      ),
    );
  }

  // Helper to get Icon and Color based on type
  ({IconData icon, Color color}) _getIconForType(String type) {
    if (type.contains('job_request')) {
      return (icon: Icons.work_outline, color: Colors.blue);
    } else if (type.contains('job_accepted')) {
      return (icon: Icons.check_circle_outline, color: Colors.green);
    } else if (type.contains('job_rejected')) {
      return (icon: Icons.cancel_outlined, color: Colors.redAccent);
    } else if (type.contains('job_completed')) {
      return (icon: Icons.task_alt, color: Colors.purple);
    } else if (type.contains('job_started')) {
      return (icon: Icons.directions_run, color: Colors.orange); // Changed icon
    } else if (type.contains('job_cancelled')) {
      return (icon: Icons.block, color: Colors.grey);
    } else if (type.contains('message')) {
      // Example for another type
      return (icon: Icons.message_outlined, color: Colors.teal);
    } else {
      return (
        icon: Icons.notifications_active_outlined,
        color: Colors.blueGrey
      ); // Default
    }
  }
}
