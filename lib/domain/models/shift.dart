import 'staff_profile.dart';

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
  final StaffRole requiredRole;
  final DateTime start; // UTC in fake API
  final DateTime end;   // UTC in fake API
  final int slots;
  int filled;

  Shift copy() => Shift(
    id: id,
    department: department,
    requiredRole: requiredRole,
    start: start,
    end: end,
    slots: slots,
    filled: filled,
  );
}
