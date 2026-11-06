
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../models/product_image_model.dart';
import '../models/product_variant_model.dart';
import '../providers/product_details_provider.dart';

const Color primaryBlue = Color(0xFF0D5CC7);
const Color darkBlue = Color(0xFF102F4F);
const Color borderColor = Color(0xFFE2EAF3);

const String _backendBaseUrl =
    'https://kwarihub-backend-production-ea77.up.railway.app';

const String _supportEmail = 'support@kwarihub.com';
const String _supportPhone = '08164045444';

String _resolveImageUrl(String path) {
  var value = path.trim().replaceAll(r'\', '/');

  if (value.isEmpty) return '';

  final storageIndex = value.indexOf('/storage/');

  if (storageIndex >= 0 &&
      !value.startsWith('http://') &&
      !value.startsWith('https://')) {
    value = value.substring(storageIndex);
  }

  if (value.startsWith('http://') ||
      value.startsWith('https://')) {
    return value.replaceFirst(
      '/api/v1/storage/',
      '/storage/',
    );
  }

  value = value.replaceFirst(RegExp(r'^/+'), '');

  if (value.startsWith('api/v1/storage/')) {
    value = value.replaceFirst(
      'api/v1/storage/',
      'storage/',
    );
  }

  if (value.startsWith('storage/') ||
      value.startsWith('uploads/')) {
    return '$_backendBaseUrl/$value';
  }

  return '';
}

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends ConsumerState<ProductDetailsScreen> {
  int _selectedImage = 0;
  int _quantity = 1;
  String? _selectedVariant;

  bool _addingToCart = false;
  bool _wishlistUpdating = false;
  bool _shippingExpanded = false;
  bool _supportExpanded = false;

  Future<void> _refresh() async {
    ref.invalidate(productDetailsProvider(widget.productId));
    ref.invalidate(wishlistProvider);

    await ref.read(
      productDetailsProvider(widget.productId).future,
    );
  }

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            success ? Colors.green.shade700 : darkBlue,
        content: Text(message),
      ),
    );
  }

  void _increaseQuantity(int available) {
    if (_quantity < available) {
      setState(() => _quantity++);
    }
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  String _extractError(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final detail = data['detail'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }

      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;

        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }

        return first.toString();
      }

      final message = data['message'] ?? data['error'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'Please check the selected variant and quantity.';
      case 401:
        return 'Please login to continue.';
      case 404:
        return 'The requested product or variant was not found.';
      case 500:
        return 'Server error. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to KwariHub server.';
    }

    return 'Something went wrong. Please try again.';
  }

  Future<void> _addToCart({
    required String? variantUuid,
    required int availableQuantity,
  }) async {
    if (_addingToCart) return;

    if (availableQuantity <= 0) {
      _showMessage('This product is currently out of stock.');
      return;
    }

    if (variantUuid == null || variantUuid.trim().isEmpty) {
      _showMessage('Please select a product variant first.');
      return;
    }

    setState(() => _addingToCart = true);

    try {
      final response = await ApiClient.instance.dio.post(
        '/cart',
        data: {
          'variant_uuid': variantUuid.trim(),
          'quantity': _quantity.clamp(1, availableQuantity),
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        _showMessage(
          'Product added to cart successfully.',
          success: true,
        );

        await Future.delayed(
          const Duration(milliseconds: 350),
        );

        if (mounted) context.push('/cart');
      } else {
        _showMessage('Unable to add product to cart.');
      }
    } on DioException catch (error) {
      if (!mounted) return;

      if (error.response?.statusCode == 401) {
        _showMessage('Please login to add products to your cart.');

        await Future.delayed(
          const Duration(milliseconds: 350),
        );

        if (mounted) context.push('/login');
      } else {
        _showMessage(_extractError(error));
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to add product to cart.');
      }
    } finally {
      if (mounted) {
        setState(() => _addingToCart = false);
      }
    }
  }

  Future<void> _toggleFavorite(String productUuid) async {
    if (_wishlistUpdating) return;

    final notifier = ref.read(wishlistProvider.notifier);
    final wasInWishlist = notifier.contains(productUuid);

    setState(() => _wishlistUpdating = true);

    try {
      final success = wasInWishlist
          ? await notifier.remove(productUuid)
          : await notifier.add(productUuid);

      if (!mounted) return;

      if (success) {
        ref.invalidate(wishlistProvider);

        _showMessage(
          wasInWishlist
              ? 'Removed from wishlist.'
              : 'Added to wishlist.',
          success: true,
        );
      } else {
        _showMessage('Unable to update wishlist.');
      }
    } on DioException catch (error) {
      if (!mounted) return;

      if (error.response?.statusCode == 401) {
        _showMessage('Please login to manage your wishlist.');

        await Future.delayed(
          const Duration(milliseconds: 350),
        );

        if (mounted) context.push('/login');
      } else {
        _showMessage(_extractError(error));
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to update wishlist.');
      }
    } finally {
      if (mounted) {
        setState(() => _wishlistUpdating = false);
      }
    }
  }

  Future<void> _openSupport(String type) async {
    Uri uri;

    switch (type) {
      case 'email':
        uri = Uri(
          scheme: 'mailto',
          path: _supportEmail,
          queryParameters: {
            'subject': 'KwariHub Customer Support',
          },
        );
        break;

      case 'whatsapp':
        final phone = _supportPhone.replaceAll(
          RegExp(r'\D'),
          '',
        );

        // Nigeria country code is needed for WhatsApp.
        final internationalPhone = phone.startsWith('0')
            ? '234${phone.substring(1)}'
            : phone;

        uri = Uri.parse(
          'https://wa.me/$internationalPhone',
        );
        break;

      default:
        final phone = _supportPhone.replaceAll(
          RegExp(r'\D'),
          '',
        );

        uri = Uri(scheme: 'tel', path: phone);
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Unable to open the selected support option.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open the selected support option.');
      }
    }
  }

  String _money(double value) {
    final amount = value.toStringAsFixed(2);
    final parts = amount.split('.');
    final whole = parts[0];
    final formatted = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

    return '₦$formatted.${parts[1]}';
  }

  String _display(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not specified';
    }

    return value.trim();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync =
        ref.watch(productDetailsProvider(widget.productId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: productAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: primaryBlue,
            ),
          ),
          error: (error, stackTrace) => _ProductError(
            message: error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
            onRetry: _refresh,
          ),
          data: (data) {
            final product = data.product;
            final images = data.images;
            final variants = data.variants;

            final wishlistState = ref.watch(wishlistProvider);

            final isInWishlist =
                wishlistState.asData?.value.any(
                      (item) => item.product.uuid == product.uuid,
                    ) ??
                    false;

            final selectedVariant = variants
                .where((variant) => variant.uuid == _selectedVariant)
                .firstOrNull;

            final stock = selectedVariant?.quantity ??
                (variants.isEmpty ? 0 : product.quantity);

            final quantity = stock <= 0
                ? 0
                : _quantity.clamp(1, stock);

            final imageIndex = images.isEmpty
                ? 0
                : _selectedImage.clamp(0, images.length - 1);

            final canAddToCart = stock > 0 &&
                variants.isNotEmpty &&
                selectedVariant != null &&
                !_addingToCart;

            final price =
                selectedVariant?.price ?? product.sellingPrice;

            return RefreshIndicator(
              color: primaryBlue,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Clean, centered product header.
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        6,
                        12,
                        12,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFECECEC),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Go back',
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/products');
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 29,
                              color: Colors.black,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Shopping cart',
                            onPressed: () => context.push('/cart'),
                            icon: const Icon(
                              Icons.shopping_bag_rounded,
                              size: 25,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Large product image and thumbnails.
                  SliverToBoxAdapter(
                    child: _ProductGallery(
                      images: images,
                      selectedIndex: imageIndex,
                      onChanged: (index) {
                        setState(() => _selectedImage = index);
                      },
                    ),
                  ),

                  // Brand, title, stars, price and description.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        22,
                        22,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((product.brand ?? '').trim().isNotEmpty)
                            Text(
                              product.brand!.trim(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 27,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Star icons are visual only until the
                          // backend provides actual rating data.
                          const _RatingStars(),

                          const SizedBox(height: 22),
                          Wrap(
                            crossAxisAlignment:
                                WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Text(
                                _money(price),
                                style: const TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              if (product.hasDiscount)
                                Text(
                                  _money(product.price),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    color: Color(0xFF9CA3AF),
                                    decoration:
                                        TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            product.description.trim().isEmpty
                                ? 'No description is available for this product.'
                                : product.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: _SectionDivider(),
                  ),

                  // Existing backend product information only.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
                      child: _ExpandableSection(
                        title: 'Product information',
                        expanded: false,
                        onToggle: null,
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Brand',
                              value: _display(product.brand),
                            ),
                            _InfoRow(
                              label: 'Origin',
                              value: _display(product.origin),
                            ),
                            _InfoRow(
                              label: 'SKU',
                              value: _display(product.sku),
                            ),
                            _InfoRow(
                              label: 'Unit',
                              value: _display(product.unit),
                              last: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: _SectionDivider(),
                  ),

                  // Variant selection is unchanged.
                  if (variants.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          22,
                          24,
                          22,
                          8,
                        ),
                        child: _VariantSection(
                          variants: variants,
                          selected: _selectedVariant,
                          onSelected: (variant) {
                            if (variant.quantity <= 0) {
                              _showMessage(
                                'This variant is out of stock.',
                              );
                              return;
                            }

                            setState(() {
                              _selectedVariant = variant.uuid;
                              _quantity = 1;
                            });
                          },
                        ),
                      ),
                    )
                  else
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Text(
                          'This product currently has no purchasable variants.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                  // Stock.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        16,
                        22,
                        0,
                      ),
                      child: _StockInformation(
                        quantity: stock,
                        unit: product.unit,
                      ),
                    ),
                  ),

                  // Quantity selector.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        20,
                        22,
                        24,
                      ),
                      child: _QuantitySection(
                        quantity: quantity,
                        available: stock,
                        onMinus: _decreaseQuantity,
                        onPlus: () => _increaseQuantity(stock),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: _SectionDivider(),
                  ),

                  // Shipping information accordion.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                      ),
                      child: _ExpandableSection(
                        title: 'Shipping info',
                        expanded: _shippingExpanded,
                        onToggle: () {
                          setState(() {
                            _shippingExpanded = !_shippingExpanded;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(
                            4,
                            0,
                            4,
                            20,
                          ),
                          child: Text(
                            'Shipping arrangements and delivery times '
                            'depend on the seller and delivery destination. '
                            'Confirm the available delivery details before '
                            'placing your order.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.65,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: _SectionDivider(),
                  ),

                  // Customer support accordion.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                      ),
                      child: _ExpandableSection(
                        title: 'Support',
                        expanded: _supportExpanded,
                        onToggle: () {
                          setState(() {
                            _supportExpanded = !_supportExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            4,
                            0,
                            4,
                            22,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Need help? Contact our customer support '
                                'team for assistance with your order.',
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Color(0xFF555555),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _SupportAction(
                                icon: Icons.email_outlined,
                                title: _supportEmail,
                                onTap: () => _openSupport('email'),
                              ),
                              const SizedBox(height: 16),
                              _SupportAction(
                                icon: Icons.phone_outlined,
                                title: _supportPhone,
                                onTap: () => _openSupport('phone'),
                              ),
                              const SizedBox(height: 16),
                              _SupportAction(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'WhatsApp support',
                                color: const Color(0xFF16A34A),
                                onTap: () => _openSupport('whatsapp'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Leave enough room for the fixed purchase bar.
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 125),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      // Fixed bottom wishlist + add-to-cart bar.
      bottomNavigationBar: productAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (data) {
          final product = data.product;
          final variants = data.variants;

          final selectedVariant = variants
              .where((variant) => variant.uuid == _selectedVariant)
              .firstOrNull;

          final stock = selectedVariant?.quantity ??
              (variants.isEmpty ? 0 : product.quantity);

          final canAdd = stock > 0 &&
              selectedVariant != null &&
              !_addingToCart;

          final wishlistState = ref.watch(wishlistProvider);
          final isFavorite =
              wishlistState.asData?.value.any(
                    (item) => item.product.uuid == product.uuid,
                  ) ??
                  false;

          return SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                18,
                14,
                18,
                12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                border: const Border(
                  top: BorderSide(color: Color(0xFFEAEAEA)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: _wishlistUpdating
                          ? null
                          : () => _toggleFavorite(product.uuid),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.zero,
                        side: const BorderSide(
                          color: Color(0xFFE2E5E9),
                          width: 1.5,
                        ),
                        shape: const CircleBorder(),
                      ),
                      child: _wishlistUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 29,
                              color: isFavorite
                                  ? Colors.red
                                  : Colors.black,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: canAdd
                            ? () => _addToCart(
                                  variantUuid: selectedVariant.uuid,
                                  availableQuantity: stock,
                                )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          disabledBackgroundColor:
                              Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(36),
                          ),
                        ),
                        child: _addingToCart
                            ? const SizedBox(
                                height: 23,
                                width: 23,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      stock <= 0
                                          ? 'OUT OF STOCK'
                                          : selectedVariant == null
                                              ? 'SELECT VARIANT'
                                              : 'ADD TO CART',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
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
}

class _ProductGallery extends StatelessWidget {
  const _ProductGallery({
    required this.images,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<ProductImageModel> images;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasImages = images.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: hasImages
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _FullScreenProductImage(
                        images: images,
                        initialIndex: selectedIndex,
                      ),
                    ),
                  );
                }
              : null,
          child: SizedBox(
            width: double.infinity,
            height: 440,
            child: hasImages
                ? _NetworkProductImage(
                    path: images[selectedIndex].image,
                  )
                : const _ImagePlaceholder(),
          ),
        ),
        if (images.length > 1)
          SizedBox(
            height: 88,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                10,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected = index == selectedIndex;

                return GestureDetector(
                  onTap: () => onChanged(index),
                  child: Container(
                    width: 68,
                    height: 68,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? Colors.black
                            : borderColor,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _NetworkProductImage(
                            path: images[index].image,
                          ),
                          if (selected)
                            Container(
                              color: Colors.black.withValues(
                                alpha: 0.12,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FullScreenProductImage extends StatefulWidget {
  const _FullScreenProductImage({
    required this.images,
    required this.initialIndex,
  });

  final List<ProductImageModel> images;
  final int initialIndex;

  @override
  State<_FullScreenProductImage> createState() =>
      _FullScreenProductImageState();
}

class _FullScreenProductImageState
    extends State<_FullScreenProductImage> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: _NetworkProductImage(
                path: widget.images[index].image,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NetworkProductImage extends StatelessWidget {
  const _NetworkProductImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final url = _resolveImageUrl(path);

    if (url.isEmpty) return const _ImagePlaceholder();

    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return const Center(
          child: CircularProgressIndicator(
            color: primaryBlue,
            strokeWidth: 2.5,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('KwariHub image failed: $url');
        return const _ImagePlaceholder();
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F6F6),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 64,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.star_rounded, color: Colors.black, size: 27),
        Icon(Icons.star_rounded, color: Colors.black, size: 27),
        Icon(Icons.star_rounded, color: Colors.black, size: 27),
        Icon(Icons.star_rounded, color: Colors.black, size: 27),
        Icon(Icons.star_rounded, color: Colors.black, size: 27),
        SizedBox(width: 9),
        Text(
          'Customer ratings',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback? onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (onToggle != null)
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 30,
                    color: Colors.black,
                  ),
              ],
            ),
          ),
        ),
        if (expanded) child,
      ],
    );
  }
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = Colors.black,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 23, color: color),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                decoration: TextDecoration.underline,
                color: Colors.black,
              ),
            ),
          ),
          const Icon(
            Icons.open_in_new_rounded,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 22,
      endIndent: 22,
      color: Color(0xFFE5E7EB),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF777777),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantSection extends StatelessWidget {
  const _VariantSection({
    required this.variants,
    required this.selected,
    required this.onSelected,
  });

  final List<ProductVariantModel> variants;
  final String? selected;
  final ValueChanged<ProductVariantModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Variants',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: variants.map((variant) {
            final isSelected = selected == variant.uuid;
            final available = variant.quantity > 0;

            return InkWell(
              onTap: available ? () => onSelected(variant) : null,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: !available
                      ? Colors.grey.shade100
                      : isSelected
                          ? const Color(0xFFF3F4F6)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.black
                        : borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          variant.color,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: available
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 15,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${variant.size} • ${variant.material}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF777777),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      available
                          ? '${variant.quantity} available'
                          : 'Out of stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: available
                            ? Colors.green.shade700
                            : Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StockInformation extends StatelessWidget {
  const _StockInformation({
    required this.quantity,
    required this.unit,
  });

  final int quantity;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final inStock = quantity > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: inStock
            ? const Color(0xFFF2FBF5)
            : const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: inStock
              ? const Color(0xFFD7EEDF)
              : const Color(0xFFF0D5D5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            inStock
                ? Icons.check_circle_outline_rounded
                : Icons.remove_circle_outline_rounded,
            size: 20,
            color: inStock ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              inStock
                  ? '$quantity $unit available'
                  : 'Currently out of stock',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: inStock ? Colors.green.shade700 : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySection extends StatelessWidget {
  const _QuantitySection({
    required this.quantity,
    required this.available,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final int available;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Quantity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: quantity > 1 ? onMinus : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 25,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: quantity < available ? onPlus : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductError extends StatelessWidget {
  const _ProductError({
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: primaryBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load product',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => onRetry(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
