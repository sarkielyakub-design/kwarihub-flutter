import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/wishlist_model.dart';
import '../providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final Set<String> _removingProducts = {};

  @override
  Widget build(BuildContext context) {
    final wishlistState = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        // We handle the back navigation ourselves so it always
        // behaves correctly with GoRouter.
        automaticallyImplyLeading: false,

        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 21,
            color: Color(0xFF172033),
          ),
          tooltip: 'Back',
        ),

        titleSpacing: 0,

        title: const Text(
          'Wishlist',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Color(0xFF172033),
          ),
        ),

        actions: [
          wishlistState.when(
            data: (items) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      color: Color(0xFF0D5CC7),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: wishlistState.when(
        // ----------------------------------------------------------
        // LOADING
        // ----------------------------------------------------------

        loading: () => const _WishlistLoading(),

        // ----------------------------------------------------------
        // ERROR
        // ----------------------------------------------------------

        error: (error, _) => _WishlistError(
          message: _errorMessage(error),
          onRetry: () {
            ref.read(wishlistProvider.notifier).refresh();
          },
        ),

        // ----------------------------------------------------------
        // DATA
        // ----------------------------------------------------------

        data: (items) {
          if (items.isEmpty) {
            return _WishlistEmpty(
              onBrowseProducts: () {
                context.go('/home');
              },
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF0D5CC7),

            onRefresh: () async {
              await ref
                  .read(wishlistProvider.notifier)
                  .refresh();
            },

            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                32,
              ),

              itemCount: items.length,

              separatorBuilder: (_, _) => const SizedBox(
                height: 12,
              ),

              itemBuilder: (context, index) {
                final item = items[index];

                return _WishlistProductCard(
                  item: item,

                  isRemoving: _removingProducts.contains(
                    item.product.uuid,
                  ),

                  onRemove: () => _removeItem(item),

                  onTap: () {
                    context.push(
                      '/products/${item.product.uuid}',
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // REMOVE ITEM
  // ================================================================

  Future<void> _removeItem(WishlistItem item) async {
    final productUuid = item.product.uuid;

    if (_removingProducts.contains(productUuid)) {
      return;
    }

    setState(() {
      _removingProducts.add(productUuid);
    });

    try {
      final success = await ref
          .read(wishlistProvider.notifier)
          .remove(productUuid);

      if (!mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Removed from wishlist',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not remove this product. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.response?.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please log in to manage your wishlist.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.go('/login');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not remove this product. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _removingProducts.remove(productUuid);
      });
    }
  }

  // ================================================================
  // ERROR MESSAGE
  // ================================================================

  String _errorMessage(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return 'Please log in to view your wishlist.';
      }

      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];

        if (detail is String && detail.isNotEmpty) {
          return detail;
        }

        final message = data['message'];

        if (message is String && message.isNotEmpty) {
          return message;
        }
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to the server.';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'The request timed out. Please try again.';
      }
    }

    return 'Something went wrong while loading your wishlist.';
  }
}

// ==================================================================
// WISHLIST PRODUCT CARD
// ==================================================================

class _WishlistProductCard extends StatelessWidget {
  const _WishlistProductCard({
    required this.item,
    required this.isRemoving,
    required this.onRemove,
    required this.onTap,
  });

  final WishlistItem item;
  final bool isRemoving;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,

      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // PRODUCT IMAGE
              // ----------------------------------------------------

              _ProductImage(
                imageUrl: product.primaryImage,
                isAvailable: product.isAvailable,
              ),

              const SizedBox(width: 14),

              // ----------------------------------------------------
              // PRODUCT INFORMATION
              // ----------------------------------------------------

              Expanded(
                child: _ProductInformation(
                  product: product,
                ),
              ),

              const SizedBox(width: 8),

              // ----------------------------------------------------
              // REMOVE BUTTON
              // ----------------------------------------------------

              _RemoveButton(
                loading: isRemoving,
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// PRODUCT IMAGE
// ==================================================================

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.imageUrl,
    required this.isAvailable,
  });

  final String? imageUrl;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 105,
          height: 120,

          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(14),
          ),

          clipBehavior: Clip.antiAlias,

          child: imageUrl == null || imageUrl!.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 38,
                    color: Color(0xFF9CA3AF),
                  ),
                )
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,

                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 36,
                        color: Color(0xFF9CA3AF),
                      ),
                    );
                  },

                  loadingBuilder: (
                    context,
                    child,
                    loadingProgress,
                  ) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0D5CC7),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // ----------------------------------------------------------
        // UNAVAILABLE OVERLAY
        // ----------------------------------------------------------

        if (!isAvailable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.38,
                ),
                borderRadius: BorderRadius.circular(14),
              ),

              alignment: Alignment.center,

              child: const Text(
                'Unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ==================================================================
// PRODUCT INFORMATION
// ==================================================================

class _ProductInformation extends StatelessWidget {
  const _ProductInformation({
    required this.product,
  });

  // WishlistItem exposes the product model.
  // Keeping this dynamic preserves compatibility with the
  // existing WishlistProduct model.
  final dynamic product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ----------------------------------------------------------
        // NAME
        // ----------------------------------------------------------

        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,

          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
            height: 1.25,
          ),
        ),

        const SizedBox(height: 7),

        // ----------------------------------------------------------
        // BRAND
        // ----------------------------------------------------------

        if (product.brand != null &&
            product.brand!.isNotEmpty)
          Text(
            product.brand!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),

        const SizedBox(height: 10),

        // ----------------------------------------------------------
        // PRICE
        // ----------------------------------------------------------

        if (product.hasDiscount)
          Row(
            children: [
              Text(
                _formatPrice(
                  product.currentPrice,
                ),

                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D5CC7),
                ),
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Text(
                  _formatPrice(product.price),
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    decoration:
                        TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            _formatPrice(product.price),

            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D5CC7),
            ),
          ),

        const SizedBox(height: 7),

        // ----------------------------------------------------------
        // AVAILABILITY
        // ----------------------------------------------------------

        Row(
          children: [
            Icon(
              product.isAvailable
                  ? Icons.check_circle_outline
                  : Icons.remove_circle_outline,

              size: 15,

              color: product.isAvailable
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),

            const SizedBox(width: 5),

            Flexible(
              child: Text(
                product.isAvailable
                    ? '${product.quantity} ${product.unit} available'
                    : 'Currently unavailable',

                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,

                  color: product.isAvailable
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPrice(double value) {
    return '₦${value.toStringAsFixed(2)}';
  }
}

// ==================================================================
// REMOVE BUTTON
// ==================================================================

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,

      child: Material(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),

        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onPressed,

          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(11),

                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFDC2626),
                  ),
                )
              : const Icon(
                  Icons.delete_outline_rounded,
                  size: 21,
                  color: Color(0xFFDC2626),
                ),
        ),
      ),
    );
  }
}

