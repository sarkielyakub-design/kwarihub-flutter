
const String _cartBackendBaseUrl =
    'https://kwarihub-backend-production-ea77.up.railway.app';

class CartItemModel {
  final int id;
  final String uuid;
  final int userId;
  final int variantId;
  final int quantity;
  final String productName;

  /// Original image URL or path received from the API.
  final String? productImage;

  final String? color;
  final String? size;
  final String? material;
  final String variantSku;
  final double unitPrice;

  const CartItemModel({
    required this.id,
    required this.uuid,
    required this.userId,
    required this.variantId,
    required this.quantity,
    required this.productName,
    this.productImage,
    this.color,
    this.size,
    this.material,
    required this.variantSku,
    required this.unitPrice,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Some API responses return product details inside a nested object.
    final product = _asMap(json['product']);
    final variant = _asMap(json['variant']);

    // Some responses place product details inside the variant.
    final variantProduct = _asMap(variant?['product']);

    final image = _firstNonEmpty([
      json['product_image'],
      json['productImage'],
      json['image_url'],
      json['imageUrl'],
      json['image'],
      json['thumbnail'],
      product?['primary_image'],
      product?['primaryImage'],
      product?['product_image'],
      product?['image_url'],
      product?['imageUrl'],
      product?['image'],
      product?['thumbnail'],
      _firstProductImage(product),
      variantProduct?['primary_image'],
      variantProduct?['primaryImage'],
      variantProduct?['product_image'],
      variantProduct?['image_url'],
      variantProduct?['imageUrl'],
      variantProduct?['image'],
      variantProduct?['thumbnail'],
      _firstProductImage(variantProduct),
      _firstProductImage(json),
    ]);

    return CartItemModel(
      id: _toInt(json['id']),
      uuid: _firstNonEmpty([
            json['uuid'],
            json['cart_item_uuid'],
          ]) ??
          '',
      userId: _toInt(
        json['user_id'] ?? json['userId'],
      ),
      variantId: _toInt(
        json['variant_id'] ??
            json['variantId'] ??
            variant?['id'],
      ),
      quantity: _toInt(json['quantity']),
      productName: _firstNonEmpty([
            json['product_name'],
            json['productName'],
            product?['name'],
            variantProduct?['name'],
          ]) ??
          'Unknown Product',
      productImage: image,
      color: _firstNonEmpty([
        json['color'],
        variant?['color'],
      ]),
      size: _firstNonEmpty([
        json['size'],
        variant?['size'],
      ]),
      material: _firstNonEmpty([
        json['material'],
        variant?['material'],
      ]),
      variantSku: _firstNonEmpty([
            json['variant_sku'],
            json['variantSku'],
            json['sku'],
            variant?['sku'],
          ]) ??
          '',
      unitPrice: _toDouble(
        json['unit_price'] ??
            json['unitPrice'] ??
            json['price'] ??
            variant?['price'],
      ),
    );
  }

  /// Normalized image URL suitable for Image.network().
  ///
  /// Handles full URLs and common backend-relative paths.
  String? get productImageUrl {
    return resolveImageUrl(productImage);
  }

  /// Convenient aliases for existing UI code.
  String get name => productName;

  double get price => unitPrice;

  double get itemTotal => unitPrice * quantity;

  /// Resolve an image path against the KwariHub backend.
  static String? resolveImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final path = value.trim();
    final uri = Uri.tryParse(path);

    // Preserve valid absolute HTTP/HTTPS URLs.
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return uri.toString();
    }

    // Remove leading slashes.
    var clean = path.replaceFirst(RegExp(r'^/+'), '');

    // Remove the API prefix if it was mistakenly included.
    if (clean.startsWith('api/v1/')) {
      clean = clean.substring('api/v1/'.length);
    }

    // Images already under /storage.
    if (clean.startsWith('storage/')) {
      return '$_cartBackendBaseUrl/$clean';
    }

    // Alternative upload directory.
    if (clean.startsWith('uploads/')) {
      return '$_cartBackendBaseUrl/$clean';
    }

    // Product image path relative to the storage directory.
    if (clean.startsWith('products/')) {
      return '$_cartBackendBaseUrl/storage/$clean';
    }

    // Support other relative storage paths.
    return '$_cartBackendBaseUrl/storage/$clean';
  }

  static String? _firstProductImage(
    Map<String, dynamic>? product,
  ) {
    if (product == null) return null;

    final images = product['images'] ??
        product['product_images'] ??
        product['productImages'];

    if (images is List) {
      // Prefer a primary image when the API identifies one.
      final maps = images
          .whereType<Map>()
          .map((image) => Map<String, dynamic>.from(image))
          .toList();

      for (final image in maps) {
        final isPrimary = image['is_primary'] == true ||
            image['isPrimary'] == true ||
            image['is_primary'] == 1;

        if (isPrimary) {
          final primary = _firstNonEmpty([
            image['image_url'],
            image['imageUrl'],
            image['image'],
            image['url'],
            image['path'],
          ]);

          if (primary != null) return primary;
        }
      }

      // Fall back to the first image with a usable path.
      for (final image in maps) {
        final first = _firstNonEmpty([
          image['image_url'],
          image['imageUrl'],
          image['image'],
          image['url'],
          image['path'],
        ]);

        if (first != null) return first;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static String? _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final value in values) {
      if (value == null) continue;

      if (value is Map || value is List) continue;

      final text = value.toString().trim();

      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return null;
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

class CartSummaryModel {
  final List<CartItemModel> items;
  final double subtotal;
  final int totalItems;

  const CartSummaryModel({
    required this.items,
    required this.subtotal,
    required this.totalItems,
  });

  factory CartSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    // Support either a direct cart response or a nested data response.
    final nestedData = json['data'];
    final data = nestedData is Map
        ? Map<String, dynamic>.from(nestedData)
        : json;

    final rawItems = data['items'] ??
        data['cart_items'] ??
        data['cartItems'];

    final items = rawItems is List
        ? rawItems
            .map(CartItemModel._asMap)
            .whereType<Map<String, dynamic>>()
            .map(CartItemModel.fromJson)
            .toList()
        : <CartItemModel>[];

    final subtotal = CartSummaryModel._toDouble(
      data['subtotal'] ?? data['total'],
    );

    final parsedTotalItems = CartSummaryModel._toInt(
      data['total_items'] ?? data['totalItems'],
    );

    return CartSummaryModel(
      items: items,
      subtotal: subtotal,
      totalItems: parsedTotalItems > 0
          ? parsedTotalItems
          : items.fold<int>(
              0,
              (total, item) => total + item.quantity,
            ),
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
