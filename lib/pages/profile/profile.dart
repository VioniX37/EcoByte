import 'dart:io';

import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker picker = ImagePicker();
  Future<Map<String, dynamic>?>? _profileFuture;
  File? image;
  String? imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = SupabaseRepository.ensureCurrentProfileExists();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    setState(() {
      image = File(pickedFile.path);
      _isUploading = true;
    });

    try {
      final uploadedImageUrl = await SupabaseRepository.uploadFile(
        file: image!,
        bucket: 'uploads',
        folder: 'avatars',
      );
      final user = SupabaseRepository.client.auth.currentUser;
      if (user == null) {
        return;
      }

      final currentProfile = await SupabaseRepository.ensureCurrentProfileExists();
      await SupabaseRepository.saveProfile(
        userId: user.id,
        name: currentProfile?['name']?.toString() ?? user.email ?? 'User',
        phone: currentProfile?['phone']?.toString() ?? '',
        address: currentProfile?['address']?.toString() ?? '',
        profileUrl: uploadedImageUrl,
        totalScore: (currentProfile?['total_score'] as num?)?.toInt(),
      );

      if (mounted) {
        setState(() {
          imageUrl = uploadedImageUrl;
          _profileFuture = SupabaseRepository.fetchCurrentProfile();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _showEditProfileDialog(Map<String, dynamic> profile) async {
    final nameController = TextEditingController(text: profile['name']?.toString() ?? '');
    final phoneController = TextEditingController(text: profile['phone']?.toString() ?? '');
    final addressController = TextEditingController(text: profile['address']?.toString() ?? '');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final user = SupabaseRepository.client.auth.currentUser;
    if (user == null) {
      return;
    }

    await SupabaseRepository.saveProfile(
      userId: user.id,
      name: nameController.text.trim().isEmpty ? 'User' : nameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      profileUrl: profile['profile_url']?.toString() ?? imageUrl ?? '',
      totalScore: (profile['total_score'] as num?)?.toInt(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _profileFuture = SupabaseRepository.fetchCurrentProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PremiumModeShell(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return PremiumModeShell(
            appBar: AppBar(
              title: const Text('Profile'),
              actions: const [ThemeToggleIconButton()],
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('We could not load your profile right now.'),
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return PremiumModeShell(
            appBar: AppBar(
              title: const Text('Profile'),
              actions: const [ThemeToggleIconButton()],
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No profile found yet.'),
              ),
            ),
          );
        }

        imageUrl = data['profile_url']?.toString();
        final email = SupabaseRepository.client.auth.currentUser?.email ?? '';
        return PremiumModeShell(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              const ThemeToggleIconButton(),
              IconButton(
                onPressed: () => _showEditProfileDialog(data),
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              PremiumModeSurface(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5269), Color(0xFF2C8C6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: 30,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: image != null
                                  ? Image.file(image!, fit: BoxFit.cover)
                                  : (imageUrl != null && imageUrl!.isNotEmpty)
                                      ? Image.network(imageUrl!, fit: BoxFit.cover)
                                      : const Icon(
                                          Icons.person,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isUploading ? Icons.hourglass_top : Icons.camera_alt,
                                size: 18,
                                color: const Color(0xFF1A5269),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['name']?.toString() ?? 'User',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isUploading ? 'Updating avatar...' : 'Tap the avatar or edit button to refresh your profile.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const PremiumModeSectionHeader(
                title: 'Account details',
                subtitle: 'Keep your contact details current for marketplace and community actions.',
              ),
              const SizedBox(height: 12),
              PremiumModeSurface(
                child: Column(
                  children: [
                    _detailRow('Email', email),
                    const Divider(),
                    _detailRow('Phone', data['phone']?.toString() ?? ''),
                    const Divider(),
                    _detailRow('Address', data['address']?.toString() ?? ''),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A5269),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not set' : value,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
