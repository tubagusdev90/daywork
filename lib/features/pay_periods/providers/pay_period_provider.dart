import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pay_period_model.dart';
import '../services/pay_period_service.dart';

final payPeriodServiceProvider = Provider<PayPeriodService>((ref) {
  return PayPeriodService();
});

final payPeriodsProvider = FutureProvider<List<PayPeriodModel>>((ref) {
  return ref.watch(payPeriodServiceProvider).getPeriods();
});

final latestPayPeriodProvider = FutureProvider<PayPeriodModel?>((ref) {
  return ref.watch(payPeriodServiceProvider).getLatestPeriod();
});
