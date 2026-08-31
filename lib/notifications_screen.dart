import 'package:flutter/material.dart';
import 'api_service.dart';
import 'send_notification_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String token;

  const NotificationsScreen({super.key, required this.token});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<dynamic>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = ApiService.getNotifications(widget.token);
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = ApiService.getNotifications(widget.token);
    });
    await _notificationsFuture;
  }

  Future<void> _openSend() async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SendNotificationScreen(token: widget.token)),
    );
    if (sent == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSend,
        child: const Icon(Icons.send),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index] as Map<String, dynamic>;
                final title = n['NotificationTitle'] ?? n['Title'];
                final description = n['NotificationDescription'] ?? n['Description'];
                final sendTo = n['SendTo'] ?? n['SendToName'];
                final sendOn = n['SendOn'] ?? n['AddedOn'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(title?.toString() ?? 'Notification'),
                    subtitle: Text(
                      [
                        if (description != null && description.toString().isNotEmpty)
                          description.toString(),
                        if (sendTo != null) 'To: $sendTo',
                        if (sendOn != null) '$sendOn',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
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
