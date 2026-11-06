class ProductVariantModel {
  final int id;
  final String uuid;
  final int productId;
  final String color;
  final String size;
  final String material;
  final String sku;
  final double price;
  final int quantity;
  final bool isActive;

  const ProductVariantModel({
    required this.id,
    required this.uuid,
    required this.productId,
    required this.color,
    required this.size,
    required this.material,
    required this.sku,
    required this.price,
    required this.quantity,
    required this.isActive,
  });

  factory ProductVariantModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProductVariantModel(
      id: _toInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      productId: _toInt(json['product_id']),
      color: json['color']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      material: json['material']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      price: _toDouble(json['price']),
      quantity: _toInt(json['quantity']),
      isActive: json['is_active'] != false,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}