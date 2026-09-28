import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/pharmacy_product.dart';

// The list endpoint (patient_api_pharmacy_products_public) already returns
// everything PharmacyProduct has, so this renders straight from the object
// Med Cabinet already fetched -- no separate detail API call needed.
// Unlike Shop's Product, PharmacyProduct has no gallery/variants (see the
// model's own doc comment), so this is a single image, no options picker.
class PharmacyProductDetailScreen extends StatelessWidget {
  final PharmacyProduct product;
  const PharmacyProductDetailScreen({super.key, required this.product});

  void _addToCart(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} — contact pharmacy to order')),
    );
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
          _buildImage(),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('NPR ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(width: 10),
                    Text(product.unit, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product.inStock ? 'In stock' : 'Out of stock',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: product.inStock ? Colors.green[700] : Colors.red[700],
                  ),
                ),
                if (product.requiresPrescription) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.local_hospital_outlined, size: 18, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Requires a valid prescription -- our team will confirm this with you before delivery.',
                            style: TextStyle(fontSize: 12.5, color: Colors.red.shade700, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              onPressed: product.inStock ? () => _addToCart(context) : null,
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: Text(product.inStock ? 'Add to Cart' : 'Out of Stock', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFFF0F4F6),
            child: product.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) => Icon(Icons.medication_outlined, color: Colors.grey[400], size: 64),
                  )
                : Icon(Icons.medication_outlined, color: Colors.grey[400], size: 64),
          ),
          if (product.requiresPrescription)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(5)),
                child: const Text('Rx', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
