import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/auth_service.dart';
import '../../../core/services/booking_service.dart';
import 'payment_screen.dart';

class HourlyBookingScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const HourlyBookingScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<HourlyBookingScreen> createState() => _HourlyBookingScreenState();
}

class _HourlyBookingScreenState extends State<HourlyBookingScreen> {
  final AuthService _authService = AuthService();
  final BookingService _bookingService = BookingService();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _specialCtrl = TextEditingController();

  Map<String, dynamic> _hotel = {};
  Map<String, dynamic> _room = {};
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  int _guests = 1;
  bool _loading = true;
  bool _previewLoading = false;
  Map<String, dynamic>? _pricePreview;

  @override
  void initState() {
    super.initState();
    _extractArguments();
    _loadProfile();
  }

  void _extractArguments() {
    if (widget.arguments != null) {
      _hotel = widget.arguments!['hotel'] ?? {};
      _room = widget.arguments!['room'] ?? {};
      _guests = widget.arguments!['guests'] ?? 1;
      if (widget.arguments!['date'] != null) {
        _date = DateTime.tryParse(widget.arguments!['date']) ?? _date;
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final userData = await _authService.getCachedUser();
    if (userData['name']?.isNotEmpty ?? false) {
      final parts = userData['name']!.split(' ');
      _firstNameCtrl.text = parts.first;
      if (parts.length > 1) _lastNameCtrl.text = parts.sublist(1).join(' ');
    }
    if (userData['email']?.isNotEmpty ?? false) _emailCtrl.text = userData['email']!;
    if (userData['phone']?.isNotEmpty ?? false) _phoneCtrl.text = userData['phone']!;
    setState(() => _loading = false);
    _fetchPricePreview();
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:00';
  }

  int get _totalHours {
    final startMins = _startTime.hour * 60 + _startTime.minute;
    final endMins = _endTime.hour * 60 + _endTime.minute;
    return endMins > startMins ? ((endMins - startMins) / 60).round() : 0;
  }

  int get _minHours => (_room['min_hours'] as num?)?.toInt() ?? 1;
  int get _maxHours => (_room['max_hours'] as num?)?.toInt() ?? 12;
  int get _hourlyPrice => (_room['hourly_price'] as num?)?.toInt() ?? 0;

  Future<void> _fetchPricePreview() async {
    if (_totalHours <= 0) return;
    setState(() => _previewLoading = true);
    try {
      final result = await _bookingService.previewPrice({
        'hotel_id': _hotel['id']?.toString() ?? '',
        'room_type_id': _room['id']?.toString() ?? '',
        'booking_type': 'hourly',
        'check_in_datetime': _formatDateTime(_date, _startTime),
        'check_out_datetime': _formatDateTime(_date, _endTime),
      });
      if (result['success'] == true) {
        setState(() => _pricePreview = result['data'] as Map<String, dynamic>?);
      }
    } catch (_) {}
    setState(() => _previewLoading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _fetchPricePreview();
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
      _fetchPricePreview();
    }
  }

  Future<void> _handleBooking() async {
    if (_firstNameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    if (_totalHours < _minHours || _totalHours > _maxHours) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duration must be between $_minHours and $_maxHours hours')),
      );
      return;
    }
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) Navigator.pushNamed(context, '/login');
      return;
    }
    final checkInDt = _formatDateTime(_date, _startTime);
    final checkOutDt = _formatDateTime(_date, _endTime);
    final totalPrice = _pricePreview != null
        ? (_pricePreview!['total_price'] as num?)?.toInt() ?? (_hourlyPrice * _totalHours)
        : _hourlyPrice * _totalHours;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          arguments: {
            'hotel': _hotel,
            'room': _room,
            'dates': {
              'checkIn': checkInDt,
              'checkOut': checkOutDt,
              'nights': 0,
              'hours': _totalHours,
              'isHourly': true,
            },
            'guests': _guests,
            'guestDetails': {
              'firstName': _firstNameCtrl.text,
              'lastName': _lastNameCtrl.text,
              'email': _emailCtrl.text,
              'phone': _phoneCtrl.text,
            },
            'specialRequests': _specialCtrl.text,
            'bookingType': 'hourly',
            'checkInDatetime': checkInDt,
            'checkOutDatetime': checkOutDt,
            'totalPrice': totalPrice,
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _specialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _pricePreview != null
        ? (_pricePreview!['total_price'] as num?)?.toInt() ?? (_hourlyPrice * _totalHours)
        : _hourlyPrice * _totalHours;
    final isValidDuration = _totalHours >= _minHours && _totalHours <= _maxHours;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hourly Booking',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: 8),
                        _buildDateTimeCard(),
                        const SizedBox(height: 8),
                        _buildGuestCard(),
                        const SizedBox(height: 8),
                        _buildSpecialRequestsCard(),
                        const SizedBox(height: 8),
                        _buildPriceCard(totalPrice, isValidDuration),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(totalPrice, isValidDuration),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hotel['name'] ?? 'Hotel',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _room['type'] ?? 'Room',
                  style: const TextStyle(fontSize: 14, color: AppColors.gray),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hourly  NPR $_hourlyPrice/hr  Min ${_minHours}h  Max ${_maxHours}h',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard() {
    final dateStr = '${_date.day}/${_date.month}/${_date.year}';
    final startStr = _startTime.format(context);
    final endStr = _endTime.format(context);
    final hours = _totalHours;
    final isValid = hours >= _minHours && hours <= _maxHours;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date & Time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDate,
            child: _buildPickerRow(Icons.calendar_today_rounded, 'Date', dateStr),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: _buildPickerRow(Icons.login_rounded, 'Check-in', startStr),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: _buildPickerRow(Icons.logout_rounded, 'Check-out', endStr),
                ),
              ),
            ],
          ),
          if (hours > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isValid
                    ? AppColors.success.withOpacity(0.08)
                    : AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isValid
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    color: isValid ? AppColors.success : AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isValid
                        ? '$hours hour${hours > 1 ? 's' : ''} selected'
                        : '$hours hours — must be between $_minHours and $_maxHours hours',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isValid ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickerRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.gray),
        ],
      ),
    );
  }

  Widget _buildGuestCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guest Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField('First Name *', _firstNameCtrl, 'John')),
              const SizedBox(width: 12),
              Expanded(child: _buildField('Last Name', _lastNameCtrl, 'Doe')),
            ],
          ),
          const SizedBox(height: 12),
          _buildField('Email *', _emailCtrl, 'you@example.com', type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildField('Phone', _phoneCtrl, '+977 9800000000', type: TextInputType.phone),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Guests',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray),
              ),
              const Spacer(),
              Row(
                children: [
                  GestureDetector(
                    onTap: () { if (_guests > 1) setState(() => _guests--); },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightGray),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.remove, size: 16, color: AppColors.darkGray),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_guests',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () { if (_guests < 6) setState(() => _guests++); },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.placeholder),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialRequestsCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Special Requests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _specialCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Quiet room, early access...',
              hintStyle: const TextStyle(color: AppColors.placeholder),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(int totalPrice, bool isValid) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray),
          ),
          const SizedBox(height: 16),
          if (_previewLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
          else ...[
            if (_pricePreview != null && (_pricePreview!['breakdown'] as List?)?.isNotEmpty == true)
              ...(_pricePreview!['breakdown'] as List).map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      b['label']?.toString() ?? '',
                      style: const TextStyle(fontSize: 14, color: AppColors.gray),
                    ),
                    Text(
                      'NPR ${b['amount']}',
                      style: const TextStyle(fontSize: 14, color: AppColors.darkGray),
                    ),
                  ],
                ),
              ))
            else if (_totalHours > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_totalHours hour${_totalHours > 1 ? 's' : ''} x NPR $_hourlyPrice',
                    style: const TextStyle(fontSize: 14, color: AppColors.gray),
                  ),
                  Text(
                    'NPR ${_hourlyPrice * _totalHours}',
                    style: const TextStyle(fontSize: 14, color: AppColors.darkGray),
                  ),
                ],
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  'NPR $totalPrice',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: AppColors.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Booking held for 10 minutes — pay promptly to confirm.',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(int totalPrice, bool isValid) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total', style: TextStyle(fontSize: 11, color: AppColors.gray)),
              Text(
                'NPR $totalPrice',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: isValid ? _handleBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.lightGray,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Continue to Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
