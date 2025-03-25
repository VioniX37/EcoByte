import 'package:flutter/material.dart';

class Textfield extends StatelessWidget {
  const Textfield(
      {super.key,
      required this.controller,
      required this.label,
      this.maxLines = 1,
      this.validator,
      this.obscureText = false});
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        obscureText: obscureText,
        validator: validator,
        maxLines: maxLines,
        controller: controller,
        decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.black),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                    color: Color.fromARGB(255, 13, 17, 161), width: 2)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Color.fromARGB(255, 13, 71, 161), width: 2),
                borderRadius: BorderRadius.circular(15)),
            focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromRGBO(3, 201, 136, 1), width: 2),
                borderRadius: BorderRadius.circular(15)),
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10)),
      ),
    );
  }
}
