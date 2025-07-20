import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../services/firebase_service.dart';
import '../models/announcement_model.dart';
import '../models/usermodel.dart';
import '../utils/constants.dart'; // For AppColors, AppTextStyles, UserRole

// DO NOT import login_screen.dart here. Navigation back to login
// is handled by the StreamBuilder in main.dart after signOut().

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  final _announcementFormKey = GlobalKey<FormState>();
  final TextEditingController _headingController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  DateTime? _selectedDate;

  final _userFormKey = GlobalKey<FormState>();
  final TextEditingController _userEmailController = TextEditingController();
  UserRole _selectedUserRole = UserRole.student;

  final TextEditingController _profileNameController = TextEditingController(); // New controller for profile name

  UserModel? _currentUser;
  bool _isLoading = true; // For initial user data loading
  String? _errorMessage;
  bool _isAddingUser = false; // For adding/updating user roles
  bool _isUpdatingProfile = false; // For updating user profile name

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _headingController.dispose();
    _messageController.dispose();
    _userEmailController.dispose();
    _profileNameController.dispose(); // Dispose new controller
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });
    try {
      _currentUser = await _firebaseService.getCurrentUserModel();
      if (_currentUser == null) {
        _errorMessage = "Could not load user data. Please re-login.";
      } else {
        _profileNameController.text = _currentUser!.displayName; // Set initial value for profile name
      }
    } catch (e) {
      _errorMessage = "Error loading user: $e";
      print("Error loading current user: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primaryColor,
            colorScheme: const ColorScheme.light(primary: AppColors.primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      if (mounted) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }
  }

  Future<void> _createAnnouncement() async {
    if (_announcementFormKey.currentState!.validate()) {
      if (_selectedDate == null) {
        if (mounted) {
          setState(() {
            _errorMessage = "Please select an event date.";
          });
        }
        return;
      }
      if (_currentUser == null) {
        if (mounted) {
          setState(() {
            _errorMessage = "User data not loaded. Cannot create announcement.";
          });
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final newAnnouncement = Announcement(
        id: '',
        hostId: _currentUser!.uid,
        hostName: _currentUser!.displayName,
        heading: _headingController.text,
        message: _messageController.text,
        eventDate: _selectedDate!,
        createdAt: DateTime.now(),
        guestResponses: {},
      );

      try {
        await _firebaseService.createAnnouncement(newAnnouncement);
        _headingController.clear();
        _messageController.clear();
        if (mounted) {
          setState(() {
            _selectedDate = null;
            _isLoading = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Announcement created successfully!'),
                backgroundColor: AppColors.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
              ),
            );
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to create announcement: $e";
            _isLoading = false;
          });
        }
        print("Error creating announcement: $e");
      }
    }
  }

  Future<void> _addGraduateUser() async {
    if (_userFormKey.currentState!.validate()) {
      if (!mounted) return;

      setState(() {
        _isAddingUser = true;
        _errorMessage = null;
      });

      try {
        final email = _userEmailController.text.trim();
        final role = _selectedUserRole;

        await _firebaseService.addGraduateUser(email, role);

        _userEmailController.clear();
        if (mounted) {
          setState(() {
            _isAddingUser = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User "$email" added/updated with role: ${role.name}!'),
                backgroundColor: AppColors.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
              ),
            );
          });
        }
      } catch (e) {
        print("Error adding graduate user: $e");
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to add user: ${e.toString()}";
            _isAddingUser = false;
          });
        }
      }
    }
  }

  // NEW: Method to update the current user's display name
  Future<void> _updateProfileName() async {
    if (!mounted || _currentUser == null) return;

    setState(() {
      _isUpdatingProfile = true;
      _errorMessage = null;
    });

    try {
      final newName = _profileNameController.text.trim();
      if (newName.isEmpty) {
        throw 'Name cannot be empty.';
      }

      await _firebaseService.updateUserName(_currentUser!.uid, newName);

      // Update the local UserModel instance
      _currentUser = _currentUser!.copyWith(displayName: newName);

      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile name updated successfully!'),
              backgroundColor: AppColors.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
            ),
          );
        });
      }
    } catch (e) {
      print("Error updating profile name: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to update profile: ${e.toString()}";
          _isUpdatingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Host Dashboard'),
        // No actions here, profile icon will be in the body
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.borderRadius),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Profile Section ---
                      Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: AppSpacing.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_circle, size: 40, color: AppColors.primaryColor),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Welcome, ${_currentUser?.displayName ?? 'Host'}!',
                                    style: AppTextStyles.heading2.copyWith(color: AppColors.primaryColor),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.logout, color: AppColors.textColor),
                                    tooltip: 'Logout',
                                    onPressed: () async {
                                      await _firebaseService.signOut();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'Email: ${_currentUser?.email ?? 'N/A'}',
                                style: AppTextStyles.bodyText,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'Edit Profile Name:',
                                style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _profileNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Display Name',
                                  hintText: 'Enter your preferred name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Name cannot be empty';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),
                              Center(
                                child: ElevatedButton(
                                  onPressed: _isUpdatingProfile ? null : _updateProfileName,
                                  child: _isUpdatingProfile
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Save Profile'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Create New Announcement Section ---
                      Text(
                        'Create New Announcement',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _announcementFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _headingController,
                              decoration: const InputDecoration(
                                labelText: 'Heading',
                                hintText: 'Enter announcement heading',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a heading';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                labelText: 'Message',
                                hintText: 'Enter detailed message for the announcement',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a message';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                  border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: AppColors.primaryColor),
                                    const SizedBox(width: 10),
                                    Text(
                                      _selectedDate == null
                                          ? 'Select Event Date'
                                          : 'Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)}',
                                      style: AppTextStyles.bodyText.copyWith(color: AppColors.primaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Center(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _createAnnouncement,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Create Announcement'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- Manage User Roles Section ---
                      Text(
                        'Manage User Roles',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _userFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _userEmailController,
                              decoration: const InputDecoration(
                                labelText: 'User Email',
                                hintText: 'Enter email of the graduate',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            DropdownButtonFormField<UserRole>(
                              value: _selectedUserRole,
                              decoration: InputDecoration(
                                labelText: 'Assign Role',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.primaryColor.withOpacity(0.05), // Light fill color
                              ),
                              items: UserRole.values.where((role) => role != UserRole.host && role != UserRole.unknown).map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role.name.capitalize()),
                                );
                              }).toList(),
                              onChanged: (UserRole? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedUserRole = newValue;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 30),
                            Center(
                              child: ElevatedButton(
                                onPressed: _isAddingUser ? null : _addGraduateUser,
                                child: _isAddingUser
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Add/Update User Role'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- Display Existing Announcements ---
                      Text(
                        'Your Announcements',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<List<Announcement>>(
                        stream: _firebaseService.getAnnouncements(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: AppColors.primaryColor),
                            );
                          }
                          if (snapshot.hasError) {
                            print('Error fetching announcements: ${snapshot.error}');
                            return Center(
                              child: Text(
                                'Error loading announcements: ${snapshot.error}',
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.errorColor),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: AppSpacing.cardPadding,
                                child: Text(
                                  'No announcements created yet.',
                                  style: AppTextStyles.bodyText.copyWith(color: AppColors.lightTextColor),
                                ),
                              ),
                            );
                          }

                          final hostAnnouncements = snapshot.data!.where((announcement) {
                            return announcement.hostId == _currentUser?.uid;
                          }).toList();

                          if (hostAnnouncements.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: AppSpacing.cardPadding,
                                child: Text(
                                  'You have not created any announcements yet.',
                                  style: AppTextStyles.bodyText.copyWith(color: AppColors.lightTextColor),
                                ),
                              ),
                            );
                          }

                          final Set<String> allGuestUids = {};
                          for (var announcement in hostAnnouncements) {
                            allGuestUids.addAll(announcement.guestResponses.keys);
                          }

                          return FutureBuilder<Map<String, UserModel>>(
                            future: _firebaseService.getUsersMapByUids(allGuestUids.toList()),
                            builder: (context, usersSnapshot) {
                              if (usersSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(color: AppColors.primaryColor),
                                );
                              }
                              if (usersSnapshot.hasError) {
                                print('Error fetching guest user details: ${usersSnapshot.error}');
                                return Center(
                                  child: Text(
                                    'Error loading guest details: ${usersSnapshot.error}',
                                    style: AppTextStyles.bodyText.copyWith(color: AppColors.errorColor),
                                  ),
                                );
                              }

                              final Map<String, UserModel> guestUsersMap = usersSnapshot.data ?? {};

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: hostAnnouncements.length,
                                itemBuilder: (context, index) {
                                  final announcement = hostAnnouncements[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Padding(
                                      padding: AppSpacing.cardPadding,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            announcement.heading,
                                            style: AppTextStyles.heading2.copyWith(color: AppColors.primaryColor),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            announcement.message,
                                            style: AppTextStyles.bodyText,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Event Date: ${DateFormat('EEE, MMM d, yyyy').format(announcement.eventDate)}',
                                            style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic),
                                          ),
                                          Text(
                                            'Created: ${DateFormat('MMM d, yyyy HH:mm').format(announcement.createdAt)}',
                                            style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Guest Responses:',
                                            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          if (announcement.guestResponses.isEmpty)
                                            Text(
                                              'No responses yet.',
                                              style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic),
                                            )
                                          else
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: announcement.guestResponses.entries.map((entry) {
                                                final guestUid = entry.key;
                                                final response = entry.value;
                                                final guestName = guestUsersMap[guestUid]?.displayName ?? 'Unknown User';

                                                return Padding(
                                                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                                  child: Text(
                                                    '• $guestName: ${response.capitalize()}', // Capitalize response for display
                                                    style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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

// Extension to capitalize first letter for display in dropdown and responses
extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
