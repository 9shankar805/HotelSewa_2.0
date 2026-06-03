import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class HousekeepingScreen extends StatefulWidget {
  const HousekeepingScreen({Key? key}) : super(key: key);

  @override
  State<HousekeepingScreen> createState() => _HousekeepingScreenState();
}

class _HousekeepingScreenState extends State<HousekeepingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _roomStatus = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final results = await Future.wait([
        ApiService.get(ApiConfig.housekeepingTasksEndpoint, token: token),
        ApiService.get(ApiConfig.housekeepingRoomStatusEndpoint, token: token),
      ]);
      if (results[0]['success'] == true) {
        final data = results[0]['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['tasks'] ?? []) : []);
        _tasks = List<Map<String, dynamic>>.from(raw);
      }
      if (results[1]['success'] == true) {
        final data = results[1]['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['rooms'] ?? []) : []);
        _roomStatus = List<Map<String, dynamic>>.from(raw);
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load housekeeping data'; _loading = false; });
    }
  }

  Future<void> _updateTaskStatus(int id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    await ApiService.put('${ApiConfig.housekeepingTaskStatusEndpoint}/$id/status', data: {'status': status}, token: token);
    _load();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Housekeeping', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: _showAddTaskDialog),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Tasks'), Tab(text: 'Room Status')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildTasksTab(), _buildRoomStatusTab()],
                ),
    );
  }

  Widget _buildTasksTab() {
    if (_tasks.isEmpty) {
      return const Center(child: Text('No housekeeping tasks', style: TextStyle(color: AppColors.gray)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (_, i) => _buildTaskCard(_tasks[i]),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = task['status'] ?? 'pending';
    final priority = task['priority'] ?? 'normal';
    final statusColor = status == 'done' ? AppColors.success : status == 'in_progress' ? AppColors.info : AppColors.warning;
    final priorityColor = priority == 'high' ? AppColors.error : priority == 'medium' ? AppColors.warning : AppColors.gray;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.cleaning_services_rounded, color: AppColors.teal, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(task['task_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'Task', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray, letterSpacing: 0.5)),
                Text('Room ${task['room_number'] ?? task['room']?['room_number'] ?? ''}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor))),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(priority.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: priorityColor))),
              ]),
            ],
          ),
          if ((task['notes'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(task['notes'], style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (status != 'in_progress' && status != 'done')
                _statusBtn('Start', AppColors.info, () => _updateTaskStatus(task['id'], 'in_progress')),
              if (status == 'in_progress')
                _statusBtn('Mark Done', AppColors.success, () => _updateTaskStatus(task['id'], 'done')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  Widget _buildRoomStatusTab() {
    if (_roomStatus.isEmpty) {
      return const Center(child: Text('No room status data', style: TextStyle(color: AppColors.gray)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1),
      itemCount: _roomStatus.length,
      itemBuilder: (_, i) {
        final room = _roomStatus[i];
        final status = room['status'] ?? 'vacant';
        final color = status == 'occupied' ? AppColors.error : status == 'dirty' ? AppColors.warning : status == 'cleaning' ? AppColors.info : AppColors.success;
        return Container(
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(room['room_number'] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.5)),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog() {
    final roomIdCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String taskType = 'cleaning';
    String priority = 'normal';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Add Housekeeping Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              TextField(controller: roomIdCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Room ID', prefixIcon: const Icon(Icons.hotel_rounded, color: AppColors.gray), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: taskType,
                decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray))),
                items: ['cleaning', 'turndown', 'deep_clean', 'linen_change'].map((e) => DropdownMenuItem(value: e, child: Text(e.replaceAll('_', ' ')))).toList(),
                onChanged: (v) => setModalState(() => taskType = v ?? 'cleaning'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray))),
                items: ['low', 'normal', 'high'].map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
                onChanged: (v) => setModalState(() => priority = v ?? 'normal'),
              ),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, maxLines: 2, decoration: InputDecoration(hintText: 'Notes (optional)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post(ApiConfig.housekeepingTasksEndpoint, data: {'room_id': int.tryParse(roomIdCtrl.text) ?? 0, 'task_type': taskType, 'priority': priority, 'notes': notesCtrl.text}, token: token);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Create Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.placeholder),
      const SizedBox(height: 16),
      Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.gray), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Retry', style: TextStyle(color: Colors.white))),
    ])));
  }
}
