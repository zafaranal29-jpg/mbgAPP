import 'package:flutter/material.dart';
import 'package:mbg_app/core/data/mock_store.dart';
import 'package:mbg_app/core/models/models.dart';
import 'package:mbg_app/core/network/api_client.dart';
import 'package:mbg_app/core/theme/app_colors.dart';
import 'package:mbg_app/core/utils/formatters.dart';
import 'package:mbg_app/core/widgets/app_widgets.dart';
import 'package:mbg_app/core/widgets/edu_background.dart';
import 'package:mbg_app/features/auth/controllers/auth_controller.dart';
import 'package:mbg_app/features/rating/presentation/rating_dialog.dart';
import 'package:mbg_app/features/scanner/controllers/claim_controller.dart';
import 'package:mbg_app/features/scanner/presentation/scanner_screen.dart';
import 'package:provider/provider.dart';

/// Beranda siswa: menu hari ini, nilai gizi/kalori, warning alergi, jadwal.
class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  late Future<TodayMenu> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiClient>().getMenuToday();
  }

  Future<void> _reload() async {
    final f = context.read<ApiClient>().getMenuToday();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    final claimed = context.watch<ClaimController>().hasClaimedToday(user.id);

    return EduBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      AvatarCircle(
                        initials: user.initials,
                        radius: 22,
                        imageUrl: user.fotoProfil,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hai, ${user.firstName}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              formatTanggal(DateTime.now()),
                              style: TextStyle(
                                color: Colors.white.op(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.op(0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.op(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          claimed
                              ? Icons.check_circle_rounded
                              : Icons.restaurant_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          claimed
                              ? 'Makan gratis hari ini sudah diklaim'
                              : 'Belum klaim makan gratis hari ini',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SheetContainer(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: FutureBuilder<TodayMenu>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return ListView(
                          children: const [
                            SizedBox(
                              height: 240,
                              child:
                                  Center(child: CircularProgressIndicator()),
                            ),
                          ],
                        );
                      }
                      if (snap.hasError) {
                        final msg = snap.error is ApiException
                            ? (snap.error as ApiException).message
                            : 'Gagal memuat menu.';
                        return ListView(
                          children: [
                            const SizedBox(height: 60),
                            EmptyState(
                              message: msg,
                              icon: Icons.no_meals_rounded,
                            ),
                            Center(
                              child: TextButton(
                                onPressed: _reload,
                                child: const Text('Muat ulang'),
                              ),
                            ),
                          ],
                        );
                      }
                      return _MenuContent(
                        menu: snap.data!,
                        claimed: claimed,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuContent extends StatelessWidget {
  const _MenuContent({required this.menu, required this.claimed});

  final TodayMenu menu;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final useMock = context.read<ApiClient>().useMock;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const SectionTitle('Menu Hari Ini'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.buttonGradient,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: EduPatternPainter(
                            opacity: 0.12, iconSize: 26, spacing: 56),
                      ),
                      const Center(
                        child: Icon(Icons.rice_bowl_rounded,
                            color: Colors.white, size: 64),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.nama,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        StatusChip(
                          '${menu.kalori} kkal',
                          color: AppColors.primary,
                          icon: Icons.local_fire_department_rounded,
                        ),
                        StatusChip(
                          'Menu bergizi',
                          color: AppColors.success,
                          icon: Icons.eco_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      menu.deskripsi,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (menu.warning) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.op(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warning.op(0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Peringatan Alergi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        menu.warningMessage ??
                            'Menu ini cocok dengan profil alergi Anda.',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          label: claimed ? 'Scan Ulang QR' : 'Scan QR untuk Klaim',
          icon: Icons.qr_code_scanner_rounded,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              final ok = await showRatingDialog(context, menu: menu);
              if (ok == true && context.mounted) {
                showSnack(context, 'Terima kasih atas penilaian Anda!');
              }
            },
            icon: const Icon(Icons.star_rounded),
            label: const Text('Beri Rating & Ulasan'),
          ),
        ),
        if (useMock) ...[
          const SizedBox(height: 26),
          const SectionTitle('Jadwal Menu'),
          SizedBox(
            height: 128,
            child: Consumer<MockStore>(
              builder: (context, store, _) {
                final items = store.sortedSchedules;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final s = items[i];
                    return _ScheduleCard(
                      schedule: s,
                      menu: store.menuById(s.menuId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.menu});

  final ScheduleData schedule;
  final MenuData menu;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = schedule.tanggal.year == now.year &&
        schedule.tanggal.month == now.month &&
        schedule.tanggal.day == now.day;
    final fg = today ? Colors.white : AppColors.textDark;

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12, bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: today ? AppColors.buttonGradient : null,
        color: today ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.op(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${namaHari(schedule.tanggal)}, ${formatTanggalPendek(schedule.tanggal)}',
            style: TextStyle(
              color: today ? Colors.white : AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              menu.nama,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${menu.kalori} kkal',
            style: TextStyle(
              color: today ? Colors.white.op(0.9) : AppColors.textGrey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
