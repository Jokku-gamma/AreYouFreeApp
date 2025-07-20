import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      elevation: 5,
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
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppColors.lightTextColor),
                const SizedBox(width: 5),
                Text(
                  'Event Date: ${DateFormat('EEE, MMM d, yyyy').format(announcement.eventDate)}',
                  style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.person, size: 18, color: AppColors.lightTextColor),
                const SizedBox(width: 5),
                Text(
                  'Host: ${announcement.hostName ?? 'Unknown'}',
                  style: AppTextStyles.bodyText.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // --- Response Section ---
            Text(
              'Your Response:',
              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (hasResponded)
              Text(
                'You marked yourself as: ${currentGuestResponse!.capitalize()}',
                style: AppTextStyles.bodyText.copyWith(
                  color: currentGuestResponse == 'available' ? AppColors.successColor : AppColors.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                'You have not responded yet.',
                style: AppTextStyles.bodyText.copyWith(fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 10),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                    child: const Text('Available'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onRespond(announcement, 'not_available'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentGuestResponse == 'not_available'
                          ? AppColors.errorColor // Highlight if already not available
                          : AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                    child: const Text('Not Available'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize first letter for display
extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
