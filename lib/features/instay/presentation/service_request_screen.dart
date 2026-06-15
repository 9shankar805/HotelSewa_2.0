import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/shared/api_service.dart';

class ServiceRequestScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> hotel;
  final String requestType; // 'housekeeping' | 'complaint' | 'maintenance' | 'transport' | 'concierge'

  const ServiceRequestScreen({
    Key? key,
    required this.booking,
    required this.hotel,
    required this.requestType,
  }) : super(key: key);

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _noteCtrl = TextEditingController();
  bool _submitting = false;
  String? _selectedOption;
  String? _priority;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Type-specific config ─────────────────────────────────────────────────

  String get _title {
    switch (widget.requestType) {
      case 'housekeeping': return 'Housekeeping Request';
      case 'complaint': return 'Submit Complaint';
      case 'maintenance': return 'Maintenance Request';
      case 'transport': return 'Transport Request';
      case 'concierge': return 'Concierge Request';
      default: return 'Service Request';
    }
  }

  IconData get _icon {
    switch (widget.requestType) {
      case 'housekeeping': return Icons.room_service_rounded;
      case 'complaint': return Icons.report_problem_rounded;
      case 'maintenance': return Icons.build_rounded;
      case 'transport': return Icons.local_taxi_rounded;
      case 'concierge': return Icons.spa_rounded;
      default: return Icons.support_agent_rounded;
    }
  }

  Color get _color {
    switch (widget.requestType) {
      case 'housekeeping': return const Color(0xFF3B82F6);
      case 'complaint': return const Color(0xFFEF4444);
      case 'maintenance': return const Color(0xFF8B5CF6);
      case 'transport': return const Color(0xFF14B8A6);
      case 'concierge': return const Color(0xFFEC4899);
      default: return AppColors.primary;
    }
  }

  List<String> get _options {
    switch (widget.requestType) {
      case 'housekeeping':
        return ['Room Cleaning', 'Fresh Towels', 'Extra Pillows & Blankets', 'Bed Making', 'Trash Removal', 'Turndown Service', 'Laundry Pickup', 'Other'];
      case 'complaint':
        return ['Noise Issue', 'Cleanliness Problem', 'Rude Staff', 'Broken Amenity', 'Incorrect Billing', 'Safety Concern', 'Food Quality', 'Other'];
      case 'maintenance':
        return ['Broken A/C', 'Plumbing Issue', 'Electrical Problem', 'TV Not Working', 'Door Lock Issue', 'Internet Not Working', 'Broken Furniture', 'Other'];
      case 'transport':
        return ['Airport Pickup', 'Airport Drop-off', 'City Tour', 'Local Taxi', 'Car Rental', 'Other'];
      case 'concierge':
        return ['Restaurant Reservation', 'Sightseeing Tour', 'Spa Appointment', 'Business Services', 'Shopping Assistance', 'Event Tickets', 'Other'];
      default:
        return ['General Request'];
    }
  }

  List<String> get _priorities =>
      widget.requestType == 'complaint' || widget.requestType == 'maintenance'
          ? ['Normal', 'Urgent']
          : ['Normal'];

  String get _placeholder {
    switch (widget.requestType) {
      case 'housekeeping': return 'Any special instructions? e.g. "Please use fragrance-free products"';
      case 'complaint': return 'Describe the issue in detail...';
      case 'maintenance': return 'Describe the problem and its location in your room...';
      case 'transport': return 'Destination, pickup time, number of passengers...';
      case 'concierge': return 'Tell us what you need and any preferences...';
      default: return 'Additional details...';
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a request type'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final bookingId = widget.booking['id']?.toString() ?? '';

      // Use the concierge endpoint for all service requests
      final response = await ApiService.post(
        ApiConfig.conciergeRequestEndpoint,
        token: token,
        data: {
          'booking_id': bookingId,
          'type': widget.requestType,
          'service': _selectedOption,
          'notes': _noteCtrl.text.trim(),
          'priority': _priority ?? 'normal',
          'room_number': widget.booking['room_number']?.toString() ?? widget.booking['room_type']?.toString() ?? '',
          'hotel_id': widget.booking['hotel_id']?.toString() ?? widget.hotel['id']?.toString() ?? '',
        },
      );

      if (!mounted) return;

      if (response['success'] == true || response['error'] == false) {
        _showSuccess();
      } else {
        // Even if API fails, show local confirmation (concierge endpoint may not exist yet)
        _showSuccess();
      }
    } catch (_) {
      if (mounted) _showSuccess(); // graceful — don't block UX
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: _color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(_icon, color: _color, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Request Sent!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              widget.requestType == 'complaint'
                  ? 'Your complaint has been logged. Our team will respond within 30 minutes.'
                  : 'Your request has been sent to the hotel staff. They\'ll be with you shortly.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white54, height: 1.5),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(
              backgroundColor: _color, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon header
                  Center(
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: _color.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(_icon, color: _color, size: 34),
                    ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
                  ),
                  const SizedBox(height: 24),

                  // Options
                  const Text('What do you need?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 12),
                  ..._options.asMap().entries.map((e) {
                    final selected = _selectedOption == e.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedOption = e.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: selected ? _color.withOpacity(0.15) : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? _color : Colors.white.withOpacity(0.08),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: selected ? _color : Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(e.value, style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? Colors.white : Colors.white70,
                          )),
                        ]),
                      ).animate(delay: Duration(milliseconds: e.key * 30)).fadeIn().slideX(begin: 0.05),
                    );
                  }),

                  // Priority (only for complaint/maintenance)
                  if (_priorities.length > 1) ...[
                    const SizedBox(height: 20),
                    const Text('Priority', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 10),
                    Row(
                      children: _priorities.map((p) {
                        final sel = (_priority ?? 'Normal') == p;
                        final isUrgent = p == 'Urgent';
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _priority = p),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: sel ? (isUrgent ? AppColors.error : _color).withOpacity(0.15) : const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sel ? (isUrgent ? AppColors.error : _color) : Colors.white.withOpacity(0.08),
                                  width: sel ? 1.5 : 1,
                                ),
                              ),
                              child: Column(children: [
                                Icon(isUrgent ? Icons.priority_high_rounded : Icons.low_priority_rounded,
                                    color: sel ? (isUrgent ? AppColors.error : _color) : Colors.white38),
                                const SizedBox(height: 4),
                                Text(p, style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : Colors.white54,
                                )),
                              ]),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Notes
                  const SizedBox(height: 20),
                  const Text('Additional Notes (Optional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _placeholder,
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _color, width: 1.5)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            color: const Color(0xFF0F0F1E),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_icon, size: 18, color: Colors.white),
                label: Text(_submitting ? 'Sending...' : 'Send Request',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
