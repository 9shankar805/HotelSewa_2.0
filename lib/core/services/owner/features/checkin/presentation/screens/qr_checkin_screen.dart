import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/checkin_service.dart';
import '../../../../features/hotel/presentation/services/hotel_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../../../core/constants/app_colors.dart';

/// QR scanner screen for hotel owner to confirm guest check-in / check-out.
class QrCheckinScreen extends StatefulWidget {
  const QrCheckinScreen({Key? key}) : super(key: key);

  @override
  State<QrCheckinScreen> createState() => _QrCheckinScreenState();
}

class _QrCheckinScreenState extends State<QrCheckinScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _torchOn = false;
  String _mode = 'checkin'; // 'checkin' or 'checkout'
  String? _hotelId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHotelId());
  }

  Future<void> _loadHotelId() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      HotelService.setToken(auth.token ?? '');
      CheckinService.setToken(auth.token ?? '');
      final hotelService = HotelService();
      final response = await hotelService.getHotelStatus();
      if (response['success'] == true && response['data'] != null) {
        setState(() => _hotelId = response['data']['id']?.toString());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final qrToken = barcode!.rawValue!;
    setState(() => _isProcessing = true);
    await _scannerController.stop();

    try {
      Map<String, dynamic> response;
      if (_mode == 'checkin') {
        response = await CheckinService.confirmCheckin({
          'qr_token': qrToken,
          'hotel_id': _hotelId ?? '',
        });
      } else {
        response = await CheckinService.confirmCheckout({
          'qr_token': qrToken,
          'hotel_id': _hotelId ?? '',
        });
      }

      if (mounted) _showResultDialog(success: true, data: response);
    } catch (e) {
      if (mounted) _showResultDialog(success: false, error: e.toString());
    }
  }

  void _showResultDialog({
    required bool success,
    Map<String, dynamic>? data,
    String? error,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final action = _mode == 'checkin' ? 'Check-in' : 'Check-out';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 64,
              color: success
                  ? const Color(AppConstants.successGreen)
                  : const Color(AppConstants.errorRed),
            ),
            const SizedBox(height: 16),
            Text(
              success ? '$action Confirmed' : '$action Failed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (success && data != null) ...[
              _buildInfoRow('Guest', data['guest_name']?.toString() ?? '—'),
              _buildInfoRow('Room', data['room_number']?.toString() ?? '—'),
              _buildInfoRow('Booking', data['booking_id']?.toString() ?? '—'),
            ],
            if (!success)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: const Color(AppConstants.mediumGray)),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
              _scannerController.start();
            },
            child: const Text('Scan Again'),
          ),
          if (success)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryRed),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(color: Color(AppConstants.mediumGray))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR Check-in Scanner'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off,
                color: _torchOn ? Colors.yellow : Colors.white),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode toggle
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF111111),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Check-in',
                    icon: Icons.login_rounded,
                    selected: _mode == 'checkin',
                    onTap: () => setState(() => _mode = 'checkin'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeButton(
                    label: 'Check-out',
                    icon: Icons.logout_rounded,
                    selected: _mode == 'checkout',
                    onTap: () => setState(() => _mode = 'checkout'),
                  ),
                ),
              ],
            ),
          ),

          // Scanner viewport
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),

                // Overlay with scan frame
                _ScanOverlay(isProcessing: _isProcessing),

                // Processing indicator
                if (_isProcessing)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          ),

          // Bottom hint
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: Text(
              _mode == 'checkin'
                  ? 'Scan guest QR code to confirm check-in'
                  : 'Scan guest QR code to confirm check-out',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(AppConstants.primaryRed)
              : Colors.white12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Darkened overlay with a transparent scan window in the center.
class _ScanOverlay extends StatelessWidget {
  final bool isProcessing;
  const _ScanOverlay({required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(isProcessing: isProcessing),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final bool isProcessing;
  _OverlayPainter({required this.isProcessing});

  @override
  void paint(Canvas canvas, Size size) {
    const cutoutSize = 260.0;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutoutSize,
      height: cutoutSize,
    );

    // Dark overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.6),
    );

    // Corner brackets
    final bracketPaint = Paint()
      ..color = isProcessing ? AppColors.success : Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const bLen = 24.0;
    final l = cutoutRect.left;
    final t = cutoutRect.top;
    final r = cutoutRect.right;
    final b = cutoutRect.bottom;

    // Top-left
    canvas.drawLine(Offset(l, t + bLen), Offset(l, t), bracketPaint);
    canvas.drawLine(Offset(l, t), Offset(l + bLen, t), bracketPaint);
    // Top-right
    canvas.drawLine(Offset(r - bLen, t), Offset(r, t), bracketPaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + bLen), bracketPaint);
    // Bottom-left
    canvas.drawLine(Offset(l, b - bLen), Offset(l, b), bracketPaint);
    canvas.drawLine(Offset(l, b), Offset(l + bLen, b), bracketPaint);
    // Bottom-right
    canvas.drawLine(Offset(r - bLen, b), Offset(r, b), bracketPaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - bLen), bracketPaint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.isProcessing != isProcessing;
}
