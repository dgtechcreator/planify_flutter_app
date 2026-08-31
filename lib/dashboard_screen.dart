import 'package:flutter/material.dart';
import 'api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({super.key, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_DashboardData> _load() async {
    final summary = await ApiService.getDashboardSummary(widget.token);
    final topEvent = await ApiService.getTopEvent(widget.token);
    return _DashboardData(summary: summary, topEvent: topEvent);
  }

  Future<void> _refresh() async {
    final data = await _load();
    setState(() => _dataFuture = Future.value(data));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final summary = snapshot.data!.summary;
        final topEvent = snapshot.data!.topEvent;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    icon: Icons.people_alt_outlined,
                    label: 'Total Users',
                    value: summary['TotalUser'],
                    color: Colors.blue,
                  ),
                  _StatCard(
                    icon: Icons.location_on_outlined,
                    label: 'My Location',
                    value: summary['MyLocation'],
                    color: Colors.redAccent,
                  ),
                  _StatCard(
                    icon: Icons.checklist_outlined,
                    label: 'My Task',
                    value: summary['TotalToDo'],
                    color: Colors.green,
                  ),
                  _StatCard(
                    icon: Icons.event_available_outlined,
                    label: 'Total Events',
                    value: summary['TotalEvents'],
                    color: Colors.deepPurple,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location Tasks',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _MiniStat(label: 'Total', value: summary['TotalLocation']),
                          _MiniStat(label: 'Completed', value: summary['CompletedLocation']),
                          _MiniStat(label: 'Pending', value: summary['PendingLocation']),
                          _MiniStat(label: 'Cancelled', value: summary['CancelledLocation']),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (topEvent != null) ...[
                Text('Recently Listed Event',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topEvent['EventName']?.toString() ?? '',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Venue: ${topEvent['Venue'] ?? '-'}'),
                            Text('City: ${topEvent['CityName'] ?? '-'}'),
                            const SizedBox(height: 8),
                            Text(
                                'Organized by ${topEvent['OrganizedBy'] ?? '-'} · ${topEvent['TimeAgo'] ?? ''}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DashboardData {
  final Map<String, dynamic> summary;
  final Map<String, dynamic>? topEvent;

  _DashboardData({required this.summary, required this.topEvent});
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const Spacer(),
            Text(
              '$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final dynamic value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
