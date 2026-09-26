import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'models/exercise_library.dart';
import 'models/pharmacy_product.dart';
import 'screens/exercise_list_screen.dart';
import 'screens/exercise_video_screen.dart';
import 'screens/lab_test_screen.dart';
import 'screens/pharmacy_screen.dart';
import 'screens/shop_screen.dart';
import 'services/api_service.dart';

void main() => runApp(const SajhyaApp());

class SajhyaApp extends StatelessWidget {
  const SajhyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sajhya',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8FBFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1261B5),
          brightness: Brightness.light,
        ),
      ),
      home: const SajhyaHomePage(),
    );
  }
}

class ServiceItem {
  final String title;
  final String subtitle;
  final String asset;
  final Color background;
  final VoidCallback? onTap;

  const ServiceItem({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.background,
    this.onTap,
  });
}

// Carries the sub-region a recommended exercise came from, since
// LibraryExercise itself doesn't know which sub-region it was fetched
// under -- needed so tapping the card can open that exercise's list.
class _RecoExercise {
  final LibraryExercise exercise;
  final int subregionId;
  final String subregionName;

  const _RecoExercise({
    required this.exercise,
    required this.subregionId,
    required this.subregionName,
  });
}

class SajhyaHomePage extends StatefulWidget {
  const SajhyaHomePage({super.key});

  @override
  State<SajhyaHomePage> createState() => _SajhyaHomePageState();
}

class _SajhyaHomePageState extends State<SajhyaHomePage> {
  int _bottomIndex = 0;
  final TextEditingController _search = TextEditingController();

