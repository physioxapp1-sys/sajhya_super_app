import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'lab_test_screen.dart';

// Review/confirm step for a lab test request -- mirrors the Shop/Pharmacy
// CheckoutScreen's itemized-summary + notes + confirm pattern, even though
// the backend here takes no delivery address (patient_api_lab_request_create
// only accepts test_ids + notes -- sample collection is arranged by the
// clinic afterward, not a delivery).
class LabCheckoutScreen extends StatefulWidget {
  final List<LabTest> tests;
  const LabCheckoutScreen({super.key, required this.tests});

  @override
  State<LabCheckoutScreen> createState() => _LabCheckoutScreenState();
}

class _LabCheckoutScreenState extends State<LabCheckoutScreen> {
  final _notesController = TextEditingController();
  bool _submitting = false;
  String? _error;

  double get _total => widget.tests.fold(0.0, (sum, t) => sum + t.price);

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ApiService().submitLabRequest(
        widget.tests.map((t) => t.id).toList(),
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Request Sent'),
            ],
          ),
          content: Text(
            'Request #${result['request_number']}\nTotal: NPR ${result['total']}\n\n'
            'The clinic will contact you, or you can visit the lab directly.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      // Pop back to Lab Test with a signal to clear the selection, same
      // success contract the old direct-submit flow had.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Confirm Request', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const Text('Selected tests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF12366B))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE8F5)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < widget.tests.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.tests[i].name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF12366B)),
                          ),
                        ),
                        Text(
                          'NPR ${widget.tests[i].price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF12366B)),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 14, color: Color(0xFF6B8098))),
                      const Spacer(),
                      Text(
                        'NPR ${_total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2384E8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Notes (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF12366B))),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Fasting status, preferred time, or anything else the lab should know',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2384E8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Confirm Request', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}
