import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class QuickActionsCard extends StatelessWidget {
  final VoidCallback onManageRooms;
  final VoidCallback onManageBookings;
  final VoidCallback onViewEarnings;
  final VoidCallback onManageGallery;

  const QuickActionsCard({
    Key? key,
    required this.onManageRooms,
    required this.onManageBookings,
    required this.onViewEarnings,
    required this.onManageGallery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildActionItem(
                  context,
                  'Manage Rooms',
                  Icons.hotel_outlined,
                  AppConstants.primaryRed,
                  onManageRooms,
                ),
                _buildActionItem(
                  context,
                  'Bookings',
                  Icons.book_online_outlined,
                  AppConstants.successGreen,
                  onManageBookings,
                ),
                _buildActionItem(
                  context,
                  'Earnings',
                  Icons.attach_money_outlined,
                  AppConstants.warningOrange,
                  onViewEarnings,
                ),
                _buildActionItem(
                  context,
                  'Gallery',
                  Icons.photo_library_outlined,
                  AppConstants.primaryRed,
                  onManageGallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    IconData icon,
    int color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: Color(color).withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: Color(color),
                size: 24,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
