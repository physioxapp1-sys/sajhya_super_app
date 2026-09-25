// Models for the public exercise library (region -> sub-region -> exercise
// browsing). Deliberately separate from any "prescribed exercise" model --
// these ids (ExerciseMain) are not interchangeable with a prescribed
// exercise's id (PrescriptionExercise), and this shape has no
// schedule_*/is_completed fields since nothing here is tied to a patient.

class StepImage {
  final int order;
  final String? imageUrl;
  final String? label;

  const StepImage({required this.order, this.imageUrl, this.label});

  factory StepImage.fromJson(Map<String, dynamic> json) {
    return StepImage(
      order: json['order'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      label: json['label'] as String?,
    );
  }
}

class LibraryExercise {
  final int id;
  final String name;
  final String exerciseType;
  final String difficultyLevel;
  final String? exerciseUrl;
  final String? youtubeUrl;
  final String? hostedVideoUrl;
  final int defaultSets;
  final int defaultReps;
  final int holdTimeSec;
  final int defaultRestTimeSec;
  final String description;
  final String descriptionNepali;
  final List<StepImage> stepImages;

  // Only present on search results (patient_api_browse_exercises_search_public),
  // which span multiple sub-regions and so need to say where each match
  // lives; null when fetched via a sub-region-scoped browse call.
  final int? subRegionId;
  final String? subRegionName;
  final String? regionName;

  const LibraryExercise({
    required this.id,
    required this.name,
    required this.exerciseType,
    required this.difficultyLevel,
    this.exerciseUrl,
    this.youtubeUrl,
    this.hostedVideoUrl,
    required this.defaultSets,
    required this.defaultReps,
    required this.holdTimeSec,
    required this.defaultRestTimeSec,
    required this.description,
    required this.descriptionNepali,
    required this.stepImages,
    this.subRegionId,
    this.subRegionName,
    this.regionName,
  });

  factory LibraryExercise.fromJson(Map<String, dynamic> json) {
    return LibraryExercise(
      id: json['id'] as int,
      name: json['exercise_name'] as String? ?? 'Unnamed exercise',
      exerciseType: json['exercise_type'] as String? ?? '',
      difficultyLevel: json['difficulty_level'] as String? ?? '',
      exerciseUrl: json['exercise_url'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      hostedVideoUrl: json['hosted_video_url'] as String?,
      defaultSets: json['default_sets'] as int? ?? 3,
      defaultReps: json['default_reps'] as int? ?? 10,
      holdTimeSec: json['hold_time_sec'] as int? ?? 0,
      defaultRestTimeSec: json['default_rest_time_sec'] as int? ?? 60,
      description: json['description'] as String? ?? '',
      descriptionNepali: json['description_nepali'] as String? ?? '',
      stepImages: ((json['step_images'] as List<dynamic>? ?? [])
              .map((e) => StepImage.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order))),
      subRegionId: json['sub_region_id'] as int?,
      subRegionName: json['sub_region_name'] as String?,
      regionName: json['region_name'] as String?,
    );
  }
}

class SubRegionSummary {
  final int id;
  final String name;
  final int exerciseCount;

  const SubRegionSummary({required this.id, required this.name, required this.exerciseCount});

  factory SubRegionSummary.fromJson(Map<String, dynamic> json) {
    return SubRegionSummary(
      id: json['id'] as int,
      name: json['sub_region_name'] as String? ?? '',
      exerciseCount: json['exercise_count'] as int? ?? 0,
    );
  }
}

class RegionSummary {
  final int id;
  final String name;
  final List<SubRegionSummary> subRegions;

  const RegionSummary({required this.id, required this.name, required this.subRegions});

  factory RegionSummary.fromJson(Map<String, dynamic> json) {
    return RegionSummary(
      id: json['id'] as int,
      name: json['region_name'] as String? ?? '',
      subRegions: (json['subregions'] as List<dynamic>? ?? [])
          .map((e) => SubRegionSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
