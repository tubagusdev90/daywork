import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance_model.dart';

class AttendanceMonthData {
  final List<AttendanceModel> attendances;
  final List<DateTime> paymentDates;

  const AttendanceMonthData({
    required this.attendances,
    required this.paymentDates,
  });
}

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AttendanceMonthData> getMonthData(DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final start = _dateString(firstDay);
    final end = _dateString(lastDay);

    try {
      final attendanceResponse = await _supabase
          .from('attendances')
          .select('''
            id,
            worker_id,
            attendance_date,
            status,
            note,
            workers(name),
            payroll_items(
              payrolls(payment_status)
            )
          ''')
          .gte('attendance_date', start)
          .lte('attendance_date', end)
          .order('attendance_date');

      final periodResponse = await _supabase
          .from('payment_periods')
          .select('payment_date')
          .gte('payment_date', start)
          .lte('payment_date', end);

      return AttendanceMonthData(
        attendances: (attendanceResponse as List)
            .map(
              (item) => AttendanceModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
        paymentDates: (periodResponse as List)
            .map(
              (item) => DateTime.parse(
                item['payment_date'].toString(),
              ),
            )
            .toList(),
      );
    } on PostgrestException catch (error) {
      throw Exception(
        'Gagal memuat absensi: ${error.message}'
        '${error.code != null ? ' (Kode: ${error.code})' : ''}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getActiveWorkers() async {
    try {
      final response = await _supabase
          .from('workers')
          .select('id, name, position')
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(
        'Gagal memuat pekerja: ${error.message}'
        '${error.code != null ? ' (Kode: ${error.code})' : ''}',
      );
    }
  }

 Future<void> saveAttendance({
  required String workerId,
  required DateTime date,
  required String status,
  String? note,
}) async {
  if (status != 'work' && status != 'absent') {
    throw Exception('Status absensi tidak valid: $status');
  }

  final data = {
    'worker_id': workerId,
    'attendance_date': _dateString(date),
    'status': status,
    'note': (note == null || note.trim().isEmpty)
        ? null
        : note.trim(),
  };

  print('========== DEBUG ABSENSI ==========');
  print('DATA: $data');

  try {
    await _supabase.from('attendances').upsert(
      data,
      onConflict: 'worker_id,attendance_date',
    );

    print('ABSENSI BERHASIL DISIMPAN');
  } on PostgrestException catch (error) {
    print('========== SUPABASE ERROR ==========');
    print('MESSAGE: ${error.message}');
    print('CODE: ${error.code}');
    print('DETAILS: ${error.details}');
    print('HINT: ${error.hint}');
    print('====================================');

    throw Exception(
      'Gagal menyimpan absensi: ${error.message}; '
      'kode: ${error.code}; '
      'detail: ${error.details}; '
      'hint: ${error.hint}',
    );
  } catch (error) {
    print('ERROR LAINNYA: $error');
    rethrow;
  }
}
  Future<void> deleteAttendance(String id) async {
    try {
      await _supabase.from('attendances').delete().eq('id', id);
    } on PostgrestException catch (error) {
      throw Exception(
        'Gagal menghapus absensi: ${error.message}'
        '${error.code != null ? ' (Kode: ${error.code})' : ''}',
      );
    }
  }

  String _dateString(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
