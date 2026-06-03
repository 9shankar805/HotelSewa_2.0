import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class SmartRoomScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const SmartRoomScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<SmartRoomScreen> createState() => _SmartRoomScreenState();
}

class _SmartRoomScreenState extends State<SmartRoomScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String _lights = 'on';
  double _acTemp = 22;
  String _tv = 'off';
  bool _dnd = false;

  int get _bookingId => widget.arguments?['booking_id'] ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get('${ApiConfig.digitalKeyMyEndpoint.replaceAll('/digital-key/my', '')}/smart-room/$_bookingId', token: token);
      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map) {
          _lights = data['lights'] ?? 'on';
          _acTemp = (data['ac_temperature'] as num?)?.toDouble() ?? 22;
          _tv = data['tv'] ?? 'off';
          _dnd = data['dnd'] == true;
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      await ApiService.put(
        '/smart-room/$_bookingId',
        data: {'lights': _lights, 'ac_temperature': _acTemp.toInt(), 'tv': _tv, 'dnd': _dnd},
        token: token,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room settings updated'), backgroundColor: AppColors.success),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Smart Room', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: true,
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            IconButton(icon: const Icon(Icons.save_rounded, color: Colors.white), onPressed: _save),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // DND toggle — prominent
                  _buildDndCard(),
                  const SizedBox(height: 16),

                  // Lights
                  _buildControlCard(
                    icon: Icons.lightbulb_rounded,
                    title: 'Lights',
                    color: const Color(0xFFFFB800),
                    child: Row(
                      children: ['on', 'dim', 'off'].map((v) {
                        final selected = _lights == v;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _lights = v),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFFFFB800) : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(v[0].toUpperCase() + v.substring(1), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.black : Colors.white70)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // AC Temperature
                  _buildControlCard(
                    icon: Icons.ac_unit_rounded,
                    title: 'AC Temperature',
                    color: const Color(0xFF38BDF8),
                    child: Column(
                      children: [
                        Text('${_acTemp.toInt()}°C', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
                        Slider(
                          value: _acTemp,
                          min: 16,
                          max: 30,
                          divisions: 14,
                          activeColor: const Color(0xFF38BDF8),
                          inactiveColor: Colors.white.withOpacity(0.2),
                          onChanged: (v) => setState(() => _acTemp = v),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('16°C', style: TextStyle(fontSize: 11, color: Colors.white54)),
                            const Text('30°C', style: TextStyle(fontSize: 11, color: Colors.white54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TV
                  _buildControlCard(
                    icon: Icons.tv_rounded,
                    title: 'Television',
                    color: const Color(0xFF818CF8),
                    child: Row(
                      children: ['on', 'off'].map((v) {
                        final selected = _tv == v;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tv = v),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF818CF8) : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(v == 'on' ? Icons.power_settings_new_rounded : Icons.power_off_rounded, size: 16, color: selected ? Colors.white : Colors.white54),
                                  const SizedBox(width: 6),
                                  Text(v[0].toUpperCase() + v.substring(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.white54)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Apply Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDndCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _dnd ? AppColors.error.withOpacity(0.2) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _dnd ? AppColors.error.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _dnd ? AppColors.error.withOpacity(0.2) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.do_not_disturb_on_rounded, color: _dnd ? AppColors.error : Colors.white54, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Do Not Disturb', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(_dnd ? 'Active — staff will not enter' : 'Inactive', style: TextStyle(fontSize: 12, color: _dnd ? AppColors.error : Colors.white54)),
          ])),
          Switch(
            value: _dnd,
            onChanged: (v) => setState(() => _dnd = v),
            activeColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard({required IconData icon, required String title, required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
