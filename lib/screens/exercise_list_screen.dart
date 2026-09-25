import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/exercise_library.dart';
import '../services/api_service.dart';
import '../widgets/exercise_media.dart';

const int _pageSize = 10;

class ExerciseListScreen extends StatefulWidget {
  final int subregionId;
  final String subregionName;

  const ExerciseListScreen({
    super.key,
    required this.subregionId,
    required this.subregionName,
  });

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  List<LibraryExercise> _exercises = [];
  int _visibleCount = _pageSize;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService().getBrowseExercises(widget.subregionId);
      setState(() {
        _exercises = raw.map(LibraryExercise.fromJson).toList();
        _visibleCount = _pageSize;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _exercises.take(_visibleCount).toList();
    final hasMore = _visibleCount < _exercises.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(widget.subregionName, style: const TextStyle(color: Colors.black87, fontSize: 16)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 36),
                          const SizedBox(height: 10),
                          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : _exercises.isEmpty
                    ? Center(child: Text('No exercises here yet.', style: TextStyle(color: Colors.grey[600])))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: visible.length + (hasMore ? 1 : 0),
                        itemBuilder: (_, index) {
                          if (index == visible.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => _visibleCount += _pageSize),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
                                  child: Text('Load ${(_exercises.length - _visibleCount).clamp(0, _pageSize)} more'),
                                ),
                              ),
                            );
                          }
                          return _ExerciseCard(exercise: visible[index]);
                        },
                      ),
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final LibraryExercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
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
