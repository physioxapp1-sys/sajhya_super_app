import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Medical Equipment & Supplies',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.teal),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Floating Cart Status (Research Point 3: Anxiety Mitigation / Undo-Modify feedback loop)
          _buildCartStatusAlert(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Natural Language Search Bar (Converts common symptoms into product matches)
                  _buildSearchBar(),
                  const SizedBox(height: 24),

                  // Quick Browse Grid Categories
                  const Text(
                    'EXPLORE CATEGORIES',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryRow(),
                  const SizedBox(height: 28),

                  // Product Feed
                  const Text(
                    'TRENDING MEDICAL SUPPLIES',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),

                  // Product item 1: Advanced Lumbar Support (Demonstrating Supply Consolidation: Buy/Rent option)
                  _buildProductCard(
                    context,
                    title: 'Premium Lumbar Support Belt',
                    category: 'Orthopedic Braces',
                    imageUrl: Icons.accessibility_new,
                    priceText: '\$45.00 Buy  /  \$8.00 Mon Rent',
                    rating: '4.8 (142 reviews)',
                    hasVerification: true,
                    isConsolidatedView: true,
                  ),
                  const SizedBox(height: 16),

                  // Product item 2: Sterile Elastic Bandages Pack
                  _buildProductCard(
                    context,
                    title: 'Sterile Self-Adherent Bandages (6-Pack)',
                    category: 'First Aid & Wound Care',
                    imageUrl: Icons.healing,
                    priceText: '\$14.99 Upfront Price',
                    rating: '4.9 (310 reviews)',
                    hasVerification: true,
                    isConsolidatedView: false,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Component Builders ---

  Widget _buildCartStatusAlert() {
    return Container(
      color: Colors.teal.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Item added to cart.',
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
            child: const Text('Undo', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search supplies (e.g., knee brace, gauze, support)...',
          hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.black45),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    final categories = [
      {'icon': Icons.healing, 'label': 'Bandages'},
      {'icon': Icons.accessibility_new, 'label': 'Braces'},
      {'icon': Icons.airline_seat_flat_angled, 'label': 'Lumbar Support'},
      {'icon': Icons.accessible, 'label': 'Mobility'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        return Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(cat['icon'] as IconData, color: Colors.teal, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              cat['label'] as String,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black70),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildProductCard(
    BuildContext context, {
    required String title,
    required String category,
    required IconData imageUrl,
    required String priceText,
    required String rating,
    required bool hasVerification,
    required bool isConsolidatedView,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Section (Research Point 1: Vetting & Trust Verification)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
                if (hasVerification)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Icon(Icons.verified, size: 12, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text('FDA CLEARED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Core Details Layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(color: const Color(0xFFF0F4F6), borderRadius: BorderRadius.circular(12)),
                  child: Icon(imageUrl, color: Colors.teal.shade700, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(rating, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Upfront Price Transparency (Research Point 1)
                      Text(priceText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Consolidated Actions Tab Layer (Research Point 4: Home Technology Integration)
            Row(
              children: isConsolidatedView
                  ? [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.teal),
                            foregroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Rent', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Buy', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]
                  : [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}
