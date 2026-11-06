
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/orders_api.dart';
import '../models/order_model.dart';

final ordersApiProvider = Provider<OrdersApi>((ref) {
  return OrdersApi();
});

final ordersProvider =
    FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final api = ref.watch(ordersApiProvider);
  return api.getOrders();
});
