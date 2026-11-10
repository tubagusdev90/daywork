class PayPeriodModel {
  final String id;
  final String? name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime paymentDate;
  final String status;

  const PayPeriodModel({
    required this.id,
    this.name,
    required this.startDate,
    required this.endDate,
    required this.paymentDate,
    required this.status,
  });

  factory PayPeriodModel.fromJson(Map<String, dynamic> json) {
    return PayPeriodModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      status: (json['status'] as String?) ?? 'open',
    );
  }

  String get displayName => name?.trim().isNotEmpty == true
      ? name!.trim()
      : 'Periode ${_date(startDate)} - ${_date(endDate)}';

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
