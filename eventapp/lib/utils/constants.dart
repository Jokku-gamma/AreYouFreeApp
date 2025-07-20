import 'package:flutter/material.dart';

// Define user roles for clarity and type safety
enum UserRole { host, student, guest, unknown }

// Define some consistent colors for the app
class AppColors {
  static const Color primaryColor = Color(0xFF673AB7); // Deep Purple
  static const Color accentColor = Color(0xFFFFC107); // Amber
  static const Color backgroundColor = Color(0xFFF3E5F5); // Light Purple
  static const Color textColor = Color(0xFF333333);
  static const Color lightTextColor = Color(0xFF666666);
  static const Color cardColor = Colors.white;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
}

// Define some common text styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textColor);
  static const TextStyle heading2 = TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textColor);
  static const TextStyle bodyText = TextStyle(fontSize: 16, color: AppColors.lightTextColor);
  static const TextStyle buttonText = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
}

// Define common padding and margin values
class AppSpacing {
  static const EdgeInsets screenPadding = EdgeInsets.all(20.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const double borderRadius = 15.0;
  static const double buttonRadius = 12.0;
}

// Define common strings (if any, for now, just a placeholder)
class AppStrings {
  static const String appName = 'Graduates Meeting App';
  static const String loginTitle = 'Welcome Back!';
  static const String signInWithGoogle = 'Sign in with Google';
}

// Hardcoded host email for initial role assignment.
// In a real app, you'd have an admin panel to assign roles.
const String kHostEmail = 'dinjoseph55@gmail.com'; // **IMPORTANT: Replace with your actual host email**
const String kStudentEmail = 'joelkuaba2004@gmail.com';
const String kGradEmail='maceeu07@gmail.com'; // <--- Make sure this line exists and has a real email
const String kWebClientId = '485242111693-44au9kgv45lk4v6mnm631mfo0jklslh8.apps.googleusercontent.com';