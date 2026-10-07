import 'package:flutter/material.dart';

import '../models/prescription.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import '../widgets/auth_gate.dart';
import 'med_cabinet_screen.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  List<UpcomingDose>? _upcomingDoses;
  List<Medication>? _medications;
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
      final doses = (profile['upcoming_doses'] as List<dynamic>? ?? [])
          .map((e) => UpcomingDose.fromJson(e as Map<String, dynamic>))
          .toList();
      final medications = (profile['medications'] as List<dynamic>? ?? [])
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _upcomingDoses = doses;
        _medications = medications;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _upcomingDoses = null;
        _medications = null;
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
            // 1. Medicine Reminders -- the patient/physio-editable "what I
            // take" list (PatientMedication). Only shown once there's
            // something to show, so an empty profile doesn't just render
            // empty whitespace at the top of the screen.
            if (!_loading && _medications != null && _medications!.isNotEmpty) ...[
              const Text(
                'MEDICINE REMINDERS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),
              _buildMedicationRemindersCard(),
              const SizedBox(height: 20),
            ],

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

  Widget _buildMedicationRemindersCard() {
    // Backend ordering is time_of_day/created_at, which sorts alphabetically
    // (evening, morning, night) rather than chronologically -- re-sorted
    // here to the actual order the day happens in.
    final medications = [..._medications!]..sort((a, b) => _slotRank(a.timeOfDay).compareTo(_slotRank(b.timeOfDay)));
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            for (int i = 0; i < medications.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildSlotRow(
                slot: medications[i].timeOfDay,
                title: '${medications[i].timeOfDayLabel} - ${medications[i].name}',
                subtitle: medications[i].instructions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Shared row chrome for both the Medicine Reminders and Upcoming Dosages
  // cards: a light tint of green per time-of-day slot (morning lightest,
  // night darkest) so entries visually group by when they're taken at a
  // glance, without needing a separate section header per slot.
  Widget _buildSlotRow({required String slot, required String title, required String subtitle}) {
    final bg = _slotBackground(slot);
    final accent = _slotAccent(slot);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.circle, color: accent, size: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: accent)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
        ],
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

  // Merges the backend's real Rx-based upcoming_doses with a client-side
  // "next occurrence" computed for each plain Medicine Reminder (see
  // Medication.nextDoseAt's doc comment for why that half isn't backend-
  // computed) into one list, ascending by time (soonest dose first).
  List<_DoseRow> _buildDoseRows() {
    final rows = <_DoseRow>[
      for (final d in _upcomingDoses ?? const <UpcomingDose>[])
        _DoseRow(
          doseAt: d.doseAt,
          name: d.name,
          subtitle: d.dosage.isNotEmpty ? d.dosage : d.slotLabel,
          // Django's get_FOO_display() just capitalizes the TIME_CHOICES key
          // (morning -> "Morning"), so this reliably recovers the raw slot.
          slot: d.slotLabel.toLowerCase(),
        ),
    ];
    final nowNepal = _nepalNow();
    for (final m in _medications ?? const <Medication>[]) {
      final at = m.nextDoseAt(nowNepal);
      if (at == null) continue;
      rows.add(_DoseRow(
        doseAt: at,
        name: m.name,
        subtitle: m.instructions.isNotEmpty ? m.instructions : m.timeOfDayLabel,
        slot: m.timeOfDay,
      ));
    }
    rows.sort((a, b) => a.doseAt.compareTo(b.doseAt));
    return rows;
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
    if (_upcomingDoses == null && _medications == null) {
      return _buildSignInPrompt('Sign in to see your upcoming doses.');
    }
    final rows = _buildDoseRows();
    if (rows.isEmpty) {
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
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildSlotRow(
                slot: rows[i].slot,
                title: '${_formatNepalTime(rows[i].doseAt)} - ${rows[i].name}',
                subtitle: rows[i].subtitle,
              ),
            ],
          ],
        ),
      ),
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

// One row in the merged "Upcoming Dosages" list -- either a real Rx dose
// (from the backend) or a computed Medicine Reminder next-occurrence; by
// the time it's a _DoseRow the two are indistinguishable for display.
// `slot` is the raw time-of-day key ('morning'/'evening'/'night'), used
// only for the shade-of-green grouping color, not for sorting (doseAt is).
class _DoseRow {
  final DateTime doseAt;
  final String name;
  final String subtitle;
  final String slot;
  const _DoseRow({required this.doseAt, required this.name, required this.subtitle, required this.slot});
}

// Chronological rank for the three slots -- used to display Medicine
// Reminders in the order the day actually happens in, since the backend's
// own ordering (time_of_day, created_at) sorts those three choice keys
// alphabetically (evening, morning, night).
int _slotRank(String slot) {
  switch (slot) {
    case 'morning':
      return 0;
    case 'evening':
      return 1;
    case 'night':
      return 2;
    default:
      return 3;
  }
}

// Shared green-shade mapping so Medicine Reminders and Upcoming Dosages
// group visually by time-of-day the same way: lighter green earlier in the
// day, darker toward night.
Color _slotBackground(String slot) {
  switch (slot) {
    case 'morning':
      return Colors.green.shade50;
    case 'evening':
      return Colors.green.shade100;
    case 'night':
      return Colors.green.shade200;
    default:
      return Colors.green.shade50;
  }
}

Color _slotAccent(String slot) {
  switch (slot) {
    case 'morning':
      return Colors.green.shade400;
    case 'evening':
      return Colors.green.shade700;
    case 'night':
      return Colors.green.shade900;
    default:
      return Colors.green.shade700;
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

// "Now" in Nepal wall-clock terms, stored as a UTC-flagged DateTime purely
// as a field-holding trick (see Medication.nextDoseAt) -- mirrors how
// _formatNepalTime derives Nepal fields from a real instant, just starting
// from the device's current time instead of a parsed one.
DateTime _nepalNow() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 45));
