import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class SecureStorage {
  SecureStorage._();
  static const _storage = FlutterSecureStorage();
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async { await _storage.write(key: accessTokenKey, value: accessToken); await _storage.write(key: refreshTokenKey, value: refreshToken); }
  static Future<String?> accessToken() => _storage.read(key: accessTokenKey);
  static Future<String?> refreshToken() => _storage.read(key: refreshTokenKey);
  static Future<void> clear() => _storage.deleteAll();
}
