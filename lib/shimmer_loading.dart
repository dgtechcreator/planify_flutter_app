import 'package:flutter/material.dart';
import 'api_service.dart';
import 'add_edit_user_screen.dart';

class UsersScreen extends StatefulWidget {
  final String token;

  const UsersScreen({super.key, required this.token});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<dynamic>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = ApiService.getUsers(widget.token);
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = ApiService.getUsers(widget.token);
    });
    await _usersFuture;
  }

  int _readId(Map<String, dynamic> row) =>
      (row['Id'] ?? row['ID'] ?? row['id']) as int;

  Future<void> _openAdd() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditUserScreen(token: widget.token)),
    );
    if (saved == true) _refresh();
  }

  Future<void> _openEdit(int id) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditUserScreen(token: widget.token, id: id),
      ),
    );
    if (saved == true) _refresh();
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.deleteUser(widget.token, id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index] as Map<String, dynamic>;
                final id = _readId(user);
                final name = [user['FirstName'], user['LastName']]
                    .where((p) => p != null && p.toString().isNotEmpty)
                    .join(' ');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _openEdit(id),
                    title: Text(name.isEmpty ? (user['UserName']?.toString() ?? '-') : name),
                    subtitle: Text(
                        '${user['Email'] ?? '-'}\n${user['ContactNo'] ?? user['Phone'] ?? '-'}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteUser(id),
                    ),
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
