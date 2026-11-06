
class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String currency;
  final double total;
  final DateTime? createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.currency,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  String get displayStatus {
    final normalized = status
        .replaceAll('OrderStatus.', '')
        .trim()
        .replaceAll('_', ' ');

    if (normalized.isEmpty) return 'Pending';

    return normalized
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}'
                  '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get displayPaymentStatus {
    final normalized = paymentStatus
        .replaceAll('PaymentStatus.', '')
        .trim()
        .replaceAll('_', ' ');

    if (normalized.isEmpty) return 'Pending';

    return normalized
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}'
                  '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ??
        json['order_items'] ??
        json['orderItems'] ??
        json['products'];

    final rawDate = json['created_at'] ??
        json['createdAt'] ??
        json['order_date'] ??
        json['date'];

    final rawTotal = json['total'] ??
        json['total_amount'] ??
        json['totalAmount'] ??
        json['grand_total'] ??
        json['amount'];

    final rawPayment = json['payment_status'] ??
        json['paymentStatus'] ??
        json['payment_state'];

    return OrderModel(
      id: _readString(
        json['uuid'] ?? json['id'] ?? json['order_id'],
        fallback: '',
      ),
      orderNumber: _readString(
        json['order_number'] ??
            json['orderNumber'] ??
            json['reference'] ??
            json['uuid'] ??
            json['id'],
        fallback: 'Order',
      ),
      status: _readString(
        json['status'] ?? json['order_status'],
        fallback: 'pending',
      ),
      paymentStatus: _readString(
        rawPayment,
        fallback: 'pending',
      ),
      currency: _readString(
        json['currency'] ?? json['currency_code'],
        fallback: 'NGN',
      ),
      total: _readAmount(rawTotal),
      createdAt: _readDate(rawDate),
      items: _parseItems(rawItems),
    );
  }

  static List<OrderItemModel> _parseItems(dynamic value) {
    if (value is! List) return const <OrderItemModel>[];

    return value.whereType<Map>().map((item) {
      return OrderItemModel.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList(growable: false);
  }

  static String _readString(
    dynamic value, {
    required String fallback,
  }) {
    if (value == null) return fallback;

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(
            value.replaceAll(',', '').trim(),
          ) ??
          0;
    }

    return 0;
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    return DateTime.tryParse(value.toString());
  }
}

class OrderItemModel {
  final String id;
  final String productName;
  final String variantName;
  final int quantity;
  final double price;
  final double totalPrice;
  final String? imageUrl;

  const OrderItemModel({
    required this.id,
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final rawQuantity = json['quantity'] ?? json['qty'] ?? 1;

    final rawPrice = json['unit_price'] ??
        json['unitPrice'] ??
        json['price'] ??
        0;

    final rawTotal = json['total_price'] ??
        json['totalPrice'] ??
        json['line_total'] ??
        json['lineTotal'] ??
        rawPrice;

    final rawImage = json['image_url'] ??
        json['imageUrl'] ??
        json['product_image'] ??
        json['image'];

    return OrderItemModel(
      id: _readString(
        json['uuid'] ??
            json['id'] ??
            json['order_item_id'] ??
            json['product_id'],
        fallback: '',
      ),
      productName: _readString(
        json['product_name'] ??
            json['productName'] ??
            json['name'] ??
            json['title'],
        fallback: 'Product',
      ),
      variantName: _readString(
        json['variant_name'] ?? json['variantName'],
        fallback: '',
      ),
      quantity: _readQuantity(rawQuantity),
      price: _readAmount(rawPrice),
      totalPrice: _readAmount(rawTotal),
      imageUrl: rawImage == null ? null : rawImage.toString(),
    );
  }

  static String _readString(
    dynamic value, {
    required String fallback,
  }) {
    if (value == null) return fallback;

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static int _readQuantity(dynamic value) {
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 1;
  }

  static double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(
            value.replaceAll(',', '').trim(),
          ) ??
          0;
    }

    return 0;
  }
}
