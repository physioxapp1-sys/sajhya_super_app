import 'package:flutter/material.dart';

class LabTestScreen extends StatefulWidget {
  const LabTestScreen({super.key});

  @override
  State<LabTestScreen> createState() => _LabTestScreenState();
}

class _LabTestScreenState extends State<LabTestScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<LabTest> popularTests = const [
    LabTest(
      name: 'HbA1c',
      patientName: 'Average Blood Sugar Test',
      description: 'Shows your average blood sugar over the past 2–3 months.',
      sample: 'Blood',
      turnaround: '1 day',
      icon: Icons.bloodtype_outlined,
      iconColor: Color(0xFFE45555),
    ),
    LabTest(
      name: 'Complete Blood Count (CBC)',
      patientName: 'Blood Cell Test',
      description: 'Checks different types of blood cells.',
      sample: 'Blood',
      turnaround: '1 day',
      icon: Icons.scatter_plot_outlined,
      iconColor: Color(0xFFD94B4B),
    ),
    LabTest(
      name: 'TSH',
      patientName: 'Thyroid Function Test',
      description: 'Checks how well your thyroid is working.',
      sample: 'Blood',
      turnaround: '1 day',
      icon: Icons.monitor_heart_outlined,
      iconColor: Color(0xFFE66B6B),
    ),
    LabTest(
      name: 'LFT',
      patientName: 'Liver Function Test',
      description: 'Checks how well your liver is working.',
      sample: 'Blood',
      turnaround: '1 day',
      icon: Icons.medical_services_outlined,
      iconColor: Color(0xFFD85656),
    ),
    LabTest(
      name: 'KFT',
      patientName: 'Kidney Function Test',
      description: 'Checks how well your kidneys are working.',
      sample: 'Blood',
      turnaround: '1 day',
      icon: Icons.water_drop_outlined,
      iconColor: Color(0xFFC84A4A),
    ),
    LabTest(
      name: 'Lipid Profile',
      patientName: 'Cholesterol & Fat Test',
      description: 'Checks cholesterol and fats in your blood.',
      sample: 'Blood',
      turnaround: '1 day',
      icon: Icons.favorite_outline,
      iconColor: Color(0xFFE05252),
    ),
  ];

  final List<BodySystem> bodySystems = const [
    BodySystem('Blood', Icons.bloodtype_outlined),
    BodySystem('Heart', Icons.favorite_outline),
    BodySystem('Lungs', Icons.air_outlined),
    BodySystem('Bones & Joints', Icons.accessibility_new_outlined),
    BodySystem('Brain & Nerves', Icons.psychology_outlined),
    BodySystem('Thyroid', Icons.medical_information_outlined),
    BodySystem('Kidney', Icons.water_drop_outlined),
    BodySystem('Liver', Icons.medical_services_outlined),
  ];

  final List<Symptom> symptoms = const [
    Symptom('Fatigue', Icons.battery_2_bar_outlined),
    Symptom('Fever', Icons.thermostat_outlined),
    Symptom('Joint pain', Icons.accessibility_new_outlined),
    Symptom('Weakness', Icons.fitness_center_outlined),
    Symptom('Frequent urination', Icons.water_drop_outlined),
    Symptom('Weight changes', Icons.monitor_weight_outlined),
  ];

  final Set<String> selectedTests = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchTests(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return;

    final results = popularTests.where((test) {
      return test.name.toLowerCase().contains(query) ||
          test.patientName.toLowerCase().contains(query) ||
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
      if (selectedTests.contains(test.name)) {
        selectedTests.remove(test.name);
      } else {
        selectedTests.add(test.name);
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
        isSelected: selectedTests.contains(test.name),
        onAdd: () {
          _toggleTest(test);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openSymptoms() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _SymptomsSheet(
        symptoms: symptoms,
        onSelected: (symptom) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Showing investigations that may be relevant to $symptom',
              ),
            ),
          );
        },
      ),
    );
  }

  void _openBodySystems() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _BodySystemsSheet(
        systems: bodySystems,
        onSelected: (system) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Showing tests related to $system')),
          );
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
                onSymptoms: _openSymptoms,
                onBodySystem: _openBodySystems,
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Popular / Common Tests',
                icon: Icons.local_fire_department_rounded,
                onViewAll: () {},
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isWide ? 2.55 : 1.85,
                ),
                itemCount: popularTests.length,
                itemBuilder: (_, index) {
                  final test = popularTests[index];
                  return _LabTestCard(
                    test: test,
                    selected: selectedTests.contains(test.name),
                    onView: () => _showTestDetails(test),
                    onAdd: () => _toggleTest(test),
                  );
                },
              ),
              const SizedBox(height: 20),
              _SafetyBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onSymptoms;
  final VoidCallback onBodySystem;

  const _HeroSection({
    required this.controller,
    required this.onSearch,
    required this.onSymptoms,
    required this.onBodySystem,
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
            'Search by test name, symptom or browse by body system.',
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
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFD3E2F1))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR FIND BY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFD3E2F1))),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 650) {
                return Column(
                  children: [
                    _PathCard(
                      icon: Icons.science_outlined,
                      title: 'Test Name',
                      subtitle: 'Search for a specific test or abbreviation.',
                      example: 'e.g. HbA1c, CBC, LFT',
                      color: const Color(0xFFE8F3FF),
                      iconColor: const Color(0xFF3288E8),
                      onTap: () => FocusScope.of(context).requestFocus(),
                    ),
                    const SizedBox(height: 12),
                    _PathCard(
                      icon: Icons.person_search_outlined,
                      title: 'Symptoms',
                      subtitle:
                          'Tell us what you are feeling. We’ll show relevant tests.',
                      example: 'e.g. fatigue, fever, joint pain',
                      color: const Color(0xFFEAF9F3),
                      iconColor: const Color(0xFF35A981),
                      onTap: onSymptoms,
                    ),
                    const SizedBox(height: 12),
                    _PathCard(
                      icon: Icons.accessibility_new_outlined,
                      title: 'Body System',
                      subtitle: 'Browse by body system to find related tests.',
                      example: 'e.g. heart, liver, kidney',
                      color: const Color(0xFFF3ECFF),
                      iconColor: const Color(0xFF7754C7),
                      onTap: onBodySystem,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _PathCard(
                      icon: Icons.science_outlined,
                      title: 'Test Name',
                      subtitle: 'Search for a specific test or abbreviation.',
                      example: 'e.g. HbA1c, CBC, LFT',
                      color: const Color(0xFFE8F3FF),
                      iconColor: const Color(0xFF3288E8),
                      onTap: () => FocusScope.of(context).requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PathCard(
                      icon: Icons.person_search_outlined,
                      title: 'Symptoms',
                      subtitle:
                          'Tell us what you are feeling. We’ll show relevant tests.',
                      example: 'e.g. fatigue, fever, joint pain',
                      color: const Color(0xFFEAF9F3),
                      iconColor: const Color(0xFF35A981),
                      onTap: onSymptoms,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PathCard(
                      icon: Icons.accessibility_new_outlined,
                      title: 'Body System',
                      subtitle: 'Browse by body system to find related tests.',
                      example: 'e.g. heart, liver, kidney',
                      color: const Color(0xFFF3ECFF),
                      iconColor: const Color(0xFF7754C7),
                      onTap: onBodySystem,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String example;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _PathCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.example,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(.58),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white.withOpacity(.75),
              child: Icon(icon, color: iconColor, size: 27),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14386C),
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: iconColor),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF55718E),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                example,
                style: TextStyle(
                  fontSize: 11,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
                      test.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B6786),
                      ),
                    ),
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
              Text(
                'Sample: ${test.sample}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF5B7695),
                ),
              ),
              const SizedBox(width: 14),
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
              const Spacer(),
              OutlinedButton(
                onPressed: onView,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(65, 34),
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
                  'Use the symptom guide or speak with your doctor for personalized advice.',
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
  final Set<String> selectedTests;

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
                  subtitle: Text(test.patientName),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        onPressed: () => onView(test),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        onPressed: () => onAdd(test),
                        icon: Icon(
                          selectedTests.contains(test.name)
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: selectedTests.contains(test.name)
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
                        test.patientName,
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
            const SizedBox(height: 24),
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

class _SymptomsSheet extends StatelessWidget {
  final List<Symptom> symptoms;
  final ValueChanged<String> onSelected;

  const _SymptomsSheet({
    required this.symptoms,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 18),
            const Text(
              'What are you experiencing?',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12366B),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'We can show investigations that may be relevant for evaluation.',
              style: TextStyle(color: Color(0xFF657C94)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: symptoms
                  .map(
                    (item) => ActionChip(
                      avatar: Icon(item.icon, size: 18),
                      label: Text(item.name),
                      onPressed: () => onSelected(item.name),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodySystemsSheet extends StatelessWidget {
  final List<BodySystem> systems;
  final ValueChanged<String> onSelected;

  const _BodySystemsSheet({
    required this.systems,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 18),
            const Text(
              'Browse by Body System',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12366B),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: systems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.7,
              ),
              itemBuilder: (_, index) {
                final item = systems[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(item.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0EAF4)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: const Color(0xFF2384E8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF34506D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class LabTest {
  final String name;
  final String patientName;
  final String description;
  final String sample;
  final String turnaround;
  final IconData icon;
  final Color iconColor;

  const LabTest({
    required this.name,
    required this.patientName,
    required this.description,
    required this.sample,
    required this.turnaround,
    required this.icon,
    required this.iconColor,
  });
}

class BodySystem {
  final String name;
  final IconData icon;

  const BodySystem(this.name, this.icon);
}

class Symptom {
  final String name;
  final IconData icon;

  const Symptom(this.name, this.icon);
}
