import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_api.dart';
import '../models/user_profile.dart';

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(),
);

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier
    extends AsyncNotifier<UserProfile> {
  late final ProfileApi _api;

  @override
  Future<UserProfile> build() async {
    _api = ref.read(profileApiProvider);

    return _api.getProfile();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      _api.getProfile,
    );
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
    final updated = await _api.updateProfile(
      firstName: firstName,
      lastName: lastName,
      username: username,
      phone: phone,
    );

    state = AsyncData(updated);

    return updated;
  }

  // ============================================================
  // UPLOAD AVATAR
  // ============================================================

  Future<String> uploadAvatar(
    String filePath,
  ) async {
    final result = await _api.uploadAvatar(
      filePath,
    );

    if (!result.success) {
      throw Exception(result.message);
    }

    await refresh();

    return result.avatarUrl;
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (!result.success) {
      throw Exception(result.message);
    }

    return result.message;
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<String> deleteAccount() async {
    final result = await _api.deleteAccount();

    if (!result.success) {
      throw Exception(result.message);
    }

    return result.message;
  }

  // ============================================================
  // ERROR HELPER
  // ============================================================

  String errorMessage(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;

      if (responseData is Map<String, dynamic>) {
        final detail = responseData['detail'];

        if (detail is String &&
            detail.trim().isNotEmpty) {
          return detail;
        }

        final message = responseData['message'];

        if (message is String &&
            message.trim().isNotEmpty) {
          return message;
        }
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

    return error.toString().replaceFirst(
          'Exception: ',
          '',
        );
  }
}