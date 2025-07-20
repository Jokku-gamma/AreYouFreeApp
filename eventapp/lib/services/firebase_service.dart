import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/usermodel.dart';
import '../models/announcement_model.dart';
import '../utils/constants.dart';


class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(clientId: kWebClientId);

  // --- Authentication ---

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore, if not, create a new entry
        await _checkAndCreateUserInFirestore(user);
      }
      return user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get current authenticated user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // --- User Management (Firestore) ---

  // Check if user exists in Firestore, create if not, and assign role
  Future<void> _checkAndCreateUserInFirestore(User user) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDocRef.get();

    if (!docSnapshot.exists) {
      // New user, determine assigned role
      UserRole assignedRole = UserRole.guest; // Default to guest

      // 1. Check for pre-assigned role from admin
      if (user.email != null) {
        try {
          final preAssignedDoc = await _firestore.collection('pre_assigned_roles').doc(user.email!.toLowerCase()).get();
          if (preAssignedDoc.exists) {
            final data = preAssignedDoc.data();
            if (data != null && data.containsKey('role')) {
              assignedRole = UserModel.stringToUserRole(data['role'] as String);
              print('Found pre-assigned role for ${user.email}: $assignedRole');
            }
          }
        } catch (e) {
          print('Error checking pre-assigned role for ${user.email}: $e');
          // Continue with default role if there's an error fetching pre-assigned
        }
      }

      // 2. Fallback to hardcoded roles if no pre-assigned role found
      // This ensures kHostEmail and kStudentEmail still work if pre_assigned_roles is not used
      // or if the email wasn't pre-assigned.
      if (assignedRole == UserRole.guest) { // Only apply hardcoded if not already assigned by admin
        if (user.email == kHostEmail) {
          assignedRole = UserRole.host;
        } else if (user.email == kStudentEmail) {
          assignedRole = UserRole.student;
        }
      }


      final newUserModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoURL: user.photoURL,
        role: assignedRole,
      );
      await userDocRef.set(newUserModel.toFirestore());
      print('New user created in Firestore: ${user.email} with role: $assignedRole');
    } else {
      print('User already exists in Firestore: ${user.email}');
      // Optional: If you want to allow hosts to *change* roles of existing users
      // via the admin panel, you'd fetch the pre_assigned_roles here and update
      // the existing user's document if the pre-assigned role is different.
      // For now, existing users retain their role unless manually changed in Firestore.
    }
  }

  // Get user role from Firestore
  Future<UserRole> getUserRole(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('role')) {
          return UserModel.stringToUserRole(data['role'] as String);
        }
      }
      return UserRole.unknown; // Default if role not found
    } catch (e) {
      print('Error getting user role: $e');
      return UserRole.unknown;
    }
  }

  // Get current user's full UserModel from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('Error getting current user model: $e');
      return null;
    }
  }

  // Get multiple user models by a list of UIDs
  Future<Map<String, UserModel>> getUsersMapByUids(List<String> uids) async {
    if (uids.isEmpty) {
      return {};
    }
    final Map<String, UserModel> usersMap = {};
    try {
      // Firestore 'whereIn' query has a limit of 10 items.
      // For more than 10 UIDs, you'd need to batch these queries.
      // For simplicity here, we'll assume a small number of responders.
      // If you expect many, implement batching (e.g., split UIDs into chunks of 10).
      final querySnapshot = await _firestore.collection('users')
          .where(FieldPath.documentId, whereIn: uids)
          .get();

      for (var doc in querySnapshot.docs) {
        final userModel = UserModel.fromFirestore(doc);
        usersMap[userModel.uid] = userModel;
      }
    } catch (e) {
      print('Error fetching users by UIDs: $e');
    }
    return usersMap;
  }

  // Method to add/update a graduate user's role manually (by host)
  Future<void> addGraduateUser(String email, UserRole role) async {
    try {
      final preAssignedDocRef = _firestore.collection('pre_assigned_roles').doc(email.toLowerCase());
      await preAssignedDocRef.set({
        'email': email.toLowerCase(),
        'role': role.name,
        'assignedBy': _auth.currentUser?.uid,
        'assignedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Pre-assigned role for $email as ${role.name}');

    } catch (e) {
      print('Error in addGraduateUser: $e');
      rethrow;
    }
  }

  // NEW: Method to update a user's display name
  Future<void> updateUserName(String uid, String newName) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'displayName': newName,
      });
      print('User $uid display name updated to $newName');
    } catch (e) {
      print('Error updating user name for $uid: $e');
      rethrow;
    }
  }


  // --- Announcement Management (Firestore) ---

  // Create a new announcement (Host only)
  Future<void> createAnnouncement(Announcement announcement) async {
    try {
      await _firestore.collection('announcements').add(announcement.toFirestore());
      print('Announcement created successfully!');
    } catch (e) {
      print('Error creating announcement: $e');
    }
  }

  // Get a stream of announcements (for Guests)
  Stream<List<Announcement>> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('eventDate', descending: false) // Order by event date
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Announcement.fromFirestore(doc)).toList());
  }

  // Update guest response for an announcement
  Future<void> updateGuestResponse(String announcementId, String guestUid, String response) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'guestResponses.$guestUid': response, // Dot notation to update nested map
      });
      print('Guest response updated for announcement $announcementId');
    } catch (e) {
      print('Error updating guest response: $e');
    }
  }

  // --- Firestore Security Rules (Conceptual) ---
  // These are not implemented in Dart, but are crucial for your Firebase project.
  // You'd set these in your Firebase Console -> Firestore Database -> Rules tab.
  /*
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      // Users collection: only authenticated users can read/write their own profile
      match /users/{userId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      // Pre-assigned roles collection: only hosts can create/update
      match /pre_assigned_roles/{email} {
        allow read: if request.auth != null; // Anyone can read to check their role
        allow create, update: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'host';
      }

      // Announcements collection:
      // Host can create, read, update, delete
      // Guests can read and update their own response
      match /announcements/{announcementId} {
        allow read: if request.auth != null; // Anyone logged in can read
        allow create: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'host';
        allow update: if request.auth != null && (
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'host' || // Host can update any field
          (request.auth.uid in request.resource.data.guestResponses && request.resource.data.guestResponses[request.auth.uid] != resource.data.guestResponses[request.auth.uid]) // Guest can only update their own response
        );
        allow delete: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'host';
      }
    }
  }
  */
}
