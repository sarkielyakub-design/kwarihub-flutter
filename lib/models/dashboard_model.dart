// lib/models/dashboard_model.dart

// ============================================================
// DASHBOARD MODEL
// ============================================================

class DashboardModel {
  final DashboardUser user;
  final DashboardWallet wallet;
  final DashboardStats stats;
  final List<RecentOrder> recentOrders;
  final List<DashboardProduct> featuredProducts;
  final List<DashboardProduct> latestProducts;
  final List<DashboardCategory> featuredCategories;
  final List<DashboardPromotion> promotions;

  const DashboardModel({
    required this.user,
    required this.wallet,
    required this.stats,
    required this.recentOrders,
    required this.featuredProducts,
    required this.latestProducts,
    required this.featuredCategories,
    this.promotions = const [],
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final data = _readMap(json['data']) ?? json;

    return DashboardModel(
      user: DashboardUser.fromJson(_readMap(data['user']) ?? {}),
      wallet: DashboardWallet.fromJson(_readMap(data['wallet']) ?? {}),
      stats: DashboardStats.fromJson(_readMap(data['stats']) ?? {}),
      recentOrders: _readList(
        data['recent_orders'],
      ).map(RecentOrder.fromJson).toList(),
      featuredProducts: _readList(
        data['featured_products'],
      ).map(DashboardProduct.fromJson).toList(),
      latestProducts: _readList(
        data['latest_products'],
      ).map(DashboardProduct.fromJson).toList(),
      featuredCategories: _readList(
        data['featured_categories'],
      ).map(DashboardCategory.fromJson).toList(),
      promotions: _readList(
        data['promotions'] ?? data['active_promotions'],
      ).map(DashboardPromotion.fromJson).toList(),
    );
  }
}

// ============================================================
// JSON HELPERS
// ============================================================

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;

  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  return null;
}

List<Map<String, dynamic>> _readList(dynamic value) {
  if (value is! List) return const [];

  return value.map(_readMap).whereType<Map<String, dynamic>>().toList();
}

String _readString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;

  final result = value.toString().trim();

  if (result.isEmpty || result.toLowerCase() == 'null') {
    return fallback;
  }

  return result;
}

String? _readNullableString(dynamic value) {
  final result = _readString(value);
  return result.isEmpty ? null : result;
}

double _readDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();

  if (value == null) return fallback;

  return double.tryParse(value.toString().replaceAll(',', '').trim()) ??
      fallback;
}

double? _readNullableDouble(dynamic value) {
  if (value == null) return null;

  final result = _readDouble(value, double.nan);

  return result.isFinite ? result : null;
}

int _readInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;

  if (value is num) return value.toInt();

  if (value == null) return fallback;

  return int.tryParse(value.toString()) ??
      _readDouble(value, fallback.toDouble()).toInt();
}

bool _readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;

  if (value is num) return value != 0;

  if (value is String) {
    switch (value.toLowerCase().trim()) {
      case 'true':
      case '1':
      case 'yes':
      case 'active':
      case 'published':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'inactive':
      case 'paused':
        return false;
    }
  }

  return fallback;
}

DateTime? _readDateTime(dynamic value) {
  if (value is DateTime) return value;

  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}

// ============================================================
// USER
// ============================================================

class DashboardUser {
  final int id;
  final String uuid;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phone;
  final String? avatar;

  const DashboardUser({
    required this.id,
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phone,
    this.avatar,
  });

  factory DashboardUser.fromJson(Map<String, dynamic> json) {
    return DashboardUser(
      id: _readInt(json['id']),
      uuid: _readString(json['uuid']),
      firstName: _readString(json['first_name']),
      lastName: _readString(json['last_name']),
      username: _readString(json['username']),
      email: _readString(json['email']),
      phone: _readString(json['phone']),
      avatar: _readNullableString(
        json['avatar_url'] ?? json['avatar'] ?? json['profile_image'],
      ),
    );
  }

  String get displayName {
    final name = '$firstName $lastName'.trim();

    if (name.isNotEmpty) return name;

    if (username.isNotEmpty) return username;

    return 'User';
  }

  String get firstNameDisplay {
    if (firstName.trim().isNotEmpty) {
      return firstName.trim();
    }

    if (username.trim().isNotEmpty) {
      return username.trim().split(RegExp(r'\s+')).first;
    }

    return 'User';
  }

