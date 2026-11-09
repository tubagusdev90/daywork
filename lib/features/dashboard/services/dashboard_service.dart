
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_summary.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<DashboardSummary> getSummary() async {
    try {
      final response = await _supabase.rpc(
        'get_dashboard_summary',
      );

      if (response == null) {
        return const DashboardSummary();
      }

      final data = Map<String, dynamic>.from(response);

      return DashboardSummary.fromJson(data);
    } catch (e) {
      throw Exception('Gagal mengambil data dashboard: $e');
    }
  }
}
