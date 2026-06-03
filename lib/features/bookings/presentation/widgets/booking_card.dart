import 'package:flutter/material.dart';
import '../models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final Function(String)? onStatusChange;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onStatusChange,
  });

  Color _statusColor() {
    switch (booking.status.toLowerCase()) {
      case 'confirmed': return const Color(0xFF10B981);
      case 'checked_in': return const Color(0xFF3B82F6);
      case 'checked_out': return const Color(0xFF6B7280);
      case 'cancelled': return const Color(0xFFEF4444);
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.guestName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Room: ${booking.roomNumber}', style: const TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              Text(
                'Check-in: ${booking.checkIn.toString().substring(0, 10)}  •  Check-out: ${booking.checkOut.toString().substring(0, 10)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NPR ${booking.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFE60023)),
                  ),
                  if (onStatusChange != null)
                    PopupMenuButton<String>(
                      onSelected: onStatusChange,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'confirmed', child: Text('Confirm')),
                        PopupMenuItem(value: 'checked_in', child: Text('Check In')),
                        PopupMenuItem(value: 'checked_out', child: Text('Check Out')),
                        PopupMenuItem(value: 'cancelled', child: Text('Cancel')),
                      ],
                      child: const Icon(Icons.more_vert_rounded, color: Color(0xFF6B7280)),
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
