import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mbg_app/core/data/mock_store.dart';
import 'package:mbg_app/core/network/api_client.dart';
import 'package:mbg_app/core/network/endpoints.dart';
import 'package:mbg_app/core/theme/app_colors.dart';
import 'package:mbg_app/features/admin/presentation/admin_home_screen.dart';
import 'package:mbg_app/features/auth/controllers/auth_controller.dart';
import 'package:mbg_app/features/auth/presentation/login_screen.dart';
import 'package:mbg_app/features/auth/presentation/splash_screen.dart';
import 'package:mbg_app/features/dapur/presentation/kitchen_home_screen.dart';
import 'package:mbg_app/features/home/presentation/student_shell.dart';
import 'package:mbg_app/features/scanner/controllers/claim_controller.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = MockStore();
  final api = ApiClient(store: store, useMock: AppConfig.useMock);
  runApp(MyApp(store: store, api: api));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.store, required this.api});

  final MockStore store;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MockStore>.value(value: store),
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(api, store)..restore(),
        ),
        ChangeNotifierProvider<ClaimController>(
          create: (_) => ClaimController(api),
        ),
      ],
      child: MaterialApp(
        title: 'MBG',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.accent,
          ),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Mengarahkan ke layar sesuai peran (RBAC): siswa, dapur, admin.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (auth.restoring) return const SplashScreen();
    final user = auth.user;
    if (user == null) return const LoginScreen();
    switch (user.role) {
      case 'admin':
        return const AdminHomeScreen();
      case 'dapur':
        return const KitchenHomeScreen();
      default:
        return const StudentShell();
    }
  }
}
