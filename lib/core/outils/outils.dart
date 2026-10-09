import 'package:flutter/material.dart';

class AppOutils {
  static const BorderRadius radius = BorderRadius.all(Radius.circular(14));
  static const SizedBox espace05 = SizedBox(height: 5);
  static const SizedBox espace10 = SizedBox(height: 10);
  static const SizedBox espace20 = SizedBox(height: 20);
  static const SizedBox espace50 = SizedBox(height: 50);
  static InputDecoration inputDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Widget? counterText,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      counter: counterText,
      errorText: errorText,
    );
  }
}
