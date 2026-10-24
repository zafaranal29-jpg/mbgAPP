import 'package:flutter/material.dart';
import 'package:mbg_app/core/network/api_client.dart';
import 'package:mbg_app/core/theme/app_colors.dart';
import 'package:mbg_app/core/widgets/app_widgets.dart';
import 'package:mbg_app/core/widgets/edu_background.dart';
import 'package:mbg_app/core/widgets/mbg_logo.dart';
import 'package:mbg_app/features/auth/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userC = TextEditingController();
  final _passC = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await context.read<AuthController>().login(_userC.text, _passC.text);
  }

  void _fill(String u, String p) {
    setState(() {
      _userC.text = u;
      _passC.text = p;
    });
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.op(0.7)),
      prefixIcon: Icon(icon, color: Colors.white),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.op(0.16),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: border(Colors.white.op(0.35)),
      enabledBorder: border(Colors.white.op(0.35)),
      focusedBorder: border(Colors.white, 1.6),
      errorBorder: border(const Color(0xFFFFD27A)),
      focusedErrorBorder: border(const Color(0xFFFFD27A), 1.6),
      errorStyle: const TextStyle(color: Color(0xFFFFD27A)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final useMock = context.read<ApiClient>().useMock;

    return Scaffold(
      body: EduBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MbgLogo(size: 96),
                    const SizedBox(height: 36),
                    const Text(
                      'Masuk ke akun Anda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gunakan akun yang diberikan sekolah',
                      style:
                          TextStyle(color: Colors.white.op(0.75), fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _userC,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('Username', Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Username wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passC,
                      obscureText: _obscure,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _dec(
                        'Password',
                        Icons.lock_outline,
                        suffix: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white.op(0.8),
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password wajib diisi'
                          : null,
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.op(0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: 'Masuk',
                      loading: auth.loading,
                      onPressed: _submit,
                    ),
                    if (useMock) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Mode demo: ketuk untuk mengisi akun contoh',
                        style: TextStyle(
                            color: Colors.white.op(0.75), fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _demoChip('Siswa', 'siswa1', 'siswa123'),
                          _demoChip('Dapur', 'dapur', 'dapur123'),
                          _demoChip('Admin', 'admin', 'admin123'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoChip(String label, String u, String p) => ActionChip(
        label: Text(label, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.white.op(0.18),
        side: BorderSide(color: Colors.white.op(0.35)),
        onPressed: () => _fill(u, p),
      );
}
