import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/categories_api.dart';
import '../models/category_model.dart';

final categoriesApiProvider = Provider<CategoriesApi>((ref) {
  return CategoriesApi();
});

final categoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final api = ref.read(categoriesApiProvider);
  final categories = await api.getCategories();

  final availableCategories = categories
      .where(
        (category) =>
            category.isActive &&
            category.uuid.isNotEmpty &&
            category.name.isNotEmpty,
      )
      .toList();

  availableCategories.sort((a, b) {
    return a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        );
  });

  return availableCategories;
});