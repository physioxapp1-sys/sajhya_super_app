import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/exercise_library.dart';
import 'exercise_media.dart';

/// Self-contained card for one library exercise: media, dose info, and a
/// "Steps" toggle that reveals the description (English/Nepali) only when
/// tapped. Used both in a single sub-region's exercise list and in search
/// results, where [locationLabel] (e.g. "Spine > Cervical") gives context
/// since a search result isn't scoped to one already-known sub-region.
class ExerciseCard extends StatefulWidget {
  final LibraryExercise exercise;
  final String? locationLabel;

  const ExerciseCard({super.key, required this.exercise, this.locationLabel});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool _showSteps = false;
  bool _showEnglish = false;

  Future<void> _openYoutube() async {
    final url = widget.exercise.youtubeUrl;
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 24 - 32; // screen padding + card padding
    final thumbnailHeight = cardWidth * 9 / 16;
    final hasNepali = exercise.descriptionNepali.trim().isNotEmpty;
    final hasEnglish = exercise.description.trim().isNotEmpty;
    final showEnglish = _showEnglish || !hasNepali;
    final description = (showEnglish ? exercise.description : exercise.descriptionNepali).trim();
    final hasSteps = description.isNotEmpty;

    return Container(
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
          ExerciseHeroMedia(exercise: exercise, height: thumbnailHeight),
          const SizedBox(height: 8),
          if (widget.locationLabel != null) ...[
            Text(
              widget.locationLabel!.toUpperCase(),
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
          const SizedBox(height: 10),
          Row(
            children: [
              if (hasSteps)
                _pillButton(
                  icon: _showSteps ? Icons.list_alt : Icons.list_alt_outlined,
                  label: 'Steps',
                  active: _showSteps,
                  onTap: () => setState(() => _showSteps = !_showSteps),
                ),
              if ((exercise.youtubeUrl ?? '').trim().isNotEmpty &&
                  (exercise.hostedVideoUrl ?? '').trim().isEmpty) ...[
                const SizedBox(width: 8),
                _pillButton(
                  icon: Icons.play_circle_outline,
                  label: 'Video',
                  color: Colors.redAccent,
                  onTap: _openYoutube,
                ),
              ],
            ],
          ),
          if (_showSteps && hasSteps) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasNepali && hasEnglish)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showEnglish = !_showEnglish),
                        icon: const Icon(Icons.translate, size: 15),
                        label: Text(showEnglish ? 'नेपालीमा हेर्नुहोस्' : 'View in English'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  if (hasNepali && hasEnglish) const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
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

  Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.teal,
    bool active = false,
  }) {
    return Material(
      color: color.withOpacity(active ? 0.18 : 0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
