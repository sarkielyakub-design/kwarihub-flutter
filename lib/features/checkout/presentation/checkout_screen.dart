import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../cart/providers/cart_provider.dart';
import '../models/checkout_response.dart';
import '../providers/checkout_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryBlue = Color(0xFF0D5CC7);

  static const Color darkBlue = Color(0xFF102F4F);

  static const Color lightBlue = Color(0xFFF4F8FF);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _shippingAddressController =
      TextEditingController();

  bool _isCheckingOut = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _shippingAddressController.dispose();
    super.dispose();
  }

  // ============================================================
  // CHECKOUT
  // ============================================================

  Future<void> _checkout() async {
    final shippingAddress = _shippingAddressController.text.trim();

    if (shippingAddress.isEmpty) {
      _showMessage('Please enter your shipping address.');
      return;
    }

    if (shippingAddress.length < 10) {
      _showMessage('Please enter a complete shipping address.');
      return;
    }

    setState(() {
      _isCheckingOut = true;
    });

    try {
      final controller = ref.read(checkoutProvider);

      final CheckoutResponseModel response = await controller.checkout(
        shippingAddress: shippingAddress,

        // This is the URL Monnify redirects to
        // after payment.
        redirectUrl: 'https://kwarihub.com/payment/success',
      );

      if (!mounted) return;

      // ========================================================
      // CHECKOUT URL
      // ========================================================

      final checkoutUrl = response.checkoutUrl;

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        _showMessage('Payment checkout URL was not returned.');
        return;
      }

      await _openPaymentPage(checkoutUrl);
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN MONNIFY
  // ============================================================

  Future<void> _openPaymentPage(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      _showMessage('Invalid payment URL.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Unable to open payment page.');
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to open payment page.');
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_rounded, color: darkBlue),
        ),

        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: darkBlue,
          ),
        ),
      ),

      body: SafeArea(
        child: cartAsync.when(
          // ======================================================
          // LOADING
          // ======================================================
          loading: () {
            return const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            );
          },

          // ======================================================
          // ERROR
          // ======================================================
          error: (error, stackTrace) {
            return _CheckoutError(
              message: error.toString().replaceFirst('Exception: ', ''),
              onRetry: () {
                ref.invalidate(cartProvider);
              },
            );
          },

          // ======================================================
          // DATA
          // ======================================================
          data: (cart) {
            if (cart.items.isEmpty) {
              return const _EmptyCheckout();
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // =================================================
                  // CHECKOUT HEADER
                  // =================================================
                  const Text(
                    'Complete your order',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: darkBlue,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Review your order and provide your delivery address.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // SHIPPING ADDRESS
                  // =================================================
                  const _SectionTitle(
                    icon: Icons.location_on_outlined,
                    title: 'Delivery Address',
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: const Color(0xFFE1E8F1)),
                    ),

                    child: TextField(
                      controller: _shippingAddressController,

                      minLines: 4,
                      maxLines: 6,

                      textInputAction: TextInputAction.newline,

                      decoration: InputDecoration(
                        hintText: 'Enter your complete delivery address',

                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),

                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14, right: 8, top: 15),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: primaryBlue,
                          ),
                        ),

                        border: InputBorder.none,

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // ORDER ITEMS
                  // =================================================
                  const _SectionTitle(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Order Items',
                  ),

                  const SizedBox(height: 12),

                  ...cart.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CheckoutItemCard(
                        productName: item.name ?? 'Unknown Product',
                        variant: item.variantId.toString(),
                        quantity: item.quantity,
                        price: item.price ?? 0.0,
                      ),
                    );
                  }),

                  const SizedBox(height: 18),

                  // =================================================
                  // ORDER SUMMARY
                  // =================================================
                  const _SectionTitle(
                    icon: Icons.receipt_long_outlined,
                    title: 'Order Summary',
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: lightBlue,

                      borderRadius: BorderRadius.circular(18),

                      border: Border.all(color: const Color(0xFFE0E9F4)),
                    ),

                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Subtotal',
                          value: _money(cart.subtotal),
                        ),

                        const SizedBox(height: 12),

                        _SummaryRow(label: 'Shipping', value: '₦0.00'),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1),
                        ),

                        _SummaryRow(
                          label: 'Total',
                          value: _money(cart.subtotal),
                          large: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // PAYMENT INFORMATION
                  // =================================================
                  Container(
                    padding: const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),

                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Container(
                          width: 38,
                          height: 38,

                          decoration: BoxDecoration(
                            color: lightBlue,
                            borderRadius: BorderRadius.circular(11),
                          ),

                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: primaryBlue,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Text(
                                'Secure Payment',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: darkBlue,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'You will be redirected to Monnify to securely complete your payment.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // =================================================
                  // PAY NOW
                  // =================================================
                  SizedBox(
                    width: double.infinity,

                    height: 56,

                    child: ElevatedButton(
                      onPressed: _isCheckingOut ? null : _checkout,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,

                        disabledBackgroundColor: primaryBlue.withValues(alpha: 0.55),

                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),

                      child: _isCheckingOut
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  'Pay ${_money(cart.subtotal)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'By continuing, you agree to complete this order.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _money(double value) {
    return '₦${value.toStringAsFixed(2)}';
  }
}

// ================================================================
// SECTION TITLE
// ================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  static const Color primaryBlue = Color(0xFF0D5CC7);

  static const Color darkBlue = Color(0xFF102F4F);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,

          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FF),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(icon, size: 19, color: primaryBlue),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: darkBlue,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// CHECKOUT ITEM
// ================================================================

class _CheckoutItemCard extends StatelessWidget {
  const _CheckoutItemCard({
    required this.productName,
    required this.variant,
    required this.quantity,
    required this.price,
  });

  final String productName;
  final String variant;
  final int quantity;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FF),
              borderRadius: BorderRadius.circular(13),
            ),

            child: const Icon(Icons.image_outlined, color: Color(0xFF0D5CC7)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102F4F),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Variant #$variant',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 4),

                Text(
                  'Qty: $quantity',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '₦${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D5CC7),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SUMMARY ROW
// ================================================================

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.large = false,
  });

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: large ? 16 : 13,
              fontWeight: large ? FontWeight.w900 : FontWeight.w500,
              color: large ? const Color(0xFF102F4F) : Colors.grey.shade700,
            ),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontSize: large ? 20 : 14,
            fontWeight: FontWeight.w900,
            color: large ? const Color(0xFF0D5CC7) : const Color(0xFF102F4F),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// EMPTY CHECKOUT
// ================================================================

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 65,
              color: Color(0xFF0D5CC7),
            ),

            const SizedBox(height: 20),

            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF102F4F),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Add products to your cart before checking out.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// ERROR
// ================================================================

class _CheckoutError extends StatelessWidget {
  const _CheckoutError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: Color(0xFF0D5CC7),
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load checkout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF102F4F),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5CC7),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
