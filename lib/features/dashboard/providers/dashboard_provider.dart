
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

final dashboardSummaryProvider =
    FutureProvider<DashboardSummary>((ref) async {
  final service = ref.watch(dashboardServiceProvider);

  return service.getSummary();
});
