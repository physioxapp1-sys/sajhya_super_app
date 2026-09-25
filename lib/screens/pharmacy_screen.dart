import 'package:flutter/material.dart';

import 'prescriptions_screen.dart';

class PharmacyScreen extends StatelessWidget {
  const PharmacyScreen({super.key});

  // TODO: replace with the patient's real active prescriptions once the
  // pharmacy backend is wired (see how lab_test_screen.dart pulls from a
  // live API for the equivalent pattern).
  static const List<RxItem> _activePrescriptions = [
    RxItem(
      name: 'Amoxicillin 500mg (Refill #2)',
      statusLabel: 'Preparing',
      progressPercent: 80,
      eta: 'Est. Ready: Today at 4:30 PM',
    ),
    RxItem(
      name: 'Metformin 500mg',
      statusLabel: 'Ready for pickup',
      progressPercent: 100,
      eta: 'Ready now',
    ),
    RxItem(
      name: 'Cetirizine 10mg',
      statusLabel: 'Preparing',
      progressPercent: 40,
      eta: 'Est. Ready: Tomorrow, 10:00 AM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.teal),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.black12),
          ),
          child: const TextField(
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Search medicines, prescriptions...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.black45),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.teal),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.teal, size: 28),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Text('SJ', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Anxiety Reduction Section: Live Rx Status Tracker
            _buildRxStatusCard(context),
            const SizedBox(height: 20),

            // 2. Cognitive Simplicity Section: Quick Actions Grid (Max 4 items)
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),

            // 3. Information Provision: Upcoming Dosages
            const Text(
              'UPCOMING DOSAGES',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            _buildUpcomingDosagesCard(),
            const SizedBox(height: 20),

            // 4. Convenience Utility: Emergency Pharmacy Map Pin
            _buildEmergencyPharmacyTile(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- Widget Builders ---

  Widget _buildRxStatusCard(BuildContext context) {
    if (_activePrescriptions.isEmpty) {
      return const SizedBox.shrink();
    }
    final headline = _activePrescriptions.first;
    final moreCount = _activePrescriptions.length - 1;

    void openAll() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PrescriptionsScreen(prescriptions: _activePrescriptions),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: openAll,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CURRENT RX STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${headline.statusLabel.toUpperCase()} (${headline.progressPercent}%)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(headline.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(headline.eta, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: headline.progressPercent / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE0E0E0),
                  color: Colors.teal,
                ),
              ),
              if (moreCount > 0) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '+$moreCount more prescription${moreCount == 1 ? '' : 's'} in progress',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: openAll,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                      child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildGridItem(Icons.camera_alt_outlined, 'Scan & Upload', 'For new prescriptions'),
        _buildGridItem(Icons.autorenew, '1-Touch Refill', 'Instant re-order'),
        _buildGridItem(Icons.volunteer_activism_outlined, 'Discounts & Subsidy', 'Apply for govt. subsidy or discounts'),
        _buildGridItem(Icons.medical_services_outlined, 'Med Cabinet', 'Schedule & History'),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.teal, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black45), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingDosagesCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildDosageRow('12:00 PM', 'Atorvastatin 20mg', 'Take with food'),
            const Divider(height: 24),
            _buildDosageRow('6:00 PM', 'Lisinopril 10mg', 'On empty stomach'),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageRow(String time, String medName, String instruction) {
    return Row(
      children: [
        Icon(Icons.check_box_outline_blank, color: Colors.teal.shade300, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$time - $medName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(instruction, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyPharmacyTile() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, color: Colors.teal, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Find Emergency Pharmacy', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)),
                  Text('Nearby 24/7 locations open now', style: TextStyle(color: Colors.teal, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.teal, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.black38,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Prescriptions'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
      ],
    );
  }
}
