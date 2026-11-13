class Shift {
  Shift({
    required this.id,
    required this.department,
    required this.requiredRole,
    required this.start,
    required this.end,
    required this.slots,
    required this.filled,
  });

  final String id;
  final String department;
  final String requiredRole;
  final DateTime start;
  final DateTime end;
  final int slots;
  int filled;

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
    id: json['id'] as String,
    department: json['department'] as String,
    requiredRole: json['requiredRole'] as String,
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    slots: json['slots'] as int,
    filled: json['filled'] as int,
  );
}
