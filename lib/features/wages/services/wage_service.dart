import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wage_rate_model.dart';

class WageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<WageRate>> getWageRates() async {
    final response = await _supabase
        .from('wage_rates')
        .select('*, workers(name)')
        .order('effective_date', ascending: false);

    return (response as List)
        .map((item) => WageRate.fromJson(item))
        .toList();
  }

  Future<List<WageRate>> getWorkerHistory(
    String workerId,
  ) async {
    final response = await _supabase
        .from('wage_rates')
        .select('*, workers(name)')
        .eq('worker_id', workerId)
        .order('effective_date', ascending: false);

    return (response as List)
        .map((item) => WageRate.fromJson(item))
        .toList();
  }

  Future<void> addWageRate(WageRate wageRate) async {
    await _supabase
        .from('wage_rates')
        .insert(wageRate.toJson());
  }

  Future<void> deleteWageRate(String id) async {
    await _supabase
        .from('wage_rates')
        .delete()
        .eq('id', id);
  }
}