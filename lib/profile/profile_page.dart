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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _profileService.getProfile(user.id);
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    print('🔵 Start picking image...');
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image == null) {
      print('❌ Image picker cancelled');
      return;
    }

    print('✅ Image picked: ${image.path}');
    setState(() => _uploading = true);

    final user = _authService.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      setState(() => _uploading = false);
      return;
    }

    print('👤 User ID: ${user.id}');
    print('📤 Starting upload...');
    
    try {
      final avatarUrl = await _storageService.uploadAvatar(
        user.id,
        image, // Pass XFile instead of File
      );

      if (!mounted) {
        print('⚠️ Widget unmounted after upload');
        return;
      }
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (avatarUrl != null && _profile != null) {
        print('✅ Avatar uploaded: $avatarUrl');
        final updatedProfile = Profile(
          id: _profile!.id,
          email: _profile!.email,
          tenantId: _profile!.tenantId,
          fullName: _profile!.fullName,
          phoneNumber: _profile!.phoneNumber,
          avatarUrl: avatarUrl,
          createdAt: _profile!.createdAt,
          updatedAt: DateTime.now(),
        );

        print('💾 Updating profile in database...');
        final success = await _profileService.updateProfile(updatedProfile);
        
        if (!mounted) {
          print('⚠️ Widget unmounted after profile update');
          return;
        }
        
        if (success) {
          print('✅ Profile updated successfully');
          setState(() => _profile = updatedProfile);
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Avatar geüpload!')),
          );
        } else {
          print('❌ Failed to update profile in database');
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Fout bij opslaan avatar')),
          );
        }
      } else {
        print('❌ Upload failed: avatarUrl=$avatarUrl, profile=${_profile != null}');
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Fout bij uploaden avatar')),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Exception during upload: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _uploading = false);
    }
    print('🔵 Upload process finished');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiel'),
        actions: [
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
                  // Profile info
                  Card(
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
