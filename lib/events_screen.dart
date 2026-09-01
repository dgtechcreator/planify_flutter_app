import 'package:flutter/material.dart';
import 'api_service.dart';
import 'auth_storage.dart';
import 'login_screen.dart';
import 'add_edit_event_screen.dart';
import 'event_detail_screen.dart';
import 'app_drawer.dart';
import 'shimmer_loading.dart';
class EventsScreen extends StatefulWidget {
  final String token;

  const EventsScreen({super.key, required this.token});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<dynamic>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = ApiService.getEvents(widget.token);
  }

  Future<void> _refresh() async {
    setState(() {
      _eventsFuture = ApiService.getEvents(widget.token);
    });
    await _eventsFuture;
  }

  Future<void> _openAddEvent() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEventScreen(token: widget.token)),
    );
    if (saved == true) _refresh();
  }

  Future<void> _deleteEvent(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.deleteEvent(widget.token, id);
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
      appBar: AppBar(
        title: const Text('Events'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddEvent,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerLoading();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(child: Text('No events found.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index] as Map<String, dynamic>;
                final id = event['ID'] as int;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(token: widget.token, eventId: id),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event['Event Name']?.toString() ?? 'Untitled Event',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteEvent(id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Venue: ${event['Venue'] ?? '-'}'),
                          Text(
                              '${event['Start Date'] ?? ''} to ${event['End Date'] ?? ''}'),
                          Text('City: ${event['CityName'] ?? '-'}'),
                          Text('Ticket Price: ${event['TicketPrice'] ?? '-'}'),
                        ],
                      ),
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
