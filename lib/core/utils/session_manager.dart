import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mbg_app/core/models/models.dart';

/// Wrapper flutter_secure_storage untuk token/JWT & data sesi.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _kToken = 'auth_token';
  static const String _kUser = 'auth_user';

  Future<void> saveSession(String token, UserModel user) async {
    try {
      await _storage.write(key: _kToken, value: token);
      await _storage.write(key: _kUser, value: jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _kToken);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getUser() async {
    try {
      final raw = await _storage.read(key: _kUser);
      if (raw == null) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kUser);
    } catch (_) {}
  }
}
