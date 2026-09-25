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
}
