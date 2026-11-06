import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/wishlist_model.dart';

class WishlistRepository {
  WishlistRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<WishlistItem>> getWishlist() async {
    final response = await _dio.get('/wishlist');

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid wishlist response.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(WishlistItem.fromJson)
        .toList();
  }

  Future<WishlistItem> addToWishlist(
    String productUuid,
  ) async {
    final uuid = productUuid.trim();

    if (uuid.isEmpty) {
      throw Exception('Product UUID is required.');
    }

    final response = await _dio.post(
      '/wishlist/${Uri.encodeComponent(uuid)}',
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid wishlist response.');
    }

    return WishlistItem.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<WishlistMessage> removeFromWishlist(
    String productUuid,
  ) async {
    final uuid = productUuid.trim();

    if (uuid.isEmpty) {
      throw Exception('Product UUID is required.');
    }

    final response = await _dio.delete(
      '/wishlist/${Uri.encodeComponent(uuid)}',
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid wishlist response.');
    }

    return WishlistMessage.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}