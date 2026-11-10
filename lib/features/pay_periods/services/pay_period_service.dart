import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pay_period_model.dart';

class PayPeriodService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PayPeriodModel>> getPeriods() async {
    final rows = await _supabase
        .from('pay_periods')
        .select('id, name, start_date, end_date, payment_date, status')
        .order('start_date', ascending: false);
    return (rows as List)
        .map((row) => PayPeriodModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<PayPeriodModel?> getLatestPeriod() async {
    final row = await _supabase
        .from('pay_periods')
        .select('id, name, start_date, end_date, payment_date, status')
        .order('payment_date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return PayPeriodModel.fromJson(row);
  }

  Future<void> createPeriod({
    required String name,
    required DateTime startDate,
    required DateTime paymentDate,
  }) async {
    final start = _dateOnly(startDate);
    final payment = _dateOnly(paymentDate);
    if (payment.isBefore(start)) {
      throw Exception('Tanggal pembayaran tidak boleh sebelum tanggal mulai.');
    }

    await _supabase.from('pay_periods').insert({
      'name': name.trim().isEmpty ? null : name.trim(),
      'start_date': _dateString(start),
      'end_date': _dateString(payment),
      'payment_date': _dateString(payment),
      'status': 'open',
    });
  }

  Future<void> deletePeriod(String id) async {
    final payroll = await _supabase
        .from('payrolls')
        .select('id')
        .eq('pay_period_id', id)
        .limit(1)
        .maybeSingle();
    if (payroll != null) {
      throw Exception('Periode tidak dapat dihapus karena sudah digunakan dalam penggajian.');
    }
    await _supabase.from('pay_periods').delete().eq('id', id);
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
  String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
