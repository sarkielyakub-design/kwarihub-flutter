import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';

// ============================================================
// CONFIGURATION
// ============================================================

const String _backendBaseUrl =
    'https://kwarihub-backend-production-ea77.up.railway.app';

const Color _blue = Color(0xFF0D5CC7);
const Color _navy = Color(0xFF102F4F);
const Color _background = Color(0xFFF4F8FC);
const Color _border = Color(0xFFE6EDF5);
const Color _muted = Color(0xFF748198);

// ============================================================
// IMAGE URL HELPER
// ============================================================

String? _imageUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  var path = value.trim().replaceAll(r'\', '/');

  if (path.startsWith('https://') || path.startsWith('http://')) {
    return path.replaceFirst('/api/v1/storage/', '/storage/');
  }

  final storageIndex = path.indexOf('/storage/');

  if (storageIndex >= 0) {
    path = path.substring(storageIndex);
  }

  path = path.replaceFirst(RegExp(r'^/+'), '');

  if (path.startsWith('api/v1/storage/')) {
    path = path.replaceFirst('api/v1/storage/', 'storage/');
  }

  if (path.startsWith('storage/') || path.startsWith('uploads/')) {
    return '$_backendBaseUrl/$path';
  }

  return null;
}

// ============================================================
// PROMOTIONS API
// ============================================================

final dashboardPromotionsProvider = FutureProvider<List<DashboardPromotion>>((
  ref,
) async {
  final response = await ApiClient.instance.dio.get('/promotions/active');

  final body = response.data;

  dynamic payload = body;

  if (body is Map) {
    payload =
        body['data'] ??
        body['promotions'] ??
        body['items'] ??
        body['results'] ??
        body;

    if (payload is Map) {
      payload =
          payload['promotions'] ??
          payload['items'] ??
          payload['results'] ??
          payload;
    }
  }

  if (payload is! List) {
    return const <DashboardPromotion>[];
  }

  return payload
      .whereType<Map>()
      .map(
        (item) => DashboardPromotion.fromJson(Map<String, dynamic>.from(item)),
      )
      .where((promotion) => promotion.isCurrentlyAvailable)
      .toList();
});

