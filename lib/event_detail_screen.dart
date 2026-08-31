import 'package:flutter/material.dart';
import 'api_service.dart';

class EventDetailScreen extends StatefulWidget {
  final String token;
  final int eventId;

  const EventDetailScreen({super.key, required this.token, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<Map<String, dynamic>> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = ApiService.getEventById(widget.token, widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final event = snapshot.data!;
          final bannerPath = event['BannerImage']?.toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (bannerPath != null && bannerPath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    '${ApiService.serverOrigin}$bannerPath',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 180,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined, size: 40),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                event['EventName']?.toString() ?? '',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  if (event['EventType'] != null) Chip(label: Text(event['EventType'].toString())),
                  if (event['Status'] != null) Chip(label: Text(event['Status'].toString())),
                ],
              ),
              const SizedBox(height: 16),
              if (event['Description'] != null && event['Description'].toString().isNotEmpty) ...[
                Text(event['Description'].toString()),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(icon: Icons.place_outlined, label: 'Venue', value: event['Venue']),
                      _DetailRow(
                          icon: Icons.location_city_outlined,
                          label: 'Location',
                          value: '${event['CityName'] ?? ''}, ${event['StateName'] ?? ''}, ${event['CountryName'] ?? ''}'),
                      _DetailRow(
                          icon: Icons.date_range_outlined,
                          label: 'Dates',
                          value: '${_fmt(event['StartDate'])} to ${_fmt(event['EndDate'])}'),
                      _DetailRow(
                          icon: Icons.currency_rupee, label: 'Ticket Price', value: event['TicketPrice']),
                      _DetailRow(icon: Icons.phone_outlined, label: 'Contact', value: event['ContactNumber']),
                      _DetailRow(icon: Icons.email_outlined, label: 'Email', value: event['Email']),
                      _DetailRow(icon: Icons.person_outline, label: 'Organized By', value: event['OrganizedBy']),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(dynamic date) {
    if (date == null) return '-';
    final parsed = DateTime.tryParse(date.toString());
    if (parsed == null) return date.toString();
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text('${value ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
