
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/product_image_model.dart' as image_model;
import '../models/product_model.dart' as product_model;
import '../models/product_variant_model.dart';

class ProductApi {
  ProductApi({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  // GET SINGLE PRODUCT
  Future<product_model.ProductModel> getProduct(String uuid) async {
    final productUuid = uuid.trim();

    if (productUuid.isEmpty) {
      throw ArgumentError.value(uuid, 'uuid', 'Product UUID is required.');
    }

    try {
      final response = await _dio.get(
        '/products/${Uri.encodeComponent(productUuid)}',
      );

      final payload = _unwrapResponse(response.data);

      if (payload is! Map) {
        throw const FormatException('Invalid product response.');
      }

      return product_model.ProductModel.fromJson(
        Map<String, dynamic>.from(payload),
      );
    } on DioException catch (error) {
      throw Exception(
        _handleError(error, fallback: 'Unable to load product.'),
      );
    }
  }

  // GET PRODUCT IMAGES
  Future<List<image_model.ProductImageModel>> getProductImages(
    String uuid,
  ) async {
    final productUuid = uuid.trim();

    if (productUuid.isEmpty) {
      throw ArgumentError.value(uuid, 'uuid', 'Product UUID is required.');
    }

    try {
      final response = await _dio.get(
        '/products/${Uri.encodeComponent(productUuid)}/images',
      );

      final payload = _unwrapResponse(response.data);

      if (payload is! List) {
        throw const FormatException(
          'Invalid product images response: expected a list.',
        );
      }

      return payload
          .whereType<Map>()
          .map(
            (item) => image_model.ProductImageModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _handleError(error, fallback: 'Unable to load product images.'),
      );
    }
  }

  // GET PRODUCT VARIANTS
  Future<List<ProductVariantModel>> getProductVariants(String uuid) async {
    final productUuid = uuid.trim();

    if (productUuid.isEmpty) {
      throw ArgumentError.value(uuid, 'uuid', 'Product UUID is required.');
    }

    try {
      final response = await _dio.get(
        '/products/${Uri.encodeComponent(productUuid)}/variants',
      );

      final payload = _unwrapResponse(response.data);

      if (payload is! List) {
        throw const FormatException(
          'Invalid product variants response: expected a list.',
        );
      }

      return payload
          .whereType<Map>()
          .map(
            (item) => ProductVariantModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _handleError(error, fallback: 'Unable to load product variants.'),
      );
    }
  }

  // RESPONSE NORMALIZATION
  dynamic _unwrapResponse(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      if (responseData['success'] == false) {
        final message = responseData['message'] ??
            responseData['detail'] ??
            'The server could not complete the request.';

        throw FormatException(_messageFrom(message));
      }

      return responseData['data'];
    }

    return responseData;
  }

  // ERROR HANDLING
  String _handleError(
    DioException error, {
    required String fallback,
  }) {
    final response = error.response;

    if (response != null) {
      final data = response.data;

      if (data is Map) {
        final detail = data['detail'];

        if (detail != null) {
          return _messageFrom(detail);
        }

        final message = data['message'];

        if (message != null) {
          return _messageFrom(message);
        }
      }

      switch (response.statusCode) {
        case 401:
          return 'Your session has expired. Please sign in again.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'The requested product resource was not found.';
        default:
          return '$fallback Status: ${response.statusCode}.';
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to KwariHub. Check your internet connection.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      default:
        return fallback;
    }
  }

  String _messageFrom(dynamic value) {
    if (value is String) {
      return value;
    }

    if (value is List) {
      return value.map(_messageFrom).join(', ');
    }

    if (value is Map) {
      final nested = value['message'] ?? value['msg'] ?? value['detail'];

      if (nested != null) {
        return _messageFrom(nested);
      }
    }

    return value.toString();
  }
}
