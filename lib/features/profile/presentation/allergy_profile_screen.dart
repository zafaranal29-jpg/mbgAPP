import 'package:flutter/material.dart';
import 'package:mbg_app/core/data/mock_store.dart';
import 'package:mbg_app/core/theme/app_colors.dart';
import 'package:mbg_app/core/widgets/app_widgets.dart';
import 'package:mbg_app/core/widgets/edu_background.dart';
import 'package:mbg_app/features/auth/controllers/auth_controller.dart';
import 'package:mbg_app/features/auth/presentation/logout_dialog.dart';
import 'package:provider/provider.dart';

/// Profil siswa + pengelolaan profil alergi makanan.
/// Catatan: blueprint belum punya endpoint alergi, jadi data disimpan di
/// MockStore (nanti disambungkan ke tabel student_allergies).
class AllergyProfileScreen extends StatefulWidget {
  const AllergyProfileScreen({super.key});

  @override
  State<AllergyProfileScreen> createState() => _AllergyProfileScreenState();
}

class _AllergyProfileScreenState extends State<AllergyProfileScreen> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user!;
    final acc = context.read<MockStore>().accountById(user.id);
    _selected = Set<int>.from(acc?.allergyIds ?? <int>{});
  }

  void _save() {
    final user = context.read<AuthController>().user!;
    context.read<MockStore>().setAllergies(user.id, _selected);
    showSnack(context, 'Profil alergi berhasil disimpan');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    final store = context.read<MockStore>();

    return EduBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                children: [
                  AvatarCircle(
                    initials: user.initials,
                    radius: 40,
                    imageUrl: user.fotoProfil,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.namaLengkap,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (user.nisn != null) 'NISN ${user.nisn}',
                      if (user.kelas != null) 'Kelas ${user.kelas}',
                    ].join('  •  '),
                    style: TextStyle(color: Colors.white.op(0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SheetContainer(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                  children: [
                    const SectionTitle('Profil Alergi Makanan'),
                    const Text(
                      'Pilih alergi yang Anda miliki. Dapur akan menyiapkan '
                      'porsi substitusi dan Anda mendapat peringatan jika '
                      'menu hari ini mengandung alergen tersebut.',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: store.allergies.map((a) {
                          final on = _selected.contains(a.id);
                          return FilterChip(
                            label: Text(a.nama),
                            selected: on,
                            showCheckmark: true,
                            selectedColor: AppColors.accent.op(0.25),
                            checkmarkColor: AppColors.primary,
                            onSelected: (v) => setState(() {
                              if (v) {
                                _selected.add(a.id);
                              } else {
                                _selected.remove(a.id);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Simpan Profil Alergi',
                      icon: Icons.save_rounded,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => confirmLogout(context),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Keluar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
