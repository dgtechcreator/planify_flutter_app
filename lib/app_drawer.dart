import 'package:flutter/material.dart';
import 'schedule_screen.dart';
import 'users_screen.dart';
import 'notifications_screen.dart';

// Shared side menu for the screens that don't have room for a bottom-nav
// destination of their own (mirrors the web app's sidebar navigation).
class AppDrawer extends StatelessWidget {
  final String token;

  const AppDrawer({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Planify',
                  style: TextStyle(
                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Schedule'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ScheduleScreen(token: token)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Users'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UsersScreen(token: token)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotificationsScreen(token: token)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
