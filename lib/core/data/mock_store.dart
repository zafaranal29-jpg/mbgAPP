import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mbg_app/core/models/models.dart';
import 'package:mbg_app/core/utils/formatters.dart';

// ---------------------------------------------------------------------------
// Data class untuk mock (mencerminkan tabel di blueprint bagian IV)
// ---------------------------------------------------------------------------

class Allergy {
  const Allergy(this.id, this.nama);
  final int id;
  final String nama;
}

class MockAccount {
  MockAccount({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.namaLengkap,
    this.nisn,
    this.kelas,
    Set<int>? allergyIds,
  }) : allergyIds = allergyIds ?? <int>{};

  final int id;
  String username;
  String password;
  String role;
  String namaLengkap;
  String? nisn;
  String? kelas;
  Set<int> allergyIds;

  UserModel toUser() => UserModel(
        id: id,
        username: username,
        role: role,
        namaLengkap: namaLengkap,
        nisn: nisn,
        kelas: kelas,
      );
}

/// MOCK: kolom allergenIds hanya untuk simulasi pencocokan alergi
/// (skema blueprint belum punya tabel relasi menu-alergen).
class MenuData {
  MenuData({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.kalori,
    Set<int>? allergenIds,
  }) : allergenIds = allergenIds ?? <int>{};

  final int id;
  final String nama;
  final String deskripsi;
  final int kalori;
  final Set<int> allergenIds;
}

class ScheduleData {
  ScheduleData({required this.id, required this.tanggal, required this.menuId});
  final int id;
  final DateTime tanggal;
  int menuId;
}

class ClaimRecord {
  ClaimRecord({
    required this.studentId,
    required this.waktu,
    required this.success,
  });
  final int studentId;
  final DateTime waktu;
  final bool success;
}

class RatingRecord {
  RatingRecord({
    required this.studentId,
    required this.scheduleId,
    required this.score,
    this.review,
    required this.waktu,
  });
  final int studentId;
  final int scheduleId;
  final int score;
  final String? review;
  final DateTime waktu;
}

class WasteRecord {
  WasteRecord({required this.waktu, required this.porsi, required this.catatan});
  final DateTime waktu;
  final int porsi;
  final String catatan;
}

class SubstitutionInfo {
  SubstitutionInfo(this.account, this.allergens);
  final MockAccount account;
  final List<String> allergens;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ---------------------------------------------------------------------------
// MockStore: "database" lokal in-memory
// ---------------------------------------------------------------------------

class MockStore extends ChangeNotifier {
  MockStore() {
    _seed();
  }

  /// Simulasi validasi backend: klaim hanya saat jam istirahat.
  /// Default dimatikan supaya mudah didemokan kapan saja.
  bool enforceBreakTime = false;
  static const int breakStartMinute = 9 * 60 + 30; // 09:30
  static const int breakEndMinute = 14 * 60; // 14:00

  final List<Allergy> allergies = [];
  final List<MockAccount> accounts = [];
  final List<MenuData> menus = [];
  final List<ScheduleData> schedules = [];
  final List<KitchenQr> _qrSessions = [];
  final List<ClaimRecord> claims = [];
  final List<RatingRecord> ratings = [];
  final List<WasteRecord> wastes = [];

  int _nextAccountId = 1;
  int _nextMenuId = 1;
  int _nextScheduleId = 1;
  final Random _rng = Random();

  // ---- seed ---------------------------------------------------------------

