class Worker {
  final String id;
  final String name;
  final String position;
  final String? whatsapp;
  final String? photoUrl;
  final DateTime joinDate;
  final bool isActive;

  const Worker({
    required this.id,
    required this.name,
    required this.position,
    this.whatsapp,
    this.photoUrl,
    required this.joinDate,
    required this.isActive,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      position: json['position'] ?? 'petukang',
      whatsapp: json['whatsapp'],
      photoUrl: json['photo_url'],
      joinDate: DateTime.parse(json['join_date']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'position': position,
      'whatsapp': whatsapp,
      'photo_url': photoUrl,
      'join_date': joinDate.toIso8601String().split('T').first,
      'is_active': isActive,
    };
  }
}