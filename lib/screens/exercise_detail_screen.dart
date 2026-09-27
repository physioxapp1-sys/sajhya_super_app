import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/exercise_library.dart';
import '../widgets/exercise_media.dart';

/// Full exercise view: this is where the real media (hosted video player or
/// step-image carousel/precache) actually loads -- deliberately deferred
/// here rather than in the list card, so browsing the list itself stays
/// cheap (static thumbnails only) and bandwidth is only spent on an
/// exercise the user actually opened.
class ExerciseDetailScreen extends StatefulWidget {
  final LibraryExercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
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
    final mediaHeight = (screenWidth - 32) * 9 / 16;
    final hasNepali = exercise.descriptionNepali.trim().isNotEmpty;
    final hasEnglish = exercise.description.trim().isNotEmpty;
    final showEnglish = _showEnglish || !hasNepali;
    final description = (showEnglish ? exercise.description : exercise.descriptionNepali).trim();
    final showYoutubeButton =
        (exercise.youtubeUrl ?? '').trim().isNotEmpty && (exercise.hostedVideoUrl ?? '').trim().isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(exercise.name, style: const TextStyle(color: Colors.black87, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExerciseHeroMedia(exercise: exercise, height: mediaHeight),
              const SizedBox(height: 16),
              Text(
                exercise.name,
                style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  if (exercise.difficultyLevel.isNotEmpty) _chip('Level', exercise.difficultyLevel),
                  _chip('Sets', '${exercise.defaultSets}'),
                  _chip('Reps', '${exercise.defaultReps}'),
                  if (exercise.holdTimeSec > 0) _chip('Hold', '${exercise.holdTimeSec}s'),
                  _chip('Rest', '${exercise.defaultRestTimeSec}s'),
                ],
              ),
              if (showYoutubeButton) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _openYoutube,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('Watch on YouTube'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                    if (hasNepali && hasEnglish)
                      TextButton.icon(
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
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
                ),
              ],
            ],
          ),
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
