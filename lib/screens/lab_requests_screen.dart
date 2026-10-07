import 'package:flutter/material.dart';

import '../models/lab_request.dart';
import '../services/api_service.dart';

class LabRequestsScreen extends StatefulWidget {
  const LabRequestsScreen({super.key});

  @override
  State<LabRequestsScreen> createState() => _LabRequestsScreenState();
}

class _LabRequestsScreenState extends State<LabRequestsScreen> {
  List<LabRequestSummary>? _requests;
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
      final raw = await ApiService().getLabRequests();
      if (!mounted) return;
      setState(() {
        _requests = raw.map(LabRequestSummary.fromJson).toList();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('My Lab Requests', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
    final requests = _requests ?? [];
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, color: Colors.grey[400], size: 48),
              const SizedBox(height: 12),
              const Text("You haven't requested any lab tests yet.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _RequestCard(request: requests[i]),
      ),
    );
  }
}

MaterialColor _statusColor(String status) {
  switch (status) {
    case 'completed':
      return Colors.green;
    case 'sample_collected':
      return Colors.blue;
    case 'cancelled':
      return Colors.red;
    default: // pending
      return Colors.orange;
  }
}

class _RequestCard extends StatelessWidget {
  final LabRequestSummary request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(request.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${request.requestNumber}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF12366B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  request.statusDisplay,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(request.createdAt, style: const TextStyle(color: Color(0xFF6B8098), fontSize: 12)),
          const SizedBox(height: 10),
          Text(
            request.tests.isEmpty ? 'No tests on file' : request.tests.join(', '),
            style: const TextStyle(color: Color(0xFF34506D), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            'Total: NPR ${double.tryParse(request.total)?.toStringAsFixed(0) ?? request.total}',
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF22A06B)),
          ),
        ],
      ),
    );
  }
}
