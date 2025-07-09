import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String heading;
  final String message;
  final DateTime date;
  final String hostId;
  final DateTime? createdAt;

  Announcement({
    required this.id,
    required this.heading,
    required this.message,
    required this.date,
    required this.hostId,
    this.createdAt,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      heading: data['heading'] ?? '',
      message: data['message'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      hostId: data['hostId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'heading': heading,
      'message': message,
      'date': Timestamp.fromDate(date),
      'hostId': hostId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}