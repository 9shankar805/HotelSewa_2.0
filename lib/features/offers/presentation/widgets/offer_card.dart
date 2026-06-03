import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/offer_model.dart';
import '../../../../core/constants/app_colors.dart';

class OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback onViewAnalytics;

  const OfferCard({
    super.key,
    required this.offer,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onViewAnalytics,
  });

  Color _statusColor() {
    switch (offer.statusColor) {
      case 'green': return AppColors.success;
      case 'red': return AppColors.error;
      case 'blue': return AppColors.info;
      case 'orange': return AppColors.warning;
      default: return AppColors.gray;
    }
  }

  IconData _statusIcon() {
    switch (offer.statusColor) {
      case 'green': return Icons.check_circle;
      case 'red': return Icons.cancel;
      case 'blue': return Icons.schedule;
      case 'orange': return Icons.block;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(_statusIcon(), size: 16, color: color),
                        const SizedBox(width: 4),
                        Text(offer.statusText,
                            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                  child: Text(offer.discountText,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.description,
                    style: TextStyle(fontSize: 14, color: AppColors.gray[700], height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                _row(Icons.calendar_today,
                    'Valid: ${DateFormat('MMM dd, yyyy').format(offer.validFrom)} - ${DateFormat('MMM dd, yyyy').format(offer.validTo)}'),
                const SizedBox(height: 8),
                _row(Icons.night_shelter,
                    'Min stay: ${offer.minStay} ${offer.minStay == 1 ? 'night' : 'nights'}'),
                if (offer.maxUsage != null) ...[
                  const SizedBox(height: 8),
                  _row(Icons.confirmation_number, 'Usage: ${offer.currentUsage}/${offer.maxUsage}'),
                ],
                if (offer.applicableRoomTypes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _row(Icons.meeting_room, 'Rooms: ${offer.applicableRoomTypes.join(', ')}'),
                ],
              ],
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(children: [
                    Icon(offer.isActive ? Icons.toggle_on : Icons.toggle_off,
                        color: offer.isActive ? AppColors.success : AppColors.gray, size: 28),
                    const SizedBox(width: 8),
                    Text(offer.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                            color: offer.isActive ? AppColors.success : AppColors.gray,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
                IconButton(onPressed: onViewAnalytics, icon: const Icon(Icons.analytics_outlined), color: AppColors.info),
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), color: AppColors.warning),
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline), color: AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.gray[600]))),
      ],
    );
  }
}