  void _seed() {
    allergies.addAll(const [
      Allergy(1, 'Kacang'),
      Allergy(2, 'Susu'),
      Allergy(3, 'Telur'),
      Allergy(4, 'Seafood'),
      Allergy(5, 'Gluten'),
    ]);

    addMenu(
      nama: 'Nasi Ayam Panggang Tumis Bayam',
      deskripsi:
          'Nasi putih, ayam panggang bumbu kecap, tumis bayam, dan jeruk. '
          'Protein 24 g, karbohidrat 68 g, lemak 12 g.',
      kalori: 520,
    );
    addMenu(
      nama: 'Nasi Telur Balado Buncis Wortel',
      deskripsi:
          'Nasi putih, telur balado, tumis buncis wortel, dan pisang. '
          'Protein 18 g, karbohidrat 72 g, lemak 14 g.',
      kalori: 480,
      allergenIds: {3},
    );
    addMenu(
      nama: 'Nasi Ikan Goreng Sayur Sop',
      deskripsi:
          'Nasi putih, ikan kembung goreng, sayur sop, dan semangka. '
          'Protein 26 g, karbohidrat 64 g, lemak 11 g.',
      kalori: 510,
      allergenIds: {4},
    );
    addMenu(
      nama: 'Mie Gandum Ayam Brokoli + Susu',
      deskripsi:
          'Mie gandum, ayam suwir, brokoli, dan segelas susu. '
          'Protein 25 g, karbohidrat 70 g, lemak 15 g.',
      kalori: 540,
      allergenIds: {2, 5},
    );
    addMenu(
      nama: 'Nasi Pecel Tahu Tempe',
      deskripsi:
          'Nasi putih, sayur pecel bumbu kacang, tahu-tempe goreng, dan jeruk. '
          'Protein 22 g, karbohidrat 66 g, lemak 16 g.',
      kalori: 500,
      allergenIds: {1},
    );

    final today = DateTime.now();
    for (var i = -2; i <= 4; i++) {
      final d = DateTime(today.year, today.month, today.day)
          .add(Duration(days: i));
      setSchedule(d, menus[(i + 2) % menus.length].id);
    }

    addAccount(
        username: 'admin',
        password: 'admin123',
        role: 'admin',
        namaLengkap: 'Administrator Sekolah');
    addAccount(
        username: 'dapur',
        password: 'dapur123',
        role: 'dapur',
        namaLengkap: 'Petugas Dapur Katering');
    addAccount(
        username: 'siswa1',
        password: 'siswa123',
        role: 'siswa',
        namaLengkap: 'Ahmad Fauzi',
        nisn: '0051234567',
        kelas: 'X-A',
        allergyIds: {1});
    addAccount(
        username: 'siswa2',
        password: 'siswa123',
        role: 'siswa',
        namaLengkap: 'Siti Nurhaliza',
        nisn: '0051234568',
        kelas: 'X-B',
        allergyIds: {3});
    addAccount(
        username: 'siswa3',
        password: 'siswa123',
        role: 'siswa',
        namaLengkap: 'Budi Santoso',
        nisn: '0051234569',
        kelas: 'XI-A',
        allergyIds: {4, 2});
    addAccount(
        username: 'siswa4',
        password: 'siswa123',
        role: 'siswa',
        namaLengkap: 'Dewi Lestari',
        nisn: '0051234570',
        kelas: 'XI-B');
    addAccount(
        username: 'siswa5',
        password: 'siswa123',
        role: 'siswa',
        namaLengkap: 'Rizky Ramadhan',
        nisn: '0051234571',
        kelas: 'XII-A',
        allergyIds: {5});

    // Data awal agar halaman monitoring tidak kosong.
    final now = DateTime.now();
    claims.add(ClaimRecord(studentId: 6, waktu: now, success: true));
    claims.add(ClaimRecord(studentId: 7, waktu: now, success: true));
    ratings.add(RatingRecord(
        studentId: 6,
        scheduleId: schedules[0].id,
        score: 5,
        review: 'Enak dan porsinya pas!',
        waktu: now.subtract(const Duration(days: 2))));
    ratings.add(RatingRecord(
        studentId: 7,
        scheduleId: schedules[1].id,
        score: 4,
        review: 'Sayurnya segar.',
        waktu: now.subtract(const Duration(days: 1))));
    wastes.add(WasteRecord(
        waktu: now.subtract(const Duration(days: 1)),
        porsi: 6,
        catatan: 'Sisa sayur bayam'));
  }

