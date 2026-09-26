// Model for patient_api_pharmacy_products_public. Deliberately separate
// from any general marketplace "Product" model -- PharmacyProduct has no
// ProductImage/ProductVariant relations (a single image_url, no gallery or
// size/variant options), and `category` here is a free-text string, not a
// taxonomy relation.

class PharmacyProduct {
  final int id;
  final String name;
  final String category;
  final String description;
  final double price;
  final String unit;
  final String? imageUrl;
  final bool inStock;
  final bool isFeatured;
  final bool requiresPrescription;

  const PharmacyProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.unit,
    this.imageUrl,
    required this.inStock,
    required this.isFeatured,
    required this.requiresPrescription,
  });

  factory PharmacyProduct.fromJson(Map<String, dynamic> json) {
    return PharmacyProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      unit: json['unit'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      inStock: json['in_stock'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      requiresPrescription: json['requires_prescription'] as bool? ?? false,
    );
  }
}
