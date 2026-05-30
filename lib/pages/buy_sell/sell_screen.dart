import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/pages/buy_sell/user_data.dart';
import 'package:e_waste/pages/buy_sell/widgets/inputfield.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final ImagePicker picker = ImagePicker();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late Future<Map<String, dynamic>?> userData;
  File? image;
  String? imageUrl;
  final List<String> selectedTopics = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    userData = getUserDataSell();
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    priceController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      image = File(pickedFile.path);
      _isUploading = true;
    });

    try {
      final uploadedImageUrl = await SupabaseRepository.uploadFile(
        file: image!,
        bucket: 'uploads',
        folder: 'products',
      );

      if (mounted) {
        setState(() {
          imageUrl = uploadedImageUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product image upload failed: $e')),
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

  Future<void> _addProduct() async {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image first.')),
      );
      return;
    }

    final user = SupabaseRepository.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final price = num.tryParse(priceController.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }

    try {
      await SupabaseRepository.insertProduct(
        userId: user.id,
        name: nameController.text.trim(),
        price: price,
        description: descriptionController.text.trim(),
        address: addressController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        imageUrl: imageUrl!,
        topics: selectedTopics,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product successfully added!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: userData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PremiumModeShell(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return PremiumModeShell(
            appBar: AppBar(
              title: const Text('Upload Product'),
              actions: const [ThemeToggleIconButton()],
            ),
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final data = snapshot.data;
        if (data != null) {
          if (nameController.text.isEmpty) {
            nameController.text = data['name']?.toString() ?? '';
          }
          if (emailController.text.isEmpty) {
            emailController.text = SupabaseRepository.client.auth.currentUser?.email ?? '';
          }
          if (phoneController.text.isEmpty) {
            phoneController.text = data['phone']?.toString() ?? '';
          }
          if (addressController.text.isEmpty) {
            addressController.text = data['address']?.toString() ?? '';
          }
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return PremiumModeShell(
          appBar: AppBar(
            title: const Text('Upload Product'),
            actions: const [ThemeToggleIconButton()],
          ),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                PremiumModeSurface(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5269), Color(0xFF2C8C6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'List a reusable item',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a photo, fill in the details, and publish a cleaner listing in minutes.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const PremiumModeSectionHeader(
                  title: 'Listing details',
                  subtitle: 'Tell buyers what you are selling and why it matters.',
                ),
                const SizedBox(height: 12),
                PremiumModeSurface(
                  child: Column(
                    children: [
                      Inputfield(
                        controller: nameController,
                        label: 'Product name',
                        validator: (value) => value == null || value.isEmpty ? 'Required to fill' : null,
                      ),
                      Inputfield(
                        controller: priceController,
                        label: 'Price',
                        validator: (value) => value == null || value.isEmpty ? 'Required to fill' : null,
                      ),
                      Inputfield(
                        controller: emailController,
                        label: 'Email',
                        validator: (value) => value == null || value.isEmpty ? 'Required to fill' : null,
                      ),
                      Inputfield(
                        controller: phoneController,
                        label: 'Phone',
                        validator: (value) => value == null || value.isEmpty ? 'Required to fill' : null,
                      ),
                      Inputfield(
                        controller: addressController,
                        label: 'Address',
                        validator: (value) => value == null || value.isEmpty ? 'Required to fill' : null,
                      ),
                      Inputfield(
                        controller: descriptionController,
                        label: 'Product description',
                        validator: (value) => value == null || value.isEmpty ? 'Tell buyers about the product' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const PremiumModeSectionHeader(
                  title: 'Choose a category',
                  subtitle: 'Categories help buyers find the right reusable items faster.',
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'IT equipment',
                      'Telecommunication',
                      'Domestic equipments',
                      'Industrial Components'
                    ]
                        .map(
                          (topic) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              selected: selectedTopics.contains(topic),
                              label: Text(topic),
                              labelStyle: TextStyle(
                                color: selectedTopics.contains(topic)
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                              selectedColor: const Color(0xFF1A5269),
                              backgroundColor: isDark
                                  ? const Color(0xFF12171D)
                                  : Colors.white,
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFF1A5269).withValues(alpha: 0.12),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  if (selectedTopics.contains(topic)) {
                                    selectedTopics.remove(topic);
                                  } else {
                                    selectedTopics.add(topic);
                                  }
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 18),
                const PremiumModeSectionHeader(
                  title: 'Product image',
                  subtitle: 'Use a clear image to make the listing look polished and trustworthy.',
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: image != null
                      ? PremiumModeSurface(
                          padding: EdgeInsets.zero,
                          borderRadius: 24,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.file(
                              image!,
                              height: 240,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : DottedBorder(
                          color: const Color(0xFF1A5269),
                          dashPattern: const [10, 4],
                          radius: const Radius.circular(24),
                          borderType: BorderType.RRect,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF12171D)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            height: 180,
                            width: double.infinity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open, size: 40, color: const Color(0xFF1A5269)),
                                const SizedBox(height: 12),
                                Text(
                                  'Upload image',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to choose from gallery',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                PremiumModeSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload summary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Review your details, then publish the listing to the marketplace.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1A5269),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _isUploading ? null : _addProduct,
                        icon: _isUploading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.publish_outlined),
                        label: Text(
                          _isUploading ? 'Uploading image...' : 'Upload Product',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
