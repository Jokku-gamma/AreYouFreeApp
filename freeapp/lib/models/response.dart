import 'package:cloud_firestore/cloud_firestore.dart';

class EventResponse {
  final String id;
  final String announcementId;
  final String userId;
  final String userName;
  final String status; // e.g., 'available', 'not_available'
  final DateTime? respondedAt;

  EventResponse({
    required this.id,
    required this.announcementId,
    required this.userId,
    required this.userName,
    required this.status,
    this.respondedAt,
  });

  factory EventResponse.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return EventResponse(
      id: doc.id,
      announcementId: data['announcementId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      status: data['status'] ?? 'pending',
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'announcementId': announcementId,
      'userId': userId,
      'userName': userName,
      'status': status,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : FieldValue.serverTimestamp(),
    };
  }
}