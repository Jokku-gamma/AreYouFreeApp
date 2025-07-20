import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart'; // Import UserRole enum

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final UserRole role;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.role,
  });

  // Factory constructor to create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id, // The document ID is the user's UID
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      role: stringToUserRole(data['role']), // Convert string to UserRole enum
    );
  }

  // Method to convert a UserModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.name, // Store enum as its string name
    };
  }

  // Helper function to convert string to UserRole enum
  static UserRole stringToUserRole(String? roleString) {
    if (roleString == null) return UserRole.unknown;
    switch (roleString) {
      case 'host':
        return UserRole.host;
      case 'student':
        return UserRole.student;
      case 'guest':
        return UserRole.guest;
      default:
        return UserRole.unknown;
    }
  }

  // NEW: copyWith method for immutability and easy updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
    );
  }
}
