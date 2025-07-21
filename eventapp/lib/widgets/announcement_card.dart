import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart'; // Import animate_do
import '../models/announcement_model.dart';
import '../utils/constants.dart'; // For AppColors, AppTextStyles, AppSpacing

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final String? currentGuestResponse; // 'available', 'not_available', or null
  final Function(Announcement, String) onRespond;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.currentGuestResponse,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the current user has already responded
    final bool hasResponded = currentGuestResponse != null && currentGuestResponse!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0), // Slightly more margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius * 1.5), // More rounded
      ),
      elevation: 10, // Increased elevation for a floating effect
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!], // Subtle gradient background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius * 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.15), // Soft shadow
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: AppSpacing.cardPadding * 1.2, // Slightly more padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement.heading,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 20, // Slightly larger heading
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                announcement.message,
                style: AppTextStyles.bodyText.copyWith(color: Colors.grey[700], fontSize: 15),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: AppColors.lightTextColor),
                  const SizedBox(width: 8),
                  Text(
                    'Event Date: ${DateFormat('EEE, MMM d, yyyy').format(announcement.eventDate)}',
                    style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: AppColors.lightTextColor),
                  const SizedBox(width: 8),
                  Text(
                    'Host: ${announcement.hostName ?? 'Unknown'}',
                    style: AppTextStyles.bodyText.copyWith(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // --- Response Section ---
              Text(
                'Your Response:',
                style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryColor),
              ),
              const SizedBox(height: 8),
              if (hasResponded)
                Text(
                  'You marked yourself as: ${currentGuestResponse!.capitalize()}',
                  style: AppTextStyles.bodyText.copyWith(
                    color: currentGuestResponse == 'available' ? AppColors.successColor : AppColors.errorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                )
              else
                Text(
                  'You have not responded yet.',
                  style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[500], fontSize: 14),
                ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onRespond(announcement, 'available'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentGuestResponse == 'available'
                            ? AppColors.successColor // Highlight if already available
                            : AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12), // Larger padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius * 1.2), // More rounded buttons
                        ),
                        elevation: 5, // Button shadow
                        shadowColor: AppColors.primaryColor.withOpacity(0.3),
                      ),
                      child: Text('Available', style: AppTextStyles.buttonText),
                    ),
                  ),
                  const SizedBox(width: 15), // Increased spacing
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onRespond(announcement, 'not_available'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentGuestResponse == 'not_available'
                            ? AppColors.errorColor // Highlight if already not available
                            : AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius * 1.2),
                        ),
                        elevation: 5,
                        shadowColor: AppColors.primaryColor.withOpacity(0.3),
                      ),
                      child: Text('Not Available', style: AppTextStyles.buttonText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize first letter for display
extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
