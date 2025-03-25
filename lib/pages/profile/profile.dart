import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_waste/others/color.dart';
import 'package:e_waste/pages/profile/rewards.dart';
import 'package:e_waste/pages/buy_sell/my_products.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userData});
  final Future<Map<String, dynamic>?> userData;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? image;
  String? imageUrl;
  final picker = ImagePicker();
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      image = File(pickedFile.path);
    });

    String? uploadedImageUrl = await _uploadImage();
    if (uploadedImageUrl != null) {
      setState(() {
        imageUrl = uploadedImageUrl;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (image == null) {
      return null;
    }
    // User canceled image picking

    final supabase = supa.Supabase.instance.client;
    final String fileName =
        'uploads/${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      File file = File(image!.path);

      // Upload image to Supabase Storage
      await supabase.storage.from('avatars').upload(fileName, file);

      // Get the public URL of the uploaded image
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> _addProductToFirestore() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'profile': imageUrl, // New field added
    });
  }

  Future<Map<String, dynamic>> getUserFields(String userId) async {
    // Get the user document from the "users" collection using the user ID
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // Check if the document exists

    // Access fields from the user document
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    return userData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
        future: getUserFields(FirebaseAuth.instance.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            ); // Show loading spinner
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No data found"));
          }

          Map<String, dynamic> data = snapshot.data!;
          imageUrl = data['profile'];

          return Scaffold(
            appBar: AppBar(
              title: Text("Profile"),
            ),
            body: Center(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  const SizedBox(height: 24),
                  // Profile Avatar

                  GestureDetector(
                    onTap: () async {
                      await _pickImage();
                      await _addProductToFirestore();
                      //  setState(() {

                      //  });
                    },
                    child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.appColor,
                          shape: BoxShape.circle,
                        ),
                        child: image != null || imageUrl != ''
                            ? ClipOval(
                                child: image != null
                                    ? Image.file(
                                        image!,
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        imageUrl!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ))
                            : Icon(
                                Icons.person_outline,
                                size: 60,
                                color: Colors.white,
                              )),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['name'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Email Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          'E MAIL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4444FF),
                          ),
                        ),
                        SizedBox(width: 24),
                        Text(
                          data['email'],
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Phone Number Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          'PH No',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4444FF),
                          ),
                        ),
                        SizedBox(width: 24),
                        Text(
                          data['phone'],
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Button Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (ctx) => MyProducts()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.appColor,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'My Products',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (ctx) =>
                                      Rewards(score: data['total_score'])));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.appColor,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Rewards',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Added to match the layout's empty space
                ],
              ),
            ),
          );
        });
  }
}
