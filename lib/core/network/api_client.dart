import 'package:dio/dio.dart';
import 'package:mbg_app/core/data/mock_store.dart';
import 'package:mbg_app/core/models/models.dart';
import 'package:mbg_app/core/network/endpoints.dart';
import 'package:mbg_app/core/utils/session_manager.dart';

/// Setup Dio & Interceptors. Mode mock/real diatur lewat [AppConfig.useMock].
class ApiClient {
  ApiClient({required this.store, this.useMock = true}) {
    _dio = Dio(BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SessionManager.instance.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  final MockStore store;
  final bool useMock;
  late final Dio _dio;
  UserModel? _currentUser; // dipakai mode mock untuk mengenali sesi

  void setCurrentUser(UserModel? user) => _currentUser = user;

  Future<void> _delay([int ms = 450]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Tidak dapat terhubung ke server.';
    }
    return 'Terjadi kesalahan pada server.';
  }

  UserModel _requireUser() {
    final u = _currentUser;
    if (u == null) throw ApiException('Sesi berakhir. Silakan login ulang.');
    return u;
  }

  // POST /api/auth/login ----------------------------------------------------
  Future<LoginResult> login(String username, String password) async {
    if (useMock) {
      await _delay();
      final acc = store.authenticate(username, password);
      if (acc == null) throw ApiException('Username atau password salah.');
      final user = acc.toUser();
      _currentUser = user;
      return LoginResult(token: 'mock-token-${acc.id}', user: user);
    }
    try {
      final res = await _dio.post(Endpoints.login,
          data: {'username': username, 'password': password});
      final data = res.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _currentUser = user;
      return LoginResult(token: data['token'] as String, user: user);
    } on DioException catch (e) {
      throw ApiException(_msg(e));
    }
  }

  // GET /api/menu/today -----------------------------------------------------
  Future<TodayMenu> getMenuToday() async {
    if (useMock) {
      await _delay(350);
      final menu = store.todayMenuFor(_requireUser().id);
      if (menu == null) throw ApiException('Belum ada menu untuk hari ini.');
      return menu;
    }
    try {
      final res = await _dio.get(Endpoints.menuToday);
      return TodayMenu.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_msg(e));
    }
  }

  // GET /api/kitchen/qr-session ---------------------------------------------
  Future<KitchenQr> getKitchenQrSession({bool renew = false}) async {
    if (useMock) {
      await _delay(300);
      return renew ? store.generateQr() : store.activeQr;
    }
    try {
      final res = await _dio.get(Endpoints.kitchenQrSession);
      return KitchenQr.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_msg(e));
    }
  }

  // POST /api/claim/submit --------------------------------------------------
  Future<ClaimResult> submitClaim({
    required int studentId,
    required String qrToken,
  }) async {
    if (useMock) {
      await _delay(600);
      return store.submitClaim(studentId, qrToken);
    }
    try {
      final res = await _dio.post(Endpoints.claimSubmit,
          data: {'student_id': studentId, 'qr_token': qrToken});
      final data = res.data as Map<String, dynamic>;
      final ok = data['status'] == 'success';
      return ClaimResult(
        success: ok,
        message: data['message'] as String? ??
            (ok ? 'Klaim berhasil.' : 'Klaim ditolak.'),
        waktuClaim: DateTime.tryParse(data['waktu_claim'] as String? ?? '') ??
            DateTime.now(),
      );
    } on DioException catch (e) {
      throw ApiException(_msg(e));
    }
  }

  // POST /api/review/submit -------------------------------------------------
  Future<void> submitReview({
    required int scheduleId,
    required int score,
    String? reviewText,
  }) async {
    if (useMock) {
      await _delay(500);
      store.submitReview(
        studentId: _requireUser().id,
        scheduleId: scheduleId,
        score: score,
        review: reviewText,
      );
      return;
    }
    try {
      await _dio.post(Endpoints.reviewSubmit, data: {
        'schedule_id': scheduleId,
        'score': score,
        'review_text': reviewText,
      });
    } on DioException catch (e) {
      throw ApiException(_msg(e));
    }
  }
}
