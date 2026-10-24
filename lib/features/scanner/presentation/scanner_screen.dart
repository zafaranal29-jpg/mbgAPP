import 'package:flutter/material.dart';
import 'package:mbg_app/core/data/mock_store.dart';
import 'package:mbg_app/core/network/api_client.dart';
import 'package:mbg_app/core/theme/app_colors.dart';
import 'package:mbg_app/core/widgets/app_widgets.dart';
import 'package:mbg_app/features/auth/controllers/auth_controller.dart';
import 'package:mbg_app/features/scanner/controllers/claim_controller.dart';
import 'package:mbg_app/features/scanner/presentation/claim_success_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy) return;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) {
        _handleToken(v);
        break;
      }
    }
  }

  Future<void> _handleToken(String token) async {
    if (_busy) return;
    setState(() => _busy = true);

    final user = context.read<AuthController>().user!;
    final result = await context
        .read<ClaimController>()
        .submit(studentId: user.id, qrToken: token);
    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ClaimSuccessScreen(user: user, result: result),
      ));
    } else {
      await _showRejected(result.message);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showRejected(String message) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.op(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.danger, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'Klaim Ditolak',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDark),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Coba Lagi',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useMock = context.read<ApiClient>().useMock;
    final store = context.read<MockStore>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _ScanOverlay())),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'Scan QR Dapur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Senter',
                        onPressed: () => _controller.toggleTorch(),
                        icon: const Icon(Icons.flashlight_on_rounded,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.op(0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Arahkan kamera ke QR Code di meja dapur untuk klaim makanan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                if (useMock) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        onPressed:
                            _busy ? null : () => _handleToken(store.activeQr.qrToken),
                        child: const Text('Simulasi scan'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        onPressed: _busy ? null : () => _handleToken('QR-SALAH'),
                        child: const Text('Simulasi QR salah'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_busy)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: 250,
      height: 250,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final scrim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(scrim, Paint()..color = Colors.black.op(0.55));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
