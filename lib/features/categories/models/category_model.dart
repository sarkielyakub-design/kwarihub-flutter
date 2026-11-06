class CategoryModel {
  final String uuid;
  final String name;
  final String slug;
  final String? description;
  final String icon;
  final bool isFeatured;
  final bool isActive;
  final int productCount;

  const CategoryModel({
    required this.uuid,
    required this.name,
    required this.slug,
    this.description,
    this.icon = 'category',
    this.isFeatured = false,
    this.isActive = true,
    this.productCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['uuid'] ??
        json['id'] ??
        json['category_id'] ??
        json['categoryId'];

    final rawName = json['name'] ??
        json['title'] ??
        json['category_name'] ??
        json['categoryName'];

    final name = rawName?.toString().trim() ?? '';
    final rawSlug = json['slug'];

    return CategoryModel(
      uuid: rawId?.toString() ?? '',
      name: name,
      slug: rawSlug?.toString() ??
          name.toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
      description: _readOptionalString(
        json['description'] ?? json['details'],
      ),
      icon: (json['icon'] ?? json['icon_name'] ?? 'category')
          .toString(),
      isFeatured: _readBool(
        json['is_featured'] ??
            json['isFeatured'] ??
            json['featured'],
        fallback: false,
      ),
      isActive: _readBool(
        json['is_active'] ??
            json['isActive'] ??
            json['active'],
        fallback: true,
      ),
      productCount: _readInt(
        json['product_count'] ??
            json['productCount'] ??
            json['products_count'],
      ),
    );
  }

  static String? _readOptionalString(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _readBool(
    dynamic value, {
    required bool fallback,
  }) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;

    switch (value.toString().trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'active':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'inactive':
        return false;
      default:
        return fallback;
    }
  }
}