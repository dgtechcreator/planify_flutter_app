import 'package:flutter/material.dart';
import 'schedule_screen.dart';
import 'users_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'mail_master_screen.dart';
import 'contact_import_screen.dart';
import 'live_map_screen.dart';



class AppDrawer extends StatelessWidget {
  final String token;

  const AppDrawer({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: null,

      onDestinationSelected: (index) {
        Navigator.pop(context);

        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduleScreen(token: token),
            ),
          );
        }

        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UsersScreen(token: token),
            ),
          );
        }

        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationsScreen(token: token),
            ),
          );
        }

        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MailMasterScreen(token: token),
            ),
          );
        }

        if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContactImportScreen(token: token),
            ),
          );
        }

        if (index == 5) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveMapScreen(token: token),
            ),
          );
        }

        if (index == 6) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(token: token),
            ),
          );
        }
      },

      children: [
        // =========================
        // HEADER
        // =========================

        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            28,
            16,
            16,
          ),

          child: Row(
            children: [
              CircleAvatar(
                radius: 26,

                backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,

                child: Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              const Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    'Planify',

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    'Schedule Management',

                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(),

        // =========================
        // MENU ITEMS
        // =========================

        const NavigationDrawerDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: Text('Schedule'),
        ),

        const NavigationDrawerDestination(
          icon: Icon(Icons.people_alt_outlined),
          selectedIcon: Icon(Icons.people_alt),
          label: Text('Users'),
        ),

        const NavigationDrawerDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: Text('Notifications'),
        ),

        const NavigationDrawerDestination(
          icon: Icon(Icons.mail_outlined),
          selectedIcon: Icon(Icons.mail),
          label: Text('Mail Master'),
        ),

        const NavigationDrawerDestination(
          icon: Icon(Icons.contacts_outlined),
          selectedIcon: Icon(Icons.contacts),
          label: Text('Contact Import'),
        ),

        const NavigationDrawerDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: Text('Live Map'),
        ),

        // =========================
        // DIVIDER
        // =========================

        const Padding(
          padding: EdgeInsets.fromLTRB(
            28,
            16,
            28,
            8,
          ),

          child: Divider(),
        ),

        // =========================
        // SETTINGS
        // =========================

        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }
}