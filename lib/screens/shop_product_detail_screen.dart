import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/shop_product.dart';

// The list endpoint (patient_api_products_public) already returns the full
// gallery, description and variants per product, so this screen renders
// straight from the ShopProduct the grid already fetched -- no separate
// detail API call needed.
class ShopProductDetailScreen extends StatefulWidget {
  final ShopProduct product;
  const ShopProductDetailScreen({super.key, required this.product});

  @override
  State<ShopProductDetailScreen> createState() => _ShopProductDetailScreenState();
}

class _ShopProductDetailScreenState extends State<ShopProductDetailScreen> {
  final PageController _pageController = PageController();
  int _imageIndex = 0;
  ShopProductVariant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    final variants = widget.product.variants;
    if (variants.isNotEmpty) {
      _selectedVariant = variants.firstWhere((v) => v.inStock, orElse: () => variants.first);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addToCart(BuildContext context) {
    final product = widget.product;
    final label = _selectedVariant != null ? '${product.name} (${_selectedVariant!.label})' : product.name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — contact store to order')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images.isNotEmpty
        ? product.images
        : (product.imageUrl != null ? [product.imageUrl!] : const <String>[]);

    final priceLabel = _selectedVariant != null
        ? 'NPR ${_selectedVariant!.price.toStringAsFixed(0)}'
        : (product.variants.isEmpty
            ? 'NPR ${product.price.toStringAsFixed(0)}'
            : 'From NPR ${product.displayPrice.toStringAsFixed(0)}');

    final outOfStock = _selectedVariant != null && !_selectedVariant!.inStock;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.teal),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildImageGallery(images),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.category.isNotEmpty ? product.category.toUpperCase() : 'GENERAL',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.6),
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
                const SizedBox(height: 8),
                Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
                if (product.brand.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(product.brand, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(priceLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                    if (outOfStock) ...[
                      const SizedBox(width: 10),
                      Text('Out of stock', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ],
                ),
                if (product.variants.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Text('Options', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  ...product.variants.map(_variantTile),
                ],
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(product.description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.45)),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: outOfStock ? null : () => _addToCart(context),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: Text(outOfStock ? 'Out of Stock' : 'Add to Cart', style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFFF0F4F6),
            child: images.isEmpty
                ? Icon(Icons.medical_services_outlined, color: Colors.teal.shade700, size: 64)
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemCount: images.length,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (_, __, ___) => Icon(Icons.medical_services_outlined, color: Colors.teal.shade700, size: 64),
                    ),
                  ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < images.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _imageIndex ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _imageIndex ? Colors.teal : Colors.black26,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _variantTile(ShopProductVariant variant) {
    final selected = _selectedVariant?.id == variant.id;
    return InkWell(
      onTap: variant.inStock ? () => setState(() => _selectedVariant = variant) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.teal : Colors.black12, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: variant.inStock ? (selected ? Colors.teal : Colors.black38) : Colors.black26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                variant.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: variant.inStock ? Colors.black87 : Colors.black38,
                ),
              ),
            ),
            if (!variant.inStock)
              Text('Out of stock', style: TextStyle(fontSize: 12, color: Colors.red[700]))
            else
              Text('NPR ${variant.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal)),
          ],
        ),
      ),
    );
  }
}
