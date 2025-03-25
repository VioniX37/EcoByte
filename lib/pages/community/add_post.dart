import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  File? image;
  String? imageUrl;
  final picker = ImagePicker();
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController descriptionController = TextEditingController();
  late String profile;

  Future<void> getUserFields(String userId) async {
    // Get the user document from the "users" collection using the user ID
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    print(userId);

    // Check if the document exists
    if (userDoc.exists) {
      // Access fields from the user document
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      profile = userData['profile'];
    }
  }

  // Function to pick an image from gallery
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
      print(publicUrl);

      return publicUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Post"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  TextField(
                    scribbleEnabled: false,
                    decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        labelText: "Description",
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 13, 71, 161),
                                width: 2)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 13, 71, 161),
                                width: 2))),
                    maxLines: 10,
                    controller: descriptionController,
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  image != null
                      ? GestureDetector(
                          onTap: () {
                            showPopup(context);
                          },
                          child: Image.file(
                            image!,
                            height: 350,
                            width: 400,
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            _pickImage();
                          },
                          child: DottedBorder(
                              color: Colors.blue,
                              dashPattern: [10, 4],
                              radius: Radius.circular(10),
                              borderType: BorderType.RRect,
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10)),
                                height: 150,
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 40,
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Text(
                                      "Upload image",
                                      style: TextStyle(fontSize: 15),
                                    )
                                  ],
                                ),
                              )),
                        ),
                  SizedBox(
                    height: 50,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 13, 71, 161)),
                      onPressed: _addProductToFirestore,
                      child: Text(
                        "Post",
                        style: TextStyle(color: Colors.white),
                      ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addProductToFirestore() async {
    CollectionReference products = firestore.collection('messages');
    await getUserFields(FirebaseAuth.instance.currentUser!.uid);

    await products.add({
      'description': descriptionController.text,
      'senderName': FirebaseAuth.instance.currentUser!.displayName,
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'imageUrl': imageUrl,
      'id': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'likedBy': [],
      'profile': profile
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Post Uploaded!")));

    descriptionController.clear();
    Navigator.of(context).pop();
  }

  void showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Change Image"),
          content: Text("Do you want to change image ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the popup
              },
              child: Text("No"),
            ),
            TextButton(
                onPressed: () async {
                  await _pickImage();
                  Navigator.pop(context);
                },
                child: Text("Yes")),
          ],
        );
      },
    );
  }
}
