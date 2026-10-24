import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mbg_app/core/data/mock_store.dart';
import 'package:mbg_app/core/theme/app_colors.dart';
import 'package:mbg_app/core/utils/formatters.dart';
import 'package:mbg_app/core/widgets/app_widgets.dart';
import 'package:mbg_app/features/auth/controllers/auth_controller.dart';
import 'package:mbg_app/features/auth/presentation/logout_dialog.dart';
import 'package:provider/provider.dart';

/// Layar Admin Sekolah: kelola pengguna, menu & jadwal, monitoring.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    return RoleTabScaffold(
      title: 'Admin Sekolah',
      subtitle: '${user.namaLengkap} • ${formatTanggal(DateTime.now())}',
      tabs: const ['Pengguna', 'Menu', 'Monitoring'],
      onLogout: () => confirmLogout(context),
      children: const [_UsersTab(), _MenuTab(), _MonitoringTab()],
    );
  }
}

InputDecoration _fieldDec(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );

// ---------------------------------------------------------------------------
// Tab 1: Manajemen user (CRUD siswa & petugas dapur)
// ---------------------------------------------------------------------------

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  Future<void> _delete(BuildContext context, MockAccount a) async {
    final store = context.read<MockStore>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus pengguna?'),
        content: Text('${a.namaLengkap} akan dihapus dari sistem.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      store.deleteAccount(a.id);
      if (context.mounted) showSnack(context, 'Pengguna dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MockStore>();
    final users = store.accounts.where((a) => a.role != 'admin').toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PrimaryButton(
          label: 'Tambah Pengguna',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const _UserFormDialog(),
          ),
        ),
        const SizedBox(height: 18),
        SectionTitle('Daftar Pengguna (${users.length})'),
        if (users.isEmpty)
          const EmptyState(message: 'Belum ada pengguna.')
        else
          ...users.map((a) {
            final isSiswa = a.role == 'siswa';
            return AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  AvatarCircle(
                    initials: a.toUser().initials,
                    radius: 20,
                    ring: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.namaLengkap,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          isSiswa
                              ? '@${a.username} • ${a.kelas ?? '-'} • ${a.nisn ?? '-'}'
                              : '@${a.username}',
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        StatusChip(
                          isSiswa ? 'Siswa' : 'Dapur',
                          color:
                              isSiswa ? AppColors.primary : AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        showDialog<void>(
                          context: context,
                          builder: (_) => _UserFormDialog(account: a),
                        );
                      } else {
                        _delete(context, a);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Ubah')),
                      PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({this.account});
  final MockAccount? account;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC;
  late final TextEditingController _userC;
  late final TextEditingController _passC;
  late final TextEditingController _nisnC;
  late final TextEditingController _kelasC;
  String _role = 'siswa';

  bool get _editing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameC = TextEditingController(text: a?.namaLengkap ?? '');
    _userC = TextEditingController(text: a?.username ?? '');
    _passC = TextEditingController();
    _nisnC = TextEditingController(text: a?.nisn ?? '');
    _kelasC = TextEditingController(text: a?.kelas ?? '');
    _role = a?.role ?? 'siswa';
  }

  @override
  void dispose() {
    _nameC.dispose();
    _userC.dispose();
    _passC.dispose();
    _nisnC.dispose();
    _kelasC.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = context.read<MockStore>();
    final isSiswa = _role == 'siswa';
    final nisn = isSiswa ? _nisnC.text.trim() : null;
    final kelas = isSiswa ? _kelasC.text.trim() : null;

    if (_editing) {
      final a = widget.account!;
      a.username = _userC.text.trim();
      a.namaLengkap = _nameC.text.trim();
      a.role = _role;
      a.nisn = nisn;
      a.kelas = kelas;
      if (_passC.text.isNotEmpty) a.password = _passC.text;
      store.updateAccount(a);
    } else {
      store.addAccount(
        username: _userC.text.trim(),
        password: _passC.text,
        role: _role,
        namaLengkap: _nameC.text.trim(),
        nisn: nisn,
        kelas: kelas,
      );
    }
    Navigator.pop(context);
    showSnack(context, _editing ? 'Pengguna diperbarui' : 'Pengguna ditambahkan');
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final store = context.read<MockStore>();
    final isSiswa = _role == 'siswa';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(_editing ? 'Ubah Pengguna' : 'Tambah Pengguna'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _role,
                decoration: _fieldDec('Peran'),
                items: const [
                  DropdownMenuItem(value: 'siswa', child: Text('Siswa')),
                  DropdownMenuItem(value: 'dapur', child: Text('Petugas Dapur')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'siswa'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameC,
                decoration: _fieldDec('Nama lengkap'),
                validator: (v) => _required(v, 'Nama'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _userC,
                decoration: _fieldDec('Username'),
                validator: (v) {
                  final r = _required(v, 'Username');
                  if (r != null) return r;
                  if (store.usernameTaken(v!.trim(),
                      exceptId: widget.account?.id)) {
                    return 'Username sudah dipakai';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passC,
                obscureText: true,
                decoration: _fieldDec(
                    _editing ? 'Password baru (opsional)' : 'Password'),
                validator: (v) {
                  if (_editing && (v == null || v.isEmpty)) return null;
                  if (v == null || v.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              if (isSiswa) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nisnC,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDec('NISN'),
                  validator: (v) => _required(v, 'NISN'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _kelasC,
                  decoration: _fieldDec('Kelas'),
                  validator: (v) => _required(v, 'Kelas'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: Menu harian & jadwal makanan
// ---------------------------------------------------------------------------

class _MenuTab extends StatelessWidget {
  const _MenuTab();

  Future<int?> _pickMenu(BuildContext context, MockStore store) {
    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pilih menu'),
        children: store.menus
            .map((m) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, m.id),
                  child: Text('${m.nama} • ${m.kalori} kkal'),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _addSchedule(BuildContext context) async {
    final store = context.read<MockStore>();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final menuId = await _pickMenu(context, store);
    if (menuId == null || !context.mounted) return;
    store.setSchedule(date, menuId);
    showSnack(context, 'Jadwal ${formatTanggal(date)} disimpan');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MockStore>();
    final items = store.sortedSchedules;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PrimaryButton(
          label: 'Tambah Jadwal Makan',
          icon: Icons.event_available_rounded,
          onPressed: () => _addSchedule(context),
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
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _MenuFormDialog(),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Menu Baru'),
          ),
        ),
        const SizedBox(height: 20),
        SectionTitle('Jadwal Makanan (${items.length})'),
        ...items.map((s) {
          final m = store.menuById(s.menuId);
          final isToday = s.tanggal.year == now.year &&
              s.tanggal.month == now.month &&
              s.tanggal.day == now.day;
          return AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isToday ? AppColors.buttonGradient : null,
                    color: isToday ? null : AppColors.primary.op(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${s.tanggal.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isToday ? Colors.white : AppColors.primary,
                        ),
                      ),
                      Text(
                        namaHari(s.tanggal).substring(0, 3),
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${m.kalori} kkal'
                        '${m.allergenIds.isEmpty ? '' : ' • Alergen: ${m.allergenIds.map(store.allergyName).join(', ')}'}',
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ganti menu',
                  icon: const Icon(Icons.edit_calendar_rounded,
                      color: AppColors.primary),
                  onPressed: () async {
                    final id = await _pickMenu(context, store);
                    if (id != null) store.setSchedule(s.tanggal, id);
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MenuFormDialog extends StatefulWidget {
  const _MenuFormDialog();

  @override
  State<_MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<_MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _descC = TextEditingController();
  final _kaloriC = TextEditingController();
  final Set<int> _allergens = {};

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    _kaloriC.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<MockStore>().addMenu(
          nama: _nameC.text.trim(),
          deskripsi: _descC.text.trim(),
          kalori: int.parse(_kaloriC.text.trim()),
          allergenIds: Set<int>.from(_allergens),
        );
    Navigator.pop(context);
    showSnack(context, 'Menu ditambahkan');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<MockStore>();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Tambah Menu'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameC,
                decoration: _fieldDec('Nama menu'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama menu wajib diisi'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descC,
                maxLines: 3,
                decoration: _fieldDec('Deskripsi & nilai gizi'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _kaloriC,
                keyboardType: TextInputType.number,
                decoration: _fieldDec('Kalori (kkal)'),
                validator: (v) =>
                    int.tryParse((v ?? '').trim()) == null
                        ? 'Kalori harus berupa angka'
                        : null,
              ),
              const SizedBox(height: 14),
              const Text('Mengandung alergen:',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: store.allergies.map((a) {
                  return FilterChip(
                    label: Text(a.nama),
                    selected: _allergens.contains(a.id),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _allergens.add(a.id);
                      } else {
                        _allergens.remove(a.id);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Monitoring distribusi & rating kepuasan
// ---------------------------------------------------------------------------

class _MonitoringTab extends StatelessWidget {
  const _MonitoringTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MockStore>();
    final total = store.students.length;
    final done = store.successToday;
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final recentClaims = store.claimsToday.reversed.take(6).toList();
    final reviews = store.ratings.reversed.take(6).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            StatCard(
                title: 'Klaim berhasil hari ini',
                value: '$done',
                icon: Icons.check_circle_rounded,
                color: AppColors.success),
            StatCard(
                title: 'Klaim ditolak',
                value: '${store.rejectedToday}',
                icon: Icons.cancel_rounded,
                color: AppColors.danger),
            StatCard(
                title: 'Total siswa',
                value: '$total',
                icon: Icons.groups_rounded),
            StatCard(
                title: 'Rata-rata rating',
                value: store.ratings.isEmpty
                    ? '-'
                    : store.averageRating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: AppColors.star),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Distribusi hari ini',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text('$done / $total siswa',
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.primary.op(0.1),
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Klaim Terbaru'),
        if (recentClaims.isEmpty)
          const EmptyState(message: 'Belum ada klaim hari ini.')
        else
          ...recentClaims.map((c) {
            final acc = store.accountById(c.studentId);
            return AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      acc?.namaLengkap ?? 'Siswa #${c.studentId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(formatJam(c.waktu),
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 12)),
                  const SizedBox(width: 10),
                  StatusChip(
                    c.success ? 'Berhasil' : 'Ditolak',
                    color: c.success ? AppColors.success : AppColors.danger,
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 18),
        const SectionTitle('Ulasan Kepuasan'),
        if (reviews.isEmpty)
          const EmptyState(message: 'Belum ada ulasan.')
        else
          ...reviews.map((r) {
            final acc = store.accountById(r.studentId);
            return AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          acc?.namaLengkap ?? 'Siswa #${r.studentId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      RatingBarIndicator(
                        rating: r.score.toDouble(),
                        itemCount: 5,
                        itemSize: 16,
                        itemBuilder: (context, _) => const Icon(
                            Icons.star_rounded,
                            color: AppColors.star),
                      ),
                    ],
                  ),
                  if (r.review != null && r.review!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      r.review!,
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
