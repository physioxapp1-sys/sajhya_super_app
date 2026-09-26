// Model for patient_api_products_public. Distinct from PharmacyProduct --
// this model has real gallery images and priced variants (e.g. size
// options), which PharmacyProduct doesn't.

class ShopProductVariant {
  final int id;
  final String label;
  final double price;
  final String? imageUrl;
  final bool inStock;

  const ShopProductVariant({
    required this.id,
    required this.label,
    required this.price,
    this.imageUrl,
    required this.inStock,
  });

  factory ShopProductVariant.fromJson(Map<String, dynamic> json) {
    return ShopProductVariant(
      id: json['id'] as int,
      label: json['label'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      imageUrl: json['image_url'] as String?,
      inStock: json['in_stock'] as bool? ?? true,
    );
  }
}

class ShopProduct {
  final int id;
  final String name;
  final String brand;
  final String category;
  final String description;
  final double price;
  final String unit;
  final String? imageUrl;
  final List<String> images;
  final bool isFeatured;
  final List<ShopProductVariant> variants;

  const ShopProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.price,
    required this.unit,
    this.imageUrl,
    required this.images,
    required this.isFeatured,
    required this.variants,
  });

  /// Lowest variant price when variants exist, otherwise the base price --
  /// variants replace the base price as the purchasable amount when present.
  double get displayPrice => variants.isEmpty ? price : variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    return ShopProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      unit: json['unit'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      images: List<String>.from(json['images'] ?? const []),
      isFeatured: json['is_featured'] as bool? ?? false,
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((v) => ShopProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}
