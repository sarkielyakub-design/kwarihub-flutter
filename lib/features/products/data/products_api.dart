import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductsApi {
  ProductsApi({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  // ============================================================
  // GET ALL PRODUCTS
  // ============================================================

  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _dio.get(
        '/products',
      );

      final data = response.data;

      if (data is! List) {
        throw Exception(
          'Invalid products response.',
        );
      }

      return data
          .map(
            (item) => ProductModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _handleError(e),
      );
    }
  }

  // ============================================================
  // GET PRODUCT
  // ============================================================

  Future<ProductModel> getProduct(
    String uuid,
  ) async {
    try {
      final response = await _dio.get(
        '/products/$uuid',
      );

      if (response.data
          is! Map<String, dynamic>) {
        throw Exception(
          'Invalid product response.',
        );
      }

      return ProductModel.fromJson(
        Map<String, dynamic>.from(
          response.data,
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _handleError(e),
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _handleError(
    DioException error,
  ) {
    final response = error.response;

    if (response != null) {
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];

        if (detail != null) {
          return detail.toString();
        }

        final message = data['message'];

        if (message != null) {
          return message.toString();
        }
      }

      return 'Request failed (${response.statusCode}).';
    }

    if (error.type ==
            DioExceptionType.connectionError ||
        error.type ==
            DioExceptionType.connectionTimeout) {
      return 'Unable to connect to KwariHub server.';
    }

    return 'Something went wrong. Please try again.';
  }
}