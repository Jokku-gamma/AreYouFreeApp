// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // For state management

// Firebase options (replace with your actual Firebase options)
import 'firebase_options.dart';

// Services
import './services/auth_service.dart';
import './services/firebase_service.dart';

// Models
import './models/userprofile.dart';

// Screens
import './screens/auth_screen.dart';
import './screens/host/host_dashboard.dart';
import './screens/guest/guest_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        // Provide UserProfile stream based on the current User
        StreamProvider<UserProfile?>(
          create: (context) {
            final user = context.read<User?>();
            if (user != null) {
              return context.read<FirestoreService>().streamUserProfile(user.uid);
            }
            return Stream.value(null);
          },
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Event Planner',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Apply rounded corners to all elements
          cardTheme: CardThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final userProfile = context.watch<UserProfile?>();

    if (user == null) {
      // User is not logged in, show AuthScreen
      return const AuthScreen();
    } else {
      // User is logged in, check user profile to determine role
      if (userProfile == null) {
        // User profile is still loading or doesn't exist, show a loading indicator
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      } else {
        // User profile loaded, navigate based on role
        if (userProfile.role == 'host') {
          return const HostDashboard();
        } else if (userProfile.role == 'guest') {
          return const GuestDashboard();
        } else {
          // Default or unknown role, perhaps show an error or a generic dashboard
          return Scaffold(
            appBar: AppBar(title: const Text('Unknown Role')),
            body: const Center(
              child: Text('Your user role is not recognized. Please contact support.'),
            ),
          );
        }
      }
    }
  }
}