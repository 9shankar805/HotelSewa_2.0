import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

class ICalSyncScreen extends StatefulWidget {
  const ICalSyncScreen({super.key});
  @override
  State<ICalSyncScreen> createState() => _ICalSyncScreenState();
}

class _ICalSyncScreenState extends State<ICalSyncScreen> {
  final List<Map<String, dynamic>> _channels = [
    {'id': 'airbnb', 'name': 'Airbnb', 'icon': Icons.home_rounded, 'color': Color(0xFFFF5A5F), 'connected': true, 'url': 'https://www.airbnb.com/calendar/ical/12345.ics', 'lastSync': '5 min ago', 'syncCount': 12},
    {'id': 'booking', 'name': 'Booking.com', 'icon': Icons.hotel_rounded, 'color': Color(0xFF003580), 'connected': false, 'url': '', 'lastSync': 'Never', 'syncCount': 0},
    {'id': 'expedia', 'name': 'Expedia', 'icon': Icons.flight_rounded, 'color': Color(0xFF00355F), 'connected': false, 'url': '', 'lastSync': 'Never', 'syncCount': 0},
    {'id': 'agoda', 'name': 'Agoda', 'icon': Icons.bed_rounded, 'color': Color(0xFFE31837), 'connected': false, 'url': '', 'lastSync': 'Never', 'syncCount': 0},
    {'id': 'custom', 'name': 'Custom iCal', 'icon': Icons.link_rounded, 'color': Color(AppConstants.mediumGray), 'connected': false, 'url': '', 'lastSync': 'Never', 'syncCount': 0},
  ];

  // My outgoing iCal URL (for guests to subscribe)
  final _myICalUrl = 'https://hotelsewa.com/calendar/ical/hotel-abc123.ics';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);
    final connectedCount = _channels.where((c) => c['connected'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Channel Sync (iCal)'),
        actions: [
          if (connectedCount > 0)
            TextButton.icon(
              onPressed: _syncAll,
              icon: const Icon(Icons.sync_rounded, size: 16, color: Color(AppConstants.primaryRed)),
              label: const Text('Sync All', style: TextStyle(color: Color(AppConstants.primaryRed), fontWeight: FontWeight.w600, fontSize: 13)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: connectedCount > 0 ? const Color(AppConstants.successGreen).withOpacity(0.08) : const Color(AppConstants.warningOrange).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (connectedCount > 0 ? const Color(AppConstants.successGreen) : const Color(AppConstants.warningOrange)).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(connectedCount > 0 ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                  color: connectedCount > 0 ? const Color(AppConstants.successGreen) : const Color(AppConstants.warningOrange), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    connectedCount > 0
                        ? '$connectedCount channel${connectedCount > 1 ? 's' : ''} connected. Availability syncs automatically every 15 minutes.'
                        : 'No channels connected. Connect OTAs to prevent double bookings.',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(AppConstants.darkGray)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // My iCal URL (outgoing)
          Text('Your iCal URL', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 6),
          const Text('Share this URL with any platform to sync your availability', style: TextStyle(fontSize: 12, color: Color(AppConstants.mediumGray))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: Color(AppConstants.primaryRed), size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_myICalUrl, style: const TextStyle(fontSize: 12, color: Color(AppConstants.mediumGray)), overflow: TextOverflow.ellipsis)),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _myICalUrl));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('iCal URL copied'), behavior: SnackBarBehavior.floating));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(AppConstants.primaryRed).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(AppConstants.primaryRed))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Channels
          Text('Connected Channels', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 10),
          ..._channels.map((c) => _channelCard(c, isDark, card, border)),
          const SizedBox(height: 20),

          // How it works
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How iCal Sync Works', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 12),
                _howStep('1', 'Paste the iCal URL from your OTA (Airbnb, Booking.com, etc.)'),
                _howStep('2', 'We import their bookings and block those dates automatically'),
                _howStep('3', 'Your availability stays in sync — no double bookings'),
                _howStep('4', 'Syncs every 15 minutes automatically'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _channelCard(Map<String, dynamic> c, bool isDark, Color card, Color border) {
    final connected = c['connected'] as bool;
    final color = c['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: connected ? color.withOpacity(0.3) : border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(c['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                      Text(connected ? 'Last sync: ${c['lastSync']} • ${c['syncCount']} bookings' : 'Not connected', style: const TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                    ],
                  ),
                ),
                if (connected)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _syncChannel(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.sync_rounded, size: 16, color: Color(AppConstants.mediumGray)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _disconnectChannel(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(AppConstants.errorRed).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Disconnect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(AppConstants.errorRed))),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: () => _connectChannel(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: const Color(AppConstants.primaryRed), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          if (connected) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 14, color: Color(AppConstants.mediumGray)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(c['url'] as String, style: const TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray)), overflow: TextOverflow.ellipsis)),
                  GestureDetector(
                    onTap: () => _editUrl(c),
                    child: const Icon(Icons.edit_outlined, size: 14, color: Color(AppConstants.mediumGray)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _howStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: const Color(AppConstants.primaryRed).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(num, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(AppConstants.primaryRed)))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(AppConstants.mediumGray), height: 1.4))),
        ],
      ),
    );
  }

  void _connectChannel(Map<String, dynamic> c) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connect ${c['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Paste the iCal URL from your ${c['name']} account', style: const TextStyle(color: Color(AppConstants.mediumGray), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'https://www.airbnb.com/calendar/ical/...',
                prefixIcon: const Icon(Icons.link_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(AppConstants.primaryRed), width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (ctrl.text.trim().isNotEmpty) {
                    setState(() { c['connected'] = true; c['url'] = ctrl.text.trim(); c['lastSync'] = 'Just now'; c['syncCount'] = 0; });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c['name']} connected'), backgroundColor: const Color(AppConstants.successGreen), behavior: SnackBarBehavior.floating));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.primaryRed), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: const Text('Connect & Sync', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editUrl(Map<String, dynamic> c) {
    final ctrl = TextEditingController(text: c['url'] as String);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit ${c['name']} URL', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: ctrl, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(AppConstants.primaryRed), width: 2)))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { setState(() => c['url'] = ctrl.text.trim()); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.primaryRed), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('Save'),
            )),
          ],
        ),
      ),
    );
  }

  void _disconnectChannel(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Disconnect ${c['name']}?'),
        content: const Text('Bookings from this channel will no longer sync.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); setState(() { c['connected'] = false; c['url'] = ''; c['lastSync'] = 'Never'; }); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.errorRed)),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  void _syncChannel(Map<String, dynamic> c) {
    setState(() => c['lastSync'] = 'Just now');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${c['name']} synced successfully'),
      backgroundColor: const Color(AppConstants.successGreen),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _syncAll() {
    for (final c in _channels.where((c) => c['connected'] == true)) {
      c['lastSync'] = 'Just now';
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('All channels synced'),
      backgroundColor: Color(AppConstants.successGreen),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
