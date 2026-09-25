import 'package:flutter/material.dart';

class RxItem {
  final String name;
  final String statusLabel;
  final int progressPercent;
  final String eta;

  const RxItem({
    required this.name,
    required this.statusLabel,
    required this.progressPercent,
    required this.eta,
  });

  bool get isReady => progressPercent >= 100;
}

class PrescriptionsScreen extends StatelessWidget {
  final List<RxItem> prescriptions;

  const PrescriptionsScreen({super.key, required this.prescriptions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.teal),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Prescription Status',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: prescriptions.isEmpty
          ? const Center(child: Text('No active prescriptions right now.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prescriptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, index) => _RxCard(item: prescriptions[index]),
            ),
    );
  }
}

class _RxCard extends StatelessWidget {
  final RxItem item;

  const _RxCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final badgeColor = item.isReady ? Colors.green : Colors.orange;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: badgeColor.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '${item.statusLabel.toUpperCase()} (${item.progressPercent}%)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.eta, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: item.progressPercent / 100,
                minHeight: 8,
                backgroundColor: const Color(0xFFE0E0E0),
                color: item.isReady ? Colors.green : Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