  // ---- akun ---------------------------------------------------------------

  List<MockAccount> get students =>
      accounts.where((a) => a.role == 'siswa').toList();

  MockAccount? accountById(int id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  MockAccount? authenticate(String username, String password) {
    for (final a in accounts) {
      if (a.username.toLowerCase() == username.toLowerCase() &&
          a.password == password) {
        return a;
      }
    }
    return null;
  }

  bool usernameTaken(String username, {int? exceptId}) => accounts.any((a) =>
      a.username.toLowerCase() == username.toLowerCase() && a.id != exceptId);

  MockAccount addAccount({
    required String username,
    required String password,
    required String role,
    required String namaLengkap,
    String? nisn,
    String? kelas,
    Set<int>? allergyIds,
  }) {
    final acc = MockAccount(
      id: _nextAccountId++,
      username: username,
      password: password,
      role: role,
      namaLengkap: namaLengkap,
      nisn: nisn,
      kelas: kelas,
      allergyIds: allergyIds,
    );
    accounts.add(acc);
    notifyListeners();
    return acc;
  }

  void updateAccount(MockAccount acc) => notifyListeners();

  void deleteAccount(int id) {
    accounts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void setAllergies(int studentId, Set<int> ids) {
    final acc = accountById(studentId);
    if (acc == null) return;
    acc.allergyIds = Set<int>.from(ids);
    notifyListeners();
  }

  String allergyName(int id) {
    for (final a in allergies) {
      if (a.id == id) return a.nama;
    }
    return '?';
  }

  // ---- menu & jadwal ------------------------------------------------------

  MenuData addMenu({
    required String nama,
    required String deskripsi,
    required int kalori,
    Set<int>? allergenIds,
  }) {
    final m = MenuData(
      id: _nextMenuId++,
      nama: nama,
      deskripsi: deskripsi,
      kalori: kalori,
      allergenIds: allergenIds,
    );
    menus.add(m);
    notifyListeners();
    return m;
  }

  MenuData menuById(int id) => menus.firstWhere((m) => m.id == id);

  void setSchedule(DateTime date, int menuId) {
    final idx = schedules.indexWhere((s) => _sameDay(s.tanggal, date));
    if (idx >= 0) {
      schedules[idx].menuId = menuId;
    } else {
      schedules.add(ScheduleData(
        id: _nextScheduleId++,
        tanggal: DateTime(date.year, date.month, date.day),
        menuId: menuId,
      ));
    }
    notifyListeners();
  }

  List<ScheduleData> get sortedSchedules {
    final list = List<ScheduleData>.from(schedules);
    list.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    return list;
  }

  ScheduleData? get todaySchedule {
    final now = DateTime.now();
    for (final s in schedules) {
      if (_sameDay(s.tanggal, now)) return s;
    }
    return null;
  }

  /// Setara GET /api/menu/today (lengkap dengan warning alergi).
  TodayMenu? todayMenuFor(int userId) {
    final sch = todaySchedule;
    if (sch == null) return null;
    final menu = menuById(sch.menuId);
    final acc = accountById(userId);
    final matched = acc == null
        ? <String>[]
        : menu.allergenIds
            .where(acc.allergyIds.contains)
            .map(allergyName)
            .toList();
    return TodayMenu(
      scheduleId: sch.id,
      tanggal: isoDate(sch.tanggal),
      nama: menu.nama,
      deskripsi: menu.deskripsi,
      kalori: menu.kalori,
      warning: matched.isNotEmpty,
      warningMessage: matched.isEmpty
          ? null
          : 'Menu ini mengandung ${matched.join(', ')}. '
              'Anda akan mendapat porsi substitusi dari dapur.',
      matchedAllergens: matched,
    );
  }

  // ---- QR dapur -----------------------------------------------------------

  /// Setara GET /api/kitchen/qr-session.
  KitchenQr get activeQr {
    final today = isoDate(DateTime.now());
    for (final q in _qrSessions.reversed) {
      if (q.isActive && q.tanggal == today) return q;
    }
    return generateQr();
  }

  KitchenQr generateQr() {
    final today = isoDate(DateTime.now());
    for (var i = 0; i < _qrSessions.length; i++) {
      _qrSessions[i] = _qrSessions[i].copyWith(isActive: false);
    }
    final suffix = (1000 + _rng.nextInt(9000)).toString();
    final qr = KitchenQr(
      qrToken: 'MBG-${today.replaceAll('-', '')}-$suffix',
      tanggal: today,
      isActive: true,
    );
    _qrSessions.add(qr);
    notifyListeners();
    return qr;
  }

  // ---- klaim --------------------------------------------------------------

  bool hasClaimedToday(int studentId) => claims.any((c) =>
      c.studentId == studentId && c.success && _sameDay(c.waktu, DateTime.now()));

  List<ClaimRecord> get claimsToday =>
      claims.where((c) => _sameDay(c.waktu, DateTime.now())).toList();

  int get successToday => claimsToday.where((c) => c.success).length;
  int get rejectedToday => claimsToday.where((c) => !c.success).length;

  bool _inBreakTime(DateTime t) {
    final m = t.hour * 60 + t.minute;
    return m >= breakStartMinute && m <= breakEndMinute;
  }

  /// Setara POST /api/claim/submit (validasi token, jam istirahat, duplikasi).
  ClaimResult submitClaim(int studentId, String token) {
    final now = DateTime.now();
    final qr = activeQr;
    String? reason;
    if (qr.qrToken != token || !qr.isActive) {
      reason = 'QR Code tidak valid atau sudah kedaluwarsa.';
    } else if (enforceBreakTime && !_inBreakTime(now)) {
      reason = 'Klaim hanya dapat dilakukan pada jam istirahat.';
    } else if (hasClaimedToday(studentId)) {
      reason = 'Anda sudah melakukan klaim makanan hari ini.';
    }
    final ok = reason == null;
    claims.add(ClaimRecord(studentId: studentId, waktu: now, success: ok));
    notifyListeners();
    return ClaimResult(
      success: ok,
      message: reason ?? 'Klaim berhasil.',
      waktuClaim: now,
    );
  }

  // ---- rating -------------------------------------------------------------

  void submitReview({
    required int studentId,
    required int scheduleId,
    required int score,
    String? review,
  }) {
    ratings.removeWhere(
        (r) => r.studentId == studentId && r.scheduleId == scheduleId);
    ratings.add(RatingRecord(
      studentId: studentId,
      scheduleId: scheduleId,
      score: score,
      review: review,
      waktu: DateTime.now(),
    ));
    notifyListeners();
  }

  double get averageRating => ratings.isEmpty
      ? 0
      : ratings.fold<int>(0, (a, r) => a + r.score) / ratings.length;

  // ---- headcount & food waste --------------------------------------------

  List<SubstitutionInfo> get substitutionsToday {
    final sch = todaySchedule;
    if (sch == null) return [];
    final menu = menuById(sch.menuId);
    final out = <SubstitutionInfo>[];
    for (final s in students) {
      final hit = menu.allergenIds.where(s.allergyIds.contains).toList();
      if (hit.isNotEmpty) {
        out.add(SubstitutionInfo(s, hit.map(allergyName).toList()));
      }
    }
    return out;
  }

  void addWaste(int porsi, String catatan) {
    wastes.add(WasteRecord(
        waktu: DateTime.now(), porsi: porsi, catatan: catatan.trim()));
    notifyListeners();
  }

  int get wasteToday => wastes
      .where((w) => _sameDay(w.waktu, DateTime.now()))
      .fold<int>(0, (a, w) => a + w.porsi);
}
