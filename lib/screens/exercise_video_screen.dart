import 'dart:async';

import 'package:flutter/material.dart';

import '../models/exercise_library.dart';
import '../services/api_service.dart';
import '../widgets/exercise_card.dart';
import 'exercise_list_screen.dart';

// The 5 top-level regions are stable reference content (they essentially
// never change, unlike the exercises within them), so they're shown
// immediately in this fixed order/wording instead of waiting on the
// network -- subregions and exercise counts still come from the live API
// and get merged in once that response arrives.
const List<(int id, String displayName, String imagePath)> _kRegions = [
  (1, 'Head & Neck', 'assets/regions/head_n_neck.jpg'),
  (2, 'Spine', 'assets/regions/spine.jpg'),
  (5, 'Trunk', 'assets/regions/trunk.jpg'),
  (3, 'Upper Limb', 'assets/regions/upper_limb.jpg'),
  (4, 'Lower Limb', 'assets/regions/lower_limb.jpg'),
];

// Not every sub-region has an illustration yet (e.g. Spine's
// cervicothoracic/lumbopelvic/thoracolumbar/wholespine) -- those fall back
// to a generic icon rather than being left unmapped here. Keyed by
// lowercased, trimmed sub-region name so "Ankle" and "ankle" both match.
// "phalanges" has no dedicated image, so it reuses the hand image
// (phalanges are the finger bones).
const Map<String, String> _kSubregionImages = {
  'brain': 'assets/subregions/brain.jpg',
  'face': 'assets/subregions/face.jpg',
  'spinal cord': 'assets/subregions/spinal_cord.jpg',
  'ankle': 'assets/subregions/ankle.jpg',
  'foot': 'assets/subregions/foot.jpg',
  'hip': 'assets/subregions/hip.jpg',
  'knee': 'assets/subregions/knee.jpg',
  'scapula': 'assets/subregions/scapula.jpg',
  'elbow': 'assets/subregions/elbow.jpg',
  'hand': 'assets/subregions/hand.jpg',
  'phalanges': 'assets/subregions/hand.jpg',
  'shoulder': 'assets/subregions/shoulder.jpg',
  'cervical': 'assets/subregions/cervical.png',
  'coccygeal': 'assets/subregions/coccyx.png',
  'lumbar': 'assets/subregions/lumbar.png',
  'pelvis': 'assets/subregions/pelvis.png',
  'thoracic': 'assets/subregions/thoracic.png',
  'wrist': 'assets/subregions/wrist.jpg',
};

class ExerciseVideoScreen extends StatelessWidget {
  const ExerciseVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('Exercise Videos', style: TextStyle(color: Colors.black87, fontSize: 16)),
          bottom: const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.teal,
            tabs: [
              Tab(text: 'Library'),
              Tab(text: 'Prescribed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LibraryTab(),
            _PrescribedTab(),
          ],
        ),
      ),
    );
  }
}

