import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/exercise_library.dart';
import '../screens/exercise_detail_screen.dart';

/// Lightweight list entry for one library exercise: a static thumbnail
/// image only (no video player, no step-image carousel/precache) -- those
/// are only built once the user actually taps in, on ExerciseDetailScreen.
/// Building the full media widget for every card the moment it scrolls
/// into view meant every exercise with a hosted video started downloading
/// it immediately, and every exercise with step images precached all of
/// them, regardless of whether the user ever opened that card.
class ExerciseCard extends StatelessWidget {
  final LibraryExercise exercise;
  final String? locationLabel;

  const ExerciseCard({super.key, required this.exercise, this.locationLabel});

  bool get _hasVideo =>
      (exercise.hostedVideoUrl ?? '').trim().isNotEmpty || (exercise.youtubeUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 24 - 24; // screen padding + card padding
    final thumbnailHeight = cardWidth * 9 / 16;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E9EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: thumbnailHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (exercise.exerciseUrl ?? '').trim().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: exercise.exerciseUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[100],
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[100],
                              alignment: Alignment.center,
                              child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                            ),
                          )
                        : Container(
                            color: Colors.grey[100],
                            alignment: Alignment.center,
                            child: Icon(Icons.fitness_center, color: Colors.grey[400], size: 32),
                          ),
                    if (_hasVideo)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (locationLabel != null) ...[
              Text(
                locationLabel!.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 0.4),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              exercise.name,
              style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (exercise.difficultyLevel.isNotEmpty) _chip('Level', exercise.difficultyLevel),
                _chip('Sets', '${exercise.defaultSets}'),
                _chip('Reps', '${exercise.defaultReps}'),
                if (exercise.holdTimeSec > 0) _chip('Hold', '${exercise.holdTimeSec}s'),
                _chip('Rest', '${exercise.defaultRestTimeSec}s'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          TextSpan(
            text: value,
            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
