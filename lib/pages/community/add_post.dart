import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:e_waste/pages/about/about_page.dart';
import 'package:e_waste/pages/buy_sell/buy_screen.dart';
import 'package:e_waste/pages/buy_sell/my_products.dart';
import 'package:e_waste/pages/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  final ImagePicker picker = ImagePicker();
  final TextEditingController descriptionController = TextEditingController();
  File? image;
  String? imageUrl;
  bool _isPosting = false;

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    setState(() {
      image = File(pickedFile.path);
    });

    final uploadedImageUrl = await _uploadImage();
    if (uploadedImageUrl != null && mounted) {
      setState(() {
        imageUrl = uploadedImageUrl;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (image == null) {
      return null;
    }

    return SupabaseRepository.uploadFile(
      file: image!,
      bucket: 'uploads',
      folder: 'posts',
    );
  }

  Future<void> _addPost() async {
    final user = SupabaseRepository.client.auth.currentUser;
    if (user == null) {
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a description')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final profile = await SupabaseRepository.ensureCurrentProfileExists();
      final postImageUrl = imageUrl ?? await _uploadImage();

      if (image != null && (postImageUrl == null || postImageUrl.isEmpty)) {
        throw StateError('Image upload failed');
      }

      await SupabaseRepository.insertMessage(
        userId: user.id,
        senderName: profile?['name']?.toString() ?? user.email ?? 'User',
        description: descriptionController.text.trim(),
        profileUrl: profile?['profile_url']?.toString() ?? '',
        imageUrl: postImageUrl,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post Uploaded!')),
      );
      descriptionController.clear();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumShell(
      appBar: AppBar(
        title: const Text('Add post'),
        actions: [
          const ThemeToggleIconButton(),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
                  );
                  break;
                case 'marketplace':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const BuyScreen()),
                  );
                  break;
                case 'my_products':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const MyProducts()),
                  );
                  break;
                case 'about':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const AboutPage()),
                  );
                  break;
                case 'logout':
                  SupabaseRepository.client.auth.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (ctx) => LoginScreen()),
                    (route) => false,
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'marketplace', child: Text('Marketplace')),
              PopupMenuItem(value: 'my_products', child: Text('My products')),
              PopupMenuItem(value: 'about', child: Text('About')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 700 ? 680.0 : double.infinity;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PremiumHeroBanner(
                        title: 'Share a repair win',
                        subtitle: 'Post a reuse idea, a recycling tip, or a community update.',
                        icon: Icons.add_photo_alternate_outlined,
                        inlineIconOnMobile: true,
                      ),
                      const SizedBox(height: 16),
                      PremiumSurface(
                        borderRadius: 28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.edit_note, color: scheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Write your post',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: scheme.onSurface,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              stylusHandwritingEnabled: false,
                              controller: descriptionController,
                              maxLines: 7,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'Share what was repaired, reused, donated, or rescued.',
                                helperText: 'Short, useful posts tend to get more engagement.',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      PremiumSurface(
                        borderRadius: 28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: scheme.secondary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.photo_library_outlined, color: scheme.secondary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add a photo',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: scheme.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap the panel to upload or replace an image.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (image != null)
                              GestureDetector(
                                onTap: () {
                                  showPopup(context);
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        image!,
                                        height: 280,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withValues(alpha: 0.42),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 14,
                                        right: 14,
                                        bottom: 14,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: FilledButton.tonalIcon(
                                                onPressed: () => showPopup(context),
                                                icon: const Icon(Icons.swap_horiz),
                                                label: const Text('Replace image'),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            IconButton(
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.black.withValues(alpha: 0.38),
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  image = null;
                                                  imageUrl = null;
                                                });
                                              },
                                              icon: const Icon(Icons.delete_outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: _pickImage,
                                child: DottedBorder(
                                  color: scheme.primary.withValues(alpha: 0.45),
                                  dashPattern: const [10, 4],
                                  radius: const Radius.circular(22),
                                  borderType: BorderType.RRect,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          scheme.primary.withValues(alpha: isDark ? 0.16 : 0.08),
                                          scheme.surface,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    height: 190,
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 64,
                                          width: 64,
                                          decoration: BoxDecoration(
                                            color: scheme.primary.withValues(alpha: 0.10),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.cloud_upload_outlined, size: 34, color: scheme.primary),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'Upload image',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: scheme.onSurface,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Use a clear photo, or leave it empty for text-only updates.',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      PremiumSurface(
                        gradient: const LinearGradient(
                          colors: [premiumPrimary, premiumAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: 28,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lock_open_rounded, color: Colors.white),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Ready to publish to the community feed',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                backgroundColor: Colors.white,
                                foregroundColor: premiumPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: _isPosting ? null : _addPost,
                              icon: _isPosting
                                  ? SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: premiumPrimary),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: Text(_isPosting ? 'Posting...' : 'Publish post'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Image'),
          content: const Text('Do you want to change image ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                await _pickImage();
                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
