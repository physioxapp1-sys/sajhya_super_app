import 'package:flutter/material.dart';

import '../services/api_service.dart';

class LabTestScreen extends StatefulWidget {
  const LabTestScreen({super.key});

  @override
  State<LabTestScreen> createState() => _LabTestScreenState();
}

class _LabTestScreenState extends State<LabTestScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<LabTest> _tests = [];
  List<LabTest> _popularTests = [];
  bool _loading = true;
  String? _error;

  final Set<int> selectedTests = {};

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTests() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService().getLabTests();
      final tests = raw.map(LabTest.fromJson).toList();
      final shuffled = List<LabTest>.of(tests)..shuffle();
      setState(() {
        _tests = tests;
        _popularTests = shuffled.take(6).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _searchTests(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return;

    final results = _tests.where((test) {
      return test.name.toLowerCase().contains(query) ||
          test.subtitle.toLowerCase().contains(query) ||
          test.description.toLowerCase().contains(query);
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _SearchResultsSheet(
        query: value,
        results: results,
        onView: _showTestDetails,
        onAdd: _toggleTest,
        selectedTests: selectedTests,
      ),
    );
  }

  void _toggleTest(LabTest test) {
    setState(() {
      if (selectedTests.contains(test.id)) {
        selectedTests.remove(test.id);
      } else {
        selectedTests.add(test.id);
      }
    });
  }

  void _showTestDetails(LabTest test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _TestDetailsSheet(
        test: test,
        isSelected: selectedTests.contains(test.id),
        onAdd: () {
          _toggleTest(test);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Find a Lab Test',
          style: TextStyle(
            color: Color(0xFF12366B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isWide ? 32 : 16,
            16,
            isWide ? 32 : 16,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroSection(
                controller: _searchController,
                onSearch: _searchTests,
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Popular / Common Tests',
                icon: Icons.local_fire_department_rounded,
                onViewAll: () {},
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorState(message: _error!, onRetry: _loadTests)
              else if (_popularTests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('No tests available right now.')),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: isWide ? 2.55 : 1.7,
                  ),
                  itemCount: _popularTests.length,
                  itemBuilder: (_, index) {
                    final test = _popularTests[index];
                    return _LabTestCard(
                      test: test,
                      selected: selectedTests.contains(test.id),
                      onView: () => _showTestDetails(test),
                      onAdd: () => _toggleTest(test),
                    );
                  },
                ),
              const SizedBox(height: 24),
              const _PackagesBanner(),
              const SizedBox(height: 20),
              _SafetyBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFF9AAFC4), size: 36),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B8098)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  const _HeroSection({
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF5FF), Color(0xFFF5FAFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find a Lab Test',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12366B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Search by test name or abbreviation.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF456789),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSearch,
            decoration: InputDecoration(
              hintText:
                  'Search test name or abbreviation (e.g. HbA1c, CBC, TSH)',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF52749C),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(6),
                child: ElevatedButton(
                  onPressed: () => onSearch(controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2384E8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Search'),
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFD4E5F7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFD4E5F7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF2384E8),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF7A2F), size: 25),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12366B),
            ),
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All →'),
        ),
      ],
    );
  }
}

class _LabTestCard extends StatelessWidget {
  final LabTest test;
  final bool selected;
  final VoidCallback onView;
  final VoidCallback onAdd;

