import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/dashboard_model.dart';
import '../../../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(),
);

final dashboardProvider =
    FutureProvider.autoDispose<DashboardModel>((ref) async {
  final service = ref.read(dashboardServiceProvider);

  return service.getDashboard();
});