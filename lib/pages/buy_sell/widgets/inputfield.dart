import 'package:flutter/material.dart';

class Inputfield extends StatelessWidget {
  const Inputfield(
      {super.key,
      required this.controller,
      required this.label,
      this.validator});
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: null,
        validator: validator,
        decoration: InputDecoration(
            //filled: true,
            //fillColor: Color.fromRGBO(214, 241, 255, 1),
            label: Text(label),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                    color: Color.fromRGBO(3, 201, 136, 1), width: 2)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                    color: Color.fromARGB(255, 13, 17, 161), width: 2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                    color: Color.fromARGB(255, 13, 17, 161), width: 2))),
      ),
    );
  }
}
