import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wishlist_repository.dart';
import '../models/wishlist_model.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepository(),
);

final wishlistProvider =
    AsyncNotifierProvider<WishlistNotifier, List<WishlistItem>>(
  WishlistNotifier.new,
);

class WishlistNotifier extends AsyncNotifier<List<WishlistItem>> {
  late final WishlistRepository _repository;

  @override
  Future<List<WishlistItem>> build() async {
    _repository = ref.read(wishlistRepositoryProvider);

    return _repository.getWishlist();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      _repository.getWishlist,
    );
  }

  bool contains(String productUuid) {
    final uuid = productUuid.trim();

    final items = state.asData?.value ?? <WishlistItem>[];

    return items.any(
      (item) => item.product.uuid == uuid,
    );
  }

  Future<bool> add(String productUuid) async {
    final uuid = productUuid.trim();

    if (uuid.isEmpty) {
      return false;
    }

    try {
      final item = await _repository.addToWishlist(uuid);

      final current =
          state.asData?.value ?? <WishlistItem>[];

      final exists = current.any(
        (wishlistItem) =>
            wishlistItem.product.uuid == uuid,
      );

      if (!exists) {
        state = AsyncData([
          item,
          ...current,
        ]);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(String productUuid) async {
    final uuid = productUuid.trim();

    if (uuid.isEmpty) {
      return false;
    }

    final previous =
        state.asData?.value ?? <WishlistItem>[];

    state = AsyncData(
      previous
          .where(
            (item) =>
                item.product.uuid != uuid,
          )
          .toList(),
    );

    try {
      await _repository.removeFromWishlist(uuid);

      return true;
    } catch (_) {
      state = AsyncData(previous);

      return false;
    }
  }

  Future<bool> toggle(String productUuid) async {
    if (contains(productUuid)) {
      return remove(productUuid);
    }

    return add(productUuid);
  }
}