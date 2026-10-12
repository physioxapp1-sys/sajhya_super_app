// Model for patient_api_refill_medications's response -- Medicine Reminders
// linked to a real PharmacyProduct (see the backend view's own doc comment
// for why unlinked custom_name-only reminders never appear here), each
// with how many days are left on an assumed 30-day supply based on this
// patient's own pharmacy order history.

class RefillMedication {
  final int medicationId;
  final int productId;
  final String name;
  final double price;
  final String? imageUrl;
  final bool inStock;
  final DateTime? lastPurchased;
  final int? daysRemaining;

  const RefillMedication({
    required this.medicationId,
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.inStock,
    this.lastPurchased,
    this.daysRemaining,
  });

  bool get everPurchased => lastPurchased != null;
  bool get isOverdue => daysRemaining != null && daysRemaining! <= 0;
  bool get isLow => daysRemaining != null && daysRemaining! > 0 && daysRemaining! <= 7;

  factory RefillMedication.fromJson(Map<String, dynamic> json) {
    final lastPurchasedRaw = json['last_purchased'] as String?;
    return RefillMedication(
      medicationId: json['medication_id'] as int,
      productId: json['product_id'] as int,
      name: json['name'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      imageUrl: json['image_url'] as String?,
      inStock: json['in_stock'] as bool? ?? true,
      lastPurchased: (lastPurchasedRaw != null && lastPurchasedRaw.isNotEmpty) ? DateTime.tryParse(lastPurchasedRaw) : null,
      daysRemaining: json['days_remaining'] as int?,
    );
  }
}
