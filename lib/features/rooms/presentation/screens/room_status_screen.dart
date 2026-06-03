import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/room_provider.dart';

class RoomStatusScreen extends StatefulWidget {
  const RoomStatusScreen({super.key});

  @override
  State<RoomStatusScreen> createState() => _RoomStatusScreenState();
}

class _RoomStatusScreenState extends State<RoomStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<RoomProvider>(context, listen: false);
    await provider.loadRooms(token: auth.token);
  }

  Color _getColor(String status) {
    switch (status) {
      case 'available': return const Color(0xFF52C41A);
      case 'occupied': return const Color(0xFFE60023);
      case 'maintenance': return const Color(0xFFFA8C16);
      case 'cleaning': return const Color(0xFF1890FF);
      default: return AppColors.gray;
    }
  }

  IconData _getIcon(String status) {
    switch (status) {
      case 'available': return Icons.check_circle;
      case 'occupied': return Icons.person;
      case 'maintenance': return Icons.build;
      case 'cleaning': return Icons.cleaning_services;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Status')),
      body: Consumer<RoomProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => const SkeletonLoader(height: double.infinity, borderRadius: 12),
            );
          }

          final rooms = provider.rooms;

          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms found'));
          }

          final counts = {
            'available': provider.availableRooms,
            'occupied': provider.occupiedRooms,
            'maintenance': provider.maintenanceRooms,
            'cleaning': provider.cleaningRooms,
          };

          return RefreshIndicator(
            onRefresh: _load,
            color: const Color(AppConstants.primaryRed),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummary(counts['available']!, 'Available'),
                      _buildSummary(counts['occupied']!, 'Occupied'),
                      _buildSummary(counts['maintenance']!, 'Maintenance'),
                      _buildSummary(counts['cleaning']!, 'Cleaning'),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final status = room.status;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(room.roomNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Icon(_getIcon(status), size: 20, color: _getColor(status)),
                              ],
                            ),
                            Text(room.type, style: const TextStyle(color: AppColors.gray)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: _getColor(status), borderRadius: BorderRadius.circular(12)),
                              child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, size: 16, color: Color(0xFF52C41A)),
                                  onPressed: () => provider.updateRoomStatus(room.id, 'available'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.build, size: 16, color: Color(0xFFFA8C16)),
                                  onPressed: () => provider.updateRoomStatus(room.id, 'maintenance'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cleaning_services, size: 16, color: Color(0xFF1890FF)),
                                  onPressed: () => provider.updateRoomStatus(room.id, 'cleaning'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(int count, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
        ],
      ),
    );
  }
}
