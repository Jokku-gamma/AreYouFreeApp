import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';
import '../models/userprofile.dart';
import '../models/response.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream user profile
  Stream<UserProfile?> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Host: Create a new announcement
  Future<void> createAnnouncement({
    required String heading,
    required String message,
    required DateTime date,
    required String hostId,
  }) async {
    await _firestore.collection('announcements').add({
      'heading': heading,
      'message': message,
      'date': Timestamp.fromDate(date),
      'hostId': hostId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // TODO: Implement FCM notification sending here via a Cloud Function
  }

  // Host/Guest: Stream all announcements
  Stream<List<Announcement>> streamAnnouncements() {
    return _firestore.collection('announcements').orderBy('date', descending: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Announcement.fromFirestore(doc)).toList();
    });
  }

  // Guest: Respond to an announcement
  Future<void> respondToAnnouncement({
    required String announcementId,
    required String userId,
    required String userName, // To display who responded
    required String status, // e.g., 'available', 'not_available'
  }) async {
    // Check if a response already exists for this user and announcement
    final existingResponse = await _firestore
        .collection('responses')
        .where('announcementId', isEqualTo: announcementId)
        .where('userId', isEqualTo: userId)
        .get();

    if (existingResponse.docs.isNotEmpty) {
      // Update existing response
      await _firestore.collection('responses').doc(existingResponse.docs.first.id).update({
        'status': status,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Add new response
      await _firestore.collection('responses').add({
        'announcementId': announcementId,
        'userId': userId,
        'userName': userName,
        'status': status,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Host/Guest: Stream responses for a specific announcement
  Stream<List<EventResponse>> streamResponsesForAnnouncement(String announcementId) {
    return _firestore
        .collection('responses')
        .where('announcementId', isEqualTo: announcementId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventResponse.fromFirestore(doc)).toList();
    });
  }

  // Host: Get user details for responses (e.g., to show email/name)
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }
}