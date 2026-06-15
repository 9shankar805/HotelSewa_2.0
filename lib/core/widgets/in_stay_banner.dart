import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/active_stay_service.dart';
import '../../features/instay/presentation/in_stay_dashboard_screen.dart';

/// A persistent banner shown on the home screen when the user has an active checked-in stay.
/// Tapping it opens the InStayDashboardScreen.
class InStayBanner extends StatelessWidget {
  const InStayBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveStayService>(
      builder: (context, service, _) {
        if (!service.hasActiveStay) return const SizedBox.shrink();

        final booking = service.activeBooking!;
        final hotelName = booking['hotel_name']?.toString()
            ?? booking['hotel']?['name']?.toString()
            ?? 'Your Hotel';
        final room = booking['room_number']?.toString()
            ?? booking['room_type']?.toString() ?? '';
        final checkOut = (booking['check_out']?.toString()
            ?? booking['check_out_date']?.toString() ?? '').split('T')[0];

        int nightsLeft = 0;
        try {
          if (checkOut.isNotEmpty) {
            nightsLeft = DateTime.parse(checkOut).difference(DateTime.now()).inDays.clamp(0, 99);
          }
        } catch (_) {}

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InStayDashboardScreen(booking: booking),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F0F1E), Color(0xFF1A1A3E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(color: AppColors.success.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                // Pulsing indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat())
                      .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1200.ms)
                      .fadeOut(duration: 1200.ms),
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hotel_rounded, color: AppColors.success, size: 22),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('CHECKED IN', style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: 0.5,
                            )),
                          ),
                          const SizedBox(width: 8),
                          if (nightsLeft > 0)
                            Text('$nightsLeft night${nightsLeft != 1 ? 's' : ''} left',
                                style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hotelName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      if (room.isNotEmpty)
                        Text(room, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // CTA
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.room_service_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text('Services', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2),
        );
      },
    );
  }
}
