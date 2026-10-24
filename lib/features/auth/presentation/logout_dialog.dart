import 'package:flutter/material.dart';
import 'package:mbg_app/core/theme/app_colors.dart';
import 'package:mbg_app/features/auth/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

Future<void> confirmLogout(BuildContext context) async {
  final auth = context.read<AuthController>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Keluar dari akun?'),
      content: const Text('Anda perlu login kembali untuk memakai aplikasi.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Keluar',
              style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
  if (ok == true) await auth.logout();
}
