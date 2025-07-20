import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ensure this is imported if User is used directly
import '../services/firebase_service.dart';
import '../utils/constants.dart'; // For AppStrings and AppColors

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    // Set loading state and clear previous error message
    if (mounted) { // Check if the widget is still in the tree before first setState
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Attempt to sign in with Google
      User? user = await FirebaseService().signInWithGoogle();

      // After the async operation completes, check if the widget is still mounted
      if (mounted) {
        if (user == null) {
          // If user is null, sign-in was cancelled or failed for other reasons
          setState(() {
            _errorMessage = 'Sign-in cancelled or failed.';
          });
        }
        // The StreamBuilder in main.dart will handle navigation after successful login
        // No explicit navigation here, as per your comment.
      }
    } catch (e) {
      // Catch any errors during the sign-in process
      print('Login error: $e'); // Log the error for debugging

      // After the async operation completes, check if the widget is still mounted
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}'; // Display the error message
        });
      }
    } finally {
      // Ensure loading state is reset, regardless of success or failure
      // After the async operation completes, check if the widget is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Icon(
                Icons.group_work_rounded, // A relevant icon
                size: 100,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 30),
              // App Title
              Text(
                AppStrings.appName,
                style: AppTextStyles.heading1.copyWith(color: AppColors.primaryColor),
              ),
              const SizedBox(height: 20),
              // Welcome Message
              Text(
                AppStrings.loginTitle,
                style: AppTextStyles.heading2.copyWith(color: AppColors.textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Google Sign-In Button
              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primaryColor)
                  : ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: Image.asset(
                        '../../assets/google_logo.png', // Ensure this path is correct relative to your project root
                        height: 24,
                        width: 24,
                      ),
                      label: const Text(AppStrings.signInWithGoogle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardColor, // White background for Google button
                        foregroundColor: AppColors.textColor, // Dark text
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        elevation: 3,
                      ),
                    ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.errorColor, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 50),
              // Footer text
              Text(
                'Connect, Collaborate, Succeed.',
                style: AppTextStyles.bodyText.copyWith(color: AppColors.lightTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
