import 'package:flutter/material.dart';

class Textfield extends StatelessWidget {
  const Textfield(
      {super.key,
      required this.controller,
      required this.label,
      this.maxLines = 1,
      this.validator,
      this.obscureText = false,
      this.keyboardType});
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
    final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        controller: controller,
        decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: scheme.onSurfaceVariant),
            filled: true,
            fillColor: scheme.surface.withOpacity(0.6),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: scheme.outline, width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: scheme.outline, width: 1.5),
                borderRadius: BorderRadius.circular(15)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: scheme.primary, width: 2),
                borderRadius: BorderRadius.circular(15)),
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10)),
      ),
    );
  }
}
