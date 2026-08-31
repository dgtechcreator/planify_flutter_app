import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'events_screen.dart';
import 'todo_screen.dart';
import 'auth_storage.dart';
import 'login_screen.dart';
import 'app_drawer.dart';

class MainShell extends StatefulWidget {
  final String token;

  const MainShell({super.key, required this.token});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await AuthStorage.clearToken();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        drawer: AppDrawer(token: widget.token),
        body: DashboardScreen(token: widget.token),
      ),
      EventsScreen(token: widget.token),
      TodoScreen(token: widget.token),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), label: 'To-Do'),
        ],
      ),
    );
  }
}
