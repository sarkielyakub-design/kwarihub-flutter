
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/order_model.dart';
import '../providers/orders_provider.dart';

const Color _primaryBlue = Color(0xFF0D5CC7);
const Color _darkBlue = Color(0xFF102F4F);
const Color _lightBlue = Color(0xFFF4F8FF);
const Color _borderColor = Color(0xFFDDE6F0);

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(ordersProvider);

    try {
      await ref.read(ordersProvider.future);
    } catch (_) {
      // The provider exposes refresh errors through its error state.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkBlue,
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _darkBlue,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: () => ref.invalidate(ordersProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ordersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _primaryBlue),
          ),
          error: (error, stackTrace) => _OrdersError(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(ordersProvider),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return RefreshIndicator(
                color: _primaryBlue,
                onRefresh: () => _refresh(ref),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: const [
                    SizedBox(height: 100),
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 70,
                      color: _primaryBlue,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No orders yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: _darkBlue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your orders will appear here after you place an order.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: _primaryBlue,
              onRefresh: () => _refresh(ref),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _OrderCard(order: orders[index]);
                },
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const _OrdersBottomNavigation(),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  Color _statusColor(String status) {
    final value = status
        .replaceAll('OrderStatus.', '')
        .trim()
        .toUpperCase();

    switch (value) {
      case 'PAID':
      case 'DELIVERED':
      case 'COMPLETED':
      case 'SUCCESS':
        return Colors.green.shade700;
      case 'CANCELLED':
      case 'FAILED':
      case 'REFUNDED':
        return Colors.red.shade700;
      case 'SHIPPED':
      case 'PROCESSING':
        return _primaryBlue;
      default:
        return Colors.orange.shade800;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Date unavailable';

    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _money(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final paymentColor = _statusColor(order.paymentStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: _lightBlue,
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _darkBlue,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      order.displayStatus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _borderColor),
            const SizedBox(height: 13),
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: _primaryBlue,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${order.items.length} '
                    '${order.items.length == 1 ? 'item' : 'items'}',
                    style: const TextStyle(
                      color: _darkBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${order.currency} ${_money(order.total)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _darkBlue,
                  ),
                ),
              ],
            ),
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...order.items.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.checkroom_outlined,
                        size: 16,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (item.variantName.isNotEmpty)
                              Text(
                                item.variantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'x${item.quantity}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (order.items.length > 3)
                Text(
                  '+ ${order.items.length - 3} more items',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Payment: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Expanded(
                  child: Text(
                    order.paymentStatus,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: paymentColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: _primaryBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load orders',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: _darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
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

class _OrdersBottomNavigation extends StatelessWidget {
  const _OrdersBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 7,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Categories',
                onTap: () => context.go('/categories'),
              ),
              _NavItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Cart',
                onTap: () => context.go('/cart'),
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                selected: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                onTap: () => context.go('/profile'),
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
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _primaryBlue : Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
