// Models for patient_api_me's `latest_prescription` key (prescription_app,
// via patient_app.views.patient_api_me) -- the single most recent exercise
// prescription a physio has issued this patient, if any. Deliberately
// separate from exercise_library.dart's LibraryExercise: a prescribed
// exercise's id is a PrescriptionExercise id, not an ExerciseMain id, and
// it carries patient-specific schedule/completion fields the public
// library has no concept of.

import 'exercise_library.dart';

class PrescribedExercise {
  final int id;
  final String name;
  final String? exerciseUrl;
  final String? youtubeUrl;
  final String? hostedVideoUrl;
  final int sets;
  final int reps;
  final int holdTimeSec;
  final int restTimeSec;
  final bool scheduleMorning;
  final bool scheduleDay;
  final bool scheduleEvening;
  final bool isCompleted;
  final String description;
  final String descriptionNepali;
  final List<StepImage> stepImages;

  const PrescribedExercise({
    required this.id,
    required this.name,
    this.exerciseUrl,
    this.youtubeUrl,
    this.hostedVideoUrl,
    required this.sets,
    required this.reps,
    required this.holdTimeSec,
    required this.restTimeSec,
    required this.scheduleMorning,
    required this.scheduleDay,
    required this.scheduleEvening,
    required this.isCompleted,
    required this.description,
    required this.descriptionNepali,
    required this.stepImages,
  });

  factory PrescribedExercise.fromJson(Map<String, dynamic> json) {
    return PrescribedExercise(
      id: json['id'] as int,
      name: json['exercise_name'] as String? ?? 'Unnamed exercise',
      exerciseUrl: json['exercise_url'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      hostedVideoUrl: json['hosted_video_url'] as String?,
      sets: json['sets'] as int? ?? 0,
      reps: json['reps'] as int? ?? 0,
      holdTimeSec: json['hold_time_sec'] as int? ?? 0,
      restTimeSec: json['rest_time_sec'] as int? ?? 0,
      scheduleMorning: json['schedule_morning'] as bool? ?? false,
      scheduleDay: json['schedule_day'] as bool? ?? false,
      scheduleEvening: json['schedule_evening'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      descriptionNepali: json['description_nepali'] as String? ?? '',
      stepImages: ((json['step_images'] as List<dynamic>? ?? [])
              .map((e) => StepImage.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order))),
    );
  }

  // Adapts to LibraryExercise's shape purely so the existing ExerciseCard /
  // ExerciseHeroMedia / ExerciseDetailScreen widgets (built for the public
  // library) can render this one's thumbnail/video/carousel/detail page
  // too, without duplicating any of that logic. exerciseType/difficultyLevel
  // don't apply to a prescribed exercise and are left blank -- nothing
  // those widgets render actually reads them for this purpose.
  LibraryExercise toLibraryExercise() {
    return LibraryExercise(
      id: id,
      name: name,
      exerciseType: '',
      difficultyLevel: '',
      exerciseUrl: exerciseUrl,
      youtubeUrl: youtubeUrl,
      hostedVideoUrl: hostedVideoUrl,
      defaultSets: sets,
      defaultReps: reps,
      holdTimeSec: holdTimeSec,
      defaultRestTimeSec: restTimeSec,
      description: description,
      descriptionNepali: descriptionNepali,
      stepImages: stepImages,
    );
  }
}

class ExercisePrescription {
  final int id;
  final DateTime? createdAt;
  final String status;
  final String? notes;
  final List<PrescribedExercise> exercises;

  const ExercisePrescription({
    required this.id,
    this.createdAt,
    required this.status,
    this.notes,
    required this.exercises,
  });

  factory ExercisePrescription.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'] as String?;
    return ExercisePrescription(
      id: json['id'] as int,
      createdAt: (createdAtRaw != null && createdAtRaw.isNotEmpty) ? DateTime.tryParse(createdAtRaw) : null,
      status: json['status'] as String? ?? 'active',
      notes: json['prescription_notes'] as String?,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => PrescribedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
