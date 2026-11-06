
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/category_model.dart';
import '../providers/categories_provider.dart';

const Color primaryBlue = Color(0xFF0D5CC7);
const Color darkBlue = Color(0xFF102F4F);
const Color lightBlue = Color(0xFFF4F8FF);
const Color borderColor = Color(0xFFDDE6F0);
const Color softBackground = Color(0xFFFAFCFF);

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({
    super.key,
    this.categoryId,
  });

  final String? categoryId;

  @override
  ConsumerState<CategoriesScreen> createState() =>
      _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(categoriesProvider);
    await ref.read(categoriesProvider.future);
  }

  List<CategoryModel> _categoriesWithProducts(
    List<CategoryModel> categories,
  ) {
    final available = categories
        .where(
          (category) =>
              category.isActive && category.productCount > 0,
        )
        .toList();

    available.sort((a, b) {
      return a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          );
    });

    return available;
  }

  List<CategoryModel> _filterCategories(
    List<CategoryModel> categories,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return categories;

    return categories.where((category) {
      return category.name.toLowerCase().contains(query) ||
          category.slug.toLowerCase().contains(query) ||
          (category.description ?? '')
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  CategoryModel? _findSelectedCategory(
    List<CategoryModel> categories,
  ) {
    final id = widget.categoryId?.trim();

    if (id == null || id.isEmpty) return null;

    for (final category in categories) {
      if (category.uuid == id) return category;
    }

    return null;
  }

  void _openCategory(CategoryModel category) {
    if (category.uuid.trim().isEmpty) return;

    context.push('/categories/${category.uuid}');
  }

  void _retry() {
    ref.invalidate(categoriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: primaryBlue,
            ),
          ),
          error: (error, stackTrace) => _ErrorView(
            message: error
                .toString()
                .replaceFirst('Exception: ', ''),
            onRetry: _retry,
          ),
          data: (allCategories) {
            final availableCategories =
                _categoriesWithProducts(allCategories);

            final filteredCategories =
                _filterCategories(availableCategories);

            final selectedCategory =
                _findSelectedCategory(availableCategories);

            final featuredCategories = availableCategories
                .where((category) => category.isFeatured)
                .toList();

            return RefreshIndicator(
              color: primaryBlue,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        0,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
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
                              'Categories',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: darkBlue,
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/kwarihub_logo.png',
                            width: 88,
                            height: 36,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(
                              Icons.storefront_rounded,
                              size: 30,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        4,
                        24,
                        0,
                      ),
                      child: Text(
                        selectedCategory == null
                            ? 'Explore categories with products available from our vendors.'
                            : 'Explore ${selectedCategory.name}.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),

                  if (selectedCategory != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          18,
                          24,
                          0,
                        ),
                        child: _SelectedCategoryCard(
                          category: selectedCategory,
                          onTap: () =>
                              _openCategory(selectedCategory),
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        18,
                        24,
                        0,
                      ),
                      child: _buildSearchBar(),
                    ),
                  ),

                  if (_searchQuery.trim().isEmpty &&
                      featuredCategories.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          25,
                          24,
                          0,
                        ),
                        child: Text(
                          'Featured Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: darkBlue,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildFeaturedCategories(
                        featuredCategories,
                      ),
                    ),
                  ],

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        25,
                        24,
                        0,
                      ),
                      child: Text(
                        _searchQuery.trim().isEmpty
                            ? 'Available Categories'
                            : 'Search Results',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: darkBlue,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        5,
                        24,
                        0,
                      ),
                      child: Text(
                        '${filteredCategories.length} '
                        '${filteredCategories.length == 1 ? 'category' : 'categories'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),

                  if (filteredCategories.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          25,
                          24,
                          35,
                        ),
                        child: _EmptyCategories(),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        16,
                        24,
                        30,
                      ),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final category =
                                filteredCategories[index];

                            return _CategoryGridCard(
                              category: category,
                              onTap: () =>
                                  _openCategory(category),
                            );
                          },
                          childCount: filteredCategories.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.88,
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
      height: 52,
      decoration: BoxDecoration(
        color: softBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(
            Icons.search_rounded,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search categories...',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: darkBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: Icon(
                Icons.close_rounded,
                size: 19,
                color: Colors.grey.shade500,
              ),
            ),
          const SizedBox(width: 3),
        ],
      ),
    );
  }

  Widget _buildFeaturedCategories(
    List<CategoryModel> categories,
  ) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final category = categories[index];

          return _FeaturedCategoryCard(
            category: category,
            onTap: () => _openCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: borderColor.withValues(alpha: 0.7),
          ),
        ),
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
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: false,
                onTap: () => context.go('/home'),
              ),
              _BottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Categories',
                selected: true,
                onTap: () {},
              ),
              _BottomNavItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Cart',
                selected: false,
                onTap: () => context.go('/cart'),
              ),
              _BottomNavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                selected: false,
                onTap: () => context.go('/orders'),
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

class _SelectedCategoryCard extends StatelessWidget {
  const _SelectedCategoryCard({
    required this.category,
    required this.onTap,
  });

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFD7E6F8),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: _CategoryImage(icon: category.icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: darkBlue,
                    ),
                  ),
                  if ((category.description ?? '')
                      .trim()
                      .isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        category.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${category.productCount} products available',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: primaryBlue,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCategoryCard extends StatelessWidget {
  const _FeaturedCategoryCard({
    required this.category,
    required this.onTap,
  });

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 145,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: softBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEAF0F6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CategoryImage(icon: category.icon),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 2),
            const Row(
              children: [
                Text(
                  'Explore',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 11,
                  color: primaryBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({
    required this.category,
    required this.onTap,
  });

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEAF0F6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CategoryImage(icon: category.icon),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: darkBlue,
              ),
            ),
            if ((category.description ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  category.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.25,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${category.productCount} products',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: primaryBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.icon});

  final String? icon;

  @override
  Widget build(BuildContext context) {
    final value = icon?.trim();

    if (value == null ||
        value.isEmpty ||
        !(value.startsWith('http://') ||
            value.startsWith('https://'))) {
      return _fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        value,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Container(
            color: lightBlue,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryBlue,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(
          Icons.checkroom_outlined,
          size: 38,
          color: primaryBlue,
        ),
      ),
    );
  }
}

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
        ? primaryBlue
        : Colors.grey.shade500;

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
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: primaryBlue,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load categories',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.isEmpty
                  ? 'Something went wrong while loading categories.'
                  : message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: softBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAF0F6),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No categories with products yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Categories will appear here when vendors add available products.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
