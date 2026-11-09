
class DashboardSummary {
  final double paidWages;
  final double unpaidWages;
  final double advancePaid;
  final double advanceUnpaid;
  final int totalWorkers;
  final int todayWorkers;

  const DashboardSummary({
    this.paidWages = 0,
    this.unpaidWages = 0,
    this.advancePaid = 0,
    this.advanceUnpaid = 0,
    this.totalWorkers = 0,
    this.todayWorkers = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return DashboardSummary(
      paidWages: toDouble(json['paid_wages']),
      unpaidWages: toDouble(json['unpaid_wages']),
      advancePaid: toDouble(json['advance_paid']),
      advanceUnpaid: toDouble(json['advance_unpaid']),
      totalWorkers: toInt(json['total_workers']),
      todayWorkers: toInt(json['today_workers']),
    );
  }
}
