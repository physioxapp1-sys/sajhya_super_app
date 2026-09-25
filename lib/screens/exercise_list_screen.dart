import 'package:flutter/material.dart';

import '../models/exercise_library.dart';
import '../services/api_service.dart';
import '../widgets/exercise_card.dart';

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
                          return ExerciseCard(exercise: visible[index]);
                        },
                      ),
      ),
    );
  }
}
