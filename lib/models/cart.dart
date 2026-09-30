// Shared shape for both carts (patient_api_cart / patient_api_pharmacy_cart).
// The two backend endpoints return near-identical JSON -- Shop's adds
// variant_id/variant_label (PharmacyProduct has no variants), Pharmacy's
// adds requires_prescription (Product/OrderItem has no such flag) -- so one
// model with optional fields covers both instead of two near-duplicates.

class CartItem {
  final int productId;
  final int? variantId;
  final String variantLabel;
  final String name;
  final double price;
  final int quantity;
  final String unit;
  final String? imageUrl;
  final double itemTotal;
  final bool requiresPrescription;

  const CartItem({
    required this.productId,
    this.variantId,
    this.variantLabel = '',
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
    this.imageUrl,
    required this.itemTotal,
    this.requiresPrescription = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final image = json['image_url'] as String?;
    return CartItem(
      productId: json['product_id'] as int,
      variantId: json['variant_id'] as int?,
      variantLabel: json['variant_label'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      unit: json['unit'] as String? ?? '',
      imageUrl: (image == null || image.isEmpty) ? null : image,
      itemTotal: double.tryParse(json['item_total']?.toString() ?? '0') ?? 0,
      requiresPrescription: json['requires_prescription'] as bool? ?? false,
    );
  }
}

class CartSummary {
  final List<CartItem> items;
  final double total;
  final int count;

  const CartSummary({required this.items, required this.total, required this.count});

  static const empty = CartSummary(items: [], total: 0, count: 0);

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }
}
