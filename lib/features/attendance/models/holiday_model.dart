class HolidayModel {
  final String id;
  final DateTime date;
  final String name;

  const HolidayModel({
    required this.id,
    required this.date,
    required this.name,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'].toString(),
      date: DateTime.parse(json['holiday_date']),
      name: json['name'].toString(),
    );
  }
}