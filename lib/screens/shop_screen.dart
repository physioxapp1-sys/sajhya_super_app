import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/shop_product.dart';
import '../services/api_service.dart';
import 'shop_product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

const int _defaultCount = 40;

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Default view: a random slice of the catalog, capped at 40 -- not the
  // whole thing, and not incrementally revealed via scroll either (that
  // still built every revealed card eagerly). The rest of the catalog is
  // reachable only by searching, which queries the backend fresh instead
  // of filtering an already-loaded list.
  List<ShopProduct> _default = [];
  List<ShopProduct>? _searchResults;

  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadDefault();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDefault() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService().getShopProducts();
      final products = raw.map(ShopProduct.fromJson).toList()..shuffle(Random());
      setState(() {
        _default = products.take(_defaultCount).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService().getShopProducts(search: query);
      if (!mounted) return;
      setState(() {
        _searchResults = raw.map(ShopProduct.fromJson).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _searchResults = null;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = query);
      _runSearch(query);
    });
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
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.black12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              isDense: true,
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(vertical: 11),
              border: InputBorder.none,
              hintText: 'Search supplies (e.g. knee brace, gauze)...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.black45),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.teal),
              prefixIconConstraints: BoxConstraints(minWidth: 36, minHeight: 20),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _query.isEmpty ? 'TRENDING MEDICAL SUPPLIES' : 'RESULTS FOR "$_query"',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.1),
            ),
            if (_query.isEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'A few from the catalog -- search above for everything else.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  // --- Widget Component Builders ---

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
              onPressed: () => _query.isEmpty ? _loadDefault() : _runSearch(_query),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final products = _searchResults ?? _default;
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          _query.isEmpty ? 'No products available right now.' : 'No products match "$_query".',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (_, index) => _ProductCard(product: products[index]),
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShopProductDetailScreen(product: product)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFFF0F4F6),
                      child: product.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (_, __, ___) =>
                                  Icon(Icons.medical_services_outlined, color: Colors.teal.shade700, size: 32),
                            )
                          : Icon(Icons.medical_services_outlined, color: Colors.teal.shade700, size: 32),
                    ),
                    if (product.isFeatured)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    if (product.category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            priceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => hasVariants
                              ? _showVariantSheet(context)
                              : ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${product.name} — contact store to order')),
                                ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(hasVariants ? Icons.tune : Icons.add_shopping_cart, size: 18, color: Colors.teal),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
