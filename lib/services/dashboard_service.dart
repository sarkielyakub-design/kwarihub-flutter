import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  DashboardService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<DashboardModel> getDashboard() async {
    try {
      final response = await _apiClient.dio.get(
        '/dashboard',
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid dashboard response.',
        );
      }

      return DashboardModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;

        if (data is Map<String, dynamic>) {
          final detail = data['detail'];

          if (detail != null) {
            throw Exception(detail.toString());
          }
        }

        throw Exception(
          'Unable to load dashboard. '
          'Status code: ${e.response?.statusCode}',
        );
      }

      throw Exception(
        'Unable to connect to KwariHub server.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}