import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/checkout_response.dart';

class CheckoutApi {
  CheckoutApi({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  // ============================================================
  // CHECKOUT
  // ============================================================

  Future<CheckoutResponseModel> checkout({
    required String shippingAddress,
    required String redirectUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/orders/checkout',
        data: {
          'shipping_address': shippingAddress,
          'redirect_url': redirectUrl,
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid checkout response.',
        );
      }

      return CheckoutResponseModel.fromJson(
        data,
      );
    } on DioException catch (e) {
      throw Exception(
        _handleError(
          e,
          fallback: 'Unable to process checkout.',
        ),
      );
    }
  }

  // ============================================================
  // ERROR HANDLING
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