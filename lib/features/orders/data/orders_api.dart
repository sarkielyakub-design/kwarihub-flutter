import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrdersApi {
  OrdersApi({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<OrderModel>> getOrders() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/orders');

      final dynamic payload = _extractList(response.data);

      if (payload is! List) {
        throw Exception(
          'The orders API returned an unexpected response format.',
        );
      }

      // Explicitly return List<OrderModel>, not List<dynamic>.
      return payload
          .map<OrderModel>((dynamic item) {
            if (item is! Map) {
              throw const FormatException(
                'An order in the API response is not a JSON object.',
              );
            }

            return OrderModel.fromJson(Map<String, dynamic>.from(item));
          })
          .toList(growable: false);
    } on DioException catch (error) {
      final int? statusCode = error.response?.statusCode;
      final dynamic responseData = error.response?.data;

      if (statusCode == 401) {
        throw Exception('Your session has expired. Please sign in again.');
      }

      if (statusCode == 403) {
        throw Exception('You do not have permission to view these orders.');
      }

      if (statusCode == 404) {
        throw Exception(
          'The orders endpoint was not found. Check GET /api/v1/orders.',
        );
      }

      if (statusCode != null && statusCode >= 500) {
        throw Exception(
          'The orders server encountered an error. Please try again.',
        );
      }

      if (responseData is Map) {
        final dynamic detail =
            responseData['detail'] ?? responseData['message'];

        if (detail != null) {
          throw Exception(detail.toString());
        }
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'The request timed out. Check your connection and try again.',
        );
      }

      if (error.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to KwariHub. Check the backend URL and network.',
        );
      }

      throw Exception('Unable to load orders. Please try again.');
    } on FormatException catch (error) {
      throw Exception('Invalid orders response: ${error.message}');
    }
  }

  dynamic _extractList(dynamic body) {
    dynamic payload = body;

    for (int depth = 0; depth < 5; depth++) {
      if (payload is List) {
        return payload;
      }

      if (payload is! Map) {
        return null;
      }

      if (payload['success'] == false) {
        throw Exception(
          (payload['message'] ??
                  payload['detail'] ??
                  'The server could not load orders.')
              .toString(),
        );
      }

      // Support common FastAPI response wrappers.
      if (payload.containsKey('data')) {
        payload = payload['data'];
      } else if (payload.containsKey('orders')) {
        payload = payload['orders'];
      } else if (payload.containsKey('items')) {
        payload = payload['items'];
      } else if (payload.containsKey('results')) {
        payload = payload['results'];
      } else {
        return null;
      }
    }

    return payload is List ? payload : null;
  }
}
