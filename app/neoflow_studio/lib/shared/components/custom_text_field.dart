import 'package:flutter/material.dart';
import 'package:neoflow_studio/core/constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: APP_PRIMARY_COLOR) : null,
      ),
    );
  }
}
