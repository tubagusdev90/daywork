
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/attendance_service.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

final attendanceMonthProvider =
    FutureProvider.family<AttendanceMonthData, DateTime>(
  (ref, month) {
    return ref
        .watch(attendanceServiceProvider)
        .getMonthData(month);
  },
);

final activeWorkersForAttendanceProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(attendanceServiceProvider)
      .getActiveWorkers();
});
