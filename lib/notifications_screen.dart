import 'package:flutter/material.dart';
import 'api_service.dart';
import 'send_notification_screen.dart';
import 'shimmer_loading.dart';
class NotificationsScreen extends StatefulWidget {
  final String token;

  const NotificationsScreen({
    super.key,
    required this.token,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<dynamic>> _notificationsFuture;

  @override
  void initState() {
    super.initState();

    _notificationsFuture =
        ApiService.getNotifications(widget.token);
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture =
          ApiService.getNotifications(widget.token);
    });

    await _notificationsFuture;
  }

  Future<void> _openSend() async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SendNotificationScreen(token: widget.token),
      ),
    );

    if (sent == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {
              // भविष्य में Mark All Read API लगा सकते हैं
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openSend,
        tooltip: 'Send Notification',
        child: const Icon(Icons.send),
      ),

      body: FutureBuilder<List<dynamic>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {

          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const  ShimmerLoading();
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final notifications =
              snapshot.data ?? [];

          // Empty Notification
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 180),

                  Center(
                    child: Icon(
                      Icons.notifications_none,
                      size: 70,
                      color: Colors.grey,
                    ),
                  ),

                  SizedBox(height: 15),

                  Center(
                    child: Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Notification List
          return RefreshIndicator(
            onRefresh: _refresh,

            child: ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: notifications.length,

              itemBuilder: (context, index) {

                final n =
                notifications[index]
                as Map<String, dynamic>;

                // API Data
                final title =
                    n['NotificationTitle'] ??
                        n['Title'] ??
                        'Notification';

                final description =
                    n['NotificationDescription'] ??
                        n['Description'] ??
                        '';

                final sendTo =
                    n['SendTo'] ??
                        n['SendToName'];

                final sendOn =
                    n['SendOn'] ??
                        n['AddedOn'];

                // अगर API में Read Status है
                final unread =
                    n['IsRead'] == false ||
                        n['Read'] == false;

                return Card(
                  elevation: 0,

                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),

                  color: unread
                      ? Colors.blue.withValues(alpha: 0.08)
                      : Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),

                  child: ListTile(

                    contentPadding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),

                    // Notification Icon
                    leading: CircleAvatar(
                      radius: 24,

                      backgroundColor: unread
                          ? Colors.blue.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),

                      child: Icon(
                        Icons.notifications,

                        color: unread
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),

                    // Title
                    title: Text(
                      title.toString(),

                      style: TextStyle(
                        fontWeight: unread
                            ? FontWeight.bold
                            : FontWeight.w600,

                        fontSize: 16,
                      ),
                    ),

                    // Description
                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        if (description
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(height: 5),

                          Text(
                            description.toString(),
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                          ),
                        ],

                        if (sendTo != null) ...[
                          const SizedBox(height: 5),

                          Text(
                            'To: $sendTo',

                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Date / Time
                    trailing: SizedBox(
                      width: 65,

                      child: Text(
                        sendOn?.toString() ?? '',

                        textAlign: TextAlign.right,

                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ),

                    onTap: () {
                      // यहाँ future में notification detail page खोल सकते हैं
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}