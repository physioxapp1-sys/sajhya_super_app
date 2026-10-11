import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/exercise_library.dart';
import '../models/pharmacy_product.dart';
import '../models/shop_product.dart';
import '../services/smart_search.dart';
import 'exercise_detail_screen.dart';
import 'exercise_video_screen.dart';
import 'lab_test_screen.dart';
import 'med_cabinet_screen.dart';
import 'pharmacy_product_detail_screen.dart';
import 'shop_product_detail_screen.dart';
import 'shop_screen.dart';

class SmartSearchResultsScreen extends StatefulWidget {
  final String query;
  const SmartSearchResultsScreen({super.key, required this.query});

  @override
  State<SmartSearchResultsScreen> createState() => _SmartSearchResultsScreenState();
}

class _SmartSearchResultsScreenState extends State<SmartSearchResultsScreen> {
  SmartSearchResults? _results;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await runSmartSearch(widget.query);
      if (!mounted) return;
      setState(() {
        _results = results;
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
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1261B5)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          '"${widget.query}"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
        ),
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
              OutlinedButton(onPressed: _run, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final results = _results!;
    if (results.nothingTriggered) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, color: Colors.grey[400], size: 48),
              const SizedBox(height: 12),
              const Text("Couldn't tell what you're looking for.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              Text(
                'Try mentioning what you need, e.g. "knee brace" or "diabetes test".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (results.shop.triggered) _ShopSection(result: results.shop),
        if (results.pharmacy.triggered) _PharmacySection(result: results.pharmacy),
        if (results.lab.triggered) _LabSection(result: results.lab),
        if (results.exercise.triggered) _ExerciseSection(result: results.exercise),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1261B5)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF12366B))),
        ],
      ),
    );
  }
}

class _BrowsePrompt extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onTap;
  const _BrowsePrompt({required this.message, required this.buttonLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E9FA)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF12366B), fontSize: 13))),
          const SizedBox(width: 8),
          TextButton(onPressed: onTap, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
    );
  }
}

class _ShopSection extends StatelessWidget {
  final SmartCategoryResult<ShopProduct> result;
  const _ShopSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.medical_services_outlined, title: 'Shop'),
          if (result.genericOnly)
            _BrowsePrompt(
              message: 'Browse health products & equipment in Shop.',
              buttonLabel: 'Browse',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
            )
          else if (result.items.isEmpty)
            _EmptyRow(message: 'No products match "${result.searchTerm}".')
          else
            ...result.items.map((p) => _ResultTile(
                  name: p.name,
                  subtitle: p.category,
                  price: 'NPR ${p.displayPrice.toStringAsFixed(0)}',
                  imageUrl: p.imageUrl,
                  icon: Icons.medical_services_outlined,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopProductDetailScreen(product: p))),
                )),
        ],
      ),
    );
  }
}

class _PharmacySection extends StatelessWidget {
  final SmartCategoryResult<PharmacyProduct> result;
  const _PharmacySection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.medication_outlined, title: 'Pharmacy'),
          if (result.genericOnly)
            _BrowsePrompt(
              message: 'Browse medicines in Med Cabinet, or search a specific name.',
              buttonLabel: 'Browse',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedCabinetScreen())),
            )
          else if (result.items.isEmpty)
            _EmptyRow(message: 'No medicines match "${result.searchTerm}".')
          else
            ...result.items.map((p) => _ResultTile(
                  name: p.name,
                  subtitle: p.category,
                  price: 'NPR ${p.price.toStringAsFixed(0)}',
                  imageUrl: p.imageUrl,
                  icon: Icons.medication_outlined,
                  badge: p.requiresPrescription ? 'Rx' : null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PharmacyProductDetailScreen(product: p))),
                )),
        ],
      ),
    );
  }
}

class _LabSection extends StatelessWidget {
  final SmartCategoryResult<LabTest> result;
  const _LabSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.science_outlined, title: 'Lab Tests'),
          if (result.genericOnly)
            _BrowsePrompt(
              message: 'Browse the lab test catalog, or name a specific test.',
              buttonLabel: 'Browse',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabTestScreen())),
            )
          else if (result.items.isEmpty)
            _EmptyRow(message: 'No tests match "${result.searchTerm}".')
          else
            ...result.items.map((t) => _ResultTile(
                  name: t.name,
                  subtitle: t.subtitle,
                  price: 'NPR ${t.price.toStringAsFixed(0)}',
                  imageUrl: null,
                  icon: t.icon,
                  iconColor: t.iconColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabTestScreen())),
                )),
        ],
      ),
    );
  }
}

class _ExerciseSection extends StatelessWidget {
  final SmartCategoryResult<LibraryExercise> result;
  const _ExerciseSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.fitness_center_rounded, title: 'Exercises'),
          if (result.genericOnly)
            _BrowsePrompt(
              message: 'Browse the exercise library, or name what you want to work on.',
              buttonLabel: 'Browse',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseVideoScreen())),
            )
          else if (result.items.isEmpty)
            _EmptyRow(message: 'No exercises match "${result.searchTerm}".')
          else
            ...result.items.map((e) => _ResultTile(
                  name: e.name,
                  subtitle: [e.regionName, e.subRegionName].whereType<String>().join(' • '),
                  price: '${e.defaultSets} × ${e.defaultReps}',
                  imageUrl: e.exerciseUrl,
                  icon: Icons.fitness_center_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: e))),
                )),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String price;
  final String? imageUrl;
  final IconData icon;
  final Color iconColor;
  final String? badge;
  final VoidCallback onTap;

  const _ResultTile({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.imageUrl,
    required this.icon,
    this.iconColor = Colors.teal,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                color: const Color(0xFFF0F4F6),
                child: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Icon(icon, color: iconColor, size: 22),
                      )
                    : Icon(icon, color: iconColor, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(4)),
                          child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
