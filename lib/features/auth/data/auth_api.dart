import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../models/auth_response.dart';

class AuthApi {
  AuthApi({
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _dio = dio ?? ApiClient.instance.dio,
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

  // ============================================================
  // REGISTER
  // ============================================================

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/otp/verify',
        data: {
          'email': email,
          'code': code,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(
        Map<String, dynamic>.from(response.data),
      );

      await saveTokens(authResponse);

      return authResponse;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ============================================================
  // SAVE TOKENS
  // ============================================================

  Future<void> saveTokens(AuthResponse auth) async {
    await _storage.write(
      key: 'access_token',
      value: auth.accessToken,
    );

    await _storage.write(
      key: 'refresh_token',
      value: auth.refreshToken,
    );

    await _storage.write(
      key: 'token_type',
      value: auth.tokenType,
    );
  }

  // ============================================================
  // ACCESS TOKEN
  // ============================================================

  Future<String?> getAccessToken() async {
    return _storage.read(
      key: 'access_token',
    );
  }

  // ============================================================
  // REFRESH TOKEN
  // ============================================================

  Future<String?> getRefreshToken() async {
    return _storage.read(
      key: 'refresh_token',
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _storage.delete(
      key: 'access_token',
    );

    await _storage.delete(
      key: 'refresh_token',
    );

    await _storage.delete(
      key: 'token_type',
    );
  }

  // ============================================================
  // CHECK LOGIN
  // ============================================================

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];

        if (detail is String) {
          return detail;
        }

        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;

          if (first is Map<String, dynamic>) {
            return first['msg']?.toString() ??
                'Validation error.';
          }

          return first.toString();
        }

        final message = data['message'];

        if (message is String) {
          return message;
        }
      }

      return 'Request failed (${error.response?.statusCode}).';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Please try again.';

      case DioExceptionType.connectionError:
        return 'Unable to connect to KwariHub server.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}