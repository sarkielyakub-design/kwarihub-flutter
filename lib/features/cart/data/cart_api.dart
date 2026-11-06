import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/cart_model.dart';

class CartApi {
  CartApi({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  // ============================================================
  // GET CART
  // ============================================================

  Future<CartSummaryModel> getCart() async {
    try {
      final response = await _dio.get('/cart');

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid cart response.');
      }

      return CartSummaryModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        _handleError(
          e,
          fallback: 'Unable to load cart.',
        ),
      );
    }
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  Future<CartItemModel> addToCart({
    required String variantUuid,
    required int quantity,
  }) async {
    try {
      final response = await _dio.post(
        '/cart',
        data: {
          'variant_uuid': variantUuid,
          'quantity': quantity,
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid add to cart response.');
      }

      return CartItemModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        _handleError(
          e,
          fallback: 'Unable to add item to cart.',
        ),
      );
    }
  }

  // ============================================================
  // UPDATE CART
  // ============================================================

  Future<CartItemModel> updateCart({
    required String cartUuid,
    required int quantity,
  }) async {
    try {
      final response = await _dio.patch(
        '/cart/$cartUuid',
        data: {
          'quantity': quantity,
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid cart update response.');
      }

      return CartItemModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        _handleError(
          e,
          fallback: 'Unable to update cart.',
        ),
      );
    }
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================

  Future<void> removeItem(
    String cartUuid,
  ) async {
    try {
      await _dio.delete(
        '/cart/$cartUuid',
      );
    } on DioException catch (e) {
      throw Exception(
        _handleError(
          e,
          fallback: 'Unable to remove item.',
        ),
      );
    }
  }

  // ============================================================
  // CLEAR CART
  // ============================================================

  Future<void> clearCart() async {
    try {
      await _dio.delete('/cart');
    } on DioException catch (e) {
      throw Exception(
        _handleError(
          e,
          fallback: 'Unable to clear cart.',
        ),
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _handleError(
    DioException error, {
    required String fallback,
  }) {
    if (error.response != null) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];

        if (detail is String) {
          return detail;
        }

        if (detail is List &&
            detail.isNotEmpty) {
          return detail.first.toString();
        }

        final message = data['message'];

        if (message is String) {
          return message;
        }
      }

      return '$fallback '
          'Status: ${error.response?.statusCode}';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Please try again.';

      case DioExceptionType.connectionError:
        return 'Unable to connect to KwariHub server.';

      default:
        return fallback;
    }
  }
}