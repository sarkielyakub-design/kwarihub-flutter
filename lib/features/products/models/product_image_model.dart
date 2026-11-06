
class ProductImageModel {
  final int id;
  final String uuid;
  final int productId;
  final String image;
  final bool isPrimary;
  final int sortOrder;

  const ProductImageModel({
    required this.id,
    required this.uuid,
    required this.productId,
    required this.image,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: _toInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      productId: _toInt(json['product_id'] ?? json['productId']),
      image: _firstNonEmpty([
            json['image'],
            json['image_url'],
            json['imageUrl'],
            json['url'],
            json['path'],
          ]) ??
          '',
      isPrimary: _toBool(json['is_primary'] ?? json['isPrimary']),
      sortOrder: _toInt(json['sort_order'] ?? json['sortOrder']),
    );
  }

  get imageUrl => null;

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null || value is Map || value is List) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return null;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }
}

class ProductModel {
  final int id;
  final String uuid;
  final int sellerId;
  final int categoryId;
  final String name;
  final String slug;
  final String sku;
  final String description;
  final double price;
  final double? discountPrice;
  final int quantity;
  final String unit;
  final String? brand;
  final String? origin;
  final String status;
  final bool isFeatured;
  final bool isActive;
  final List<ProductImageModel> images;

  const ProductModel({
    required this.id,
    required this.uuid,
    required this.sellerId,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.sku,
    required this.description,
    required this.price,
    required this.discountPrice,
    required this.quantity,
    required this.unit,
    required this.brand,
    required this.origin,
    required this.status,
    required this.isFeatured,
    required this.isActive,
    this.images = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] ??
        json['product_images'] ??
        json['productImages'];

    final parsedImages = <ProductImageModel>[];

    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is Map) {
          parsedImages.add(
            ProductImageModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        } else if (item is String && item.trim().isNotEmpty) {
          parsedImages.add(
            ProductImageModel(
              id: 0,
              uuid: '',
              productId: _toInt(json['id']),
              image: item.trim(),
              isPrimary: parsedImages.isEmpty,
              sortOrder: parsedImages.length,
            ),
          );
        }
      }
    }

    // The current KwariHub API returns image_url at the product level.
    final topLevelImage = _firstNonEmpty([
      json['image_url'],
      json['imageUrl'],
      json['primary_image'],
      json['primaryImage'],
      json['product_image'],
      json['thumbnail_url'],
      json['thumbnail'],
      json['image'],
    ]);

    if (topLevelImage != null &&
        !parsedImages.any((image) => image.image == topLevelImage)) {
      parsedImages.add(
        ProductImageModel(
          id: 0,
          uuid: '',
          productId: _toInt(json['id']),
          image: topLevelImage,
          isPrimary: parsedImages.isEmpty,
          sortOrder: -1,
        ),
      );
    }

    parsedImages.sort((a, b) {
      if (a.isPrimary != b.isPrimary) {
        return a.isPrimary ? -1 : 1;
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return ProductModel(
      id: _toInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      sellerId: _toInt(json['seller_id'] ?? json['sellerId']),
      categoryId: _toInt(json['category_id'] ?? json['categoryId']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      discountPrice: json['discount_price'] == null &&
              json['discountPrice'] == null
          ? null
          : _toDouble(json['discount_price'] ?? json['discountPrice']),
      quantity: _toInt(json['quantity']),
      unit: json['unit']?.toString() ?? '',
      brand: json['brand']?.toString(),
      origin: json['origin']?.toString(),
      status: json['status']?.toString() ?? '',
      isFeatured: _toBool(json['is_featured'] ?? json['isFeatured']),
      isActive: _toBool(json['is_active'] ?? json['isActive'], defaultValue: true),
      images: parsedImages,
    );
  }

  bool get hasDiscount =>
      discountPrice != null &&
      discountPrice! > 0 &&
      discountPrice! < price;

  double get sellingPrice => hasDiscount ? discountPrice! : price;

  String? get primaryImage {
    for (final productImage in images) {
      if (productImage.image.trim().isNotEmpty) {
        return productImage.image.trim();
      }
    }
    return null;
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null || value is Map || value is List) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return null;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value != null) {
      final text = value.toString().toLowerCase();
      if (text == 'true' || text == '1') return true;
      if (text == 'false' || text == '0') return false;
    }

    return defaultValue;
  }
}