  PharmacyProduct? _recoProduct;
  List<_RecoExercise> _recoExercises = [];
  bool _recoLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  // Pulls one random pharmacy product and two random exercises (each from a
  // randomly chosen sub-region that actually has exercises) to populate
  // "Recommended for You" with real data instead of the old hardcoded list.
  // Shop has no public API yet, so it's left out of the mix for now.
  Future<void> _loadRecommendations() async {
    final rng = Random();
    try {
      final results = await Future.wait([
        ApiService().getPharmacyProducts(),
        ApiService().getBrowseRegions(),
      ]);
      final products = (results[0]).map(PharmacyProduct.fromJson).toList();
      final regions = (results[1]).map(RegionSummary.fromJson).toList();

      final product = products.isEmpty ? null : products[rng.nextInt(products.length)];

      final browsableSubregions = <SubRegionSummary>[
        for (final r in regions) ...r.subRegions.where((s) => s.exerciseCount > 0),
      ]..shuffle(rng);

      final exerciseItems = <_RecoExercise>[];
      for (final sub in browsableSubregions.take(2)) {
        try {
          final raw = await ApiService().getBrowseExercises(sub.id);
          if (raw.isEmpty) continue;
          final exercises = raw.map(LibraryExercise.fromJson).toList();
          final exercise = exercises[rng.nextInt(exercises.length)];
          exerciseItems.add(_RecoExercise(exercise: exercise, subregionId: sub.id, subregionName: sub.name));
        } catch (_) {
          // Skip this sub-region and keep whatever else loaded rather than
          // failing the whole recommendations row over one bad fetch.
        }
      }

      if (!mounted) return;
      setState(() {
        _recoProduct = product;
        _recoExercises = exerciseItems;
        _recoLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _recoLoading = false);
    }
  }

  final List<ServiceItem> services = const [
    ServiceItem(
      title: 'Shop',
      subtitle: 'Health products, rehab equipment & more',
      asset: 'assets/shop.svg',
      background: Color(0xFFEAF8F2),
    ),
    ServiceItem(
      title: 'Pharmacy',
      subtitle: 'Order medicines & health essentials',
      asset: 'assets/pharmacy.svg',
      background: Color(0xFFEAF4FF),
    ),
    ServiceItem(
      title: 'Exercise Videos',
      subtitle: 'Follow guided exercises for better recovery',
      asset: 'assets/exercise.svg',
      background: Color(0xFFFFF2E6),
    ),
    ServiceItem(
      title: 'Lab Test',
      subtitle: 'Book tests & view reports online',
      asset: 'assets/lab.svg',
      background: Color(0xFFF2F0FF),
    ),
    ServiceItem(
      title: 'Home Visits',
      subtitle: 'Doctor, physiotherapist & specialist at your home',
      asset: 'assets/home_visit.svg',
      background: Color(0xFFFFEEF2),
    ),
    ServiceItem(
      title: 'Swift Delivery',
      subtitle: 'Delivers medicines and all necessary items',
      asset: 'assets/delivery.svg',
      background: Color(0xFFEAF8FF),
    ),
  ];

  void _openService(ServiceItem service) {
    final Widget? screen = switch (service.title) {
      'Lab Test' => const LabTestScreen(),
      'Pharmacy' => const PharmacyScreen(),
      'Shop' => const ShopScreen(),
      'Exercise Videos' => const ExerciseVideoScreen(),
      _ => null,
    };

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service.title} selected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _bottomIndex,
          children: [
            _home(),
            _simplePage('Health', Icons.favorite_rounded),
            _simplePage('Records', Icons.description_rounded),
            _simplePage('Messages', Icons.chat_bubble_rounded),
            _simplePage('More', Icons.menu_rounded),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (index) {
          setState(() => _bottomIndex = index);
        },
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Health'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Records'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }

  Widget _home() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(child: _header()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverToBoxAdapter(child: _searchBar()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: _healthCard()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          sliver: SliverToBoxAdapter(
            child: _sectionTitle('Our Services', onViewAll: () {}),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = services[index];
                return _serviceCard(item);
              },
              childCount: services.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.38,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          sliver: SliverToBoxAdapter(
            child: _sectionTitle('Recommended for You', onViewAll: () {}),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(child: _recommendations()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          sliver: SliverToBoxAdapter(
            child: _sectionTitle('Recent Activity', onViewAll: () {}),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          sliver: SliverToBoxAdapter(child: _recentActivity()),
        ),
      ],
    );
  }

  Widget _header() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset('assets/icon.png', width: 42, height: 42, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        const Text(
          'Sajhya',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0B417E),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Badge(
            smallSize: 9,
            child: Icon(Icons.notifications_none_rounded, size: 29),
          ),
        ),
        const CircleAvatar(
          radius: 21,
          backgroundColor: Color(0xFFE4F0FF),
          child: Icon(Icons.person, color: Color(0xFF1261B5)),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFDDEBFA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1261B5),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 18, right: 10),
            child: Icon(Icons.search, size: 32, color: Color(0xFF1261B5)),
          ),
          Expanded(
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search medicines, tests, exercises, symptoms...',
                hintStyle: TextStyle(color: Color(0xFF7890AA), fontSize: 15),
              ),
            ),
          ),
          Container(
            height: 42,
            width: 74,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(23),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(23),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Open camera / scan')),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, color: Color(0xFF1261B5), size: 22),
                  Text('Scan', style: TextStyle(color: Color(0xFF1261B5), fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthCard() {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/health_banner.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(.55),
                    Colors.black.withOpacity(.25),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good morning 👋',
                  style: TextStyle(fontSize: 15, color: Colors.white)),
              const SizedBox(height: 4),
              const Text(
                'Your Health Today',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Stay active, stay healthy.',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(.85)),
              ),
              const Spacer(),
              Container(
                height: 62,
                margin: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.88),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    _HealthStat(icon: Icons.directions_run, value: '0/3', label: 'Exercises'),
                    _HealthStat(icon: Icons.description_outlined, value: '2', label: 'New Reports'),
                    _HealthStat(icon: Icons.calendar_month, value: '1', label: 'Appointment'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(ServiceItem item) {
    return Material(
      color: item.background,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () => _openService(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(item.asset, width: 46, height: 46),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0B417E),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF0B417E)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF56718E)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recommendations() {
    if (_recoLoading) {
      return const SizedBox(
        height: 185,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final cards = <Widget>[
      for (final reco in _recoExercises)
        _recoCard(
          title: reco.exercise.name,
          subtitle: '${reco.subregionName} • ${reco.exercise.defaultSets} sets × ${reco.exercise.defaultReps} reps',
          leading: (reco.exercise.exerciseUrl ?? '').trim().isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: reco.exercise.exerciseUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFEAF4FF),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFEAF4FF),
                    alignment: Alignment.center,
                    child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF1261B5), size: 40),
                  ),
                )
              : Container(
                  color: const Color(0xFFEAF4FF),
                  alignment: Alignment.center,
                  child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF1261B5), size: 40),
                ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseListScreen(subregionId: reco.subregionId, subregionName: reco.subregionName),
            ),
          ),
        ),
      if (_recoProduct != null)
        _recoCard(
          title: _recoProduct!.name,
          subtitle: 'Pharmacy • NPR ${_recoProduct!.price.toStringAsFixed(0)}',
          leading: _recoProduct!.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: _recoProduct!.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFEAF8FF),
                    alignment: Alignment.center,
                    child: const Icon(Icons.medication_outlined, color: Color(0xFF1261B5), size: 40),
                  ),
                )
              : Container(
                  color: const Color(0xFFEAF8FF),
                  alignment: Alignment.center,
                  child: const Icon(Icons.medication_outlined, color: Color(0xFF1261B5), size: 40),
                ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PharmacyScreen()),
          ),
        ),
    ];

    if (cards.isEmpty) {
      return SizedBox(
        height: 185,
        child: Center(
          child: Text('No recommendations right now.', style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }

    return SizedBox(
      height: 185,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  Widget _recoCard({
    required String title,
    required String subtitle,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 205,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCEAF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF1F7FC),
                  // Stack + StackFit.expand forces the non-positioned child
                  // to fill this box (a plain Container child would render
                  // at its own small natural size in the top-left corner
                  // instead) -- same fix as _ProductCard in pharmacy_screen.dart.
                  child: Stack(
                    fit: StackFit.expand,
                    children: [leading],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF123F72))),
            const SizedBox(height: 3),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF68819A))),
          ],
        ),
      ),
    );
  }

  Widget _recentActivity() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEAF7)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFEAF4FF),
            child: Icon(Icons.calendar_month, color: Color(0xFF1261B5)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appointment Booked',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF164A7B))),
                SizedBox(height: 4),
                Text('Physiotherapy • Upcoming appointment',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B8298))),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Color(0xFF7890A6)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onViewAll}) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0A417D))),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _simplePage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: const Color(0xFF1261B5)),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HealthStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HealthStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 21, color: const Color(0xFF1982D2)),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF124B80))),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Color(0xFF71869A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
