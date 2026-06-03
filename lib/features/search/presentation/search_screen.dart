import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/nepal_locations.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/floating_chatbot.dart';
import '../../hotel/presentation/hotel_list_screen.dart';

enum _BookingType { nightly, hourly }

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocus = FocusNode();

  // Booking type
  _BookingType _bookingType = _BookingType.nightly;

  // Nightly
  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 1));

  // Hourly
  DateTime _hourlyDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  int _hours = 2;

  int _guests = 1;
  int _rooms = 1;
  bool _detectingLocation = false;
  List<String> _suggestions = [];

  static const _popularCities = [
    'Kathmandu', 'Pokhara', 'Chitwan', 'Lumbini',
    'Bhaktapur', 'Lalitpur', 'Biratnagar', 'Birgunj',
    'Dharan', 'Butwal', 'Nepalgunj', 'Dhangadhi',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
    _locationController.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    _locationController.removeListener(_onLocationChanged);
    _locationController.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCity() async {
    final city = await LocationService.getSavedCity();
    if (city != null && mounted) _locationController.text = city;
  }

  void _onLocationChanged() {
    final query = _locationController.text.trim().toLowerCase();
    if (query.isEmpty) { setState(() => _suggestions = []); return; }
    final results = <String>{};
    NepalLocationData.provinces.forEach((_, province) {
      for (final district in province.districts) {
        if (district.name.toLowerCase().contains(query)) results.add(district.name);
        for (final muni in district.municipalities) {
          if (muni.toLowerCase().contains(query)) results.add('$muni, ${district.name}');
        }
      }
    });
    for (final city in _popularCities) {
      if (city.toLowerCase().contains(query)) results.add(city);
    }
    setState(() => _suggestions = results.take(8).toList());
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location. Please enable GPS.'), behavior: SnackBarBehavior.floating));
        return;
      }
      await LocationService.saveCity('Near Me', lat: position.latitude, lng: position.longitude);
      if (mounted) {
        _locationController.text = 'Near Me';
        setState(() => _suggestions = []);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HotelListScreen(arguments: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'location': 'Near Me',
          'checkIn': _fmtDate(_checkInDate),
          'checkOut': _fmtDate(_checkOutDate),
          'guests': _guests,
          'rooms': _rooms,
          'useGps': true,
          'bookingType': _bookingType == _BookingType.hourly ? 'hourly' : 'nightly',
        })));
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  void _selectSuggestion(String s) {
    _locationController.text = s;
    setState(() => _suggestions = []);
    _locationFocus.unfocus();
  }

  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  String _fmtTime(TimeOfDay t) => t.format(context);

  DateTime get _hourlyCheckIn {
    return DateTime(_hourlyDate.year, _hourlyDate.month, _hourlyDate.day, _startTime.hour, _startTime.minute);
  }

  DateTime get _hourlyCheckOut => _hourlyCheckIn.add(Duration(hours: _hours));

  void _handleSearch() {
    final loc = _locationController.text.trim();
    if (loc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location'), behavior: SnackBarBehavior.floating));
      return;
    }
    LocationService.saveCity(loc);

    // Save to recent searches for home screen
    _saveRecentSearch(loc);

    final args = <String, dynamic>{
      'location': loc,
      'guests': _guests,
      'rooms': _rooms,
      'bookingType': _bookingType == _BookingType.hourly ? 'hourly' : 'nightly',
    };

    if (_bookingType == _BookingType.nightly) {
      args['checkIn'] = _fmtDate(_checkInDate);
      args['checkOut'] = _fmtDate(_checkOutDate);
    } else {
      args['checkIn'] = DateFormat('dd MMM yyyy HH:mm').format(_hourlyCheckIn);
      args['checkOut'] = DateFormat('dd MMM yyyy HH:mm').format(_hourlyCheckOut);
      args['hours'] = _hours;
      args['hourly'] = true;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HotelListScreen(arguments: args)));
  }

  /// Saves the search to SharedPreferences so the home screen can show recent searches.
  Future<void> _saveRecentSearch(String location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('recent_searches') ?? '[]';
      final List existing = jsonDecode(raw) as List;

      // Build the entry
      final entry = <String, dynamic>{
        'location': location,
        'dates': _bookingType == _BookingType.nightly
            ? '${_fmtDate(_checkInDate)} - ${_fmtDate(_checkOutDate)}'
            : DateFormat('dd MMM yyyy').format(_hourlyDate),
        'guests': '$_guests Guest${_guests > 1 ? 's' : ''}',
        'image': 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=200',
        'bookingType': _bookingType == _BookingType.hourly ? 'hourly' : 'nightly',
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Remove duplicate location if exists
      existing.removeWhere((e) =>
          (e as Map<String, dynamic>)['location']?.toString().toLowerCase() ==
          location.toLowerCase());

      // Prepend new entry, keep max 5
      existing.insert(0, entry);
      final trimmed = existing.take(5).toList();

      await prefs.setString('recent_searches', jsonEncode(trimmed));
    } catch (_) {}
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final first = isCheckIn ? DateTime.now() : _checkInDate.add(const Duration(days: 1));
    final initial = isCheckIn ? _checkInDate : _checkOutDate;
    final picked = await showDatePicker(
      context: context, initialDate: initial, firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkInDate = picked;
        if (!_checkOutDate.isAfter(_checkInDate)) _checkOutDate = _checkInDate.add(const Duration(days: 1));
      } else {
        _checkOutDate = picked;
      }
    });
  }

  Future<void> _pickHourlyDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _hourlyDate, firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
    );
    if (picked != null) setState(() => _hourlyDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: _startTime,
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  int get _nights => _checkOutDate.difference(_checkInDate).inDays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Search Hotels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Booking Type Toggle ───────────────────────────────────
                _sectionCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Booking Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          _typeTab(_BookingType.nightly, Icons.nights_stay_rounded, 'Nightly', 'Full day stay'),
                          _typeTab(_BookingType.hourly, Icons.access_time_rounded, 'Hourly', 'Few hours stay'),
                        ],
                      ),
                    ),
                  ],
                )),
                const SizedBox(height: 12),

                // ── Location ──────────────────────────────────────────────
                _sectionCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Where are you going?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          focusNode: _locationFocus,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray),
                          decoration: InputDecoration(
                            hintText: 'City, district or area',
                            hintStyle: const TextStyle(color: AppColors.placeholder, fontWeight: FontWeight.w400),
                            prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                            suffixIcon: _locationController.text.isNotEmpty
                                ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.gray),
                                    onPressed: () { _locationController.clear(); setState(() => _suggestions = []); })
                                : null,
                            filled: true, fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _detectingLocation ? null : _detectLocation,
                        child: Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                          child: _detectingLocation
                              ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                              : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 22),
                        ),
                      ),
                    ]),
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray), boxShadow: AppColors.cardShadow),
                        child: Column(children: _suggestions.asMap().entries.map((e) {
                          final isLast = e.key == _suggestions.length - 1;
                          return InkWell(
                            onTap: () => _selectSuggestion(e.value),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF5F5F5)))),
                              child: Row(children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gray),
                                const SizedBox(width: 10),
                                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 14, color: AppColors.darkGray))),
                              ]),
                            ),
                          );
                        }).toList()),
                      ),
                    ],
                  ],
                )),
                const SizedBox(height: 12),

                // ── Date / Time ───────────────────────────────────────────
                if (_bookingType == _BookingType.nightly)
                  _sectionCard(child: Row(children: [
                    Expanded(child: _dateTile('Check-in', _checkInDate, () => _pickDate(isCheckIn: true))),
                    Container(width: 1, height: 48, color: AppColors.lightGray, margin: const EdgeInsets.symmetric(horizontal: 12)),
                    Expanded(child: _dateTile('Check-out', _checkOutDate, () => _pickDate(isCheckIn: false))),
                    Container(width: 1, height: 48, color: AppColors.lightGray, margin: const EdgeInsets.symmetric(horizontal: 12)),
                    Column(children: [
                      Text('$_nights', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      Text(_nights == 1 ? 'night' : 'nights', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                    ]),
                  ]))
                else
                  _sectionCard(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date & Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _dateTile('Date', _hourlyDate, _pickHourlyDate)),
                        Container(width: 1, height: 48, color: AppColors.lightGray, margin: const EdgeInsets.symmetric(horizontal: 12)),
                        Expanded(child: GestureDetector(
                          onTap: _pickStartTime,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Start Time', style: TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(_fmtTime(_startTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                          ]),
                        )),
                      ]),
                      const SizedBox(height: 14),
                      // Hours selector
                      Row(children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Duration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                        const Spacer(),
                        _counterBtn(Icons.remove_rounded, _hours > 1 ? () => setState(() => _hours--) : null),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$_hours hr${_hours > 1 ? "s" : ""}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        ),
                        _counterBtn(Icons.add_rounded, _hours < 12 ? () => setState(() => _hours++) : null),
                      ]),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Check-out: ${DateFormat('dd MMM, hh:mm a').format(_hourlyCheckOut)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ]),
                      ),
                    ],
                  )),
                const SizedBox(height: 12),

                // ── Guests & Rooms ────────────────────────────────────────
                _sectionCard(child: Row(children: [
                  Expanded(child: _counterTile('Guests', Icons.person_outline_rounded, _guests, (v) => setState(() => _guests = v), min: 1, max: 10)),
                  Container(width: 1, height: 48, color: AppColors.lightGray, margin: const EdgeInsets.symmetric(horizontal: 12)),
                  Expanded(child: _counterTile('Rooms', Icons.bed_outlined, _rooms, (v) => setState(() => _rooms = v), min: 1, max: 5)),
                ])),
                const SizedBox(height: 20),

                // ── Popular Cities ────────────────────────────────────────
                const Text('Popular Destinations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _popularCities.map((city) => GestureDetector(
                    onTap: () => _selectSuggestion(city),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _locationController.text == city ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _locationController.text == city ? AppColors.primary : AppColors.lightGray),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.location_city_rounded, size: 14, color: _locationController.text == city ? Colors.white : AppColors.gray),
                        const SizedBox(width: 5),
                        Text(city, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: _locationController.text == city ? Colors.white : AppColors.darkGray)),
                      ]),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          // Search button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))]),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleSearch,
                  icon: Icon(_bookingType == _BookingType.hourly ? Icons.access_time_rounded : Icons.search_rounded, color: Colors.white, size: 20),
                  label: Text(
                    _bookingType == _BookingType.hourly
                        ? 'Search Hourly Hotels${_locationController.text.isNotEmpty ? " in ${_locationController.text}" : ""}'
                        : 'Search Hotels${_locationController.text.isNotEmpty ? " in ${_locationController.text}" : ""}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bookingType == _BookingType.hourly ? AppColors.info : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ),
          const FloatingChatbot(),
        ],
      ),
    );
  }

  Widget _typeTab(_BookingType type, IconData icon, String label, String sub) {
    final isSelected = _bookingType == type;
    final color = type == _BookingType.hourly ? AppColors.info : AppColors.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _bookingType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Icon(icon, size: 22, color: isSelected ? Colors.white : AppColors.gray),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.darkGray)),
            Text(sub, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : AppColors.gray)),
          ]),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
    child: child,
  );

  Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(DateFormat('EEE, dd MMM').format(date), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      ]),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary.withOpacity(0.1) : AppColors.lightGray,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: onTap != null ? AppColors.primary : AppColors.placeholder),
      ),
    );
  }

  Widget _counterTile(String label, IconData icon, int value, ValueChanged<int> onChange, {required int min, required int max}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        _counterBtn(Icons.remove_rounded, value > min ? () => onChange(value - 1) : null),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray))),
        _counterBtn(Icons.add_rounded, value < max ? () => onChange(value + 1) : null),
      ]),
    ]);
  }
}