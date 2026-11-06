import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/products_api.dart';
import '../models/product_model.dart';

final productsApiProvider =
    Provider<ProductsApi>(
  (ref) {
    return ProductsApi();
  },
);

final productsProvider =
    FutureProvider.autoDispose<
        List<ProductModel>>(
  (ref) async {
    final api =
        ref.read(productsApiProvider);

    return api.getProducts();
  },
);