class CheckoutItemModel {
  final String uuid;
  final String productName;
  final String variantName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  CheckoutItemModel({
    required this.uuid,
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory CheckoutItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CheckoutItemModel(
      uuid: json['uuid']?.toString() ?? '',
      productName:
          json['product_name']?.toString() ?? '',
      variantName:
          json['variant_name']?.toString() ?? '',
      quantity:
          (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice:
          double.tryParse(
                json['unit_price']?.toString() ?? '',
              ) ??
              0,
      totalPrice:
          double.tryParse(
                json['total_price']?.toString() ?? '',
              ) ??
              0,
    );
  }
}

class CheckoutResponseModel {
  final String uuid;
  final String orderNumber;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String status;
  final String shippingAddress;
  final List<CheckoutItemModel> items;

  final String? paymentReference;
  final String? transactionReference;
  final String? checkoutUrl;
  final double? amount;
  final String? currency;

  CheckoutResponseModel({
    required this.uuid,
    required this.orderNumber,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.status,
    required this.shippingAddress,
    required this.items,
    this.paymentReference,
    this.transactionReference,
    this.checkoutUrl,
    this.amount,
    this.currency,
  });

  factory CheckoutResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CheckoutResponseModel(
      uuid: json['uuid']?.toString() ?? '',
      orderNumber:
          json['order_number']?.toString() ?? '',
      subtotal:
          double.tryParse(
                json['subtotal']?.toString() ?? '',
              ) ??
              0,
      shippingFee:
          double.tryParse(
                json['shipping_fee']?.toString() ?? '',
              ) ??
              0,
      total:
          double.tryParse(
                json['total']?.toString() ?? '',
              ) ??
              0,
      status:
          json['status']?.toString() ?? 'PENDING',
      shippingAddress:
          json['shipping_address']?.toString() ?? '',
      items:
          (json['items'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    CheckoutItemModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
      paymentReference:
          json['payment_reference']?.toString(),
      transactionReference:
          json['transaction_reference']?.toString(),
      checkoutUrl:
          json['checkout_url']?.toString(),
      amount:
          json['amount'] == null
              ? null
              : double.tryParse(
                  json['amount'].toString(),
                ),
      currency:
          json['currency']?.toString(),
    );
  }
}