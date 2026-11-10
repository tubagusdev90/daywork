import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wage_rate_model.dart';
import '../services/wage_service.dart';

final wageServiceProvider = Provider<WageService>((ref) {
  return WageService();
});

final wageRatesProvider = FutureProvider<List<WageRate>>((ref) async {
  return ref.watch(wageServiceProvider).getWageRates();
});

final workerWageHistoryProvider =
    FutureProvider.family<List<WageRate>, String>((ref, workerId) async {
  return ref.watch(wageServiceProvider).getWorkerHistory(workerId);
});