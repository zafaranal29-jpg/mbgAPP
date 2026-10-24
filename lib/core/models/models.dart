class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.namaLengkap,
    this.nisn,
    this.kelas,
    this.fotoProfil,
  });

  final int id;
  final String username;
  final String role; // siswa | dapur | admin
  final String namaLengkap;
  final String? nisn;
  final String? kelas;
  final String? fotoProfil;

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: (j['id'] as num).toInt(),
        username: j['username'] as String? ?? '',
        role: j['role'] as String? ?? 'siswa',
        namaLengkap:
            j['nama_lengkap'] as String? ?? (j['username'] as String? ?? ''),
        nisn: j['nisn'] as String?,
        kelas: j['kelas'] as String?,
        fotoProfil: j['foto_profil'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role,
        'nama_lengkap': namaLengkap,
        'nisn': nisn,
        'kelas': kelas,
        'foto_profil': fotoProfil,
      };

  String get firstName {
    final parts = namaLengkap.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? username : parts.first;
  }

  String get initials {
    final parts = namaLengkap
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class LoginResult {
  const LoginResult({required this.token, required this.user});
  final String token;
  final UserModel user;
}

class TodayMenu {
  const TodayMenu({
    required this.scheduleId,
    required this.tanggal,
    required this.nama,
    required this.deskripsi,
    required this.kalori,
    this.fotoUrl,
    this.warning = false,
    this.warningMessage,
    this.matchedAllergens = const [],
  });

  final int scheduleId;
  final String tanggal;
  final String nama;
  final String deskripsi;
  final int kalori;
  final String? fotoUrl;
  final bool warning;
  final String? warningMessage;
  final List<String> matchedAllergens;

  factory TodayMenu.fromJson(Map<String, dynamic> j) {
    final menu = (j['menu'] ?? j) as Map<String, dynamic>;
    return TodayMenu(
      scheduleId: (j['schedule_id'] as num?)?.toInt() ?? 0,
      tanggal: j['tanggal'] as String? ?? '',
      nama: menu['nama_menu'] as String? ?? '-',
      deskripsi: menu['deskripsi'] as String? ?? '',
      kalori: (menu['kalori'] as num?)?.toInt() ?? 0,
      fotoUrl: menu['foto_url'] as String?,
      warning: j['warning'] as bool? ?? false,
      warningMessage: j['warning_message'] as String?,
      matchedAllergens: ((j['matched_allergens'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class ClaimResult {
  const ClaimResult({
    required this.success,
    required this.message,
    required this.waktuClaim,
  });

  final bool success;
  final String message;
  final DateTime waktuClaim;
}

class KitchenQr {
  const KitchenQr({
    required this.qrToken,
    required this.tanggal,
    required this.isActive,
  });

  final String qrToken;
  final String tanggal;
  final bool isActive;

  KitchenQr copyWith({bool? isActive}) => KitchenQr(
        qrToken: qrToken,
        tanggal: tanggal,
        isActive: isActive ?? this.isActive,
      );

  factory KitchenQr.fromJson(Map<String, dynamic> j) => KitchenQr(
        qrToken: j['qr_token'] as String? ?? '',
        tanggal: j['tanggal'] as String? ?? '',
        isActive: j['is_active'] as bool? ?? true,
      );
}
