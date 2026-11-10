class WageRate {
  final String id;
  final String workerId;
  final String workerName;
  final double dailyWage;
  final DateTime effectiveDate;
  final String? note;

  const WageRate({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.dailyWage,
    required this.effectiveDate,
    this.note,
  });

  factory WageRate.fromJson(Map<String, dynamic> json) {
    return WageRate(
      id: json['id'].toString(),
      workerId: json['worker_id'].toString(),
      workerName: json['workers']?['name'] ?? '-',
      dailyWage: double.parse(json['daily_wage'].toString()),
      effectiveDate: DateTime.parse(json['effective_date']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worker_id': workerId,
      'daily_wage': dailyWage,
      'effective_date':
          effectiveDate.toIso8601String().split('T').first,
      'note': note,
    };
  }
}