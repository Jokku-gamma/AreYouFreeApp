import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/announcement.dart';
import '../../models/response.dart';
import '../../services/firebase_service.dart';
import '../../models/userprofile.dart'; // Import UserProfile

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  void _showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  Future<void> _respond(BuildContext context, String status) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<User?>(context, listen: false);
    final userProfile = Provider.of<UserProfile?>(context, listen: false); // Get user profile

    if (user == null || userProfile == null) {
      _showAlertDialog(context, 'Error', 'You must be logged in to respond.');
      return;
    }

    try {
      await firestoreService.respondToAnnouncement(
        announcementId: announcement.id,
        userId: user.uid,
        userName: userProfile.email, // Use user's email as name for display
        status: status,
      );
      _showAlertDialog(context, 'Success', 'Your response has been recorded as "$status".');
    } catch (e) {
      _showAlertDialog(context, 'Error', 'Failed to record response: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUser = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.heading,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Date: ${announcement.date.toLocal().toIso8601String().split('T')[0]}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      announcement.message,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Response:',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respond(context, 'available'),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('I will come'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respond(context, 'not_available'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cannot come'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Who is coming:',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<EventResponse>>(
              stream: firestoreService.streamResponsesForAnnouncement(announcement.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No one has responded yet.'));
                }

                final responses = snapshot.data!;
                final availableGuests = responses.where((res) => res.status == 'available').toList();

                if (availableGuests.isEmpty) {
                  return const Center(child: Text('No one has marked themselves as available yet.'));
                }

                return ListView.builder(
                  shrinkWrap: true, // Important for nested list views
                  physics: const NeverScrollableScrollPhysics(), // Important for nested list views
                  itemCount: availableGuests.length,
                  itemBuilder: (context, index) {
                    final response = availableGuests[index];
                    final isCurrentUser = currentUser?.uid == response.userId;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 2,
                      color: isCurrentUser ? Colors.deepPurple.shade50 : Colors.white,
                      child: ListTile(
                        leading: Icon(Icons.person, color: isCurrentUser ? Theme.of(context).primaryColor : Colors.grey),
                        title: Text(
                          isCurrentUser ? '${response.userName} (You)' : response.userName,
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentUser ? Theme.of(context).primaryColor : Colors.black,
                          ),
                        ),
                        subtitle: Text('Status: ${response.status.toUpperCase()}'),
                        trailing: isCurrentUser ? const Icon(Icons.star, color: Colors.amber) : null,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}