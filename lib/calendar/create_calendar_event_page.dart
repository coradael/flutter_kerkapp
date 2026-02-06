import 'package:flutter/material.dart';
import 'calendar_service.dart';

class CreateCalendarEventPage extends StatefulWidget {
  final String tenantId;
  final String userId;
  final DateTime selectedDate;

  const CreateCalendarEventPage({
    super.key,
    required this.tenantId,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<CreateCalendarEventPage> createState() => _CreateCalendarEventPageState();
}

class _CreateCalendarEventPageState extends State<CreateCalendarEventPage> {
  final _calendarService = CalendarService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  late DateTime _selectedDate;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  String _selectedColor = 'blue';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voer een titel in')),
      );
      return;
    }

    setState(() => _saving = true);

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    DateTime? endDateTime;
    if (_endTime != null) {
      endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime!.hour,
        _endTime!.minute,
      );
    }

    final success = await _calendarService.createEvent(
      tenantId: widget.tenantId,
      userId: widget.userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      eventDate: _selectedDate,
      startTime: startDateTime,
      endTime: endDateTime,
      location: _locationController.text.trim().isEmpty 
          ? null 
          : _locationController.text.trim(),
      color: _selectedColor,
    );

    setState(() => _saving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Evenement toegevoegd')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Fout bij opslaan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuw Evenement'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Opslaan', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschrijving',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Locatie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Datum'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectDate,
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Starttijd'),
              subtitle: Text(_startTime.format(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectStartTime,
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Eindtijd (optioneel)'),
              subtitle: Text(
                _endTime != null ? _endTime!.format(context) : 'Niet ingesteld',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _endTime = null),
                    ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: _selectEndTime,
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kleur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _buildColorOption('blue', Colors.blue),
                _buildColorOption('red', Colors.red),
                _buildColorOption('green', Colors.green),
                _buildColorOption('orange', Colors.orange),
                _buildColorOption('purple', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(String colorName, Color color) {
    final isSelected = _selectedColor == colorName;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = colorName),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.black, width: 3)
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }
}
