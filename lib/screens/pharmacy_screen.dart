import 'package:flutter/material.dart';

import '../models/prescription.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import '../widgets/auth_gate.dart';
import 'med_cabinet_screen.dart';
import 'prescriptions_screen.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  List<Prescription>? _prescriptions;
  List<UpcomingDose>? _upcomingDoses;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Pharmacy is browsable without login (soft gate), so a failed fetch here
  // -- whether that's "not logged in" or a genuine network error -- just
  // falls back to the same lightweight sign-in/retry prompt rather than
  // forcing a login screen open on page load. Mirrors how AuthState.checkSession
  // treats any failure from a login-required call uniformly.
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await ApiService().getMedicalProfile();
      final prescriptions = (profile['prescriptions'] as List<dynamic>? ?? [])
          .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
          .toList();
      final doses = (profile['upcoming_doses'] as List<dynamic>? ?? [])
          .map((e) => UpcomingDose.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _prescriptions = prescriptions;
        _upcomingDoses = doses;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _prescriptions = null;
        _upcomingDoses = null;
        _loading = false;
      });
    }
  }

  Future<void> _signInAndReload() async {
    final ok = await ensureLoggedIn(context);
    if (ok) _load();
  }

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
        title: const Text(
          'Pharmacy',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
            _buildQuickActionsGrid(context),
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

  Widget _buildSignInPrompt(String message) {
    final loggedIn = AuthState().isLoggedIn;
    return Card(
      elevation: 0,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.medical_information_outlined, color: Colors.teal.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: Colors.teal.shade900, fontSize: 13)),
            ),
            TextButton(
              onPressed: _signInAndReload,
              child: Text(loggedIn ? 'Retry' : 'Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRxStatusCard(BuildContext context) {
    if (_loading) {
      return const Card(
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_prescriptions == null) {
      return _buildSignInPrompt('Sign in to see your current prescriptions.');
    }
    final active = _prescriptions!.where((p) => p.isActive).toList();
    if (active.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No active prescriptions right now.', style: TextStyle(color: Colors.black54)),
        ),
      );
    }
    final headline = active.first;
    final moreCount = active.length - 1;

    void openAll() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PrescriptionsScreen(prescriptions: _prescriptions!)),
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
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'ACTIVE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(headline.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (headline.dosage.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(headline.dosage, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 4),
              Text('Taken ${headline.timeOfDayLabel.toLowerCase()}', style: const TextStyle(color: Colors.black54)),
              if (moreCount > 0) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '+$moreCount more prescription${moreCount == 1 ? '' : 's'}',
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

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildGridItem(Icons.camera_alt_outlined, 'Scan & Upload', 'For new prescriptions', () {}),
        _buildGridItem(Icons.autorenew, '1-Touch Refill', 'Instant re-order', () {}),
        _buildGridItem(Icons.volunteer_activism_outlined, 'Discounts & Subsidy', 'Apply for govt. subsidy or discounts', () {}),
        _buildGridItem(
          Icons.medical_services_outlined,
          'Med Cabinet',
          'Browse & search medicines',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedCabinetScreen())),
        ),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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
    if (_loading) {
      return const Card(
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_upcomingDoses == null) {
      return _buildSignInPrompt('Sign in to see your upcoming doses.');
    }
    if (_upcomingDoses!.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No doses due in the next 24 hours.', style: TextStyle(color: Colors.black54)),
        ),
      );
    }
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            for (int i = 0; i < _upcomingDoses!.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              _buildDosageRow(_upcomingDoses![i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDosageRow(UpcomingDose dose) {
    return Row(
      children: [
        Icon(Icons.check_box_outline_blank, color: Colors.teal.shade300, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_formatNepalTime(dose.doseAt)} - ${dose.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(
                dose.dosage.isNotEmpty ? dose.dosage : dose.slotLabel,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
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

// Dose times come from the backend as Nepal-local clock times serialized
// with their UTC+05:45 offset (get_nepal_time() in personal_account/models.py
// -- this app is Nepal-only). DateTime.parse keeps that as an absolute
// instant, not a Nepal wall-clock time, so it's converted back explicitly
// here rather than trusting the device's own timezone to match.
String _formatNepalTime(DateTime instant) {
  final nepal = instant.toUtc().add(const Duration(hours: 5, minutes: 45));
  final hour12 = nepal.hour % 12 == 0 ? 12 : nepal.hour % 12;
  final period = nepal.hour < 12 ? 'AM' : 'PM';
  final minute = nepal.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}
