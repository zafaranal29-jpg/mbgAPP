import 'package:flutter/foundation.dart';
import 'package:mbg_app/core/data/mock_store.dart';
import 'package:mbg_app/core/models/models.dart';
import 'package:mbg_app/core/network/api_client.dart';
import 'package:mbg_app/core/utils/session_manager.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._api, this._store);

  final ApiClient _api;
  final MockStore _store;

  UserModel? _user;
  bool _loading = false;
  bool _restoring = true;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get restoring => _restoring;
  String? get error => _error;

  /// Pulihkan sesi dari flutter_secure_storage saat app dibuka.
  Future<void> restore() async {
    final token = await SessionManager.instance.getToken();
    final saved = await SessionManager.instance.getUser();
    if (token != null && saved != null) {
      if (_api.useMock && _store.accountById(saved.id) == null) {
        await SessionManager.instance.clear();
      } else {
        _user = saved;
        _api.setCurrentUser(saved);
      }
    }
    _restoring = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.login(username.trim(), password);
      await SessionManager.instance.saveSession(result.token, result.user);
      _user = result.user;
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Terjadi kesalahan. Coba lagi.';
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await SessionManager.instance.clear();
    _api.setCurrentUser(null);
    _user = null;
    _error = null;
    notifyListeners();
  }
}
