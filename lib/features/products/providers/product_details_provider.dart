
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/product_api.dart';
import '../models/product_image_model.dart' as image_model;
import '../models/product_model.dart' as product_model;
import '../models/product_variant_model.dart';

const String _backendBaseUrl =
    'https://kwarihub-backend-production-ea77.up.railway.app';

final productApiProvider = Provider<ProductApi>((ref) {
  return ProductApi();
});

/// Converts a backend image path into a usable URL.
String? _resolveImageUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  var path = value.trim().replaceAll(r'\', '/');

  final uri = Uri.tryParse(path);

  if (uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty) {
    return path.replaceFirst('/api/v1/storage/', '/storage/');
  }

  final storageIndex = path.indexOf('/storage/');

  if (storageIndex >= 0) {
    path = path.substring(storageIndex + 1);
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

class ProductDetailsData {
  final product_model.ProductModel product;
  final List<image_model.ProductImageModel> images;
  final List<ProductVariantModel> variants;

  const ProductDetailsData({
    required this.product,
    required this.images,
    required this.variants,
  });

  image_model.ProductImageModel? get primaryImage {
    for (final image in images) {
      if (image.isPrimary && _resolveImageUrl(image.image) != null) {
        return image;
      }
    }

    for (final image in images) {
      if (_resolveImageUrl(image.image) != null) {
        return image;
      }
    }

    return null;
  }

  String? get primaryImageUrl {
    final image = primaryImage;
    return image == null ? null : _resolveImageUrl(image.image);
  }
}

List<image_model.ProductImageModel> _prepareImages(
  Iterable<image_model.ProductImageModel> source,
) {
  final validImages = source
      .where((image) => _resolveImageUrl(image.image) != null)
      .toList();

  validImages.sort((a, b) {
    if (a.isPrimary != b.isPrimary) {
      return a.isPrimary ? -1 : 1;
    }

    return a.sortOrder.compareTo(b.sortOrder);
  });

  final seen = <String>{};

  return validImages.where((image) {
    final url = _resolveImageUrl(image.image);
    return url != null && seen.add(url);
  }).toList();
}

final productImagesProvider =
    FutureProvider.autoDispose.family<
        List<image_model.ProductImageModel>, String>(
  (ref, productUuid) async {
    final api = ref.read(productApiProvider);
    final images = await api.getProductImages(productUuid);

    return _prepareImages(images);
  },
);

final productVariantsProvider =
    FutureProvider.autoDispose.family<List<ProductVariantModel>, String>(
  (ref, productUuid) async {
    final api = ref.read(productApiProvider);
    return api.getProductVariants(productUuid);
  },
);

final productDetailsProvider =
    FutureProvider.autoDispose.family<ProductDetailsData, String>(
  (ref, productUuid) async {
    final api = ref.read(productApiProvider);

    final product = await api.getProduct(productUuid);
    final fetchedImages = await api.getProductImages(productUuid);
    final variants = await api.getProductVariants(productUuid);

    final combinedImages =
        <image_model.ProductImageModel>[...fetchedImages];

    // Fall back to the image supplied by the product endpoint.
    final productImage = _resolveImageUrl(product.primaryImage);

    if (productImage != null) {
      final alreadyIncluded = combinedImages.any(
        (image) => _resolveImageUrl(image.image) == productImage,
      );

      if (!alreadyIncluded) {
        combinedImages.add(
          image_model.ProductImageModel(
            id: 0,
            uuid: '',
            productId: product.id,
            image: productImage,
            isPrimary: combinedImages.isEmpty,
            sortOrder: -1,
          ),
        );
      }
    }

    return ProductDetailsData(
      product: product,
      images: _prepareImages(combinedImages),
      variants: variants,
    );
  },
);
