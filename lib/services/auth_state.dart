import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// App-wide "is a patient logged in" signal. Soft-gate design: the app
/// itself never forces a check on startup -- individual screens call
/// [ensureLoggedIn] (see auth_gate.dart) only when the user taps something
/// that actually needs an account (booking, checkout, viewing prescribed
/// exercises), not before browsing anything.
class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  Map<String, dynamic>? _patient;

  bool get isLoggedIn => _patient != null;
  Map<String, dynamic>? get patient => _patient;
  String? get patientName => _patient?['patient_name'] as String?;
  String? get patientCode => _patient?['patient_code'] as String?;

  /// Checks whether a previously-saved session is still valid (e.g. on
  /// first opening a screen that needs login, before showing LoginScreen).
  /// Cheap to call repeatedly -- just hits /api/me/.
  Future<bool> checkSession() async {
    try {
      final data = await ApiService().getCurrentUser();
      _patient = data;
      notifyListeners();
      return true;
    } catch (_) {
      if (_patient != null) {
        _patient = null;
        notifyListeners();
      }
      return false;
    }
  }

  void setLoggedIn(Map<String, dynamic> patientData) {
    _patient = patientData;
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService().logout();
    _patient = null;
    notifyListeners();
  }
}
