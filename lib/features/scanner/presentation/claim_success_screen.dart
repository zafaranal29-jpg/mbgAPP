import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mbg_app/core/models/models.dart';
import 'package:mbg_app/core/theme/app_colors.dart';
import 'package:mbg_app/core/utils/formatters.dart';
import 'package:mbg_app/core/widgets/app_widgets.dart';
import 'package:mbg_app/core/widgets/edu_background.dart';

/// Layar hijau + foto profil + timer digital untuk verifikasi visual
/// langsung ke petugas dapur (blueprint bagian VI langkah 6).
class ClaimSuccessScreen extends StatefulWidget {
  const ClaimSuccessScreen({
    super.key,
    required this.user,
    required this.result,
  });

  final UserModel user;
  final ClaimResult result;

  @override
  State<ClaimSuccessScreen> createState() => _ClaimSuccessScreenState();
}

class _ClaimSuccessScreenState extends State<ClaimSuccessScreen> {
  late final Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.result.waktuClaim);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _elapsed = DateTime.now().difference(widget.result.waktuClaim);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final waktu = widget.result.waktuClaim;
    final info = [
      if (user.nisn != null) 'NISN ${user.nisn}',
      if (user.kelas != null) 'Kelas ${user.kelas}',
    ].join('  •  ');

    return Scaffold(
      body: EduBackground(
        gradient: AppColors.successGradient,
        patternOpacity: 0.09,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              children: [
                const Spacer(),
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 56),
                const SizedBox(height: 8),
                const Text(
                  'KLAIM BERHASIL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                AvatarCircle(
                  initials: user.initials,
                  radius: 62,
                  imageUrl: user.fotoProfil,
                ),
                const SizedBox(height: 16),
                Text(
                  user.namaLengkap,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (info.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    info,
                    style: TextStyle(color: Colors.white.op(0.9), fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.op(0.28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Waktu sejak klaim',
                        style: TextStyle(
                            color: Colors.white.op(0.85), fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDurasi(_elapsed),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Diklaim ${formatJam(waktu)} • ${formatTanggal(waktu)}',
                        style: TextStyle(
                            color: Colors.white.op(0.85), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Tunjukkan layar ini kepada petugas dapur',
                  style: TextStyle(color: Colors.white.op(0.9), fontSize: 12),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.successDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Selesai',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
