// Models for the `upcoming_doses` and `medications` keys of
// patient_api_medical_profile's response (patient_app.views.
// _medical_profile_dict on the backend). `Medication` is the patient-or-
// physio-editable "what I take" reminder list (PatientMedication) -- no
// status/timeline, just a name and a time-of-day slot. The backend also
// has a separate doctor-issued Rx model with a real status lifecycle, but
// the app doesn't surface that directly (Pharmacy only shows Medicine
// Reminders + the merged upcoming-doses timeline); UpcomingDose below is
// still fed partly from Rx data server-side even though no Rx-specific
// model is parsed here.

class Medication {
  final int id;
  final String timeOfDay;
  final String name;
  final String instructions;

  const Medication({
    required this.id,
    required this.timeOfDay,
    required this.name,
    required this.instructions,
  });

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

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as int,
      timeOfDay: json['time_of_day'] as String? ?? '',
      name: json['name'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
    );
  }

  // Mirrors personal_account.models.DOSE_SLOT_TIMES exactly (morning 08:00,
  // evening 18:00, night 21:00, Nepal local clock time) -- the backend's
  // own get_upcoming_doses() only resolves this for Rx, not this
  // patient/physio-editable reminder list, so the same "next occurrence,
  // roll to tomorrow if passed" computation is mirrored here client-side.
  static const Map<String, Duration> _slotOffsets = {
    'morning': Duration(hours: 8),
    'evening': Duration(hours: 18),
    'night': Duration(hours: 21),
  };

  /// `nowNepal` must be Nepal wall-clock "now" (see pharmacy_screen's
  /// _nepalNow -- NOT device-local time), used only to read its
  /// year/month/day/compare-against fields. Returns a true UTC instant
  /// (by subtracting the same +05:45 offset back out), so it sorts and
  /// formats identically to the backend's own real `dose_at` values --
  /// not a second Nepal-shifted value stacked on top of an already-shifted
  /// `nowNepal`.
  DateTime? nextDoseAt(DateTime nowNepal) {
    final offset = _slotOffsets[timeOfDay];
    if (offset == null) return null;
    var doseNepalWallClock = DateTime.utc(nowNepal.year, nowNepal.month, nowNepal.day).add(offset);
    if (doseNepalWallClock.isBefore(nowNepal)) {
      doseNepalWallClock = doseNepalWallClock.add(const Duration(days: 1));
    }
    return doseNepalWallClock.subtract(const Duration(hours: 5, minutes: 45));
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
