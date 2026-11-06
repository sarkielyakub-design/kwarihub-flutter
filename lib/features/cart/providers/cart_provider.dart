import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cart_api.dart';
import '../models/cart_model.dart';

final cartApiProvider = Provider<CartApi>(
  (ref) => CartApi(),
);

final cartProvider = FutureProvider.autoDispose<CartSummaryModel>(
  (ref) async {
    final api = ref.read(cartApiProvider);

    return api.getCart();
  },
);