import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/auth_state.dart';

/// Soft-gate helper: call this right before a login-required action
/// (booking, checkout, viewing prescribed exercises). Returns true if
/// already logged in, or if the user just logged in successfully via the
/// pushed LoginScreen; returns false if they backed out. Callers should
/// only proceed with the gated action when this returns true.
///
/// Re-checks a possibly-stale session first (cheap /api/me/ call) rather
/// than trusting AuthState blindly, since the session cookie could have
/// expired server-side since the last check.
Future<bool> ensureLoggedIn(BuildContext context) async {
  if (AuthState().isLoggedIn) return true;

  final hasSession = await AuthState().checkSession();
  if (hasSession) return true;

  if (!context.mounted) return false;
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return result == true;
}
