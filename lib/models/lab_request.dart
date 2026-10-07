// Model for patient_api_lab_requests's response -- a booked lab test
// request's status, not the catalog itself (see LabTest/LabPanel in
// lab_test_screen.dart for that).

class LabRequestSummary {
  final String requestNumber;
  final String status;
  final String statusDisplay;
  final String total;
  final String createdAt;
  final List<String> tests;

  const LabRequestSummary({
    required this.requestNumber,
    required this.status,
    required this.statusDisplay,
    required this.total,
    required this.createdAt,
    required this.tests,
  });

  factory LabRequestSummary.fromJson(Map<String, dynamic> json) {
    return LabRequestSummary(
      requestNumber: json['request_number'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusDisplay: json['status_display'] as String? ?? '',
      total: json['total']?.toString() ?? '0',
      createdAt: json['created_at'] as String? ?? '',
      tests: List<String>.from(json['tests'] ?? const []),
    );
  }
}
