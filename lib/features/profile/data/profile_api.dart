import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/user_profile.dart';

class ProfileApi {
  ProfileApi({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  // ============================================================
  // GET PROFILE
  // ============================================================

  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get(
        '/users/profile',
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid profile response.',
        );
      }

      return UserProfile.fromJson(data);
    } on DioException {
      rethrow;
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
  }) async {
    try {
      final response = await _dio.put(
        '/users/profile',
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'username': username.trim(),
          'phone': phone.trim(),
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid profile response.',
        );
      }

      return UserProfile.fromJson(data);
    } on DioException {
      rethrow;
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<ProfileMessage> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/users/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid password response.',
        );
      }

      return ProfileMessage.fromJson(data);
    } on DioException {
      rethrow;
    }
  }

  // ============================================================
  // UPLOAD AVATAR
  // ============================================================

  Future<ProfileMessageWithAvatar> uploadAvatar(
    String filePath,
  ) async {
    try {
      final fileName = filePath.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/users/avatar',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid avatar response.',
        );
      }

      return ProfileMessageWithAvatar.fromJson(
        data,
      );
    } on DioException {
      rethrow;
    }
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<ProfileMessage> deleteAccount() async {
    try {
      final response = await _dio.delete(
        '/users/account',
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid account response.',
        );
      }

      return ProfileMessage.fromJson(data);
    } on DioException {
      rethrow;
    }
  }
}

// ================================================================
// MESSAGE
// ================================================================

class ProfileMessage {
  const ProfileMessage({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  factory ProfileMessage.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProfileMessage(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}

// ================================================================
// MESSAGE + AVATAR
// ================================================================

class ProfileMessageWithAvatar {
  const ProfileMessageWithAvatar({
    required this.success,
    required this.message,
    required this.avatarUrl,
  });

  final bool success;
  final String message;
  final String avatarUrl;

  factory ProfileMessageWithAvatar.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProfileMessageWithAvatar(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
    );
  }
}