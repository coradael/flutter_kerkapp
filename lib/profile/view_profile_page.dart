import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ViewProfilePage extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool isCurrentUser;

  const ViewProfilePage({
    super.key,
    required this.member,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();
    final profile = member['profiles'] as Map<String, dynamic>?;
    final fullName = profile?['full_name'] as String?;
    final email = profile?['email'] as String?;
    final phoneNumber = profile?['phone_number'] as String?;
    final avatarUrl = profile?['avatar_url'] as String?;
    final role = member['role'] as String? ?? 'member';
    final isActive = member['is_active'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiel member'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header met grote foto
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Grote avatar
                    Hero(
                      tag: 'avatar_${profile?['id']}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(storageService.getAvatarUrl(avatarUrl)!)
                              : null,
                          child: avatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Naam
                    Text(
                      fullName ?? email ?? 'Geen naam',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: role == 'admin'
                            ? Colors.orange.withOpacity(0.9)
                            : Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role == 'admin' ? '👑 Admin' : '👤 Member',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Informatie sectie
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCurrentUser)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Dit is jouw profiel. Ga naar tap profiel om je gegevens te bewerken.',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isCurrentUser) const SizedBox(height: 20),
                  
                  // Email
                  _buildInfoCard(
                    context,
                    icon: Icons.email,
                    title: 'Email',
                    value: email ?? 'Niet ingevuld',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  
                  // Telefoonnummer
                  _buildInfoCard(
                    context,
                    icon: Icons.phone,
                    title: 'Telefoonnummer',
                    value: phoneNumber ?? 'Niet ingevuld',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  
                  // Status
                  _buildInfoCard(
                    context,
                    icon: isActive ? Icons.check_circle : Icons.block,
                    title: 'Status',
                    value: isActive ? 'Actief' : 'Inactief',
                    color: isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 12),
                  
                  // Rol
                  _buildInfoCard(
                    context,
                    icon: role == 'admin' ? Icons.shield : Icons.person,
                    title: 'Rol',
                    value: role == 'admin' ? 'Administrator' : 'Lid',
                    color: role == 'admin' ? Colors.orange : Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
