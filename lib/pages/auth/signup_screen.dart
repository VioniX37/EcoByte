import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:e_waste/pages/auth/widgets/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> register() async {
    try {
      FirebaseAuth.instance.setLanguageCode("en");

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      await userCredential.user!
          .updateProfile(displayName: nameController.text);
      await userCredential.user!.reload();

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text,
        'address': addressController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'total_score': 0,
        'profile': '',
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Registration Successful!"),
      ));
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => LoginScreen()), (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Registration Failed: $e"),
      ));
    }
  }

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                Image.asset(
                  'assets/logo.png',
                  height: 100,
                ),
                SizedBox(
                  height: 30,
                ),
                Text(
                  "Create an account",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                SizedBox(
                  height: 20,
                ),
                Textfield(
                  controller: nameController,
                  label: "Name",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Required to fill";
                    }
                    return null;
                  },
                ),
                Textfield(
                  controller: emailController,
                  label: "Email",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Required to fill";
                    }
                    return null;
                  },
                ),
                Textfield(
                  controller: phoneController,
                  label: "Phone",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Required to fill";
                    }
                    return null;
                  },
                ),
                Textfield(
                  controller: passwordController,
                  label: "Password",
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Required to fill";
                    }
                    return null;
                  },
                ),
                Textfield(
                  controller: confirmpasswordController,
                  label: "Confirm Password",
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Required to fill";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // If all fields are valid
                      if (passwordController.text !=
                          confirmpasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: Colors.red,
                          content: Text("Password Confirmation Failed!"),
                        ));
                      } else {
                        register();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill in all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 13, 71, 161),
                  ),
                  child: Text(
                    "Register",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (ctx) => LoginScreen()),
                        (route) => false);
                  },
                  child: RichText(
                      text: TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(color: Colors.black),
                          children: [
                        TextSpan(
                          text: "Log In",
                        )
                      ])),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
