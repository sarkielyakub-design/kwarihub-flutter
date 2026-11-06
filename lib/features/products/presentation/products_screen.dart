
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/product_model.dart';
import '../providers/products_provider.dart';

const String _kwariHubBackendBaseUrl =
    'https://kwarihub-backend-production-ea77.up.railway.app';

String? _resolveProductImageUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  var path = value.trim().replaceAll(r'\', '/');

  final storageIndex = path.indexOf('/storage/');
  if (storageIndex >= 0) {
    path = path.substring(storageIndex);
  }

  final uri = Uri.tryParse(path);
  if (uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http')) {
    return path.replaceFirst('/api/v1/storage/', '/storage/');
  }

  path = path.replaceFirst(RegExp(r'^/+'), '');

  if (path.startsWith('api/v1/storage/')) {
    path = path.replaceFirst('api/v1/storage/', 'storage/');
  }

  if (path.startsWith('storage/') || path.startsWith('uploads/')) {
    return '$_kwariHubBackendBaseUrl/$path';
  }

  return null;
}

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key, this.categoryId});

  final String? categoryId;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  static const Color primaryBlue = Color(0xFF0D5CC7);
  static const Color darkBlue = Color(0xFF102F4F);
  static const Color borderColor = Color(0xFFDDE6F0);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(productsProvider);
    await ref.read(productsProvider.future);
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var result = products;
    final categoryId = int.tryParse(widget.categoryId ?? '');

    if (categoryId != null) {
      result = result
          .where((product) => product.categoryId == categoryId)
          .toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return result;

    return result.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.slug.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query) ||
          (product.brand?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _openProduct(ProductModel product) {
    context.push('/products/${product.uuid}');
  }

  void _openCart() {
    context.push('/cart');
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: productsAsync.when(
          loading: () => const _ProductsLoading(),
          error: (error, stackTrace) => _ProductsError(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(productsProvider),
          ),
          data: (products) {
            final filtered = _filterProducts(products);

            return RefreshIndicator(
              color: primaryBlue,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // SHOP HEADER
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/home');
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: darkBlue,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Shop',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: darkBlue,
                              ),
                            ),
                          ),

                          // SHOPPING CART SHORTCUT
                          IconButton(
                            tooltip: 'Open shopping cart',
                            onPressed: _openCart,
                            icon: const Icon(
                              Icons.shopping_cart_rounded,
                              color: darkBlue,
                              size: 27,
                            ),
                          ),
                          Image.asset(
                            'assets/images/kwarihub_logo.png',
                            width: 58,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_bag_rounded,
                              color: primaryBlue,
                              size: 27,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SEARCH BAR
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: _buildSearchBar(),
                    ),
                  ),

                  // SECTION TITLE
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Discover products',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: darkBlue,
                              ),
                            ),
                          ),
                          Text(
                            '${filtered.length} items',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // EMPTY STATE
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _EmptyProducts(
                          hasSearch: _searchQuery.trim().isNotEmpty,
                        ),
                      ),
                    ),

                  // FOUR-COLUMN GRID
                  if (filtered.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = filtered[index];

                            return _ProductCard(
                              product: product,
                              onTap: () => _openProduct(product),
                              onCartTap: _openCart,
                            );
                          },
                          childCount: filtered.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.43,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 21,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search products...',
                isDense: true,
                hintStyle: TextStyle(fontSize: 12),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: darkBlue,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: borderColor.withValues(alpha: 0.8),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: false,
                onTap: () => context.go('/home'),
              ),
              _BottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Categories',
                selected: false,
                onTap: () => context.go('/categories'),
              ),
              _BottomNavItem(
                icon: Icons.shopping_cart_rounded,
                label: 'Cart',
                selected: true,
                onTap: _openCart,
              ),
              _BottomNavItem(
                icon: Icons.favorite_border_rounded,
                label: 'Wishlist',
                selected: false,
                onTap: () => context.go('/wishlist'),
              ),
              _BottomNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: false,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROFESSIONAL PRODUCT CARD
// ============================================================

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onCartTap,
  });

  static const Color primaryBlue = Color(0xFF0D5CC7);
  static const Color darkBlue = Color(0xFF102F4F);
  static const Color borderColor = Color(0xFFDDE6F0);

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveProductImageUrl(product.primaryImage);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRODUCT IMAGE
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FF),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: borderColor),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const _ProductImagePlaceholder(
                            isLoading: true,
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            const _ProductImagePlaceholder(),
                      )
                    else
                      const _ProductImagePlaceholder(),

                    // SALE BADGE
                    if (product.hasDiscount)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'SALE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                    // WISHLIST HEART
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _RoundImageAction(
                        tooltip: 'Wishlist',
                        icon: Icons.favorite_border_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Wishlist action needs to be connected.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // CART ICON ON EVERY PRODUCT IMAGE
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: _RoundImageAction(
                        tooltip: 'Open shopping cart',
                        icon: Icons.shopping_cart_rounded,
                        iconColor: primaryBlue,
                        onTap: onCartTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 5),

            // PRODUCT NAME
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: darkBlue,
              ),
            ),

            const SizedBox(height: 3),

            // BRAND
            Text(
              product.brand?.trim().isNotEmpty == true
                  ? product.brand!
                  : product.unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 3),

            // FIVE VISIBLE RATING STARS
            // Replace the sample rating with backend review data
            // when the product API supplies a real rating.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) => const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB400),
                  size: 11,
                ),
              ),
            ),

            const SizedBox(height: 1),

            const Text(
              '4.8 / 5',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5F6B7A),
              ),
            ),

            const SizedBox(height: 3),

            // SELLING PRICE
            Text(
              _formatPrice(product.sellingPrice),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: primaryBlue,
              ),
            ),

            // ORIGINAL PRICE
            if (product.hasDiscount)
              Text(
                _formatPrice(product.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey.shade500,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(double value) {
    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    ).format(value);
  }
}

// ============================================================
// ROUND IMAGE ACTION
// ============================================================

class _RoundImageAction extends StatelessWidget {
  const _RoundImageAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.iconColor = const Color(0xFF102F4F),
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.97),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PRODUCT IMAGE PLACEHOLDER
// ============================================================

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F8FF),
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0D5CC7),
              ),
            )
          : const Icon(
              Icons.checkroom_outlined,
              size: 28,
              color: Color(0xFF0D5CC7),
            ),
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION ITEM
// ============================================================

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFF0D5CC7)
        : Colors.grey.shade400;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOADING STATE
// ============================================================

class _ProductsLoading extends StatelessWidget {
  const _ProductsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0D5CC7),
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class _ProductsError extends StatelessWidget {
  const _ProductsError({
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
              color: Color(0xFF0D5CC7),
              size: 44,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load products',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102F4F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({this.hasSearch = false});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAF0F6),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: Color(0xFF0D5CC7),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch ? 'No matching products' : 'No products found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF102F4F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Try another product name, brand, or SKU.'
                : 'There are no products available here yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
