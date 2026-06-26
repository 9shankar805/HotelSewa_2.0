import 'package:flutter/foundation.dart';
import '../models/room_model.dart';
import '../services/real_room_service.dart';

class RoomProvider extends ChangeNotifier {
  final RealRoomService _roomService = RealRoomService();
  
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  List<Room> get rooms => _filteredRooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRooms({String filter = 'all', String? hotelId, String? token}) async {
    _setLoading(true);
    _clearError();

    try {
      if (hotelId != null) {
        final response = await RealRoomService.getRooms(
          hotelId: hotelId,
          status: filter == 'all' ? null : filter,
          token: token,
        );

        if (response['success'] == true) {
          final raw = response['data'];

          List<dynamic> rawList;
          if (raw is List) {
            rawList = raw;
          } else if (raw is Map) {
            final nested = raw['rooms'] ?? raw['data'] ?? raw['room_types'];
            if (nested is List) {
              rawList = nested;
            } else if (raw['id'] != null) {
              rawList = [raw];
            } else {
              rawList = [];
            }
          } else {
            rawList = [];
          }

          _rooms = rawList
              .whereType<Map>()
              .map((json) => Room.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          _applyFilters();
        } else {
          _rooms = [];
          _filteredRooms = [];
        }
      } else {
        _rooms = [];
        _filteredRooms = [];
      }
    } catch (e) {
      _setError('Failed to load rooms: ${e.toString()}');
      _rooms = [];
      _filteredRooms = [];
    } finally {
      _setLoading(false);
    }
  }

  void _applyFilters() {
    _filteredRooms = _rooms.where((room) {
      bool matchesFilter = _selectedFilter == 'all' || 
          (_selectedFilter == 'available' && room.status == 'available') ||
          (_selectedFilter == 'occupied' && room.status == 'occupied') ||
          (_selectedFilter == 'maintenance' && room.status == 'maintenance') ||
          (_selectedFilter == 'cleaning' && room.status == 'cleaning');

      bool matchesSearch = _searchQuery.isEmpty || 
          room.roomNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          room.type.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  void searchRooms(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  Future<void> filterByCapacity(int capacity) async {
    _setLoading(true);
    _clearError();

    try {
      final roomsData = await _roomService.getRoomsByCapacity(capacity);
      _rooms = roomsData.map((json) => Room.fromJson(json)).toList();
      _filteredRooms = List.from(_rooms);
    } catch (e) {
      _setError('Failed to filter rooms: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateRoomStatus(String roomId, String newStatus, {String? token}) async {
    _clearError();

    try {
      final response = await RealRoomService.updateRoomStatus(
        roomId: roomId,
        newStatus: newStatus,
        token: token,
      );

      if (response['success'] == true) {
        final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
        if (roomIndex != -1) {
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(status: newStatus);
          
          final filteredIndex = _filteredRooms.indexWhere((r) => r.id == roomId);
          if (filteredIndex != -1) {
            _filteredRooms[filteredIndex] = _filteredRooms[filteredIndex].copyWith(status: newStatus);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update room status: ${e.toString()}');
    }
  }

  Future<void> createRoom(Room room) async {
    _setLoading(true);
    _clearError();

    try {
      // Get hotelId from storage or context
      // For now, we need to pass it when calling this method
      if (room.hotelId == null || room.hotelId!.isEmpty) {
        _setError('Hotel ID is required. Please ensure you are logged in as a hotel owner.');
        _setLoading(false);
        return;
      }

      final roomData = await _roomService.createRoom(room.toJson());
      final newRoom = Room.fromJson(roomData);
      
      _rooms.insert(0, newRoom);
      _filteredRooms.insert(0, newRoom);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to create room: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateRoom(Room room) async {
    _setLoading(true);
    _clearError();

    try {
      final roomData = await _roomService.updateRoom(room.id, room.toJson());
      final updatedRoom = Room.fromJson(roomData);
      
      final roomIndex = _rooms.indexWhere((r) => r.id == room.id);
      if (roomIndex != -1) {
        _rooms[roomIndex] = updatedRoom;
      }
      
      final filteredIndex = _filteredRooms.indexWhere((r) => r.id == room.id);
      if (filteredIndex != -1) {
        _filteredRooms[filteredIndex] = updatedRoom;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to update room: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteRoom(String roomId) async {
    _clearError();

    try {
      await _roomService.deleteRoom(roomId);
      
      _rooms.removeWhere((r) => r.id == roomId);
      _filteredRooms.removeWhere((r) => r.id == roomId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete room: ${e.toString()}');
    }
  }

  Future<void> markRoomClean(String roomId) async {
    await updateRoomStatus(roomId, 'available');
  }

  Future<void> markRoomMaintenance(String roomId) async {
    await updateRoomStatus(roomId, 'maintenance');
  }

  Future<void> markRoomOccupied(String roomId) async {
    await updateRoomStatus(roomId, 'occupied');
  }

  Future<void> markRoomCleaning(String roomId) async {
    await updateRoomStatus(roomId, 'cleaning');
  }

  // Statistics
  int get totalRooms => _rooms.length;
  int get availableRooms => _rooms.where((r) => r.status == 'available').length;
  int get occupiedRooms => _rooms.where((r) => r.status == 'occupied').length;
  int get maintenanceRooms => _rooms.where((r) => r.status == 'maintenance').length;
  int get cleaningRooms => _rooms.where((r) => r.status == 'cleaning').length;
  
  double get occupancyRate {
    if (totalRooms == 0) return 0.0;
    return (occupiedRooms / totalRooms) * 100;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
