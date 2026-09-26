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
                border: InputBorder.none,
                hintText: 'Search exercises (e.g. neck stretch, squat)',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF7890AA)),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.teal),
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

  @override
  Widget build(BuildContext context) {
    final browsable = (subRegions ?? []).where((s) => s.exerciseCount > 0).toList();

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
          ...browsable.map((sub) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: const Icon(Icons.fitness_center, size: 18, color: Colors.teal),
                title: Text(sub.name, style: const TextStyle(fontSize: 14)),
                trailing: Text(
                  '${sub.exerciseCount}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseListScreen(subregionId: sub.id, subregionName: sub.name),
                  ),
                ),
              )),
      ],
    );
  }
}
