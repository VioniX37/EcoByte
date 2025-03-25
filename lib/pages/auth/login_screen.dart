import 'package:e_waste/pages/auth/widgets/textfield.dart';
import 'package:e_waste/pages/main_screen.dart';
import 'package:e_waste/pages/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> login() async {
    try {
      FirebaseAuth.instance.setLanguageCode("en");

      await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Login Successful!"),
      ));
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => MainScreen()), (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Login Failed: $e"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EcoByte',
          style: GoogleFonts.macondo(fontSize: 30),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 80,
              ),
              // Text(
              //   "EcoByte",
              //   style: TextStyle(fontSize: 25),
              // ),
              Image.asset(
                'assets/logo.png',
                height: 100,
              ),
              SizedBox(
                height: 50,
              ),
              Textfield(controller: emailController, label: "Email"),
              Textfield(
                controller: passwordController,
                label: "Password",
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 13, 71, 161),
                  ),
                  child: Text(
                    "Login",
                    style: TextStyle(color: Colors.white),
                  )),
              SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => SignupScreen()));
                },
                child: RichText(
                    text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.black),
                        children: [
                      TextSpan(
                        text: "Sign Up",
                      )
                    ])),
              )
            ],
          ),
        ),
      ),
    );
  }
}
