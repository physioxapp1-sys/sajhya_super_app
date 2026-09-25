import 'package:flutter/material.dart';

import '../models/exercise_library.dart';
import '../services/api_service.dart';
import 'exercise_list_screen.dart';

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
              Tab(text: 'Prescribed'),
              Tab(text: 'Library'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PrescribedTab(),
            _LibraryTab(),
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
  List<RegionSummary> _regions = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

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
      final raw = await ApiService().getBrowseRegions();
      setState(() {
        _regions = raw.map(RegionSummary.fromJson).toList();
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
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
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
      );
    }
    if (_regions.isEmpty) {
      return Center(child: Text('No exercise regions available yet.', style: TextStyle(color: Colors.grey[600])));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _regions.length,
      itemBuilder: (_, index) => _RegionTile(region: _regions[index]),
    );
  }
}

class _RegionTile extends StatelessWidget {
  final RegionSummary region;
  const _RegionTile({required this.region});

  @override
  Widget build(BuildContext context) {
    final browsable = region.subRegions.where((s) => s.exerciseCount > 0).toList();
    if (browsable.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      title: Text(
        region.name,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 15),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 4),
      children: browsable
          .map((sub) => ListTile(
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
              ))
          .toList(),
    );
  }
}
