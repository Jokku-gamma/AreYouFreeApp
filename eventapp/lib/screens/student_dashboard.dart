import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/announcement_model.dart';
import '../models/usermodel.dart';
import '../utils/constants.dart'; // For AppColors, AppTextStyles
import '../widgets/announcement_card.dart'; // Reusable widget

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUpdatingProfile = false;
  final TextEditingController _profileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _profileNameController.dispose();
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
        _profileNameController.text = _currentUser!.displayName;
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

  void _handleGuestResponse(Announcement announcement, String response) async {
    if (!mounted) return;

    if (_currentUser?.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error: User not logged in.'),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }

    try {
      await _firebaseService.updateGuestResponse(
        announcement.id,
        _currentUser!.uid,
        response,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your response "$response" recorded!'),
            backgroundColor: AppColors.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record response: $e'),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
                                    'Welcome, ${_currentUser?.displayName ?? 'Student'}!',
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

                      // --- Announcements Section ---
                      Text(
                        'Announcements',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<List<Announcement>>(
                        stream: _firebaseService.getAnnouncements(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading announcements: ${snapshot.error}',
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.errorColor),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                'No announcements available yet.',
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.lightTextColor),
                              ),
                            );
                          }

                          final announcements = snapshot.data!;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: announcements.length,
                            itemBuilder: (context, index) {
                              final announcement = announcements[index];
                              final String? guestResponse = _currentUser?.uid != null
                                  ? announcement.guestResponses[_currentUser!.uid]
                                  : null;

                              return AnnouncementCard(
                                announcement: announcement,
                                currentGuestResponse: guestResponse,
                                onRespond: _handleGuestResponse,
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
