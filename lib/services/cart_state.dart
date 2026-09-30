import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import 'api_service.dart';

/// Shop (marketplace Product) cart item count, kept reactive so a cart
/// badge anywhere in the app updates immediately after an add/update --
/// same singleton-ChangeNotifier pattern as AuthState.
class ShopCartState extends ChangeNotifier {
  static final ShopCartState _instance = ShopCartState._internal();
  factory ShopCartState() => _instance;
  ShopCartState._internal();

  int _count = 0;
  int get count => _count;

  /// Re-checks the real count from the backend. Silently leaves the last
  /// known count alone on failure (e.g. not logged in yet) rather than
  /// resetting it to 0 -- this is a background refresh, not a user action.
  Future<void> refresh() async {
    try {
      final data = await ApiService().getCart();
      _count = CartSummary.fromJson(data).count;
      notifyListeners();
    } catch (_) {}
  }

  void setCount(int value) {
    _count = value;
    notifyListeners();
  }
}

/// Same shape as ShopCartState but for the pharmacy cart -- kept as its own
/// class rather than a shared one with a "which cart" flag, since the two
/// carts key off unrelated models and unrelated backend session keys (same
/// reasoning the backend itself uses for keeping _build_pharmacy_cart_lines
/// separate from _build_cart_lines).
class PharmacyCartState extends ChangeNotifier {
  static final PharmacyCartState _instance = PharmacyCartState._internal();
  factory PharmacyCartState() => _instance;
  PharmacyCartState._internal();

  int _count = 0;
  int get count => _count;

  Future<void> refresh() async {
    try {
      final data = await ApiService().getPharmacyCart();
      _count = CartSummary.fromJson(data).count;
      notifyListeners();
    } catch (_) {}
  }

  void setCount(int value) {
    _count = value;
    notifyListeners();
  }
}
