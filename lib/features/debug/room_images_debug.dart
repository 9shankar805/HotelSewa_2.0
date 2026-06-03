import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/shared/api_service.dart';
import '../../core/services/hotel_service.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';

class RoomImagesDebugScreen extends StatefulWidget {
  const RoomImagesDebugScreen({super.key});

  @override
  State<RoomImagesDebugScreen> createState() => _RoomImagesDebugScreenState();
}

class _RoomImagesDebugScreenState extends State<RoomImagesDebugScreen> {
  final _hotelIdController = TextEditingController();
  final _roomTypeIdController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _debugData;

  @override
  void dispose() {
    _hotelIdController.dispose();
    _roomTypeIdController.dispose();
    super.dispose();
  }

  Future<void> _testRoomImages() async {
    setState(() {
      _loading = true;
      _debugData = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final hotelService = HotelService();
      
      final debugInfo = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'auth_token_available': authProvider.token != null,
        'hotel_id': _hotelIdController.text,
        'room_type_id': _roomTypeIdController.text,
      };

      // Test 1: Get hotel details to see room data structure
      if (_hotelIdController.text.isNotEmpty) {
        debugPrint('🔍 Testing hotel details for room images...');
        final hotelResult = await hotelService.getHotelDetails(_hotelIdController.text);
        debugInfo['hotel_details'] = {
          'success': hotelResult['success'],
          'has_data': hotelResult['data'] != null,
        };

        if (hotelResult['success'] == true && hotelResult['data'] != null) {
          final data = hotelResult['data'];
          final roomTypes = data['room_types'] as List? ?? [];
          
          debugInfo['room_types_count'] = roomTypes.length;
          debugInfo['room_types_analysis'] = [];

          for (int i = 0; i < roomTypes.length; i++) {
            final room = roomTypes[i];
            final roomAnalysis = {
              'index': i,
              'id': room['id'],
              'name': room['name'],
              'has_images_field': room.containsKey('images'),
              'images_type': room['images']?.runtimeType.toString(),
              'images_count': room['images'] is List ? (room['images'] as List).length : 0,
              'images_sample': room['images'] is List && (room['images'] as List).isNotEmpty 
                  ? (room['images'] as List).take(2).toList() 
                  : null,
              'has_image_field': room.containsKey('image'),
              'single_image': room['image'],
              'has_media_field': room.containsKey('media'),
              'media_type': room['media']?.runtimeType.toString(),
              'has_gallery_field': room.containsKey('gallery'),
              'gallery_type': room['gallery']?.runtimeType.toString(),
            };
            debugInfo['room_types_analysis'].add(roomAnalysis);
          }
        }
      }

      // Test 2: Direct API call to room type media endpoint
      if (_roomTypeIdController.text.isNotEmpty) {
        debugPrint('🔍 Testing room type media endpoint...');
        try {
          final mediaResult = await ApiService.get(
            '/room-types/${_roomTypeIdController.text}/media',
            token: authProvider.token,
          );
          debugInfo['room_media_endpoint'] = {
            'success': mediaResult['success'] ?? false,
            'data_available': mediaResult['data'] != null,
            'data_structure': mediaResult['data']?.keys?.toList(),
            'raw_response': mediaResult,
          };
        } catch (e) {
          debugInfo['room_media_endpoint'] = {
            'success': false,
            'error': e.toString(),
          };
        }

        // Test 3: Gallery endpoint
        debugPrint('🔍 Testing room type gallery endpoint...');
        try {
          final galleryResult = await ApiService.get(
            '/room-types/${_roomTypeIdController.text}/gallery',
            token: authProvider.token,
          );
          debugInfo['room_gallery_endpoint'] = {
            'success': galleryResult['success'] ?? false,
            'data_available': galleryResult['data'] != null,
            'data_structure': galleryResult['data']?.keys?.toList(),
            'raw_response': galleryResult,
          };
        } catch (e) {
          debugInfo['room_gallery_endpoint'] = {
            'success': false,
            'error': e.toString(),
          };
        }
      }

      // Test 4: Check API endpoints that might contain room images
      final testEndpoints = [
        '/hotels/${_hotelIdController.text}/rooms',
        '/hotels/${_hotelIdController.text}/room-types',
        '/room-types',
      ];

      debugInfo['endpoint_tests'] = {};
      for (final endpoint in testEndpoints) {
        if (_hotelIdController.text.isNotEmpty || !endpoint.contains('hotels/')) {
          try {
            final result = await ApiService.get(endpoint, token: authProvider.token);
            debugInfo['endpoint_tests'][endpoint] = {
              'success': result['success'] ?? false,
              'has_data': result['data'] != null,
              'data_type': result['data']?.runtimeType.toString(),
            };
          } catch (e) {
            debugInfo['endpoint_tests'][endpoint] = {
              'success': false,
              'error': e.toString(),
            };
          }
        }
      }

      setState(() {
        _debugData = debugInfo;
        _loading = false;
      });

    } catch (e) {
      setState(() {
        _debugData = {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Images Debug'),
        backgroundColor: const Color(0xFFE60023),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Room Images Storage Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hotelIdController,
              decoration: const InputDecoration(
                labelText: 'Hotel ID',
                hintText: 'Enter hotel ID to test',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomTypeIdController,
              decoration: const InputDecoration(
                labelText: 'Room Type ID (optional)',
                hintText: 'Enter room type ID for specific tests',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _testRoomImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE60023),
                  foregroundColor: Colors.white,
                ),
                child: _loading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Test Room Images'),
              ),
            ),
            const SizedBox(height: 20),
            if (_debugData != null) ...[
              const Text(
                'Debug Results:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.lightGray!),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _formatDebugData(_debugData!),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDebugData(Map<String, dynamic> data) {
    return _prettyPrintJson(data, 0);
  }

  String _prettyPrintJson(dynamic obj, int indent) {
    final spaces = '  ' * indent;
    if (obj is Map) {
      final buffer = StringBuffer('{\n');
      obj.forEach((key, value) {
        buffer.write('$spaces  "$key": ${_prettyPrintJson(value, indent + 1)},\n');
      });
      buffer.write('$spaces}');
      return buffer.toString();
    } else if (obj is List) {
      if (obj.isEmpty) return '[]';
      final buffer = StringBuffer('[\n');
      for (int i = 0; i < obj.length; i++) {
        buffer.write('$spaces  ${_prettyPrintJson(obj[i], indent + 1)}');
        if (i < obj.length - 1) buffer.write(',');
        buffer.write('\n');
      }
      buffer.write('$spaces]');
      return buffer.toString();
    } else if (obj is String) {
      return '"$obj"';
    } else {
      return obj.toString();
    }
  }
}