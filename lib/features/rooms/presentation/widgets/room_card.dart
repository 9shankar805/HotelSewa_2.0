import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/room_model.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  final Function(String) onStatusChange;

  const RoomCard({Key? key, required this.room, required this.onTap, required this.onStatusChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);
    final statusColor = _statusColor(room.status);
    final statusIcon = _statusIcon(room.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    _statusLabel(room.status),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Room ${room.roomNumber}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(room.type, style: const TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people_outline, size: 12, color: const Color(AppConstants.mediumGray)),
                const SizedBox(width: 4),
                Text('${room.capacity}', style: const TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                const SizedBox(width: 10),
                Icon(Icons.currency_rupee, size: 12, color: const Color(AppConstants.mediumGray)),
                Expanded(child: Text('${(room.pricePerNight / 1000).toStringAsFixed(1)}K/night', style: const TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray)), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 10),
            _buildActionButton(context, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Color statusColor) {
    String label;
    String nextStatus;
    Color btnColor;

    switch (room.status.toLowerCase()) {
      case 'available':
        label = 'Set Maintenance';
        nextStatus = 'maintenance';
        btnColor = const Color(AppConstants.warningOrange);
        break;
      case 'maintenance':
        label = 'Mark Available';
        nextStatus = 'available';
        btnColor = const Color(AppConstants.successGreen);
        break;
      case 'occupied':
        label = 'Check-out';
        nextStatus = 'cleaning';
        btnColor = const Color(AppConstants.primaryRed);
        break;
      case 'cleaning':
        label = 'Mark Clean';
        nextStatus = 'available';
        btnColor = const Color(AppConstants.successGreen);
        break;
      default:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => onStatusChange(nextStatus),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: btnColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: btnColor.withOpacity(0.3))),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: btnColor)),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available': return 'Available';
      case 'occupied': return 'Occupied';
      case 'maintenance': return 'Maintenance';
      case 'cleaning': return 'Cleaning';
      default: return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available': return Icons.check_circle_outline_rounded;
      case 'occupied': return Icons.person_rounded;
      case 'maintenance': return Icons.build_outlined;
      case 'cleaning': return Icons.cleaning_services_outlined;
      default: return Icons.bed_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available': return const Color(AppConstants.successGreen);
      case 'occupied': return const Color(AppConstants.primaryRed);
      case 'maintenance': return const Color(AppConstants.warningOrange);
      case 'cleaning': return const Color(0xFF1890FF);
      default: return const Color(AppConstants.mediumGray);
    }
  }
}
