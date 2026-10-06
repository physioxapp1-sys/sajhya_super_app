import 'package:flutter/material.dart';

import '../models/prescription.dart';

class PrescriptionsScreen extends StatelessWidget {
  final List<Prescription> prescriptions;

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
          'Prescriptions',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: prescriptions.isEmpty
          ? const Center(child: Text('No prescriptions on file yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prescriptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, index) => _RxCard(item: prescriptions[index]),
            ),
    );
  }
}

// Matches the web Medical Profile's own status badge colors
// (.mp-rx-status-active/completed/discontinued): green/gray/red.
MaterialColor _statusColor(String status) {
  switch (status) {
    case 'active':
      return Colors.green;
    case 'discontinued':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

class _RxCard extends StatelessWidget {
  final Prescription item;

  const _RxCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
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
                  child: Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.shade800),
                  ),
                ),
              ],
            ),
            if (item.dosage.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.dosage, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 6),
            Text(
              'Taken ${item.timeOfDayLabel.toLowerCase()} -- since ${_formatDate(item.startDate)}'
              '${item.endDate != null ? ' until ${_formatDate(item.endDate!)}' : ''}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            if (item.issuedBy != null) ...[
              const SizedBox(height: 4),
              Text('Prescribed by Dr. ${item.issuedBy}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
            ],
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(item.notes, style: const TextStyle(color: Colors.black54, fontSize: 13, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
