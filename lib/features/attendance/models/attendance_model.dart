class AttendanceModel {
  final String id;
  final String workerId;
  final String workerName;
  final DateTime attendanceDate;
  final String status;
  final bool isPaid;
  final String? note;

  const AttendanceModel({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.attendanceDate,
    required this.status,
    required this.isPaid,
    this.note,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    final worker = json['workers'] as Map<String, dynamic>? ?? {};

    final payrollItems =
        json['payroll_items'] as List<dynamic>? ?? [];

    final isPaid = payrollItems.any((item) {
      final payrollItem = item as Map<String, dynamic>;
      final payroll = payrollItem['payrolls'];

      if (payroll is Map<String, dynamic>) {
        return payroll['payment_status'] == 'paid';
      }

      return false;
    });

    return AttendanceModel(
      id: json['id'].toString(),
      workerId: json['worker_id'].toString(),
      workerName: worker['name']?.toString() ?? 'Tanpa nama',
      attendanceDate: DateTime.parse(json['attendance_date']),
      status: json['status']?.toString() ?? 'work',
      isPaid: isPaid,
      note: json['note']?.toString(),
    );
  }
}