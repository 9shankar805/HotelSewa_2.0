import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        ApiService.get(ApiConfig.ownerStaffEndpoint, token: token),
        ApiService.get(ApiConfig.ownerStaffShiftsEndpoint, token: token),
        ApiService.get(ApiConfig.ownerStaffTasksEndpoint, token: token),
      ]);
      if (results[0]['success'] == true) {
        final data = results[0]['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['staff'] ?? []) : []);
        _staff = List<Map<String, dynamic>>.from(raw);
      }
      if (results[1]['success'] == true) {
        final data = results[1]['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['shifts'] ?? []) : []);
        _shifts = List<Map<String, dynamic>>.from(raw);
      }
      if (results[2]['success'] == true) {
        final data = results[2]['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['tasks'] ?? []) : []);
        _tasks = List<Map<String, dynamic>>.from(raw);
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load staff data'; _loading = false; });
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Staff Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.person_add_rounded, color: AppColors.primary), onPressed: _showAddStaffDialog),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Staff'), Tab(text: 'Shifts'), Tab(text: 'Tasks')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildStaffTab(), _buildShiftsTab(), _buildTasksTab()],
                ),
    );
  }

  Widget _buildStaffTab() {
    if (_staff.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.people_rounded, size: 40, color: AppColors.info)),
        const SizedBox(height: 20),
        const Text('No Staff Added', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        const Text('Add staff members to manage shifts, tasks and attendance.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
      ])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _staff.length,
      itemBuilder: (_, i) {
        final s = _staff[i];
        final roleColors = {'housekeeping': AppColors.teal, 'reception': AppColors.info, 'maintenance': AppColors.warning, 'security': AppColors.error};
        final role = s['role'] ?? 'staff';
        final color = roleColors[role] ?? AppColors.gray;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.15),
                child: Text((s['name'] ?? 'S')[0].toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(role.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color))),
                  const SizedBox(width: 8),
                  Text(s['mobile'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                ]),
              ])),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'credentials') {
                    // Re-show credentials for this staff member
                    final mobile = s['mobile']?.toString() ?? '';
                    final digits = mobile.replaceAll(RegExp(r'\D'), '');
                    final email = s['email']?.toString().isNotEmpty == true
                        ? s['email']
                        : 'staff_$digits@hotelsewa.com';
                    final password = s['temp_password']?.toString().isNotEmpty == true
                        ? s['temp_password']
                        : '${digits.length >= 4 ? digits.substring(0, 4) : digits.padRight(4, "0")}Staff@';
                    _showCredentialsDialog(s['name'] ?? '', email, password, mobile);
                  } else if (action == 'clock_in') {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post(ApiConfig.ownerStaffAttendanceClockInEndpoint, data: {'staff_id': s['id']}, token: token);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked in'), backgroundColor: AppColors.success));
                  } else if (action == 'clock_out') {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post(ApiConfig.ownerStaffAttendanceClockOutEndpoint, data: {'staff_id': s['id']}, token: token);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked out'), backgroundColor: AppColors.success));
                  } else if (action == 'delete') {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.delete('${ApiConfig.ownerStaffEndpoint}/${s['id']}', token: token);
                    _load();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'credentials', child: Row(children: [Icon(Icons.key_rounded, size: 16, color: AppColors.info), SizedBox(width: 8), Text('View Credentials')])),
                  const PopupMenuItem(value: 'clock_in', child: Text('Clock In')),
                  const PopupMenuItem(value: 'clock_out', child: Text('Clock Out')),
                  const PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(color: AppColors.error))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShiftsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._shifts.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.schedule_rounded, color: AppColors.info, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['staff_name'] ?? 'Staff #${s['staff_id']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                Text('${s['shift_start'] ?? ''} – ${s['shift_end'] ?? ''} · ${s['date'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
              ])),
            ],
          ),
        )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showAddShiftDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Shift'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._tasks.map((t) {
          final status = t['status'] ?? 'pending';
          final statusColor = status == 'completed' ? AppColors.success : status == 'in_progress' ? AppColors.info : AppColors.warning;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
            child: Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.task_rounded, color: statusColor, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                  Text('Staff #${t['staff_id']} · Due: ${t['due_time'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor))),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showAssignTaskDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Assign Task'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ],
    );
  }

  /// Generates a simple temporary password from the staff's mobile number.
  /// Format: first 4 digits of mobile + "Staff@" → e.g. "9800Staff@"
  String _generateTempPassword(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    final prefix = digits.length >= 4 ? digits.substring(0, 4) : digits.padRight(4, '0');
    return '${prefix}Staff@';
  }

  /// Derives a staff email from mobile: staff_<mobile>@hotelsewa.com
  String _generateStaffEmail(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    return 'staff_$digits@hotelsewa.com';
  }

  void _showCredentialsDialog(String name, String email, String password, String mobile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Text('Staff Account Created', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Share these credentials with the staff member:', style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _CredRow(label: 'Name', value: name),
                const SizedBox(height: 8),
                _CredRow(label: 'Mobile', value: mobile),
                const SizedBox(height: 8),
                _CredRow(label: 'Login Email', value: email),
                const SizedBox(height: 8),
                _CredRow(label: 'Temp Password', value: password),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(child: Text('Staff should change their password after first login.', style: TextStyle(fontSize: 12, color: AppColors.warning))),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role = 'housekeeping';
    bool autoGenerate = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setModalState) {
          // Auto-fill email/password when mobile changes
          void onMobileChanged(String val) {
            if (autoGenerate) {
              emailCtrl.text = _generateStaffEmail(val);
              passwordCtrl.text = _generateTempPassword(val);
            }
          }

          return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Add Staff Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 4),
              const Text('Credentials will be shared with the staff to log into the Staff App.', style: TextStyle(fontSize: 12, color: AppColors.gray)),
              const SizedBox(height: 16),

              // Name
              TextField(controller: nameCtrl, decoration: InputDecoration(hintText: 'Full name', prefixIcon: const Icon(Icons.person_outline, color: AppColors.gray), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 12),

              // Mobile
              TextField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                onChanged: onMobileChanged,
                decoration: InputDecoration(hintText: 'Mobile number', prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.gray), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray))),
              ),
              const SizedBox(height: 12),

              // Role
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.work_outline_rounded, color: AppColors.gray), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray))),
                items: ['housekeeping', 'reception', 'maintenance', 'security', 'restaurant', 'management'].map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
                onChanged: (v) => setModalState(() => role = v ?? 'housekeeping'),
              ),
              const SizedBox(height: 16),

              // Credentials section
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lightGray)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Login Credentials', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                    Row(children: [
                      const Text('Auto-generate', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                      const SizedBox(width: 4),
                      Switch(
                        value: autoGenerate,
                        onChanged: (v) => setModalState(() {
                          autoGenerate = v;
                          if (v) onMobileChanged(mobileCtrl.text);
                        }),
                        activeColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ]),
                  ]),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    enabled: !autoGenerate,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(hintText: 'Staff login email', prefixIcon: const Icon(Icons.email_outlined, color: AppColors.gray, size: 18), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)), disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordCtrl,
                    enabled: !autoGenerate,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(hintText: 'Temporary password', prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.gray, size: 18), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)), disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || mobileCtrl.text.isEmpty) return;
                    final name = nameCtrl.text.trim();
                    final mobile = mobileCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final password = passwordCtrl.text.trim();
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post(ApiConfig.ownerStaffEndpoint, data: {
                      'name': name,
                      'role': role,
                      'mobile': mobile,
                      'email': email,
                      'password': password,
                    }, token: token);
                    _load();
                    // Show credentials dialog so owner can share them
                    if (mounted) _showCredentialsDialog(name, email, password, mobile);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Create Staff Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
        }),
      ),
    );
  }

  void _showAddShiftDialog() {
    final staffIdCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Add Shift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              TextField(controller: staffIdCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Staff ID', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: startCtrl, decoration: InputDecoration(hintText: 'Start (08:00)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray))))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: endCtrl, decoration: InputDecoration(hintText: 'End (16:00)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray))))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: dateCtrl, decoration: InputDecoration(hintText: 'Date (YYYY-MM-DD)', prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.gray), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post(ApiConfig.ownerStaffShiftsEndpoint, data: {'staff_id': int.tryParse(staffIdCtrl.text) ?? 0, 'shift_start': startCtrl.text, 'shift_end': endCtrl.text, 'date': dateCtrl.text}, token: token);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Add Shift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignTaskDialog() {
    final staffIdCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final dueCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Assign Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              TextField(controller: staffIdCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Staff ID', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: InputDecoration(hintText: 'Task title', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 12),
              TextField(controller: dueCtrl, decoration: InputDecoration(hintText: 'Due time (14:00)', prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.gray), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post(ApiConfig.ownerStaffTasksEndpoint, data: {'staff_id': int.tryParse(staffIdCtrl.text) ?? 0, 'title': titleCtrl.text, 'due_time': dueCtrl.text}, token: token);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Assign Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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

// ── Helper widget for credential rows ────────────────────────────────────────

class _CredRow extends StatelessWidget {
  final String label;
  final String value;
  const _CredRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGray),
          ),
        ),
      ],
    );
  }
}
