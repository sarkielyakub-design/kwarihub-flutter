import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/checkout_api.dart';
import '../models/checkout_response.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) {
  return CheckoutApi();
});

final checkoutProvider =
    Provider<CheckoutController>((ref) {
  return CheckoutController(ref);
});

class CheckoutController {
  CheckoutController(this.ref);

  final Ref ref;

  // ============================================================
  // CHECKOUT
  // ============================================================

  Future<CheckoutResponseModel> checkout({
    required String shippingAddress,
    required String redirectUrl,
  }) async {
    final api = ref.read(
      checkoutApiProvider,
    );

    return api.checkout(
      shippingAddress: shippingAddress,
      redirectUrl: redirectUrl,
    );
  }
}