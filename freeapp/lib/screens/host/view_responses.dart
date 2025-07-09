import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../models/response.dart';
import '../../services/firebase_service.dart';

class ViewResponsesScreen extends StatelessWidget {
  final Announcement announcement;

  const ViewResponsesScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Responses'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.heading,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${announcement.date.toLocal().toIso8601String().split('T')[0]}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      announcement.message,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Guest Responses:',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<EventResponse>>(
                stream: firestoreService.streamResponsesForAnnouncement(announcement.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No responses yet.'));
                  }

                  final responses = snapshot.data!;
                  final availableResponses = responses.where((res) => res.status == 'available').toList();
                  final notAvailableResponses = responses.where((res) => res.status == 'not_available').toList();

                  return ListView(
                    children: [
                      if (availableResponses.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available (${availableResponses.length}):',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green),
                            ),
                            ...availableResponses.map((res) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text(res.userName),
                                subtitle: Text('Responded at: ${res.respondedAt?.toLocal().toIso8601String().split('.')[0] ?? 'N/A'}'),
                              ),
                            )),
                            const SizedBox(height: 10),
                          ],
                        ),
                      if (notAvailableResponses.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Not Available (${notAvailableResponses.length}):',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red),
                            ),
                            ...notAvailableResponses.map((res) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                leading: const Icon(Icons.cancel, color: Colors.red),
                                title: Text(res.userName),
                                subtitle: Text('Responded at: ${res.respondedAt?.toLocal().toIso8601String().split('.')[0] ?? 'N/A'}'),
                              ),
                            )),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}