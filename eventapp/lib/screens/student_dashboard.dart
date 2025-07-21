import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:animate_do/animate_do.dart'; // For animations
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
    setState(() => _isLoading = true);
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
      if (mounted) setState(() => _isLoading = false);
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
      if (newName.isEmpty) throw 'Name cannot be empty.';
      await _firebaseService.updateUserName(_currentUser!.uid, newName);
      _currentUser = _currentUser!.copyWith(displayName: newName);
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile name updated successfully!', style: AppTextStyles.bodyText.copyWith(color: Colors.white)),
              backgroundColor: AppColors.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(12),
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
          content: Text('Error: User not logged in.', style: AppTextStyles.bodyText.copyWith(color: Colors.white)),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }
    try {
      await _firebaseService.updateGuestResponse(announcement.id, _currentUser!.uid, response);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your response "$response" recorded!', style: AppTextStyles.bodyText.copyWith(color: Colors.white)),
            backgroundColor: AppColors.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record response: $e', style: AppTextStyles.bodyText.copyWith(color: Colors.white)),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: FadeInDown(
          child: Text(
            'Student Dashboard',
            style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          // Profile Icon and Welcome Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(Icons.account_circle, size: 28, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Welcome, ${_currentUser?.displayName?.split(' ').first ?? 'Student'}!', // Display first name
                  style: AppTextStyles.bodyText.copyWith(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          // Logout Button
          ZoomIn(
            child: TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () async => await _firebaseService.signOut(),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor.withOpacity(0.05), AppColors.backgroundColor], // Lighter gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.borderRadius),
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodyText.copyWith(color: AppColors.errorColor, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInLeft(child: _buildProfileCard()),
                        const SizedBox(height: 30),
                        FadeInRight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Announcements',
                                style: AppTextStyles.heading2.copyWith(color: AppColors.primaryColor, fontSize: 22),
                              ),
                              const SizedBox(height: 15),
                              _buildAnnouncementsList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // --- Profile Card Widget ---
  Widget _buildProfileCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: AppSpacing.cardPadding * 1.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ZoomIn(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryColor,
                      child: Icon(Icons.account_circle, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${_currentUser?.displayName?.split(' ').first ?? 'Student'}!',
                          style: AppTextStyles.heading2.copyWith(color: AppColors.primaryColor, fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Email: ${_currentUser?.email ?? 'N/A'}',
                          style: AppTextStyles.bodyText.copyWith(color: Colors.grey[800], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Update Display Name',
                style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryColor),
              ),
              const SizedBox(height: 10),
              FadeIn(
                child: TextFormField(
                  controller: _profileNameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'e.g., John Doe',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                    ),
                    labelStyle: AppTextStyles.bodyText.copyWith(color: AppColors.primaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Name cannot be empty';
                    return null;
                  },
                  style: AppTextStyles.bodyText.copyWith(color: Colors.grey[800]),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: ZoomIn(
                  child: ElevatedButton.icon(
                    icon: _isUpdatingProfile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _isUpdatingProfile ? 'Saving...' : 'Save Profile',
                      style: AppTextStyles.bodyText.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _isUpdatingProfile ? null : _updateProfileName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      shadowColor: AppColors.primaryColor.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Announcements List Widget ---
  Widget _buildAnnouncementsList() {
    return StreamBuilder<List<Announcement>>(
      stream: _firebaseService.getAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading announcements: ${snapshot.error}',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.errorColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No announcements available yet.',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.lightTextColor, fontSize: 16),
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
            final String? guestResponse = _currentUser?.uid != null ? announcement.guestResponses[_currentUser!.uid] : null;
            return FadeInUp(
              delay: Duration(milliseconds: index * 100), // Staggered animation
              child: AnnouncementCard(
                announcement: announcement,
                currentGuestResponse: guestResponse,
                onRespond: _handleGuestResponse,
              ),
            );
          },
        );
      },
    );
  }
}

// Extension to capitalize first letter for display
extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
