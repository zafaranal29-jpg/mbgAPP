import 'package:flutter/foundation.dart';
import 'package:mbg_app/core/models/models.dart';
import 'package:mbg_app/core/network/api_client.dart';
import 'package:mbg_app/core/utils/formatters.dart';

class ClaimController extends ChangeNotifier {
  ClaimController(this._api);

  final ApiClient _api;

  bool _loading = false;
  int? _claimedUserId;
  String? _claimedDate;

  bool get loading => _loading;

  bool hasClaimedToday(int userId) =>
      _claimedUserId == userId && _claimedDate == isoDate(DateTime.now());

  /// POST /api/claim/submit
  Future<ClaimResult> submit({
    required int studentId,
    required String qrToken,
  }) async {
    _loading = true;
    notifyListeners();

    ClaimResult result;
    try {
      result = await _api.submitClaim(studentId: studentId, qrToken: qrToken);
    } on ApiException catch (e) {
      result = ClaimResult(
          success: false, message: e.message, waktuClaim: DateTime.now());
    } catch (_) {
      result = ClaimResult(
        success: false,
        message: 'Terjadi kesalahan. Coba lagi.',
        waktuClaim: DateTime.now(),
      );
    }

    if (result.success) {
      _claimedUserId = studentId;
      _claimedDate = isoDate(result.waktuClaim);
    }
    _loading = false;
    notifyListeners();
    return result;
  }
}
