/// Saklar utama aplikasi.
class AppConfig {
  AppConfig._();

  /// true  -> semua data dari MockStore (tanpa server, untuk demo/tugas)
  /// false -> memanggil REST API PHP lewat Dio (isi baseUrl di bawah)
  static const bool useMock = true;
}

/// Konstanta URL API (sesuai blueprint bagian V).
class Endpoints {
  Endpoints._();

  // Emulator Android: localhost PC = 10.0.2.2. HP asli: pakai IP laptop.
  static const String baseUrl = 'http://10.0.2.2:8000';

  static const String login = '/api/auth/login';
  static const String menuToday = '/api/menu/today';
  static const String kitchenQrSession = '/api/kitchen/qr-session';
  static const String claimSubmit = '/api/claim/submit';
  static const String reviewSubmit = '/api/review/submit';
}