class _PrescribedTab extends StatelessWidget {
  const _PrescribedTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Sign in to see your prescribed exercises',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              'Exercises prescribed to you by your physio will show up here once you have an account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTab extends StatefulWidget {
  const _LibraryTab();

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  Map<int, List<SubRegionSummary>> _subregionsByRegionId = {};
  bool _loadingRegions = true;
  String? _regionsError;

  String _query = '';
  bool _searching = false;
  String? _searchError;
  List<LibraryExercise>? _searchResults;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSubregions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubregions() async {
    setState(() {
      _loadingRegions = true;
      _regionsError = null;
    });
    try {
      final raw = await ApiService().getBrowseRegions();
      final regions = raw.map(RegionSummary.fromJson).toList();
      final map = <int, List<SubRegionSummary>>{
        for (final r in regions) r.id: r.subRegions,
      };
      setState(() {
        _subregionsByRegionId = map;
        _loadingRegions = false;
      });
    } catch (e) {
      setState(() {
        _regionsError = e.toString();
        _loadingRegions = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _searchResults = null;
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _query = query;
      _searching = true;
      _searchError = null;
    });
    try {
      final raw = await ApiService().searchExercises(query);
      if (!mounted) return;
      setState(() {
        _searchResults = raw.map(LibraryExercise.fromJson).toList();
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e.toString();
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.06))),
          ),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FB),
              borderRadius: BorderRadius.circular(21),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 11),
                border: InputBorder.none,
                hintText: 'Search exercises (e.g. neck stretch, squat)',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF7890AA)),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.teal),
                prefixIconConstraints: BoxConstraints(minWidth: 36, minHeight: 20),
              ),
            ),
          ),
        ),
        Expanded(
          child: _query.isNotEmpty ? _buildSearchResults() : _buildRegionList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 36),
              const SizedBox(height: 10),
              Text(_searchError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => _runSearch(_query), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final results = _searchResults ?? [];
    if (results.isEmpty) {
      return Center(
        child: Text('No exercises match "$_query".', style: TextStyle(color: Colors.grey[600])),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: results.length,
      itemBuilder: (_, index) {
        final exercise = results[index];
        final location = [exercise.regionName, exercise.subRegionName]
            .where((s) => (s ?? '').trim().isNotEmpty)
            .join(' > ');
        return ExerciseCard(exercise: exercise, locationLabel: location.isEmpty ? null : location);
      },
    );
  }

  Widget _buildRegionList() {
    if (_regionsError != null && _subregionsByRegionId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 36),
              const SizedBox(height: 10),
              Text(_regionsError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadSubregions, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _kRegions.length,
      itemBuilder: (_, index) {
        final (id, name, imagePath) = _kRegions[index];
        return _RegionTile(
          name: name,
          imagePath: imagePath,
          subRegions: _subregionsByRegionId[id],
          loading: _loadingRegions && _subregionsByRegionId[id] == null,
        );
      },
    );
  }
}

class _RegionTile extends StatelessWidget {
  final String name;
  final String imagePath;
  final List<SubRegionSummary>? subRegions;
  final bool loading;

  const _RegionTile({
    required this.name,
    required this.imagePath,
    required this.subRegions,
    required this.loading,
  });

  // Content still being added -- shown even at 0 exercises so patients can
  // see they exist, unlike other empty sub-regions which are hidden as
  // dead ends. Names, not ids: the backend currently has duplicate rows
  // for both (two "Hip", two "Foot"), so dedup-by-name below also covers
  // whichever one ends up holding the real exercises.
  static const _kAlwaysShow = {'hip', 'foot'};

  @override
  Widget build(BuildContext context) {
    // Dedup by name, keeping whichever duplicate has more exercises --
    // guards against the backend's duplicate Hip/Foot rows rendering as
    // two identical-looking tiles.
    final byName = <String, SubRegionSummary>{};
    for (final s in subRegions ?? []) {
      final key = s.name.trim().toLowerCase();
      final existing = byName[key];
      if (existing == null || s.exerciseCount > existing.exerciseCount) {
        byName[key] = s;
      }
    }
    final browsable = byName.values
        .where((s) => s.exerciseCount > 0 || _kAlwaysShow.contains(s.name.trim().toLowerCase()))
        .toList();

    return ExpansionTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imagePath,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 15),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 4),
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else if (browsable.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Text('No exercises here yet.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          )
        else
          ...browsable.map((sub) {
            final imagePath = _kSubregionImages[sub.name.trim().toLowerCase()];
            return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(imagePath, width: 34, height: 34, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.fitness_center, size: 18, color: Colors.teal),
                title: Text(sub.name, style: const TextStyle(fontSize: 14)),
                trailing: Text(
                  sub.exerciseCount > 0 ? '${sub.exerciseCount}' : 'Coming soon',
                  style: TextStyle(
                    color: sub.exerciseCount > 0 ? Colors.grey[500] : Colors.orange[700],
                    fontSize: 12,
                    fontStyle: sub.exerciseCount > 0 ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseListScreen(subregionId: sub.id, subregionName: sub.name),
                  ),
                ),
              );
          }),
      ],
    );
  }
}