// ==================================================================
// EMPTY WISHLIST
// ==================================================================

class _WishlistEmpty extends StatelessWidget {
  const _WishlistEmpty({
    required this.onBrowseProducts,
  });

  final VoidCallback onBrowseProducts;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // ------------------------------------------------------
            // ICON
            // ------------------------------------------------------

            Container(
              width: 100,
              height: 100,

              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(30),
              ),

              child: const Icon(
                Icons.favorite_border_rounded,
                size: 52,
                color: Color(0xFF0D5CC7),
              ),
            ),

            const SizedBox(height: 24),

            // ------------------------------------------------------
            // TITLE
            // ------------------------------------------------------

            const Text(
              'Your wishlist is empty',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF172033),
              ),
            ),

            const SizedBox(height: 10),

            // ------------------------------------------------------
            // DESCRIPTION
            // ------------------------------------------------------

            const Text(
              'Save products you love here so you can easily find them later.',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 26),

            // ------------------------------------------------------
            // BROWSE PRODUCTS
            // ------------------------------------------------------

            SizedBox(
              height: 50,

              child: ElevatedButton(
                onPressed: onBrowseProducts,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5CC7),
                  foregroundColor: Colors.white,
                  elevation: 0,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                child: const Text(
                  'Browse Products',

                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// WISHLIST ERROR
// ==================================================================

class _WishlistError extends StatelessWidget {
  const _WishlistError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // ------------------------------------------------------
            // ERROR ICON
            // ------------------------------------------------------

            Container(
              width: 90,
              height: 90,

              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(28),
              ),

              child: const Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: Color(0xFFDC2626),
              ),
            ),

            const SizedBox(height: 22),

            // ------------------------------------------------------
            // TITLE
            // ------------------------------------------------------

            const Text(
              'Unable to load wishlist',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF172033),
              ),
            ),

            const SizedBox(height: 9),

            // ------------------------------------------------------
            // ERROR MESSAGE
            // ------------------------------------------------------

            Text(
              message,
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 24),

            // ------------------------------------------------------
            // RETRY
            // ------------------------------------------------------

            OutlinedButton(
              onPressed: onRetry,

              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D5CC7),

                side: const BorderSide(
                  color: Color(0xFF0D5CC7),
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),

              child: const Text(
                'Try Again',

                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// WISHLIST LOADING
// ==================================================================

class _WishlistLoading extends StatelessWidget {
  const _WishlistLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),

      itemCount: 5,

      separatorBuilder: (_, _) => const SizedBox(
        height: 12,
      ),

      itemBuilder: (context, index) {
        return Container(
          height: 144,

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),

          child: const Padding(
            padding: EdgeInsets.all(12),

            child: Row(
              children: [
                _ShimmerBox(
                  width: 105,
                  height: 120,
                ),

                SizedBox(width: 14),

                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      _ShimmerBox(
                        width: double.infinity,
                        height: 16,
                      ),

                      SizedBox(height: 10),

                      _ShimmerBox(
                        width: 120,
                        height: 13,
                      ),

                      SizedBox(height: 16),

                      _ShimmerBox(
                        width: 100,
                        height: 18,
                      ),

                      SizedBox(height: 10),

                      _ShimmerBox(
                        width: 130,
                        height: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================================================================
// SHIMMER BOX
// ==================================================================

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,

      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF3),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}