
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/cart_model.dart';
import '../providers/cart_provider.dart';

const String _backendBaseUrl =
    'https://kwarihub-backend-production-ea77.up.railway.app';

const Color _primaryBlue = Color(0xFF0D5CC7);
const Color _darkBlue = Color(0xFF102F4F);
const Color _lightBlue = Color(0xFFF4F8FF);
const Color _borderColor = Color(0xFFE3EAF3);

String? _resolveCartImageUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final path = value.trim();
  final uri = Uri.tryParse(path);

  if (uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty) {
    return uri.toString();
  }

  var clean = path.replaceFirst(RegExp(r'^/+'), '');

  if (clean.startsWith('api/v1/')) {
    clean = clean.substring('api/v1/'.length);
  }

  if (clean.startsWith('storage/') ||
      clean.startsWith('uploads/')) {
    return '$_backendBaseUrl/$clean';
  }

  if (clean.startsWith('products/')) {
    return '$_backendBaseUrl/storage/$clean';
  }

  return '$_backendBaseUrl/storage/$clean';
}

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Future<void> _refresh() async {
    ref.invalidate(cartProvider);
    await ref.read(cartProvider.future);
  }

  Future<void> _updateQuantity(
    CartItemModel item,
    int quantity,
  ) async {
    if (quantity < 1) return;

    try {
      await ref.read(cartApiProvider).updateCart(
            cartUuid: item.uuid,
            quantity: quantity,
          );

      if (mounted) ref.invalidate(cartProvider);
    } catch (e) {
      if (mounted) _showMessage(_cleanError(e));
    }
  }

  Future<void> _removeItem(CartItemModel item) async {
    try {
      await ref.read(cartApiProvider).removeItem(item.uuid);
      ref.invalidate(cartProvider);

      if (mounted) {
        _showMessage('Item removed from cart.');
      }
    } catch (e) {
      if (mounted) _showMessage(_cleanError(e));
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Clear Cart',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _darkBlue,
          ),
        ),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(cartApiProvider).clearCart();
      ref.invalidate(cartProvider);

      if (mounted) {
        _showMessage('Cart cleared successfully.');
      }
    } catch (e) {
      if (mounted) _showMessage(_cleanError(e));
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 82),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // Use the same Home route as CategoriesScreen.
  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _goToHome() => context.go('/home');

  void _goToCategories() => context.go('/categories');

  void _goToCart() => context.go('/cart');

  void _goToOrders() => context.go('/orders');

  void _goToProfile() => context.go('/profile');

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkBlue,
        elevation: 0,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _goBack,
          tooltip: 'Back to Home',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 21,
            color: _darkBlue,
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _darkBlue,
          ),
        ),
        actions: [
          cartAsync.when(
            data: (cart) => cart.items.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: _clearCart,
                    tooltip: 'Clear cart',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: _darkBlue,
                      size: 23,
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: cartAsync.when(
          loading: () => const _CartLoading(),
          error: (error, stackTrace) => _CartError(
            message: _cleanError(error),
            onRetry: _refresh,
          ),
          data: (cart) {
            if (cart.items.isEmpty) {
              return RefreshIndicator(
                color: _primaryBlue,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 120),
                  children: const [
                    SizedBox(height: 120),
                    _EmptyCart(),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: _primaryBlue,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _lightBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${cart.totalItems} '
                            '${cart.totalItems == 1 ? 'item' : 'items'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverList.separated(
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];

                        return _CartItemCard(
                          item: item,
                          onMinus: () => _updateQuantity(
                            item,
                            item.quantity - 1,
                          ),
                          onPlus: () => _updateQuantity(
                            item,
                            item.quantity + 1,
                          ),
                          onRemove: () => _removeItem(item),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
                      child: _CartSummary(cart: cart),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => context.push('/checkout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 20,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'Proceed to Checkout',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _CartBottomNavigation(
        currentIndex: 2,
        onHome: _goToHome,
        onCategories: _goToCategories,
        onCart: _goToCart,
        onOrders: _goToOrders,
        onProfile: _goToProfile,
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  final CartItemModel item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(imageUrl: item.productImageUrl),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: _darkBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onRemove,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _VariantInfo(item: item),
                const SizedBox(height: 9),
                Text(
                  _money(item.unitPrice),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _QuantityController(
                      quantity: item.quantity,
                      onMinus: onMinus,
                      onPlus: onPlus,
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        _money(item.itemTotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _darkBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveCartImageUrl(imageUrl);

    return Container(
      width: 88,
      height: 105,
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: resolvedUrl == null
          ? const _CartImagePlaceholder()
          : Image.network(
              resolvedUrl,
              width: 88,
              height: 105,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return const Center(
                  child: SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryBlue,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const _CartImagePlaceholder(),
            ),
    );
  }
}

class _CartImagePlaceholder extends StatelessWidget {
  const _CartImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 31,
            color: _primaryBlue,
          ),
          SizedBox(height: 5),
          Text(
            'No image',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _darkBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantInfo extends StatelessWidget {
  const _VariantInfo({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final values = <String>[];

    if (item.color != null && item.color!.trim().isNotEmpty) {
      values.add('Color: ${item.color}');
    }

    if (item.size != null && item.size!.trim().isNotEmpty) {
      values.add('Size: ${item.size}');
    }

    if (item.material != null && item.material!.trim().isNotEmpty) {
      values.add('Material: ${item.material}');
    }

    final text = values.isEmpty
        ? 'SKU: ${item.variantSku}'
        : values.join(' • ');

    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        height: 1.3,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _QuantityController extends StatelessWidget {
  const _QuantityController({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 1 ? onMinus : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 38,
            ),
            icon: const Icon(Icons.remove_rounded, size: 17),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _darkBlue,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 38,
            ),
            icon: const Icon(Icons.add_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});

  final CartSummaryModel cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal',
            value: _money(cart.subtotal),
            valueStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _darkBlue,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Total items',
            value: '${cart.totalItems}',
            valueStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _darkBlue,
            ),
          ),
          const SizedBox(height: 15),
          _SummaryRow(
            label: 'Total',
            value: _money(cart.subtotal),
            labelStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _darkBlue,
            ),
            valueStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueStyle,
    this.labelStyle,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle ??
                const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Your Cart is Empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: _darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Products you add to your cart will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go('/categories'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLoading extends StatelessWidget {
  const _CartLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _primaryBlue),
    );
  }
}

class _CartError extends StatelessWidget {
  const _CartError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBottomNavigation extends StatelessWidget {
  const _CartBottomNavigation({
    required this.currentIndex,
    required this.onHome,
    required this.onCategories,
    required this.onCart,
    required this.onOrders,
    required this.onProfile,
  });

  final int currentIndex;
  final VoidCallback onHome;
  final VoidCallback onCategories;
  final VoidCallback onCart;
  final VoidCallback onOrders;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE8EDF3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: onHome,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Categories',
                  selected: currentIndex == 1,
                  onTap: onCategories,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: 'Cart',
                  selected: currentIndex == 2,
                  onTap: onCart,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  selected: currentIndex == 3,
                  onTap: onOrders,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  selected: currentIndex == 4,
                  onTap: onProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: _primaryBlue.withValues(alpha: 0.06),
      highlightColor: _primaryBlue.withValues(alpha: 0.03),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? activeIcon : icon,
            size: 23,
            color: selected
                ? _primaryBlue
                : const Color(0xFFB7C1CC),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight:
                  selected ? FontWeight.w800 : FontWeight.w500,
              color: selected
                  ? _primaryBlue
                  : const Color(0xFFB7C1CC),
            ),
          ),
        ],
      ),
    );
  }
}

String _money(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value.toString()) ?? 0;

  return '₦${number.toStringAsFixed(2)}';
}
