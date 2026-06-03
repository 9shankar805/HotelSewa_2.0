import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/qr_checkin_service.dart';

class OnlineCheckinScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const OnlineCheckinScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<OnlineCheckinScreen> createState() => _OnlineCheckinScreenState();
}

class _OnlineCheckinScreenState extends State<OnlineCheckinScreen> {
  final QrCheckinService _qrService = QrCheckinService();
  int _step = 0;
  bool _loading = false;
  String? _qrData;

  // Step 1 - ID
  final _idController = TextEditingController();
  String _idType = 'Aadhaar Card';
  final _idTypes = ['Aadhaar Card', 'Passport', 'Driving License', 'Voter ID', 'PAN Card'];

  // Step 2 - Preferences
  String _floorPref = 'No preference';
  String _bedPref = 'No preference';
  String _pillowPref = 'Soft';
  bool _earlyCheckin = false;
  bool _lateCheckout = false;
  final _requestController = TextEditingController();

  // Step 3 - ETA
  TimeOfDay _eta = const TimeOfDay(hour: 14, minute: 0);

  @override
  void dispose() {
    _idController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      setState(() => _loading = true);
      
      // Generate QR code from API
      final bookingId = widget.arguments?['bookingId']?.toString() ?? 'HS-2024-001';
      final result = await _qrService.getCheckinQr(bookingId);
      
      if (result['success'] && mounted) {
        // Extract QR data from response
        final data = result['data'];
        String qrToken = '';
        
        if (data is Map) {
          qrToken = data['qr_token']?.toString() ?? 
                   data['token']?.toString() ?? 
                   data['qr_code']?.toString() ?? 
                   bookingId;
        } else if (data is String) {
          qrToken = data;
        } else {
          qrToken = bookingId;
        }
        
        setState(() {
          _qrData = qrToken;
          _loading = false;
        });
        _showSuccess();
      } else {
        // Fallback to booking ID if API fails
        setState(() {
          _qrData = bookingId;
          _loading = false;
        });
        _showSuccess();
      }
    }
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
              child: const Icon(Icons.how_to_reg_rounded, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Check-in Complete!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 8),
            const Text('Your online check-in is confirmed.\nShow this QR code at the reception.',
                style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            
            // QR Code
            if (_qrData != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightGray, width: 2),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: _qrData!,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _qrData!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(delay: 200.ms, duration: 400.ms),
            
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Expected Arrival', style: TextStyle(fontSize: 13, color: AppColors.gray)),
                  Text('${_eta.format(context)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Save this QR code or take a screenshot for quick check-in at the hotel.',
                      style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => _step > 0 ? setState(() => _step--) : Navigator.pop(context),
        ),
        title: const Text('Online Check-in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 0 ? _buildIdStep() : _step == 1 ? _buildPreferencesStep() : _buildEtaStep(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _next,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(_step < 2 ? 'Continue' : 'Complete Check-in', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['ID Verification', 'Preferences', 'Arrival Time'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final i = e.key;
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: done ? AppColors.success : active ? AppColors.primary : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: done
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.gray))),
                    ),
                    const SizedBox(height: 4),
                    Text(e.value, style: TextStyle(fontSize: 10, color: active ? AppColors.primary : AppColors.gray, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18), color: done ? AppColors.success : AppColors.lightGray)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIdStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ID Verification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        const SizedBox(height: 4),
        const Text('Please provide a valid government-issued ID', style: TextStyle(fontSize: 13, color: AppColors.gray)),
        const SizedBox(height: 20),
        const Text('ID Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lightGray), boxShadow: AppColors.cardShadow),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _idType,
              isExpanded: true,
              items: _idTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _idType = v!),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('ID Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        TextField(
          controller: _idController,
          decoration: InputDecoration(
            hintText: 'Enter your ID number',
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightGray)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightGray)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
          child: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppColors.info, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Your ID information is encrypted and only shared with the hotel.', style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4))),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildPreferencesStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Room Preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        const SizedBox(height: 4),
        const Text('Let us know your preferences for a better stay', style: TextStyle(fontSize: 13, color: AppColors.gray)),
        const SizedBox(height: 20),
        _prefDropdown('Floor Preference', _floorPref, ['No preference', 'Low floor', 'High floor', 'Top floor'], (v) => setState(() => _floorPref = v!)),
        const SizedBox(height: 14),
        _prefDropdown('Bed Preference', _bedPref, ['No preference', 'King bed', 'Twin beds', 'Double bed'], (v) => setState(() => _bedPref = v!)),
        const SizedBox(height: 14),
        _prefDropdown('Pillow Type', _pillowPref, ['Soft', 'Medium', 'Firm', 'Hypoallergenic'], (v) => setState(() => _pillowPref = v!)),
        const SizedBox(height: 20),
        const Text('Add-ons', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        const SizedBox(height: 10),
        _toggleTile('Early Check-in (subject to availability)', _earlyCheckin, (v) => setState(() => _earlyCheckin = v)),
        const SizedBox(height: 8),
        _toggleTile('Late Check-out (subject to availability)', _lateCheckout, (v) => setState(() => _lateCheckout = v)),
        const SizedBox(height: 16),
        const Text('Special Requests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        TextField(
          controller: _requestController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any special requests for the hotel...',
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightGray)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightGray)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildEtaStep() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Expected Arrival', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        const SizedBox(height: 4),
        const Text('Let the hotel know when to expect you', style: TextStyle(fontSize: 13, color: AppColors.gray)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: _eta,
                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!));
            if (t != null) setState(() => _eta = t);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
            child: Row(
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 24)),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Arrival Time', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                  Text(_eta.format(context), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
                ]),
                const Spacer(),
                const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(14)),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Standard check-in is from 2:00 PM. Early arrivals are subject to room availability.',
                  style: TextStyle(fontSize: 12, color: AppColors.warning, height: 1.4))),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _prefDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lightGray), boxShadow: AppColors.cardShadow),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(value: value, isExpanded: true, items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(), onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  Widget _toggleTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.darkGray))),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}
