// Models for the `prescriptions` and `upcoming_doses` keys of
// patient_api_medical_profile's response (patient_app.views._medical_profile_dict
// on the backend). `Prescription` is a doctor-issued Rx -- status has a real
// lifecycle (active/completed/discontinued), unlike the separate, patient-
// editable "medication reminder" list this app doesn't surface yet.

class Prescription {
  final int id;
  final String name;
  final String dosage;
  final String timeOfDay;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'active' | 'completed' | 'discontinued'
  final String notes;
  final String? issuedBy;

  const Prescription({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timeOfDay,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.notes,
    this.issuedBy,
  });

  bool get isActive => status == 'active';

  String get timeOfDayLabel {
    switch (timeOfDay) {
      case 'morning':
        return 'Morning';
      case 'evening':
        return 'Evening';
      case 'night':
        return 'Night';
      default:
        return timeOfDay;
    }
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      timeOfDay: json['time_of_day'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String? ?? '',
      issuedBy: json['issued_by'] as String?,
    );
  }
}

class UpcomingDose {
  final int rxId;
  final String name;
  final String dosage;
  final String slotLabel;
  final DateTime doseAt;

  const UpcomingDose({
    required this.rxId,
    required this.name,
    required this.dosage,
    required this.slotLabel,
    required this.doseAt,
  });

  factory UpcomingDose.fromJson(Map<String, dynamic> json) {
    return UpcomingDose(
      rxId: json['rx_id'] as int,
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      slotLabel: json['slot_label'] as String? ?? '',
      doseAt: DateTime.parse(json['dose_at'] as String),
    );
  }
}
