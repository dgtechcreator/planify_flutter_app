import 'package:flutter/material.dart';
import 'api_service.dart';
import 'add_edit_todo_screen.dart';
import 'app_drawer.dart';

class TodoScreen extends StatefulWidget {
  final String token;

  const TodoScreen({super.key, required this.token});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late Future<List<dynamic>> _todosFuture;

  @override
  void initState() {
    super.initState();
    _todosFuture = ApiService.getTodos(widget.token);
  }

  Future<void> _refresh() async {
    setState(() {
      _todosFuture = ApiService.getTodos(widget.token);
    });
    await _todosFuture;
  }

  Future<void> _openAdd() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditTodoScreen(token: widget.token)),
    );
    if (saved == true) _refresh();
  }

  Future<void> _openEdit(Map<String, dynamic> todo) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTodoScreen(
          token: widget.token,
          id: _readId(todo),
          initialTask: todo['Task']?.toString(),
          initialDescription: todo['Description']?.toString(),
        ),
      ),
    );
    if (saved == true) _refresh();
  }

  Future<void> _setDone(int id, bool done) async {
    try {
      await ApiService.setTodoDone(widget.token, id, done);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  int _readId(Map<String, dynamic> row) =>
      (row['ID'] ?? row['Id'] ?? row['id']) as int;

  // The exact "done/pending" column name from the underlying stored
  // procedure isn't confirmed yet -- check a few likely candidates and
  // fall back to showing both actions when we can't tell.
  bool? _readDone(Map<String, dynamic> row) {
    for (final key in ['IsDone', 'IsCompleted', 'Completed', 'Status']) {
      final v = row[key];
      if (v == null) continue;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      if (s == 'done' || s == 'completed' || s == 'true' || s == '1') return true;
      if (s == 'pending' || s == 'false' || s == '0') return false;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('To-Do')),
      drawer: AppDrawer(token: widget.token),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _todosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final todos = snapshot.data ?? [];
          if (todos.isEmpty) {
            return const Center(child: Text('No tasks yet.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index] as Map<String, dynamic>;
                final id = _readId(todo);
                final done = _readDone(todo);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _openEdit(todo),
                    title: Text(
                      todo['Task']?.toString() ?? 'Untitled Task',
                      style: TextStyle(
                        decoration: done == true ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: todo['Description'] != null &&
                            todo['Description'].toString().isNotEmpty
                        ? Text(todo['Description'].toString())
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (done != true)
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            tooltip: 'Mark done',
                            onPressed: () => _setDone(id, true),
                          ),
                        if (done != false)
                          IconButton(
                            icon: const Icon(Icons.undo),
                            tooltip: 'Mark not done',
                            onPressed: () => _setDone(id, false),
                          ),
                      ],
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
