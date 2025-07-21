import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:animate_do/animate_do.dart'; // For animations
import '../services/firebase_service.dart';
import '../models/announcement_model.dart';
import '../models/usermodel.dart';
import '../utils/constants.dart'; // For AppColors, AppTextStyles, UserRole
import '../widgets/announcement_card.dart'; // Reusable widget

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
  UserRole _selectedUserRole = UserRole.student; // Default role

  final TextEditingController _profileNameController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAddingUser = false;
  bool _isUpdatingProfile = false;

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _createAnnouncement() async {
    if (_announcementFormKey.currentState!.validate()) {
      if (_selectedDate == null) {
        if (mounted) setState(() => _errorMessage = "Please select an event date.");
        return;
      }
      if (_currentUser == null) {
        if (mounted) setState(() => _errorMessage = "User data not loaded.");
        return;
      }

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
                content: Text('Announcement created successfully!', style: AppTextStyles.bodyText.copyWith(color: Colors.white)),
                backgroundColor: AppColors.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(12),
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
                content: Text('User "$email" added/updated with role: ${StringCasingExtension(role.name).capitalize()}!', style: AppTextStyles.bodyText.copyWith(color: Colors.white)),
                backgroundColor: AppColors.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor.withOpacity(0.9), AppColors.backgroundColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: FadeInDown(
                  child: Text(
                    'Host Dashboard',
                    style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: FadeInUp(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.account_circle, size: 50, color: AppColors.primaryColor),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Welcome, ${_currentUser?.displayName?.split(' ').first ?? 'Host'}!',
                            style: AppTextStyles.bodyText.copyWith(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Logout', style: TextStyle(color: Colors.white)),
                  onPressed: () async => await _firebaseService.signOut(),
                ),
                const SizedBox(width: 10),
              ],
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.borderRadius),
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.bodyText.copyWith(color: AppColors.errorColor, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Padding(
                          padding: AppSpacing.screenPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Management
                              FadeInLeft(
                                child: _buildSectionCard(
                                  title: 'Your Profile',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Email: ${_currentUser?.email ?? 'N/A'}',
                                        style: AppTextStyles.bodyText.copyWith(color: Colors.grey[800]),
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        'Update Display Name:',
                                        style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                                      ),
                                      const SizedBox(height: 10),
_buildTextField(
  controller: _profileNameController,
  label: 'Display Name',
  hint: 'e.g., Joel Joseph',
),
                                      const SizedBox(height: 15),
                                      Center(
                                        child: _buildAnimatedButton(
                                          label: _isUpdatingProfile ? 'Saving...' : 'Save Profile',
                                          icon: _isUpdatingProfile ? null : Icons.save,
                                          onPressed: _isUpdatingProfile ? null : _updateProfileName,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Create Announcement
                              FadeInRight(
                                child: _buildSectionCard(
                                  title: 'Create New Announcement',
                                  child: Form(
                                    key: _announcementFormKey,
                                    child: Column(
                                      children: [
                                        _buildTextField(
                                          controller: _headingController,
                                          label: 'Heading',
                                          hint: 'Enter announcement heading',
                                        ),
                                        const SizedBox(height: 15),
                                        _buildTextField(
                                          controller: _messageController,
                                          label: 'Message',
                                          hint: 'Enter detailed message',
                                          maxLines: 5,
                                        ),
                                        const SizedBox(height: 15),
                                        _buildDatePicker(),
                                        const SizedBox(height: 20),
                                        _buildAnimatedButton(
                                          label: _isLoading ? 'Creating...' : 'Create Announcement',
                                          icon: _isLoading ? null : Icons.add,
                                          onPressed: _isLoading ? null : _createAnnouncement,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Manage User Roles
                              FadeInLeft(
                                child: _buildSectionCard(
                                  title: 'Manage User Roles',
                                  child: Form(
                                    key: _userFormKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildTextField(
                                          controller: _userEmailController,
                                          label: 'User Email',
                                          hint: 'Enter email of the graduate',
                                          keyboardType: TextInputType.emailAddress,
                                        ),
                                        const SizedBox(height: 15),
                                        _buildDropdown(),
                                        const SizedBox(height: 20),
                                        _buildAnimatedButton(
                                          label: _isAddingUser ? 'Adding...' : 'Add/Update User Role',
                                          icon: _isAddingUser ? null : Icons.person_add,
                                          onPressed: _isAddingUser ? null : _addGraduateUser,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Announcements
                              FadeInUp(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Announcements',
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
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
        ),
        child: Padding(
          padding: AppSpacing.cardPadding * 1.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 20, thickness: 2, color: AppColors.primaryColor),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return FadeIn(
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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
          if (value == null || value.isEmpty) {
            return 'Please enter $label.toLowerCase()';
          }
          if (label == 'User Email' && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          return null;
        },
        style: AppTextStyles.bodyText.copyWith(color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildDatePicker() {
    return FadeIn(
      child: GestureDetector(
        onTap: () => _selectDate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                _selectedDate == null
                    ? 'Select Event Date'
                    : 'Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)}',
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return FadeIn(
      child: DropdownButtonFormField<UserRole>(
        value: _selectedUserRole,
        decoration: InputDecoration(
          labelText: 'Assign Role',
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
        ),
        items: UserRole.values
            .where((role) => role != UserRole.host && role != UserRole.unknown)
            .map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(

                    StringCasingExtension(role.name).capitalize(),
                    style: AppTextStyles.bodyText.copyWith(color: Colors.grey[800]),
                  ),
                ))
            .toList(),
        onChanged: (UserRole? newValue) {
          if (newValue != null) setState(() => _selectedUserRole = newValue);
        },
      ),
    );
  }

  Widget _buildAnimatedButton({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
  }) {
    return ZoomIn(
      child: ElevatedButton.icon(
        icon: icon != null
            ? Icon(icon, size: 20, color: Colors.white)
            : const SizedBox.shrink(),
        label: Text(
          label,
          style: AppTextStyles.bodyText.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          shadowColor: AppColors.primaryColor.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return StreamBuilder<List<Announcement>>(
      stream: _firebaseService.getAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
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

        final hostAnnouncements = snapshot.data!.where((announcement) => announcement.hostId == _currentUser?.uid).toList();

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
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
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
                return FadeInUp(
                  delay: Duration(milliseconds: index * 100),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey[50]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: AppSpacing.cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement.heading,
                              style: AppTextStyles.heading2.copyWith(
                                color: AppColors.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              announcement.message,
                              style: AppTextStyles.bodyText.copyWith(color: Colors.grey[800]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Event Date: ${DateFormat('EEE, MMM d, yyyy').format(announcement.eventDate)}',
                              style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[600]),
                            ),
                            Text(
                              'Created: ${DateFormat('MMM d, yyyy HH:mm').format(announcement.createdAt)}',
                              style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Guest Responses:',
                              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                            ),
                            if (announcement.guestResponses.isEmpty)
                              Text(
                                'No responses yet.',
                                style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[600]),
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
                                      '• $guestName: ${StringCasingExtension(response).capitalize()}',
                                      style: AppTextStyles.bodyText.copyWith(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}