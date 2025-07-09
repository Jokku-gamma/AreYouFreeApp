// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/userprofile.dart';
import 'package:firebase_core/firebase_core.dart'; // Import firebase_core to access DefaultFirebaseOptions

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Initialize GoogleSignIn with the correct clientId for web/desktop platforms
  // The clientId is found in your firebase_options.dart file for the web platform.
  final GoogleSignIn _googleSignIn = GoogleSignIn();
    // Use the webClientId from the generated firebase_options.dart file);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Helper to create or update user profile in Firestore
  Future<void> _createUserProfile(User user, String role) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': role,
      'uid': user.uid,
      // 'fcmToken': null, // Add FCM token here if implementing notifications
    }, SetOptions(merge: true)); // Use merge: true to avoid overwriting existing data
  }

  // Email/Password Sign-in (keeping it for reference, though UI will change)
  Future<User?> signIn({required String email, required String password}) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // For email/password, role is determined at signup.
      // We'll fetch the existing role here or default to guest if not found.
      final userProfileDoc = await _firestore.collection('users').doc(result.user!.uid).get();
      String role = 'guest'; // Default role
      if (userProfileDoc.exists && userProfileDoc.data() != null) {
        role = userProfileDoc.data()!['role'] ?? 'guest';
      }
      await _createUserProfile(result.user!, role); // Ensure profile exists/is updated
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Error signing in: ${e.message}');
      rethrow;
    }
  }

  // Email/Password Sign-up (keeping it for reference, though UI will change)
  Future<User?> signUp({required String email, required String password, required String role}) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await _createUserProfile(user, role);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Error signing up: ${e.message}');
      rethrow;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If the user cancels the sign-in, googleUser will be null
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Determine role based on Google email by checking Firestore 'hosts' collection
        String role;
        if (user.email != null) {
          final hostDoc = await _firestore.collection('hosts').doc(user.email!).get();
          if (hostDoc.exists && hostDoc.data()?['isHost'] == true) {
            role = 'host';
          } else {
            role = 'guest';
          }
        } else {
          // If email is null (shouldn't happen for Google, but as a fallback)
          role = 'guest';
        }
        await _createUserProfile(user, role);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Error signing in with Google: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred during Google sign-in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut(); // Also sign out from Google if signed in via Google
  }
}