// ============================================================
// DASHBOARD SCREEN
// ============================================================

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardPromotionsProvider);

    await Future.wait([
      ref.read(dashboardProvider.future),
      ref
          .read(dashboardPromotionsProvider.future)
          .catchError((_) => <DashboardPromotion>[]),
    ]);
  }

  void _openCategories() => context.go('/categories');

  void _openCart() => context.go('/cart');

  void _openOrders() => context.go('/orders');

  void _openProfile() => context.go('/profile');

  void _openProduct(DashboardProduct product) {
    if (product.uuid.isEmpty) {
      _openCategories();
      return;
    }

    context.push('/products/${product.uuid}');
  }

  void _openCategory(DashboardCategory category) {
    if (category.uuid.isEmpty) {
      _openCategories();
      return;
    }

    context.push('/categories/${category.uuid}');
  }

  void _submitSearch(String value) {
    final query = value.trim();

    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    // Keeps the current route structure intact.
    // Connect this to the real search route when available.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Search: $query'),
        action: SnackBarAction(label: 'Categories', onPressed: _openCategories),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _blue)),
          error: (error, stack) => _buildError(error),
          data: (dashboard) => RefreshIndicator(
            color: _blue,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(dashboard.user)),
                SliverToBoxAdapter(child: _buildSearch()),
                SliverToBoxAdapter(child: _buildHero(dashboard)),
                SliverToBoxAdapter(child: _buildPromotions()),
                SliverToBoxAdapter(
                  child: _sectionHeader(
                    'Shop by category',
                    'See all',
                    _openCategories,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildCategories(dashboard.featuredCategories),
                ),
                SliverToBoxAdapter(
                  child: _sectionHeader(
                    'Featured products',
                    'Explore',
                    _openCategories,
                  ),
                ),
                _buildProductGrid(dashboard.featuredProducts),
                SliverToBoxAdapter(
                  child: _sectionHeader(
                    'Latest products',
                    'Explore',
                    _openCategories,
                  ),
                ),
                _buildProductGrid(dashboard.latestProducts),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================================
  // ERROR STATE
  // ==========================================================

  Widget _buildError(Object error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 52, color: _blue),
            const SizedBox(height: 14),
            const Text(
              'Unable to load KwariHub',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 10),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(dashboardProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER: LOGO + SIGNED-IN USER + NOTIFICATIONS
  // ==========================================================

  Widget _buildHeader(DashboardUser user) {
    final avatarUrl = _imageUrl(user.avatar);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 7),
      child: Row(
        children: [
          Image.asset(
            'assets/images/kwarihub_logo.png',
            width: 112,
            height: 39,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              'KWARIHUB',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: _navy,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: _openProfile,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFFE7F0FF),
                    backgroundImage: avatarUrl == null
                        ? null
                        : NetworkImage(avatarUrl),
                    onBackgroundImageError: avatarUrl == null
                        ? null
                        : (_, __) {},
                    child: avatarUrl == null
                        ? Text(
                            user.initials,
                            style: const TextStyle(
                              color: _blue,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Welcome back,',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: _muted),
                        ),
                        Text(
                          user.firstNameDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: IconButton(
              tooltip: 'Notifications',
              visualDensity: VisualDensity.compact,
              onPressed: () => context.push('/notifications'),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: _navy,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        height: 49,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: _navy, size: 23),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: _searchController,
                onTap: () => setState(() => _searching = true),
                onSubmitted: _submitSearch,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search fabrics, styles, vendors...',
                  hintStyle: TextStyle(color: Color(0xFF8A96A8), fontSize: 12),
                  isDense: true,
                ),
              ),
            ),
            if (_searching)
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                  setState(() => _searching = false);
                },
                icon: const Icon(Icons.close_rounded, size: 19, color: _navy),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HERO
  // ==========================================================

  Widget _buildHero(DashboardModel dashboard) {
    final products = <DashboardProduct>[
      ...dashboard.featuredProducts,
      ...dashboard.latestProducts,
    ];

    final imageUrls = <String>[];

    for (final product in products) {
      final url = _imageUrl(product.image);

      if (url != null && !imageUrls.contains(url)) {
        imageUrls.add(url);
      }

      if (imageUrls.length == 3) break;
    }

    Widget imageTile(String? url) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.white.withOpacity(0.12),
          width: double.infinity,
          height: double.infinity,
          child: url == null
              ? const Center(
                  child: Icon(
                    Icons.checkroom_rounded,
                    color: Colors.white70,
                    size: 27,
                  ),
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.checkroom_rounded,
                      color: Colors.white70,
                      size: 27,
                    ),
                  ),
                ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 208,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_navy, _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -46,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'KWARIHUB MARKETPLACE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 11),
                          const Text(
                            'Quality Textiles\nFrom Kwari Market\nto Your Doorstep',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              height: 1.14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _openCategories,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Shop now',
                                    style: TextStyle(
                                      color: _blue,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: _blue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 174,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 6,
                              child: imageTile(
                                imageUrls.isNotEmpty ? imageUrls[0] : null,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: imageTile(
                                      imageUrls.length > 1
                                          ? imageUrls[1]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: imageTile(
                                      imageUrls.length > 2
                                          ? imageUrls[2]
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LIVE PROMOTIONS
  // ==========================================================

  Widget _buildPromotions() {
    final promotionsAsync = ref.watch(dashboardPromotionsProvider);

    return promotionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: LinearProgressIndicator(minHeight: 2, color: _blue),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (promotions) {
        if (promotions.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 154,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            scrollDirection: Axis.horizontal,
            itemCount: promotions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _PromotionCard(
                promotion: promotions[index],
                onTap: _openCategories,
              );
            },
          ),
        );
      },
    );
  }

  // ==========================================================
  // SECTION HEADER
  // ==========================================================

  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 23, 14, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: _navy,
                letterSpacing: -0.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: const TextStyle(
                color: _blue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CATEGORIES
  // ==========================================================

  Widget _buildCategories(List<DashboardCategory> categories) {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No categories available',
            style: TextStyle(color: _muted),
          ),
        ),
      );
    }

    return SizedBox(
      height: 123,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final url = _imageUrl(category.image ?? category.icon);

          return GestureDetector(
            onTap: () => _openCategory(category),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Container(
                      width: 74,
                      height: 75,
                      color: _background,
                      child: url == null
                          ? const Icon(
                              Icons.checkroom_outlined,
                              size: 30,
                              color: _blue,
                            )
                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.checkroom_outlined,
                                size: 30,
                                color: _blue,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // PRODUCT GRID
  // ==========================================================

  Widget _buildProductGrid(List<DashboardProduct> products) {
    if (products.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Text(
            'No products available yet.',
            style: TextStyle(color: _muted),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];

          return _ProductCard(
            product: product,
            onTap: () => _openProduct(product),
          );
        }, childCount: products.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.59,
        ),
      ),
    );
  }

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 57,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Categories',
                onTap: _openCategories,
              ),
              _NavItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Cart',
                onTap: _openCart,
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                onTap: _openOrders,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                onTap: _openProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROMOTION CARD
// ============================================================

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.promotion, required this.onTap});

  final DashboardPromotion promotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = _imageUrl(promotion.bannerUrl);

    return SizedBox(
      width: 310,
      child: Material(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              if (image != null)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _navy.withOpacity(0.88),
                        _blue.withOpacity(0.45),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              if (image == null)
                Positioned(
                  right: -10,
                  bottom: -20,
                  child: Icon(
                    Icons.local_offer_rounded,
                    size: 110,
                    color: _blue.withOpacity(0.08),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (promotion.hasDiscount)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: image == null ? _blue : Colors.white,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          promotion.discountLabel,
                          style: TextStyle(
                            color: image == null ? Colors.white : _navy,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    const SizedBox(height: 7),
                    Text(
                      promotion.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: image == null ? _navy : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((promotion.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        promotion.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: image == null ? _muted : Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    if (promotion.hasCouponCode) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Code: ${promotion.couponCode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: image == null ? _blue : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PRODUCT CARD
// ============================================================

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final DashboardProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = _imageUrl(product.image);
    final originalPrice = product.priceValue;
    final discountPrice = product.discountPriceValue;

    final hasDiscount =
        discountPrice != null &&
        discountPrice > 0 &&
        discountPrice < originalPrice;

    final price = hasDiscount ? discountPrice! : originalPrice;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFF0F2F5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: _background,
                        child: image == null
                            ? const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: _blue,
                                  size: 30,
                                ),
                              )
                            : Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: _blue,
                                    size: 28,
                                  ),
                                ),
                              ),
                      ),
                      if (hasDiscount)
                        Positioned(
                          top: 7,
                          left: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF3838),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SALE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 7,
                        bottom: 7,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onTap,
                            child: const Padding(
                              padding: EdgeInsets.all(9),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                color: _blue,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),

              // Show only actual rating data returned by the API.
              _ProductRating(product: product),

              const SizedBox(height: 5),
              Text(
                _formatPrice(price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(height: 2),
                Text(
                  _formatPrice(originalPrice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              const SizedBox(height: 3),
            ],
          ),
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
// PRODUCT RATING
// ============================================================

class _ProductRating extends StatelessWidget {
  const _ProductRating({required this.product});

  final DashboardProduct product;

  @override
  Widget build(BuildContext context) {
    if (!product.hasRating) {
      return const Text(
        'No reviews yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: _muted, fontSize: 9),
      );
    }

    final rating = product.safeRating;

    return Row(
      children: [
        ...List.generate(5, (index) {
          final filled = rating >= index + 1;
          final half = !filled && rating > index;

          return Icon(
            filled
                ? Icons.star_rounded
                : half
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: 13,
            color: const Color(0xFFFFB323),
          );
        }),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${rating.toStringAsFixed(1)} (${product.reviewCount})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION ITEM
// ============================================================

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
    final color = selected ? _blue : Colors.grey.shade500;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 57,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
