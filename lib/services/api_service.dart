// lib/services/api_service.dart
//
// Talks to the sajhya.com production backend's public, no-login lab test
// catalog endpoint (patient_app.views.patient_api_lab_tests_public). The
// authenticated lab endpoints (booking, request history) require a patient
// session and are intentionally not wired here.
import 'dart:convert';
import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio()
    ..options.baseUrl = baseUrl
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 10)
    ..options.responseType = ResponseType.plain;

  static const String baseUrl = 'https://sajhya.com/patient-app';

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
}
