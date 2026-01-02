import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../auth/auth_service.dart';
import 'event_model.dart';
import 'event_service.dart';
import 'event_storage_service.dart';

class CreateEventPage extends StatefulWidget {
  final String tenantId;

  const CreateEventPage({super.key, required this.tenantId});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _eventService = EventService();
  final _storageService = EventStorageService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  
  DateTime? _selectedDate;
  bool _uploading = false;
  final List<Map<String, dynamic>> _selectedFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedFiles.add({
          'type': 'image',
          'file': image,
          'name': image.name,
        });
      });
    }
  }

  Future<void> _pickVideo() async {
    final video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
    );

    if (video != null) {
      setState(() {
        _selectedFiles.add({
          'type': 'video',
          'file': video,
          'name': video.name,
        });
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _selectedFiles.add({
          'type': 'document',
          'file': file,
          'name': file.name,
        });
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _createEvent() async {
    if (kDebugMode) {
      print('📝 CreateEvent - Starting with tenantId: "${widget.tenantId}"');
      print('📝 CreateEvent - TenantId isEmpty: ${widget.tenantId.isEmpty}');
      print('📝 CreateEvent - TenantId length: ${widget.tenantId.length}');
    }
    
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Niet ingelogd')),
        );
      }
      return;
    }

    if (widget.tenantId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Geen kerk geselecteerd')),
        );
      }
      return;
    }

    setState(() => _uploading = true);

    try {
      // 1. Create event
      final event = Event(
        id: '',
        tenantId: widget.tenantId,
        createdBy: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        eventDate: _selectedDate,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final eventId = await _eventService.createEvent(event);

      if (eventId == null) {
        throw Exception('Failed to create event');
      }

      // 2. Upload files
      for (final fileData in _selectedFiles) {
        String? filePath;
        String fileType = _storageService.getFileType(fileData['name']);

        if (fileData['type'] == 'image' || fileData['type'] == 'video') {
          filePath = await _storageService.uploadImage(fileData['file'], user.id);
        } else {
          filePath = await _storageService.uploadDocument(fileData['file'], user.id);
        }

        if (filePath != null) {
          final eventFile = EventFile(
            id: '',
            eventId: eventId,
            filePath: filePath,
            fileType: fileType,
            fileName: fileData['name'],
            fileSize: null,
            createdAt: DateTime.now(),
          );

          await _eventService.addEventFile(eventFile);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Event aangemaakt!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fout: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuw Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Titel is verplicht' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschrijving',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Selecteer datum',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _pickDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Locatie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bestanden',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Foto'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Video'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.insert_drive_file),
                      label: const Text('Document'),
                    ),
                  ),
                ],
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...List.generate(_selectedFiles.length, (index) {
                  final file = _selectedFiles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(_getFileIcon(file['type'])),
                      title: Text(file['name']),
                      subtitle: Text(file['type'].toString().toUpperCase()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFile(index),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _uploading ? null : _createEvent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _uploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Event Aanmaken',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'document':
        return Icons.insert_drive_file;
      default:
        return Icons.attach_file;
    }
  }
}
