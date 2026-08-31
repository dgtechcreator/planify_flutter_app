import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'theme.dart';

class AddEventScreen extends StatefulWidget {
  final String token;

  const AddEventScreen({super.key, required this.token});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ticketPriceController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();

  int? _eventTypeId;
  int? _organizerId;
  int? _countryId;
  int? _stateId;
  int? _cityId;
  DateTime? _startDate;
  DateTime? _endDate;
  File? _bannerImage;

  late Future<Map<String, dynamic>> _dropdownsFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dropdownsFuture = ApiService.getEventDropdowns(widget.token);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    _ticketPriceController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _bannerImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates.')),
      );
      return;
    }
    if (_countryId == null || _stateId == null || _cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select country, state and city.')),
      );
      return;
    }
    if (_eventTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event type.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.saveEvent(
        widget.token,
        eventName: _nameController.text.trim(),
        eventTypeId: _eventTypeId!,
        organizedBy: _organizerId,
        description: _descriptionController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        venue: _venueController.text.trim(),
        cityId: _cityId!,
        stateId: _stateId!,
        countryId: _countryId!,
        ticketPrice: double.tryParse(_ticketPriceController.text),
        contactNumber: _contactController.text.trim(),
        email: _emailController.text.trim(),
        bannerImage: _bannerImage,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Add Event')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dropdownsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final countries = snapshot.data!['countries'] as List<dynamic>;
          final states = snapshot.data!['states'] as List<dynamic>;
          final cities = snapshot.data!['cities'] as List<dynamic>;
          final organizers = snapshot.data!['organizers'] as List<dynamic>;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      image: _bannerImage != null
                          ? DecorationImage(
                              image: FileImage(_bannerImage!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _bannerImage == null
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 32),
                                SizedBox(height: 8),
                                Text('Add Banner Image'),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Event Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _eventTypeId,
                  decoration: const InputDecoration(labelText: 'Event Type'),
                  items: eventTypes.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _eventTypeId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _organizerId,
                  decoration: const InputDecoration(labelText: 'Organized By'),
                  items: organizers
                      .map((o) => DropdownMenuItem(
                            value: o['id'] as int,
                            child: Text(o['name'].toString()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _organizerId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isStart: true),
                        child: Text(_startDate == null
                            ? 'Start Date'
                            : dateFormat.format(_startDate!)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isStart: false),
                        child: Text(_endDate == null
                            ? 'End Date'
                            : dateFormat.format(_endDate!)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(labelText: 'Venue'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _countryId,
                  decoration: const InputDecoration(labelText: 'Country'),
                  items: countries
                      .map((c) => DropdownMenuItem(
                            value: c['id'] as int,
                            child: Text(c['name'].toString()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _countryId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _stateId,
                  decoration: const InputDecoration(labelText: 'State'),
                  items: states
                      .map((s) => DropdownMenuItem(
                            value: s['id'] as int,
                            child: Text(s['name'].toString()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _stateId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _cityId,
                  decoration: const InputDecoration(labelText: 'City'),
                  items: cities
                      .map((c) => DropdownMenuItem(
                            value: c['id'] as int,
                            child: Text(c['name'].toString()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _cityId = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ticketPriceController,
                  decoration: const InputDecoration(labelText: 'Ticket Price'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Event'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
