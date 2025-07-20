import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String hostId;
  final String hostName;
  final String heading;
  final String message;
  final DateTime eventDate;
  final DateTime createdAt;
  // Map to store guest availability: {guestUid: 'available'/'not_available'}
  final Map<String, String> guestResponses;

  Announcement({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.heading,
    required this.message,
    required this.eventDate,
    required this.createdAt,
    this.guestResponses = const {},
  });

  // Factory constructor to create an Announcement from a Firestore DocumentSnapshot
  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      heading: data['heading'] ?? '',
      message: data['message'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      guestResponses: Map<String, String>.from(data['guestResponses'] ?? {}),
    );
  }

  // Convert Announcement to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'heading': heading,
      'message': message,
      'eventDate': Timestamp.fromDate(eventDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'guestResponses': guestResponses,
    };
  }

  // Method to update the announcement with new guest responses
  Announcement copyWith({
    Map<String, String>? guestResponses,
  }) {
    return Announcement(
      id: id,
      hostId: hostId,
      hostName: hostName,
      heading: heading,
      message: message,
      eventDate: eventDate,
      createdAt: createdAt,
      guestResponses: guestResponses ?? this.guestResponses,
    );
  }
}
