import 'package:flutter/material.dart';
import 'package:mbg_app/core/data/mock_store.dart';
import 'package:mbg_app/core/models/models.dart';
import 'package:mbg_app/core/network/api_client.dart';
import 'package:mbg_app/core/theme/app_colors.dart';
import 'package:mbg_app/core/utils/formatters.dart';
import 'package:mbg_app/core/widgets/app_widgets.dart';
import 'package:mbg_app/features/auth/controllers/auth_controller.dart';
import 'package:mbg_app/features/auth/presentation/logout_dialog.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Layar Dapur/Katering: QR harian, headcount presisi, log food waste.
class KitchenHomeScreen extends StatelessWidget {
  const KitchenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    return RoleTabScaffold(
      title: 'Dapur / Katering',
      subtitle: '${user.namaLengkap} • ${formatTanggal(DateTime.now())}',
      tabs: const ['QR Harian', 'Headcount', 'Food Waste'],
      onLogout: () => confirmLogout(context),
      children: const [_QrTab(), _HeadcountTab(), _WasteTab()],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: QR Code harian (GET /api/kitchen/qr-session)
// ---------------------------------------------------------------------------

class _QrTab extends StatefulWidget {
  const _QrTab();

  @override
  State<_QrTab> createState() => _QrTabState();
}

class _QrTabState extends State<_QrTab> {
  late Future<KitchenQr> _future;
  bool _renewing = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiClient>().getKitchenQrSession();
  }

  Future<void> _renew() async {
    setState(() => _renewing = true);
    try {
      final f = context.read<ApiClient>().getKitchenQrSession(renew: true);
      await f;
      if (!mounted) return;
      setState(() {
        _future = f;
        _renewing = false;
      });
      showSnack(context, 'QR Code baru berhasil dibuat');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _renewing = false);
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<KitchenQr>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: EmptyState(
              message: snap.error is ApiException
                  ? (snap.error as ApiException).message
                  : 'Gagal memuat QR Code.',
            ),
          );
        }
        final qr = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  StatusChip(
                    qr.isActive ? 'Sesi klaim aktif' : 'Tidak aktif',
                    color: qr.isActive ? AppColors.success : AppColors.danger,
                    icon: qr.isActive
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: qr.qrToken,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    qr.qrToken,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tanggal ${qr.tanggal}',
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tampilkan QR ini di meja dapur. Siswa memindainya lewat '
              'aplikasi MBG untuk mengklaim makanan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textGrey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Buat QR Baru',
              icon: Icons.refresh_rounded,
              loading: _renewing,
              onPressed: _renew,
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: Headcount (porsi normal vs substitusi alergi)
// ---------------------------------------------------------------------------

class _HeadcountTab extends StatelessWidget {
  const _HeadcountTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MockStore>();
    final sch = store.todaySchedule;
    final menu = sch == null ? null : store.menuById(sch.menuId);
    final subs = store.substitutionsToday;
    final total = store.students.length;
    final normal = total - subs.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.op(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.rice_bowl_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Menu hari ini',
                        style: TextStyle(
                            color: AppColors.textGrey, fontSize: 12)),
                    Text(
                      menu?.nama ?? 'Belum ada jadwal menu',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            StatCard(
                title: 'Total porsi',
                value: '$total',
                icon: Icons.groups_rounded),
            StatCard(
                title: 'Porsi normal',
                value: '$normal',
                icon: Icons.restaurant_rounded,
                color: AppColors.success),
            StatCard(
                title: 'Porsi substitusi',
                value: '${subs.length}',
                icon: Icons.health_and_safety_rounded,
                color: AppColors.warning),
            StatCard(
                title: 'Sudah klaim',
                value: '${store.successToday}',
                icon: Icons.how_to_reg_rounded,
                color: AppColors.accent),
          ],
        ),
        const SizedBox(height: 22),
        const SectionTitle('Siswa dengan Porsi Substitusi'),
        if (subs.isEmpty)
          const EmptyState(
            message: 'Tidak ada siswa yang perlu porsi substitusi hari ini.',
            icon: Icons.verified_rounded,
          )
        else
          ...subs.map((s) => AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    AvatarCircle(
                      initials: s.account.toUser().initials,
                      radius: 18,
                      ring: false,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.account.namaLengkap,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Kelas ${s.account.kelas ?? '-'}',
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(s.allergens.join(', '),
                        color: AppColors.warning),
                  ],
                ),
              )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Log food waste
// ---------------------------------------------------------------------------

class _WasteTab extends StatefulWidget {
  const _WasteTab();

  @override
  State<_WasteTab> createState() => _WasteTabState();
}

class _WasteTabState extends State<_WasteTab> {
  final _porsiC = TextEditingController();
  final _noteC = TextEditingController();

  @override
  void dispose() {
    _porsiC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  void _save() {
    final porsi = int.tryParse(_porsiC.text.trim());
    if (porsi == null || porsi < 0) {
      showSnack(context, 'Jumlah porsi sisa harus berupa angka', error: true);
      return;
    }
    context.read<MockStore>().addWaste(porsi, _noteC.text);
    _porsiC.clear();
    _noteC.clear();
    FocusScope.of(context).unfocus();
    showSnack(context, 'Log food waste tersimpan');
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MockStore>();
    final logs = store.wastes.reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catat sisa makanan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _porsiC,
                keyboardType: TextInputType.number,
                decoration: _dec('Jumlah porsi sisa'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteC,
                decoration: _dec('Catatan (opsional)'),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Simpan Log',
                icon: Icons.save_rounded,
                onPressed: _save,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StatCard(
          title: 'Total sisa hari ini (porsi)',
          value: '${store.wasteToday}',
          icon: Icons.delete_sweep_rounded,
          color: AppColors.danger,
        ),
        const SizedBox(height: 22),
        const SectionTitle('Riwayat Food Waste'),
        if (logs.isEmpty)
          const EmptyState(message: 'Belum ada log food waste.')
        else
          ...logs.map((w) => AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    StatusChip('${w.porsi} porsi', color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w.catatan.isEmpty ? '-' : w.catatan,
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    ),
                    Text(
                      '${formatTanggalPendek(w.waktu)} ${formatJam(w.waktu)}',
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 11),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
