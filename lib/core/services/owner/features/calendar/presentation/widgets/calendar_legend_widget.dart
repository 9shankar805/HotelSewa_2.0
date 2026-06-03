import 'package:flutter/material.dart';
import '../models/calendar_model.dart';
import '../../../../../../../core/constants/app_colors.dart';

class CalendarLegendWidget extends StatelessWidget {
  const CalendarLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildLegendItem(
            'Available',
            AppColors.success,
            Icons.check_circle,
            'Rooms available for booking',
          ),
          _buildLegendItem(
            'Limited',
            AppColors.warning,
            Icons.warning,
            'Limited availability (80%+ occupied)',
          ),
          _buildLegendItem(
            'Full',
            AppColors.error,
            Icons.close,
            'No rooms available',
          ),
          _buildLegendItem(
            'Blocked',
            AppColors.gray,
            Icons.block,
            'Date blocked for booking',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon, String description) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
          child: Icon(
            icon,
            size: 12,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gray[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