  const _LabTestCard({
    required this.test,
    required this.selected,
    required this.onView,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: test.iconColor.withOpacity(.10),
                child: Icon(
                  test.icon,
                  color: test.iconColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12366B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      test.subtitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B6786),
                      ),
                    ),
                    if (test.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        test.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFF6B8098),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                'NPR ${test.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22A06B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.water_drop_outlined,
                size: 15,
                color: Color(0xFF5B7695),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Sample: ${test.sample}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5B7695),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: Color(0xFF5B7695),
              ),
              const SizedBox(width: 4),
              Text(
                test.turnaround,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF5B7695),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onView,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(60, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View'),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton.filled(
                  onPressed: onAdd,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: selected
                        ? const Color(0xFF22A06B)
                        : const Color(0xFF2384E8),
                  ),
                  icon: Icon(
                    selected ? Icons.check_rounded : Icons.add_rounded,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackagesBanner extends StatelessWidget {
  const _PackagesBanner();

  static const List<(String, String, IconData, Color)> _packages = [
    (
      'Diabetes Panel',
      'Fasting sugar, PP sugar & HbA1c bundled together.',
      Icons.bloodtype_outlined,
      Color(0xFF7754C7),
    ),
    (
      'Whole Body Checkup',
      'A broad general-health panel covering major organ systems.',
      Icons.health_and_safety_outlined,
      Color(0xFF2384E8),
    ),
  ];

  void _notify(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name — contact us to book this package')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Packages & Panels',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF12366B),
          ),
        ),
        const SizedBox(height: 10),
        ..._packages.map((pkg) {
          final (name, description, icon, color) = pkg;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _notify(context, name),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(.25)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(.12),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12366B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B8098),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: color),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E9FA)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: const Color(0xFF3288E8),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not sure which tests you need?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12366B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Speak with your doctor for advice on which tests are right for you.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFF55718E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsSheet extends StatelessWidget {
  final String query;
  final List<LabTest> results;
  final Function(LabTest) onView;
  final Function(LabTest) onAdd;
  final Set<int> selectedTests;

  const _SearchResultsSheet({
    required this.query,
    required this.results,
    required this.onView,
    required this.onAdd,
    required this.selectedTests,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Results for "$query"',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12366B),
              ),
            ),
            const SizedBox(height: 12),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 35),
                child: Center(
                  child: Text(
                    'No matching tests found.\nTry a test name, abbreviation, or keyword.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...results.map(
                (test) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: test.iconColor.withOpacity(.10),
                    child: Icon(test.icon, color: test.iconColor),
                  ),
                  title: Text(
                    test.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(test.subtitle),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        onPressed: () => onView(test),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        onPressed: () => onAdd(test),
                        icon: Icon(
                          selectedTests.contains(test.id)
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: selectedTests.contains(test.id)
                              ? Colors.green
                              : const Color(0xFF2384E8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TestDetailsSheet extends StatelessWidget {
  final LabTest test;
  final bool isSelected;
  final VoidCallback onAdd;

  const _TestDetailsSheet({
    required this.test,
    required this.isSelected,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: test.iconColor.withOpacity(.10),
                  child: Icon(test.icon, color: test.iconColor, size: 32),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.name,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12366B),
                        ),
                      ),
                      Text(
                        test.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF56718E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'NPR ${test.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF22A06B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (test.description.isNotEmpty) ...[
              const Text(
                'What is this test?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF12366B),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                test.description,
                style: const TextStyle(
                  height: 1.5,
                  color: Color(0xFF526A83),
                ),
              ),
              const SizedBox(height: 20),
            ],
            _InfoRow(
              icon: Icons.water_drop_outlined,
              title: 'Sample',
              value: test.sample,
            ),
            _InfoRow(
              icon: Icons.access_time_rounded,
              title: 'Typical turnaround',
              value: test.turnaround,
            ),
            const SizedBox(height: 20),
            const Text(
              'Preparation',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12366B),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Preparation requirements can vary by laboratory and by the complete set of tests ordered. Follow the instructions provided by your laboratory or healthcare professional.',
              style: TextStyle(
                height: 1.5,
                color: Color(0xFF526A83),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: Icon(
                  isSelected ? Icons.check_rounded : Icons.add_rounded,
                ),
                label: Text(
                  isSelected ? 'Added to My Tests' : 'Add to My Tests',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFF22A06B)
                      : const Color(0xFF2384E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2384E8)),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF34506D),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF657C94)),
            ),
          ),
        ],
      ),
    );
  }
}

class LabTest {
  final int id;
  final String name;
  final String subtitle;
  final String description;
  final String sample;
  final String turnaround;
  final double price;
  final IconData icon;
  final Color iconColor;

  const LabTest({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.sample,
    required this.turnaround,
    required this.price,
    required this.icon,
    required this.iconColor,
  });

  factory LabTest.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? 'other';
    final style = _categoryStyle[category] ?? _categoryStyle['other']!;
    return LabTest(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      subtitle: json['category_display'] as String? ?? '',
      description: json['prep_instructions'] as String? ?? '',
      sample: json['sample_type'] as String? ?? 'Not specified',
      turnaround: json['turnaround_time'] as String? ?? 'Not specified',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      icon: style.$1,
      iconColor: style.$2,
    );
  }

  static const Map<String, (IconData, Color)> _categoryStyle = {
    'hematology': (Icons.bloodtype_outlined, Color(0xFFE45555)),
    'biochemistry': (Icons.science_outlined, Color(0xFF7754C7)),
    'hormonal': (Icons.monitor_heart_outlined, Color(0xFFE66B6B)),
    'serology': (Icons.coronavirus_outlined, Color(0xFF35A981)),
    'electrolytes': (Icons.water_drop_outlined, Color(0xFF3288E8)),
    'urine': (Icons.opacity_outlined, Color(0xFFD9A441)),
    'other': (Icons.medical_information_outlined, Color(0xFF5B7695)),
  };
}
