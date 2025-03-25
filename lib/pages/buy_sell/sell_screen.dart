import 'package:e_waste/pages/buy_sell/user_data.dart';
import 'package:e_waste/pages/buy_sell/widgets/inputfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

TextEditingController emailController = TextEditingController();
TextEditingController nameController = TextEditingController();
TextEditingController priceController = TextEditingController();
TextEditingController phoneController = TextEditingController();
TextEditingController descriptionController = TextEditingController();
TextEditingController addressController = TextEditingController();

class SellScreen extends StatefulWidget {
  @override
  _SellScreenState createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  File? image;
  String? imageUrl;
  final picker = ImagePicker();
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Future<Map<String, dynamic>?> userData = getUserDataSell();

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

  // Function to upload the image to Firebase Storage
  Future<String?> _uploadImage() async {
    if (image == null) {
      return null;
    }
    // User canceled image picking

    final supabase = Supabase.instance.client;
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

  // Function to add product details to Firestore
  Future<void> _addProductToFirestore() async {
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please upload an image first.")));
      return;
    }

    CollectionReference products = firestore.collection('products');

    await products.add({
      'name': nameController.text,
      'price': priceController.text,
      'description': descriptionController.text,
      'address': addressController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'imageUrl': imageUrl,
      'id': FirebaseAuth.instance.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'topics': selectedTopics
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Product successfully added!")));
    nameController.clear();
    priceController.clear();
    descriptionController.clear();

    Navigator.of(context).pop();
  }

  List<String> selectedTopics = [];
  final formKey = GlobalKey<FormState>();
  void _submitForm() {
    if (formKey.currentState!.validate()) {
      // If all fields are valid
      _addProductToFirestore();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: const Center(child: CircularProgressIndicator()),
            ); // Show loading spinner
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No data found"));
          }

          Map<String, dynamic> data = snapshot.data!;
          emailController = TextEditingController(text: data['email']);
          phoneController = TextEditingController(text: data['phone']);

          return Scaffold(
            appBar: AppBar(
              title: Text(
                "Upload Product",
              ),
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Inputfield(
                      controller: nameController,
                      label: "Product name",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Required to fill";
                        }
                        return null;
                      },
                    ),
                    Inputfield(
                        controller: priceController,
                        label: "Price",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Required to fill";
                          }
                          return null;
                        }),
                    SizedBox(
                      height: 10,
                    ),
                    Text("Select Category"),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          "IT equipment",
                          "Telecommunication",
                          "Domestic equipments",
                          "Industrial Components"
                        ]
                            .map((e) => Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedTopics.contains(e)) {
                                        selectedTopics.remove(e);
                                      } else {
                                        selectedTopics.add(e);
                                      }

                                      setState(() {});
                                    },
                                    child: Chip(
                                      label: Text(
                                        e,
                                        style: TextStyle(
                                            color: selectedTopics.contains(e)
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                      backgroundColor:
                                          selectedTopics.contains(e)
                                              ? Color.fromARGB(255, 13, 71, 161)
                                              : null,
                                      side: BorderSide(color: Colors.black),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Inputfield(
                        controller: emailController,
                        label: "Email",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Required to fill";
                          }
                          return null;
                        }),
                    Inputfield(
                        controller: phoneController,
                        label: "Phone",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Required to fill";
                          }
                          return null;
                        }),
                    Inputfield(
                        controller: addressController,
                        label: "Address",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Required to fill";
                          }
                          return null;
                        }),
                    Inputfield(
                        controller: descriptionController,
                        label: "Description",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Required to fill";
                          }
                          return null;
                        }),
                    SizedBox(height: 10),
                    image != null
                        ? GestureDetector(
                            onTap: () {
                              showPopup(context);
                            },
                            child: Image.file(
                              image!,
                              height: 300,
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
                                        color: Colors.blue[900],
                                        Icons.folder_open,
                                        size: 40,
                                      ),
                                      SizedBox(
                                        height: 15,
                                      ),
                                      Text(
                                        "Select your image",
                                        style: TextStyle(fontSize: 15),
                                      )
                                    ],
                                  ),
                                )),
                          ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 13, 71, 161)),
                          onPressed: _submitForm,
                          child: Text(
                            "Submit",
                            style: TextStyle(color: Colors.white),
                          )),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
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
                  _pickImage();
                  Navigator.pop(context);
                },
                child: Text("Yes")),
          ],
        );
      },
    );
  }
}
