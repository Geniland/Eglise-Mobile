import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5546C7);
  static const Color primaryLight = Color(0xFF7568DE);
  static const Color primaryDark = Color(0xFF4034A2);
  static const Color secondary = Color(0xFF0F9D91);
  static const Color secondaryLight = Color(0xFF4ABDB1);
  static const Color secondaryDark = Color(0xFF08796F);

  static const Color success = Color(0xFF138A62);
  static const Color error = Color(0xFFB42318);
  static const Color warning = Color(0xFFB54708);
  static const Color info = Color(0xFF2870BD);

  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1B2030);
  static const Color textPrimary = Color(0xFF20243A);
  static const Color textSecondary = Color(0xFF62697B);
  static const Color textLight = Color(0xFF8A90A2);

  // Legacy names kept for existing screens while they migrate to semantic tokens.
  static const Color couleur1 = primary;
  static const Color couleur11 = primaryLight;
  static const Color couleur2 = secondary;
  static const Color couleur21 = secondaryLight;
  static const Color couleur3 = warning;
  static const Color couleur31 = Color(0xFFFFD589);
  static const Color couleur4 = Color(0xFF2870BD);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