  String get initials {
    final name = displayName.trim();

    if (name.isEmpty || name == 'User') return 'U';

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ============================================================
// WALLET
// ============================================================

class DashboardWallet {
  final dynamic balance;
  final dynamic totalEarned;
  final dynamic totalWithdrawn;

  const DashboardWallet({
    required this.balance,
    required this.totalEarned,
    required this.totalWithdrawn,
  });

  factory DashboardWallet.fromJson(Map<String, dynamic> json) {
    return DashboardWallet(
      balance: json['balance'] ?? 0,
      totalEarned: json['total_earned'] ?? 0,
      totalWithdrawn: json['total_withdrawn'] ?? 0,
    );
  }

  double get balanceValue => _readDouble(balance);

  double get earnedValue => _readDouble(totalEarned);

  double get withdrawnValue => _readDouble(totalWithdrawn);
}

// ============================================================
// DASHBOARD STATISTICS
// ============================================================

class DashboardStats {
  final int cartCount;
  final int wishlistCount;
  final int unreadNotifications;
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final dynamic totalSpent;

  const DashboardStats({
    required this.cartCount,
    required this.wishlistCount,
    required this.unreadNotifications,
    required this.totalOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalSpent,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      cartCount: _readInt(json['cart_count']),
      wishlistCount: _readInt(json['wishlist_count']),
      unreadNotifications: _readInt(json['unread_notifications']),
      totalOrders: _readInt(json['total_orders']),
      pendingOrders: _readInt(json['pending_orders']),
      processingOrders: _readInt(json['processing_orders']),
      deliveredOrders: _readInt(json['delivered_orders']),
      cancelledOrders: _readInt(json['cancelled_orders']),
      totalSpent: json['total_spent'] ?? 0,
    );
  }

  double get totalSpentValue => _readDouble(totalSpent);
}

// ============================================================
// PRODUCT
// ============================================================

class DashboardProduct {
  final String uuid;
  final String name;
  final String slug;
  final dynamic price;
  final dynamic discountPrice;
  final int quantity;
  final String unit;
  final String? brand;
  final bool isFeatured;
  final String? image;

  // Product rating fields.
  // They remain null/zero when the API has no rating data.
  final double? averageRating;
  final int reviewCount;

  const DashboardProduct({
    required this.uuid,
    required this.name,
    required this.slug,
    required this.price,
    required this.discountPrice,
    required this.quantity,
    required this.unit,
    required this.brand,
    required this.isFeatured,
    required this.image,
    this.averageRating,
    this.reviewCount = 0,
  });

  factory DashboardProduct.fromJson(Map<String, dynamic> json) {
    return DashboardProduct(
      uuid: _readString(json['uuid']),
      name: _readString(json['name'], 'Unnamed product'),
      slug: _readString(json['slug']),
      price: json['price'] ?? 0,
      discountPrice: json['discount_price'],
      quantity: _readInt(json['quantity']),
      unit: _readString(json['unit']),
      brand: _readNullableString(json['brand']),
      isFeatured: _readBool(json['is_featured']),
      image: _extractImage(json),

      averageRating: _readNullableDouble(
        json['average_rating'] ??
            json['averageRating'] ??
            json['avg_rating'] ??
            json['rating'],
      ),
      reviewCount: _readInt(
        json['review_count'] ?? json['reviews_count'] ?? json['ratings_count'],
      ),
    );
  }

  static String? _extractImage(Map<String, dynamic> json) {
    final directImage = _readNullableString(
      json['image_url'] ??
          json['image'] ??
          json['thumbnail_url'] ??
          json['thumbnail'],
    );

    if (directImage != null) return directImage;

    final images = json['images'];

    if (images is List) {
      final entries = images
          .map(_readMap)
          .whereType<Map<String, dynamic>>()
          .toList();

      // Prefer the primary product image.
      for (final entry in entries) {
        if (_readBool(entry['is_primary'])) {
          final url = _readNullableString(
            entry['image_url'] ?? entry['image'] ?? entry['url'],
          );

          if (url != null) return url;
        }
      }

      // Otherwise use the first available image.
      for (final entry in entries) {
        final url = _readNullableString(
          entry['image_url'] ?? entry['image'] ?? entry['url'],
        );

        if (url != null) return url;
      }
    }

    return null;
  }

  double get priceValue => _readDouble(price);

  double? get discountPriceValue {
    final value = _readNullableDouble(discountPrice);

    if (value == null || value <= 0) return null;

    return value;
  }

  bool get hasDiscount {
    final discount = discountPriceValue;

    return discount != null && discount < priceValue;
  }

  double get displayPrice {
    return hasDiscount ? discountPriceValue! : priceValue;
  }

  bool get hasRating {
    return averageRating != null && averageRating! > 0 && reviewCount > 0;
  }

  double get safeRating {
    final rating = averageRating ?? 0;

    if (rating < 0) return 0;
    if (rating > 5) return 5;

    return rating;
  }

  String get ratingLabel {
    if (!hasRating) return 'No reviews yet';

    return '${safeRating.toStringAsFixed(1)} ($reviewCount)';
  }
}

// ============================================================
// CATEGORY
// ============================================================

class DashboardCategory {
  final String uuid;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final bool isFeatured;
  final String? image;
  final int productCount;

  const DashboardCategory({
    required this.uuid,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.isFeatured,
    this.image,
    this.productCount = 0,
  });

  factory DashboardCategory.fromJson(Map<String, dynamic> json) {
    return DashboardCategory(
      uuid: _readString(json['uuid']),
      name: _readString(json['name'], 'Unnamed category'),
      slug: _readString(json['slug']),
      description: _readNullableString(json['description']),
      icon: _readNullableString(json['icon']),
      isFeatured: _readBool(json['is_featured']),
      image: _readNullableString(
        json['image_url'] ?? json['image'] ?? json['thumbnail_url'],
      ),
      productCount: _readInt(json['product_count'] ?? json['products_count']),
    );
  }
}

// ============================================================
// RECENT ORDER
// ============================================================

class RecentOrder {
  final String uuid;
  final String orderNumber;
  final String status;
  final dynamic total;
  final String? currency;
  final DateTime? createdAt;

  const RecentOrder({
    required this.uuid,
    required this.orderNumber,
    required this.status,
    required this.total,
    this.currency,
    this.createdAt,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      uuid: _readString(json['uuid']),
      orderNumber: _readString(json['order_number'] ?? json['orderNumber']),
      status: _readString(json['status'], 'pending'),
      total: json['total'] ?? json['total_amount'] ?? 0,
      currency: _readNullableString(json['currency']),
      createdAt: _readDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  double get totalValue => _readDouble(total);

  String get statusLabel {
    if (status.isEmpty) return 'Pending';

    return status
        .split(RegExp(r'[_\-\s]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

// ============================================================
// PROMOTION
// ============================================================

class DashboardPromotion {
  final int id;
  final String uuid;
  final String title;
  final String? description;
  final String? bannerUrl;
  final String promotionType;
  final String? discountType;
  final double? discountValue;
  final String? couponCode;
  final String? productId;
  final String? categoryId;
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;
  final int? usageLimit;
  final int usageCount;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DashboardPromotion({
    required this.id,
    required this.uuid,
    required this.title,
    this.description,
    this.bannerUrl,
    required this.promotionType,
    this.discountType,
    this.discountValue,
    this.couponCode,
    this.productId,
    this.categoryId,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.usageLimit,
    required this.usageCount,
    this.startsAt,
    this.endsAt,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory DashboardPromotion.fromJson(Map<String, dynamic> json) {
    return DashboardPromotion(
      id: _readInt(json['id']),
      uuid: _readString(json['uuid']),
      title: _readString(json['title'], 'Special promotion'),
      description: _readNullableString(json['description']),
      bannerUrl: _readNullableString(
        json['banner_url'] ??
            json['image_url'] ??
            json['banner'] ??
            json['image'],
      ),
      promotionType: _readString(
        json['promotion_type'] ?? json['type'],
        'general',
      ),
      discountType: _readNullableString(json['discount_type']),
      discountValue: _readNullableDouble(json['discount_value']),
      couponCode: _readNullableString(json['coupon_code']),
      productId: _readNullableString(json['product_id']),
      categoryId: _readNullableString(json['category_id']),
      minimumOrderAmount: _readNullableDouble(json['minimum_order_amount']),
      maximumDiscountAmount: _readNullableDouble(
        json['maximum_discount_amount'],
      ),
      usageLimit: json['usage_limit'] == null
          ? null
          : _readInt(json['usage_limit']),
      usageCount: _readInt(json['usage_count']),
      startsAt: _readDateTime(json['starts_at']),
      endsAt: _readDateTime(json['ends_at']),
      isActive: _readBool(json['is_active']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  bool get hasDiscount {
    return discountValue != null && discountValue! > 0;
  }

  bool get hasCouponCode {
    return couponCode != null && couponCode!.trim().isNotEmpty;
  }

  bool get hasBanner {
    return bannerUrl != null && bannerUrl!.trim().isNotEmpty;
  }

  bool get isPercentageDiscount {
    return (discountType ?? '').toLowerCase() == 'percentage';
  }

  bool get isFixedDiscount {
    final type = (discountType ?? '').toLowerCase();

    return type == 'fixed' || type == 'fixed_amount' || type == 'amount';
  }

  String get discountLabel {
    if (!hasDiscount) return '';

    if (isPercentageDiscount) {
      return '${discountValue!.toStringAsFixed(discountValue! % 1 == 0 ? 0 : 2)}% OFF';
    }

    if (isFixedDiscount) {
      return 'Save ${discountValue!.toStringAsFixed(2)}';
    }

    return 'Special offer';
  }

  bool get hasStarted {
    final start = startsAt;

    return start == null || !DateTime.now().isBefore(start);
  }

  bool get hasNotExpired {
    final end = endsAt;

    return end == null || !DateTime.now().isAfter(end);
  }

  bool get isCurrentlyAvailable {
    return isActive && hasStarted && hasNotExpired;
  }

  bool get hasRemainingUses {
    return usageLimit == null || usageCount < usageLimit!;
  }
}
