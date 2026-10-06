// lib/services/api_service.dart
//
// Talks to the sajhya.com production backend. Most methods here are
// public/no-login (lab tests, exercise library, pharmacy/shop catalogs).
// The methods under each "requires login" section below need a patient
// session (Django session cookie holding patient_id, set by login()/
// signup()) -- call those without a session and the backend 401s.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio()
    ..options.baseUrl = baseUrl
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 10)
    ..options.responseType = ResponseType.plain;

  late PersistCookieJar _cookieJar;
  bool _initialized = false;

  static const String baseUrl = 'https://sajhya.com/patient-app';

  /// Sets up the persistent cookie jar so the session survives app
  /// restarts. Safe to call multiple times -- only runs once. Call this
  /// before any login-required method (login/signup already call it
  /// themselves, but a cold app relying on a previously-saved session
  /// should call it once at startup before getCurrentUser()).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final appDocDir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(storage: FileStorage('${appDocDir.path}/.cookies/'));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<void> _ensureCsrfToken() async {
    await _dio.get('/api/csrf/');
  }

  Future<String> _getCsrfToken() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    final csrf = cookies.firstWhere((c) => c.name == 'csrftoken', orElse: () => Cookie('csrftoken', ''));
    return csrf.value;
  }

  // ── Auth (patient account) ─────────────────────────────────────────────────

  /// `username` is the patient's Patient Code (the backend's own login
  /// identifier, not an email/username in the usual sense).
  Future<Map<String, dynamic>> login(String patientCode, String password) async {
    await init();
    try {
      await _ensureCsrfToken();
      final csrf = await _getCsrfToken();
      final r = await _dio.post(
        '/api/login/',
        data: {'username': patientCode, 'password': password},
        options: Options(headers: {'X-CSRFToken': csrf}),
      );
      final parsed = jsonDecode(r.data as String);
      if (parsed is Map<String, dynamic>) return parsed;
      throw Exception('Unexpected response format');
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallback: 'Login failed'));
    }
  }

  Future<Map<String, dynamic>> signup(String name, String password) async {
    await init();
    try {
      await _ensureCsrfToken();
      final csrf = await _getCsrfToken();
      final r = await _dio.post(
        '/api/signup/',
        data: {'patient_name': name, 'password': password},
        options: Options(headers: {'X-CSRFToken': csrf}),
      );
      final parsed = jsonDecode(r.data as String);
      if (parsed is Map<String, dynamic>) return parsed;
      throw Exception('Unexpected response format');
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallback: 'Signup failed'));
    }
  }

  /// Throws if not logged in (or the session expired) -- callers use this
  /// to check login state, not just to fetch profile data.
  Future<Map<String, dynamic>> getCurrentUser() async {
    await init();
    final r = await _dio.get('/api/me/');
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await init();
    try {
      final csrf = await _getCsrfToken();
      await _dio.post('/api/logout/', options: Options(headers: {'X-CSRFToken': csrf}));
    } catch (_) {
    } finally {
      await _cookieJar.deleteAll();
    }
  }

  String _extractError(DioException e, {required String fallback}) {
    if (e.response == null) return 'Network error: ${e.message}';
    try {
      final body = e.response?.data;
      final parsed = body is String ? jsonDecode(body) : body;
      if (parsed is Map && parsed['error'] != null) return parsed['error'].toString();
    } catch (_) {}
    return '$fallback (${e.response?.statusCode})';
  }

  Future<List<Map<String, dynamic>>> getLabTests() async {
    try {
      final r = await _dio.get('/api/lab/public-tests/');
      final d = jsonDecode(r.data as String);
      return List<Map<String, dynamic>>.from(d['lab_tests']);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Could not load lab tests (${e.response?.statusCode})');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getLabPanels() async {
    try {
      final r = await _dio.get('/api/lab/public-panels/');
      final d = jsonDecode(r.data as String);
      return List<Map<String, dynamic>>.from(d['lab_panels']);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Could not load lab packages (${e.response?.statusCode})');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // ── Exercise library (browse, no login required) ──────────────────────────

  Future<List<Map<String, dynamic>>> getBrowseRegions() async {
    try {
      final r = await _dio.get('/api/browse/public-regions/');
      final d = jsonDecode(r.data as String);
      return List<Map<String, dynamic>>.from(d['regions']);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Could not load exercise regions (${e.response?.statusCode})');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getBrowseExercises(int subregionId) async {
    try {
      final r = await _dio.get(
        '/api/browse/public-exercises/',
        queryParameters: {'subregion_id': subregionId},
      );
      final d = jsonDecode(r.data as String);
      return List<Map<String, dynamic>>.from(d['exercises']);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Could not load exercises (${e.response?.statusCode})');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> searchExercises(String query) async {
    try {
      final r = await _dio.get(
        '/api/browse/public-exercises/search/',
        queryParameters: {'q': query},
      );
      final d = jsonDecode(r.data as String);
      return List<Map<String, dynamic>>.from(d['exercises']);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Could not search exercises (${e.response?.statusCode})');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // ── Pharmacy (browse, no login required) ───────────────────────────────────

  Future<List<Map<String, dynamic>>> getPharmacyProducts({String? search}) async {
    try {
      final r = await _dio.get(
        '/api/pharmacy/public-products/',
        queryParameters: (search != null && search.isNotEmpty) ? {'search': search} : null,
      );
      final d = jsonDecode(r.data as String);
      return List<Map<String, dynamic>>.from(d['products']);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Could not load pharmacy products (${e.response?.statusCode})');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // ── Pharmacy cart/checkout (requires login) ─────────────────────────────────

  Future<Map<String, dynamic>> getPharmacyCart() async {
    await init();
    final r = await _dio.get('/api/pharmacy/cart/');
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addToPharmacyCart(int productId) async {
    await init();
    final csrf = await _getCsrfToken();
    final r = await _dio.post(
      '/api/pharmacy/cart/add/$productId/',
      options: Options(headers: {'X-CSRFToken': csrf}),
    );
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePharmacyCart(int productId, int quantity) async {
    await init();
    final csrf = await _getCsrfToken();
    final r = await _dio.post(
      '/api/pharmacy/cart/update/',
      data: {'product_id': productId, 'quantity': quantity},
      options: Options(headers: {'X-CSRFToken': csrf}),
    );
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> placePharmacyOrder({
    required String address,
    required String phone,
    String notes = '',
  }) async {
    await init();
    try {
      final csrf = await _getCsrfToken();
      final r = await _dio.post(
        '/api/pharmacy/order/',
        data: {'delivery_address': address, 'customer_phone': phone, 'notes': notes},
        options: Options(headers: {'X-CSRFToken': csrf}),
      );
      return jsonDecode(r.data as String) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallback: 'Could not place order'));
    }
  }

  // ── Shop / marketplace (browse, no login required) ─────────────────────────

  Future<List<Map<String, dynamic>>> getShopProducts({String? search}) async {
    try {
      final r = await _dio.get(
        '/api/public-products/',
        queryParameters: (search != null && search.isNotEmpty) ? {'search': search} : null,
      );
      final d = jsonDecode(r.data as String);
      return List<Map<String, dynamic>>.from(d['products']);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Could not load products (${e.response?.statusCode})');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // ── Shop cart/checkout (requires login) ─────────────────────────────────────

  Future<Map<String, dynamic>> getCart() async {
    await init();
    final r = await _dio.get('/api/cart/');
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addToCart(int productId, {int? variantId}) async {
    await init();
    final csrf = await _getCsrfToken();
    final r = await _dio.post(
      '/api/cart/add/$productId/',
      data: variantId != null ? {'variant_id': variantId} : null,
      options: Options(headers: {'X-CSRFToken': csrf}),
    );
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCart(int productId, int quantity, {int? variantId}) async {
    await init();
    final csrf = await _getCsrfToken();
    final r = await _dio.post(
      '/api/cart/update/',
      data: {
        'product_id': productId,
        'quantity': quantity,
        if (variantId != null) 'variant_id': variantId,
      },
      options: Options(headers: {'X-CSRFToken': csrf}),
    );
    return jsonDecode(r.data as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> placeOrder({
    required String address,
    required String phone,
    String notes = '',
  }) async {
    await init();
    try {
      final csrf = await _getCsrfToken();
      final r = await _dio.post(
        '/api/order/',
        data: {'delivery_address': address, 'customer_phone': phone, 'notes': notes},
        options: Options(headers: {'X-CSRFToken': csrf}),
      );
      return jsonDecode(r.data as String) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallback: 'Could not place order'));
    }
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    await init();
    final r = await _dio.get('/api/orders/');
    final d = jsonDecode(r.data as String);
    return List<Map<String, dynamic>>.from(d['orders']);
  }

  // ── Lab test booking (requires login; catalog itself is public above) ──────

  Future<Map<String, dynamic>> submitLabRequest(List<int> testIds, {String notes = ''}) async {
    await init();
    try {
      final r = await _dio.post(
        '/api/lab/request/',
        data: {'test_ids': testIds, 'notes': notes},
      );
      return jsonDecode(r.data as String) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallback: 'Could not submit request'));
    }
  }

  Future<List<Map<String, dynamic>>> getLabRequests() async {
    await init();
    final r = await _dio.get('/api/lab/requests/');
    final d = jsonDecode(r.data as String);
    return List<Map<String, dynamic>>.from(d['lab_requests']);
  }

  // ── Medical profile (requires login) ────────────────────────────────────────
  // Full payload includes allergies/history/nursing plus every Medical
  // Profile tab's list (medications, blood_tests, aids, saved_exercises,
  // assessment_entries, diet_entries, consultations, prescriptions,
  // upcoming_doses) -- see patient_app.views._medical_profile_dict on the
  // backend for the exact shape. The app only consumes prescriptions/
  // upcoming_doses today (Pharmacy's Rx status + dosage cards); the rest of
  // the payload is just along for the ride, not parsed yet.

  Future<Map<String, dynamic>> getMedicalProfile() async {
    await init();
    final r = await _dio.get('/api/medical-profile/');
    final d = jsonDecode(r.data as String);
    return d['medical_profile'] as Map<String, dynamic>;
  }
}
