import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/auth_service.dart';
import '../services/storage_service.dart';
import 'profile_service.dart';
import 'profile_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _profileService = ProfileService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  Profile? _profile;
  bool _loading = true;
  bool _uploading = false;
  bool _isEditing = false;
  bool _saving = false;
  
  // Text controllers voor edit mode
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _profileService.getProfile(user.id);
      setState(() {
        _profile = profile;
        _loading = false;
        // Vul controllers met huidige data
        _fullNameController.text = profile?.fullName ?? '';
        _emailController.text = profile?.email ?? '';
        _phoneController.text = profile?.phoneNumber ?? '';
      });
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      // Reset controllers met huidige profiel data
      _fullNameController.text = _profile?.fullName ?? '';
      _emailController.text = _profile?.email ?? '';
      _phoneController.text = _profile?.phoneNumber ?? '';
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;

    setState(() => _saving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final updatedProfile = Profile(
      id: _profile!.id,
      email: _emailController.text.trim(),
      tenantId: _profile!.tenantId,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
      avatarUrl: _profile!.avatarUrl,
      role: _profile!.role,
      createdAt: _profile!.createdAt,
      updatedAt: DateTime.now(),
    );

    final success = await _profileService.updateProfile(updatedProfile);

    if (!mounted) return;

    setState(() {
      _saving = false;
      if (success) {
        _profile = updatedProfile;
        _isEditing = false;
      }
    });

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(success ? '✅ Profiel opgeslagen' : '❌ Fout bij opslaan'),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    debugPrint('🔵 Start picking image...');
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image == null) {
      debugPrint('❌ Image picker cancelled');
      return;
    }

    debugPrint('✅ Image picked: ${image.path}');
    setState(() => _uploading = true);

    final user = _authService.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in');
      setState(() => _uploading = false);
      return;
    }

    debugPrint('👤 User ID: ${user.id}');
    debugPrint('📤 Starting upload...');
    
    try {
      final avatarUrl = await _storageService.uploadAvatar(
        user.id,
        image, // Pass XFile instead of File
      );

      if (!mounted) {
        debugPrint('⚠️ Widget unmounted after upload');
        return;
      }
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (avatarUrl != null && _profile != null) {
        debugPrint('✅ Avatar uploaded: $avatarUrl');
        final updatedProfile = Profile(
          id: _profile!.id,
          email: _profile!.email,
          tenantId: _profile!.tenantId,
          fullName: _profile!.fullName,
          phoneNumber: _profile!.phoneNumber,
          avatarUrl: avatarUrl,
          role: _profile!.role,
          createdAt: _profile!.createdAt,
          updatedAt: DateTime.now(),
        );

        debugPrint('💾 Updating profile in database...');
        final success = await _profileService.updateProfile(updatedProfile);
        
        if (!mounted) {
          debugPrint('⚠️ Widget unmounted after profile update');
          return;
        }
        
        if (success) {
          debugPrint('✅ Profile updated successfully');
          setState(() => _profile = updatedProfile);
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Avatar geüpload!')),
          );
        } else {
          debugPrint('❌ Failed to update profile in database');
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Fout bij opslaan avatar')),
          );
        }
      } else {
        debugPrint('❌ Upload failed: avatarUrl=$avatarUrl, profile=${_profile != null}');
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Fout bij uploaden avatar')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception during upload: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _uploading = false);
    }
    debugPrint('🔵 Upload process finished');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiel'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _startEditing,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await _authService.signOut();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Uitgelogd')),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _profile?.avatarUrl != null
                            ? NetworkImage(
                                _storageService.getAvatarUrl(_profile!.avatarUrl)!,
                              )
                            : null,
                        child: _profile?.avatarUrl == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                      if (_uploading)
                        const Positioned.fill(
                          child: CircularProgressIndicator(),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _uploading ? null : _pickAndUploadAvatar,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Profile info - Edit mode of View mode
                  _isEditing ? _buildEditForm() : _buildProfileInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              Icons.email,
              'Email',
              _profile?.email ?? 'Niet beschikbaar',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.person,
              'Naam',
              _profile?.fullName ?? 'Niet ingesteld',
            ),
            if (_profile?.phoneNumber != null) ...[
              const Divider(),
              _buildInfoRow(
                Icons.phone,
                'Telefoon',
                _profile!.phoneNumber!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Naam veld
            Text(
              'Naam',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameController,
              enabled: !_saving,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Voer je naam in',
              ),
            ),
            const SizedBox(height: 16),
            
            // Email veld
            Text(
              'E-mail',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'voornaam@voorbeeld.nl',
              ),
            ),
            const SizedBox(height: 16),
            
            // Telefoonnummer veld
            Text(
              'Telefoonnummer',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '+31 6 12345678',
              ),
            ),
            const SizedBox(height: 24),
            
            // Acties: Opslaan en Annuleren
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _saving ? null : _cancelEditing,
                  icon: const Icon(Icons.close),
                  label: const Text('Annuleren'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _saveProfile,
                  icon: _saving 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Opslaan...' : 'Opslaan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
