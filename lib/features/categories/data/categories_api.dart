
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/category_model.dart';

class CategoriesApi {
  CategoriesApi({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<CategoryModel>> getCategories() async {
    try {
      // ApiClient should already configure the backend base URL
      // and /api/v1 prefix, if required by your project.
      final response = await _dio.get('/categories');

      final payload = _extractList(response.data);

      final categories = payload
          .whereType<Map>()
          .map(
            (json) => CategoryModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .where(
            (category) =>
                category.uuid.isNotEmpty &&
                category.name.isNotEmpty &&
                category.isActive,
          )
          .toList();

      return categories;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      if (statusCode == 401) {
        throw Exception(
          'Your session has expired. Please sign in again.',
        );
      }

      if (statusCode == 403) {
        throw Exception(
          'You do not have permission to load categories.',
        );
      }

      if (statusCode == 404) {
        throw Exception(
          'Categories endpoint not found. Verify the FastAPI route '
          'and the base URL configured in ApiClient.',
        );
      }

      if (statusCode != null && statusCode >= 500) {
        throw Exception(
          'The categories server encountered an error. Please try again.',
        );
      }

      if (responseData is Map) {
        final detail = responseData['detail'] ??
            responseData['message'];

        if (detail != null) {
          throw Exception(_errorMessage(detail));
        }
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'The categories request timed out. Please try again.',
        );
      }

      if (error.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to KwariHub. Check the backend URL and network.',
        );
      }

      throw Exception(
        'Unable to load categories. Please try again.',
      );
    } on FormatException catch (error) {
      throw Exception(
        'Invalid categories response: ${error.message}',
      );
    }
  }

  /// Accepts a raw list or common wrapped API responses.
  ///
  /// Examples:
  /// [...]
  /// {"data": [...]}
  /// {"categories": [...]}
  /// {"items": [...]}
  /// {"results": [...]}
  /// {"success": true, "data": [...]}
  List<dynamic> _extractList(dynamic body) {
    dynamic payload = body;

    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      if (payload['success'] == false) {
        throw Exception(
          _errorMessage(
            payload['message'] ??
                payload['detail'] ??
                'The server could not load categories.',
          ),
        );
      }

      // Support common FastAPI response wrappers.
      for (final key in const [
        'data',
        'categories',
        'items',
        'results',
      ]) {
        if (payload.containsKey(key) && payload[key] != null) {
          payload = payload[key];
          break;
        }
      }

      // Some APIs wrap the list inside data.items or data.results.
      if (payload is Map) {
        for (final key in const [
          'categories',
          'items',
          'results',
        ]) {
          if (payload.containsKey(key) && payload[key] != null) {
            payload = payload[key];
            break;
          }
        }
      }
    }

    if (payload is List) {
      return payload;
    }

    throw const FormatException(
      'Expected a list of categories from the API.',
    );
  }

  String _errorMessage(dynamic value) {
    if (value is String) {
      return value;
    }

    if (value is List) {
      return value.map(_errorMessage).join(', ');
    }

    if (value is Map) {
      final message = value['msg'] ??
          value['message'] ??
          value['detail'];

      if (message != null) {
        return _errorMessage(message);
      }
    }

    return value.toString();
  }
}
