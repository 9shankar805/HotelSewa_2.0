import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class PricingBreakdownScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  const PricingBreakdownScreen({Key? key, this.arguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = arguments ?? {};
    final roomRate = (args['roomRate'] ?? args['room_rate'] ?? args['price'] ?? 0) as num;
    final nights = (args['nights'] ?? 1) as num;
    final rooms = (args['rooms'] ?? 1) as num;
    final subtotal = roomRate * nights * rooms;
    final taxRate = (args['taxRate'] ?? 0.18) as num;
    final taxes = (subtotal * taxRate).round();
    final serviceFee = (args['serviceFee'] ?? 0) as num;
    final discount = (args['discount'] ?? 0) as num;
    final loyaltyDiscount = (args['loyaltyDiscount'] ?? 0) as num;
    final couponDiscount = (args['couponDiscount'] ?? 0) as num;
    final total = (args['total'] ?? args['totalAmount'] ?? (subtotal + taxes + serviceFee - discount - loyaltyDiscount - couponDiscount)) as num;
    final hotelName = args['hotelName'] ?? args['hotel_name'] ?? 'Hotel';
    final roomType = args['roomType'] ?? args['room_type'] ?? 'Room';
    final checkIn = args['checkIn'] ?? args['check_in'] ?? '';
    final checkOut = args['checkOut'] ?? args['check_out'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Price Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Hotel summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.hotel_rounded, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hotelName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(roomType, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
                if (checkIn.isNotEmpty && checkOut.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.gray),
                    const SizedBox(width: 4),
                    Text('$checkIn  →  $checkOut', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                  ]),
                ],
              ])),
            ]),
          ).animate().fadeIn(),

          const SizedBox(height: 16),

          // Breakdown card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Price Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),

              _row('NPR ${roomRate.toInt()} × $nights night${nights > 1 ? "s" : ""}${rooms > 1 ? " × $rooms rooms" : ""}',
                  'NPR ${subtotal.toInt()}'),
              if (serviceFee > 0) ...[const SizedBox(height: 10), _row('Service Fee', 'NPR ${serviceFee.toInt()}')],
              const SizedBox(height: 10),
              _row('Taxes & Fees (${(taxRate * 100).toInt()}%)', 'NPR $taxes'),

              if (discount > 0 || loyaltyDiscount > 0 || couponDiscount > 0) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(color: AppColors.lightGray, height: 1)),
                const Text('Discounts Applied', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                const SizedBox(height: 10),
                if (discount > 0) ...[
                  _row('Special Discount', '-NPR ${discount.toInt()}', valueColor: AppColors.success),
                  const SizedBox(height: 8),
                ],
                if (loyaltyDiscount > 0) ...[
                  _row('Loyalty Points', '-NPR ${loyaltyDiscount.toInt()}', valueColor: AppColors.success),
                  const SizedBox(height: 8),
                ],
                if (couponDiscount > 0)
                  _row('Coupon Discount', '-NPR ${couponDiscount.toInt()}', valueColor: AppColors.success),
              ],

              const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(color: AppColors.lightGray, height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
                  Text('NPR ${total.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
            ]),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          // What's included
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("What's Included", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 14),
              _included(Icons.bed_rounded, 'Room accommodation for $nights night${nights > 1 ? "s" : ""}'),
              _included(Icons.wifi_rounded, 'Complimentary WiFi'),
              _included(Icons.cleaning_services_rounded, 'Daily housekeeping'),
              _included(Icons.receipt_long_rounded, 'Tax invoice provided'),
              _included(Icons.support_agent_rounded, '24/7 customer support'),
            ]),
          ).animate().fadeIn(delay: 180.ms),

          const SizedBox(height: 16),

          // Cancellation note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.info.withOpacity(0.2))),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Prices are inclusive of all applicable taxes. Cancellation charges may apply as per hotel policy.',
                style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.5),
              )),
            ]),
          ).animate().fadeIn(delay: 240.ms),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.gray))),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.darkGray)),
    ],
  );

  Widget _included(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.success),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.darkGray))),
    ]),
  );
}
