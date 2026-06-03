import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/hotel_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/image_url_helper.dart';

class NearMeScreen extends StatefulWidget {
  const NearMeScreen({Key? key}) : super(key: key);

  @override
  State<NearMeScreen> createState() => _NearMeScreenState();
}

class _NearMeScreenState extends State<NearMeScreen> {
  final HotelService _hotelService = HotelService();

  _Status _status = _Status.idle;
  String _errorMessage = '';
  List<Map<String, dynamic>> _hotels = [];
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _status = _Status.requesting);

    // 1. Check if location service is on
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _status = _Status.serviceDisabled;
        _errorMessage = 'Location services are turned off on your device.';
      });
      return;
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        _status = _Status.permissionDenied;
        _errorMessage = 'Location permission was denied. Please allow it to find nearby hotels.';
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _status = _Status.permissionPermanentlyDenied;
        _errorMessage = 'Location permission is permanently denied. Open Settings to enable it.';
      });
      return;
    }

    // 3. Get position
    setState(() => _status = _Status.locating);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      _lat = position.latitude;
      _lng = position.longitude;
      await LocationService.saveCity('Near Me', lat: _lat, lng: _lng);
      _fetchHotels();
    } catch (e) {
      setState(() {
        _status = _Status.error;
        _errorMessage = 'Could not get your location. Please try again.';
      });
    }
  }

  Future<void> _fetchHotels() async {
    setState(() => _status = _Status.loading);
    try {
      final result = await _hotelService.getNearbyHotels(
        lat: _lat!,
        lng: _lng!,
        radius: 50,
      );
      if (result['success'] == true) {
        final data = result['data'];
        List raw = data is List
            ? data
            : (data is Map ? (data['data'] ?? data['hotels'] ?? []) : []);
        if (raw.isEmpty) {
          // Fallback: load all hotels
          final fallback = await _hotelService.getHotels();
          if (fallback['success'] == true) {
            final fd = fallback['data'];
            raw = fd is List ? fd : (fd is Map ? (fd['data'] ?? fd['hotels'] ?? []) : []);
          }
        }
        setState(() {
          _hotels = List<Map<String, dynamic>>.from(raw);
          _status = _Status.done;
        });
      } else {
        setState(() {
          _status = _Status.error;
          _errorMessage = result['message'] ?? 'Failed to load nearby hotels.';
        });
      }
    } catch (e) {
      setState(() {
        _status = _Status.error;
        _errorMessage = 'Failed to load nearby hotels.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Hotels Near Me',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          if (_status == _Status.done)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray),
              onPressed: _start,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _Status.idle:
      case _Status.requesting:
        return _buildState(
          icon: Icons.location_searching_rounded,
          iconColor: AppColors.info,
          iconBg: AppColors.infoLight,
          title: 'Requesting Permission',
          subtitle: 'Please allow location access to find hotels near you.',
          showSpinner: true,
        );

      case _Status.locating:
        return _buildState(
          icon: Icons.my_location_rounded,
          iconColor: AppColors.primary,
          iconBg: AppColors.errorLight,
          title: 'Getting Your Location',
          subtitle: 'Finding your current position...',
          showSpinner: true,
        );

      case _Status.loading:
        return _buildState(
          icon: Icons.hotel_rounded,
          iconColor: AppColors.success,
          iconBg: AppColors.successLight,
          title: 'Finding Nearby Hotels',
          subtitle: 'Searching hotels within 50 km of you...',
          showSpinner: true,
        );

      case _Status.serviceDisabled:
        return _buildState(
          icon: Icons.location_off_rounded,
          iconColor: AppColors.warning,
          iconBg: AppColors.warningLight,
          title: 'Location Services Off',
          subtitle: _errorMessage,
          action: _ActionButton(
            label: 'Open Location Settings',
            icon: Icons.settings_rounded,
            onTap: () async {
              await Geolocator.openLocationSettings();
            },
          ),
          secondaryAction: _ActionButton(
            label: 'Try Again',
            icon: Icons.refresh_rounded,
            onTap: _start,
            outlined: true,
          ),
        );

      case _Status.permissionDenied:
        return _buildState(
          icon: Icons.location_disabled_rounded,
          iconColor: AppColors.error,
          iconBg: AppColors.errorLight,
          title: 'Permission Denied',
          subtitle: _errorMessage,
          action: _ActionButton(
            label: 'Allow Location',
            icon: Icons.location_on_rounded,
            onTap: _start,
          ),
          secondaryAction: _ActionButton(
            label: 'Browse All Hotels',
            icon: Icons.hotel_rounded,
            onTap: () => context.push(AppRoutes.hotelList,
                extra: <String, dynamic>{}),
            outlined: true,
          ),
        );

      case _Status.permissionPermanentlyDenied:
        return _buildState(
          icon: Icons.lock_rounded,
          iconColor: AppColors.error,
          iconBg: AppColors.errorLight,
          title: 'Permission Blocked',
          subtitle: _errorMessage,
          action: _ActionButton(
            label: 'Open App Settings',
            icon: Icons.settings_rounded,
            onTap: () async {
              await Geolocator.openAppSettings();
            },
          ),
          secondaryAction: _ActionButton(
            label: 'Browse All Hotels',
            icon: Icons.hotel_rounded,
            onTap: () => context.push(AppRoutes.hotelList,
                extra: <String, dynamic>{}),
            outlined: true,
          ),
        );

      case _Status.error:
        return _buildState(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          iconBg: AppColors.errorLight,
          title: 'Something Went Wrong',
          subtitle: _errorMessage,
          action: _ActionButton(
            label: 'Try Again',
            icon: Icons.refresh_rounded,
            onTap: _start,
          ),
          secondaryAction: _ActionButton(
            label: 'Browse All Hotels',
            icon: Icons.hotel_rounded,
            onTap: () => context.push(AppRoutes.hotelList,
                extra: <String, dynamic>{}),
            outlined: true,
          ),
        );

      case _Status.done:
        return _buildResults();
    }
  }

  Widget _buildState({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    bool showSpinner = false,
    _ActionButton? action,
    _ActionButton? secondaryAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(28)),
              child: Icon(icon, size: 44, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGray),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.gray, height: 1.5),
                textAlign: TextAlign.center),
            if (showSpinner) ...[
              const SizedBox(height: 28),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: AppColors.primary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: action.onTap,
                  icon: Icon(action.icon, size: 18),
                  label: Text(action.label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: secondaryAction.outlined
                    ? OutlinedButton.icon(
                        onPressed: secondaryAction.onTap,
                        icon: Icon(secondaryAction.icon, size: 18),
                        label: Text(secondaryAction.label),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: secondaryAction.onTap,
                        icon: Icon(secondaryAction.icon, size: 18),
                        label: Text(secondaryAction.label),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_hotels.isEmpty) {
      return _buildState(
        icon: Icons.search_off_rounded,
        iconColor: AppColors.gray,
        iconBg: AppColors.surfaceVariant,
        title: 'No Hotels Found Nearby',
        subtitle:
            'We couldn\'t find any hotels within 50 km of your location.',
        action: _ActionButton(
          label: 'Browse All Hotels',
          icon: Icons.hotel_rounded,
          onTap: () =>
              context.push(AppRoutes.hotelList, extra: <String, dynamic>{}),
        ),
        secondaryAction: _ActionButton(
          label: 'Try Again',
          icon: Icons.refresh_rounded,
          onTap: _start,
          outlined: true,
        ),
      );
    }

    return Column(
      children: [
        // Location banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.my_location_rounded,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Showing ${_hotels.length} hotels near your location',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: _hotels.length,
            itemBuilder: (_, i) => _buildHotelCard(_hotels[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    final name = hotel['name'] ?? 'Hotel';
    final city = hotel['city'] ?? hotel['address'] ?? '';
    final rating = (hotel['rating'] as num?)?.toDouble() ?? 0.0;
    final price = hotel['min_price'] ?? hotel['price'] ?? 0;
    
    // Handle image if it's a list or string
    String rawImage = '';
    final imgData = hotel['image'] ?? hotel['images'];
    if (imgData is List && imgData.isNotEmpty) {
      rawImage = imgData.first.toString();
    } else if (imgData != null) {
      rawImage = imgData.toString();
    }
    
    final imageUrl = ImageUrlHelper.fix(rawImage);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.hotelDetails,
          extra: {'hotel_id': hotel['id'], 'hotel': hotel}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (rating > 0)
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFFFB800)),
                          const SizedBox(width: 3),
                          Text(rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkGray)),
                        ]),
                    ],
                  ),
                  if (city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: AppColors.gray),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(city,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.gray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (price > 0)
                        RichText(
                          text: TextSpan(children: [
                            const TextSpan(
                                text: 'NPR ',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray,
                                    fontWeight: FontWeight.w500)),
                            TextSpan(
                                text: '$price',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary)),
                            const TextSpan(
                                text: '/night',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.gray)),
                          ]),
                        )
                      else
                        const Text('Price on request',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.gray)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('View',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.hotel_rounded, size: 48, color: AppColors.placeholder),
    );
  }
}

enum _Status {
  idle,
  requesting,
  locating,
  loading,
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  error,
  done,
}

class _ActionButton {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });
}
