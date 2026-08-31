import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'auth_storage.dart';
import 'theme.dart';

void main() {
  runApp(const PlanifyApp());
}

class PlanifyApp extends StatelessWidget {
  const PlanifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planify',
      theme: AppTheme.light(),
      home: const StartupScreen(),
    );
  }
}

// Checks for a saved login token before deciding whether to show
// the login screen or go straight to the main app.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    final token = await AuthStorage.getToken();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            token != null ? MainShell(token: token) : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
