class WishlistImage {
  final int id;
  final String uuid;
  final String image;
  final bool isPrimary;
  final int sortOrder;

  const WishlistImage({
    required this.id,
    required this.uuid,
    required this.image,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory WishlistImage.fromJson(Map<String, dynamic> json) {
    return WishlistImage(
      id: _toInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: _toInt(json['sort_order']),
    );
  }
}

class WishlistProduct {
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
  final List<WishlistImage> images;

  const WishlistProduct({
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
    required this.images,
  });

  factory WishlistProduct.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];

    final images = rawImages is List
        ? rawImages
            .whereType<Map<String, dynamic>>()
            .map(WishlistImage.fromJson)
            .toList()
        : <WishlistImage>[];

    return WishlistProduct(
      id: _toInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      sellerId: _toInt(json['seller_id']),
      categoryId: _toInt(json['category_id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      discountPrice: json['discount_price'] == null
          ? null
          : _toDouble(json['discount_price']),
      quantity: _toInt(json['quantity']),
      unit: json['unit']?.toString() ?? '',
      brand: json['brand']?.toString(),
      origin: json['origin']?.toString(),
      status: json['status']?.toString() ?? 'active',
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      images: images,
    );
  }

  bool get hasDiscount =>
      discountPrice != null && discountPrice! < price;

  double get currentPrice =>
      hasDiscount ? discountPrice! : price;

  bool get isAvailable =>
      isActive &&
      quantity > 0 &&
      status.toLowerCase() == 'active';

  String? get primaryImage {
    if (images.isEmpty) {
      return null;
    }

    for (final image in images) {
      if (image.isPrimary && image.image.isNotEmpty) {
        return image.image;
      }
    }

    final sortedImages = [...images]
      ..sort(
        (a, b) => a.sortOrder.compareTo(b.sortOrder),
      );

    for (final image in sortedImages) {
      if (image.image.isNotEmpty) {
        return image.image;
      }
    }

    return null;
  }
}

class WishlistItem {
  final int id;
  final String uuid;
  final int userId;
  final int productId;
  final WishlistProduct product;

  const WishlistItem({
    required this.id,
    required this.uuid,
    required this.userId,
    required this.productId,
    required this.product,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];

    if (productJson is! Map<String, dynamic>) {
      throw const FormatException(
        'Wishlist item does not contain a valid product.',
      );
    }

    return WishlistItem(
      id: _toInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      userId: _toInt(json['user_id']),
      productId: _toInt(json['product_id']),
      product: WishlistProduct.fromJson(productJson),
    );
  }
}

class WishlistMessage {
  final bool success;
  final String message;

  const WishlistMessage({
    required this.success,
    required this.message,
  });

  factory WishlistMessage.fromJson(
    Map<String, dynamic> json,
  ) {
    return WishlistMessage(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}