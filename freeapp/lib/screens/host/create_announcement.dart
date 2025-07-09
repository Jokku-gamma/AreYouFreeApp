import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_inputfield.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final TextEditingController _headingController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAlertDialog(String title, String message) {
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

  Future<void> _submitAnnouncement() async {
    if (_headingController.text.isEmpty || _messageController.text.isEmpty || _selectedDate == null) {
      _showAlertDialog('Missing Information', 'Please fill all fields and select a date.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<User?>(context, listen: false);

    try {
      await firestoreService.createAnnouncement(
        heading: _headingController.text.trim(),
        message: _messageController.text.trim(),
        date: _selectedDate!,
        hostId: user!.uid,
      );
      _showAlertDialog('Success', 'Announcement created successfully!');
      Navigator.of(context).pop(); // Go back to host dashboard
    } catch (e) {
      _showAlertDialog('Error', 'Failed to create announcement: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Announcement'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Announce an Event',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                CustomInputField(
                  controller: _headingController,
                  labelText: 'Heading',
                  icon: Icons.title,
                ),
                const SizedBox(height: 16),
                CustomInputField(
                  controller: _messageController,
                  labelText: 'Message',
                  maxLines: 5,
                  icon: Icons.message,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'No Date Chosen!'
                            : 'Picked Date: ${(_selectedDate!).toLocal().toIso8601String().split('T')[0]}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    CustomButton(
                      text: 'Choose Date',
                      onPressed: _pickDate,
                      icon: Icons.calendar_today,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Center(
                    child: CustomButton(
                      text: 'Create Announcement',
                      onPressed: _submitAnnouncement,
                      icon: Icons.send,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}