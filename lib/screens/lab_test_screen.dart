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
  List<LabPanel> _panels = [];
  bool _loading = true;
  String? _error;

  final Set<int> selectedTests = {};

  @override
  void initState() {
    super.initState();
    _loadTests();
    _loadPanels();
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

  Future<void> _loadPanels() async {
    // Best-effort: no active panels yet is expected until seeded, so any
    // failure here just leaves the banner on its static illustrative list
    // rather than blocking or erroring the whole screen.
    try {
      final raw = await ApiService().getLabPanels();
      if (!mounted) return;
      setState(() => _panels = raw.map(LabPanel.fromJson).toList());
    } catch (_) {}
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
              _PackagesBanner(panels: _panels, allTests: _tests),
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
  final List<LabPanel> panels;
  final List<LabTest> allTests;

  const _PackagesBanner({required this.panels, required this.allTests});

  // Illustrative fallback shown until real LabTestPanel rows exist on the
  // backend (see lab_app.management.commands.seed_lab_panels) -- matches
  // the packages sajhya.com's own site copy already promises.
  static const List<(String, String, IconData, Color)> _placeholderPackages = [
    (
      'Diabetes Panel',
      'Fasting sugar, PP sugar & HbA1c bundled together.',
      Icons.bloodtype_outlined,
      Color(0xFF7754C7),
    ),
    (
      'Fever Panel',
      'CBC plus common fever screens for quick evaluation.',
      Icons.thermostat_outlined,
      Color(0xFFE07A3F),
    ),
    (
      'Master Health Checkup',
      'A comprehensive panel covering blood count, sugar, lipids, liver & kidney function.',
      Icons.health_and_safety_outlined,
      Color(0xFF2384E8),
    ),
  ];

  static const List<Color> _panelColors = [
    Color(0xFF7754C7),
    Color(0xFFE07A3F),
    Color(0xFF2384E8),
    Color(0xFF35A981),
  ];

  void _notify(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name — contact us to book this package')),
    );
  }

  void _openPanelDetails(BuildContext context, LabPanel panel, Color color) {
    final byId = {for (final t in allTests) t.id: t};
    final included = panel.testIds
        .map((id) => byId[id])
        .whereType<LabTest>()
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _PanelDetailsSheet(
        panel: panel,
        includedTests: included,
        color: color,
      ),
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
        if (panels.isEmpty)
          ..._placeholderPackages.map((pkg) {
            final (name, description, icon, color) = pkg;
            return _packageCard(
              context,
              name: name,
              description: description,
              icon: icon,
              color: color,
              onTap: () => _notify(context, name),
            );
          })
        else
          ...panels.asMap().entries.map((entry) {
            final panel = entry.value;
            final color = _panelColors[entry.key % _panelColors.length];
            final savings = double.tryParse(panel.savings) ?? 0;
            final description = savings > 0
                ? '${panel.description} Save NPR ${savings.toStringAsFixed(0)} vs individual tests.'
                : panel.description;
            return _packageCard(
              context,
              name: panel.name,
              description: description,
              icon: Icons.medical_information_outlined,
              color: color,
              price: panel.price,
              onTap: () => _openPanelDetails(context, panel, color),
            );
          }),
      ],
    );
  }

  Widget _packageCard(
    BuildContext context, {
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? price,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
              if (price != null) ...[
                Text(
                  'NPR ${double.tryParse(price)?.toStringAsFixed(0) ?? price}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelDetailsSheet extends StatelessWidget {
  final LabPanel panel;
  final List<LabTest> includedTests;
  final Color color;

  const _PanelDetailsSheet({
    required this.panel,
    required this.includedTests,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(panel.price) ?? 0;
    final savings = double.tryParse(panel.savings) ?? 0;
    final alaCarteTotal = includedTests.fold<double>(0, (sum, t) => sum + t.price);

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
                  radius: 28,
                  backgroundColor: color.withOpacity(.12),
                  child: Icon(Icons.medical_information_outlined, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        panel.name,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF12366B),
                        ),
                      ),
                      Text(
                        '${includedTests.length} tests included',
                        style: const TextStyle(
                          color: Color(0xFF56718E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (panel.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                panel.description,
                style: const TextStyle(height: 1.5, color: Color(0xFF526A83)),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Package price',
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B8098)),
                        ),
                        Text(
                          'NPR ${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (savings > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'NPR ${alaCarteTotal.toStringAsFixed(0)} individually',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B8098),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          'You save NPR ${savings.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF22A06B),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'What\'s included',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12366B),
              ),
            ),
            const SizedBox(height: 8),
            ...includedTests.map((test) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: test.iconColor.withOpacity(.10),
                        child: Icon(test.icon, color: test.iconColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              test.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF12366B),
                              ),
                            ),
                            Text(
                              test.description.isNotEmpty ? test.description : test.subtitle,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B8098)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NPR ${test.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B8098),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${panel.name} — contact us to book this package')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Book This Package'),
              ),
            ),
          ],
        ),
      ),
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

class LabPanel {
  final int id;
  final String name;
  final String description;
  final String price;
  final String savings;
  final List<int> testIds;

  const LabPanel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.savings,
    required this.testIds,
  });

  factory LabPanel.fromJson(Map<String, dynamic> json) {
    return LabPanel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price']?.toString() ?? '0',
      savings: json['savings']?.toString() ?? '0',
      testIds: List<int>.from(json['test_ids'] ?? const []),
    );
  }
}
