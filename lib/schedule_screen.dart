import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'api_service.dart';
import 'event_detail_screen.dart';

// Reuses the existing Event API -- on the web app "Schedule" is just a
// calendar view over the same Event data as the Events screen, not a
// separate backend feature.
class ScheduleScreen extends StatefulWidget {
  final String token;

  const ScheduleScreen({super.key, required this.token});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<dynamic>> _eventsFuture;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _eventsByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _eventsFuture = ApiService.getEvents(widget.token);
  }

  DateTime? _parseStartDate(Map<String, dynamic> event) {
    final raw = event['Start Date'] ?? event['StartDate'];
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  void _index(List<dynamic> events) {
    final map = <DateTime, List<Map<String, dynamic>>>{};
    for (final e in events) {
      final event = e as Map<String, dynamic>;
      final day = _parseStartDate(event);
      if (day == null) continue;
      map.putIfAbsent(day, () => []).add(event);
    }
    _eventsByDay = map;
  }

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _eventsByDay[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: FutureBuilder<List<dynamic>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          _index(snapshot.data ?? []);
          final selectedEvents = _eventsForDay(_selectedDay ?? _focusedDay);

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _eventsForDay,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) => _focusedDay = focused,
              ),
              const Divider(height: 1),
              Expanded(
                child: selectedEvents.isEmpty
                    ? const Center(child: Text('No events on this day.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedEvents[index];
                          final id = (event['ID'] ?? event['Id']) as int?;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                  event['Event Name']?.toString() ?? 'Untitled Event'),
                              subtitle: Text('Venue: ${event['Venue'] ?? '-'}'),
                              onTap: id == null
                                  ? null
                                  : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EventDetailScreen(
                                            token: widget.token,
                                            eventId: id,
                                          ),
                                        ),
                                      ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
