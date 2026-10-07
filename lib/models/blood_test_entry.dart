// Model for the `blood_tests` key of patient_api_medical_profile's response
// (PatientBloodTest on the backend) -- routine/historical tests the
// patient or physio has logged, explicitly NOT a booking (see
// LabRequestSummary / lab_app.LabTestRequest for that): no status
// lifecycle, just a name, free-text notes (which may hold a past result
// value as plain text per the model's own help_text), and when it was
// logged.

class BloodTestEntry {
  final int id;
  final String name;
  final String notes;
  final DateTime? createdAt;

  const BloodTestEntry({
    required this.id,
    required this.name,
    required this.notes,
    this.createdAt,
  });

  factory BloodTestEntry.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'] as String?;
    return BloodTestEntry(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: (createdAtRaw != null && createdAtRaw.isNotEmpty) ? DateTime.tryParse(createdAtRaw) : null,
    );
  }
}
