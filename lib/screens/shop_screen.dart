import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/shop_product.dart';
import '../services/api_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<ShopProduct> _products = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService().getShopProducts(search: search);
      setState(() {
        _products = raw.map(ShopProduct.fromJson).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = query);
      _loadProducts(search: query.isEmpty ? null : query);
    });
  }

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
          // Fixed search bar -- stays put while the content below scrolls.
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.06))),
            ),
            child: _buildSearchBar(),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Browse Grid Categories
                  const Text(
                    'EXPLORE CATEGORIES',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryRow(),
                  const SizedBox(height: 28),

                  // Product Feed (live catalog)
                  Text(
                    _query.isEmpty ? 'TRENDING MEDICAL SUPPLIES' : 'RESULTS FOR "$_query"',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),
                  _buildProductsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Component Builders ---

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: const InputDecoration(
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildProductsSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _loadProducts(search: _query.isEmpty ? null : _query),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          _query.isEmpty ? 'No products available right now.' : 'No products match "$_query".',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    return Column(
      children: [
        for (final product in _products) ...[
          _ProductCard(product: product),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ShopProduct product;
  const _ProductCard({required this.product});

  void _showVariantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _VariantSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVariants = product.variants.isNotEmpty;
    final priceLabel = hasVariants
        ? 'From NPR ${product.displayPrice.toStringAsFixed(0)}'
        : 'NPR ${product.displayPrice.toStringAsFixed(0)}';

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
            // Top Badge Section: real category on the left, real
            // is_featured flag on the right (was a fake "FDA CLEARED"
            // verification badge -- same visual slot, real data now).
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.category.isNotEmpty ? product.category.toUpperCase() : 'GENERAL',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45),
                  ),
                ),
                if (product.isFeatured)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text('FEATURED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: const Color(0xFFF0F4F6),
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (_, __, ___) => Icon(Icons.medical_services_outlined, color: Colors.teal.shade700, size: 32),
                          )
                        : Icon(Icons.medical_services_outlined, color: Colors.teal.shade700, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      // Real brand line, in the visual slot the old star
                      // rating row used to occupy -- there's no rating data.
                      if (product.brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(product.brand, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                      const SizedBox(height: 8),
                      Text(priceLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions: a product with real priced options gets a "View
            // Options" + "Add to Cart" pair (was a fake Buy/Rent pair);
            // one without just gets a single Add to Cart button.
            Row(
              children: hasVariants
                  ? [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showVariantSheet(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.teal),
                            foregroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('View Options', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${product.name} — contact store to order')),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]
                  : [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${product.name} — contact store to order')),
                          ),
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

class _VariantSheet extends StatelessWidget {
  final ShopProduct product;
  const _VariantSheet({required this.product});

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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 18),
            Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 4),
            Text('${product.variants.length} option${product.variants.length == 1 ? '' : 's'} available',
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            ...product.variants.map((v) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(v.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(v.inStock ? 'In stock' : 'Out of stock', style: TextStyle(color: v.inStock ? Colors.green[700] : Colors.red[700])),
                  trailing: SizedBox(
                    width: 130,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('NPR ${v.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                          onPressed: v.inStock
                              ? () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${product.name} (${v.label}) — contact store to order')),
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
