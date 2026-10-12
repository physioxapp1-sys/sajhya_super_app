import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/refill_medication.dart';
import '../services/api_service.dart';
import '../services/cart_state.dart';
import 'checkout_screen.dart';

// "1-Touch Refill" -- browse every Medicine Reminder that's linked to a
// real PharmacyProduct (see patient_api_refill_medications's doc comment
// for why unlinked ones don't show here), pick which to refill (all
// selected by default), then one tap bulk-adds them to the pharmacy cart
// and goes straight to Checkout -- skips the "find each medicine in Med
// Cabinet" shopping trip, but still needs the one address/phone
// confirmation Checkout already handles, since there's no saved delivery
// address on file to skip that step entirely.
//
// Reached only via ensureLoggedIn-gated navigation (see pharmacy_screen.dart),
// so this screen itself assumes it's already signed in -- no soft-gate
// prompt of its own.
class RefillScreen extends StatefulWidget {
  const RefillScreen({super.key});

  @override
  State<RefillScreen> createState() => _RefillScreenState();
}

class _RefillScreenState extends State<RefillScreen> {
  List<RefillMedication>? _medications;
  bool _loading = true;
  String? _error;
  bool _ordering = false;

  final Set<int> _selectedProductIds = {};

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
      final raw = await ApiService().getRefillMedications();
      final medications = raw.map(RefillMedication.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _medications = medications;
        // Everything starts selected -- "1-touch" means the default path
        // is refilling all of it; unchecking specific ones is the
        // exception, not the rule.
        _selectedProductIds
          ..clear()
          ..addAll(medications.where((m) => m.inStock).map((m) => m.productId));
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

  void _toggle(int productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  Future<void> _orderRefill() async {
    if (_selectedProductIds.isEmpty || _ordering) return;
    setState(() => _ordering = true);
    try {
      // Sequential, not Future.wait -- these all write to the same session
      // cart dict server-side, and concurrent writes to it could race and
      // drop an item.
      for (final productId in _selectedProductIds) {
        await ApiService().addToPharmacyCart(productId);
      }
      final cartData = await ApiService().getPharmacyCart();
      final cart = CartSummary.fromJson(cartData);
      PharmacyCartState().setCount(cart.count);
      if (!mounted) return;
      // Pushed (not replaced) -- CheckoutScreen._submit() always pops
      // exactly twice on success, assuming it was reached via a 2-level
      // Cart push (see its own comment). Keeping that same stack depth
      // here (Pharmacy -> Refill -> Checkout) means that still lands back
      // on Pharmacy correctly instead of over-popping past it.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CheckoutScreen(isPharmacy: true, total: cart.total, items: cart.items)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.teal),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('1-Touch Refill', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
      bottomNavigationBar: (_medications != null && _medications!.isNotEmpty) ? _buildFooter() : null,
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
    final medications = _medications ?? [];
    if (medications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.autorenew, color: Colors.grey[400], size: 48),
              const SizedBox(height: 12),
              const Text('Nothing to refill yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              Text(
                'Add a medicine from Pharmacy\'s catalog search to your Medicine Reminders, and it\'ll show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: medications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RefillTile(
        medication: medications[i],
        selected: _selectedProductIds.contains(medications[i].productId),
        onToggle: medications[i].inStock ? () => _toggle(medications[i].productId) : null,
      ),
    );
  }

  Widget _buildFooter() {
    final count = _selectedProductIds.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: (count == 0 || _ordering) ? null : _orderRefill,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _ordering
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text('Order Refill${count > 0 ? ' ($count)' : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _RefillTile extends StatelessWidget {
  final RefillMedication medication;
  final bool selected;
  final VoidCallback? onToggle;
  const _RefillTile({required this.medication, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.teal : Colors.black12, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Checkbox(value: selected, onChanged: onToggle == null ? null : (_) => onToggle!()),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                color: const Color(0xFFF0F4F6),
                child: medication.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: medication.imageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Icon(Icons.medication_outlined, color: Colors.grey[400]),
                      )
                    : Icon(Icons.medication_outlined, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('NPR ${medication.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal)),
                      const SizedBox(width: 8),
                      _statusChip(medication),
                    ],
                  ),
                  if (!medication.inStock) ...[
                    const SizedBox(height: 2),
                    Text('Out of stock', style: TextStyle(fontSize: 11, color: Colors.red[700])),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(RefillMedication m) {
    late final MaterialColor color;
    late final String label;
    if (!m.everPurchased) {
      color = Colors.grey;
      label = 'Not ordered yet';
    } else if (m.isOverdue) {
      color = Colors.red;
      label = 'Refill overdue';
    } else if (m.isLow) {
      color = Colors.orange;
      label = '${m.daysRemaining}d left';
    } else {
      color = Colors.green;
      label = '${m.daysRemaining}d left';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.shade700)),
    );
  }
}
