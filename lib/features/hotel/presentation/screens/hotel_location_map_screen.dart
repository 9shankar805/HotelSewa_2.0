import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';

class HotelLocationMapScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String hotelName;

  const HotelLocationMapScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.hotelName,
  });

  @override
  State<HotelLocationMapScreen> createState() => _HotelLocationMapScreenState();
}

class _HotelLocationMapScreenState extends State<HotelLocationMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    // Marker will be added after map is created
  }

  void _addMarker(LatLng position) {
    debugPrint('Adding marker at position: ${position.latitude}, ${position.longitude}');
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('hotel_location'),
          position: position,
          infoWindow: InfoWindow(
            title: widget.hotelName,
            snippet: 'Hotel Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
    debugPrint('Total markers: ${_markers.length}');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Add initial marker if coordinates are provided
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _addMarker(_selectedLocation!);
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _markers.clear();
      _addMarker(position);
    });

    // Move camera to selected location
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Get current location with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        final location = LatLng(position.latitude, position.longitude);
        _onMapTap(location);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location captured!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pin Hotel Location'),
        backgroundColor: AppColors.error.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Get Current Location',
          ),
          if (_selectedLocation != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedLocation);
              },
              icon: const Icon(Icons.check),
              tooltip: 'Confirm Location',
            ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target:
              widget.initialLatitude != null && widget.initialLongitude != null
                  ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
                  : const LatLng(27.7172, 85.3240), // Default to Kathmandu
          zoom: 15,
        ),
        onMapCreated: _onMapCreated,
        onTap: _onMapTap,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
        compassEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: AppColors.error.shade600,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
