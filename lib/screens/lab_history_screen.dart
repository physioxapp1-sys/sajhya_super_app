import 'package:flutter/material.dart';

import '../models/blood_test_entry.dart';
import '../services/api_service.dart';
import 'lab_requests_screen.dart';

// Entry point for both "what have I booked" (LabRequestsBody, status-
// tracked) and "what's been logged as routine/history" (TestHistoryBody,
// free-text, no status) -- kept as two tabs rather than one merged list
// since they come from genuinely different backend models with different
// shapes (see each body widget's own doc comment), same split already
// made for Pharmacy's Medicine Reminders vs Prescriptions.
class LabHistoryScreen extends StatelessWidget {
  const LabHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('Lab Tests', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: Color(0xFF2384E8),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF2384E8),
            tabs: [
              Tab(text: 'My Requests'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LabRequestsBody(),
            TestHistoryBody(),
          ],
        ),
      ),
    );
  }
}

// Body only (no Scaffold/AppBar) -- see LabHistoryScreen's doc comment.
class TestHistoryBody extends StatefulWidget {
  const TestHistoryBody({super.key});

  @override
  State<TestHistoryBody> createState() => _TestHistoryBodyState();
}

class _TestHistoryBodyState extends State<TestHistoryBody> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<BloodTestEntry>? _entries;
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
      final profile = await ApiService().getMedicalProfile();
      final entries = (profile['blood_tests'] as List<dynamic>? ?? [])
          .map((e) => BloodTestEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
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
              Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 32),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final entries = _entries ?? [];
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, color: Colors.grey[400], size: 48),
              const SizedBox(height: 12),
              const Text(
                'No test history logged yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                'Routine tests you or your physio log on your Medical Profile show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _HistoryCard(entry: entries[i]),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final BloodTestEntry entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8F5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF7754C7).withOpacity(.10),
            child: const Icon(Icons.bloodtype_outlined, color: Color(0xFF7754C7), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF12366B))),
                if (entry.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(_formatDate(entry.createdAt!), style: const TextStyle(color: Color(0xFF6B8098), fontSize: 12)),
                ],
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(entry.notes, style: const TextStyle(color: Color(0xFF34506D), fontSize: 13, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
