import '../models/shift.dart';

class ShiftPage {
  const ShiftPage({required this.items, required this.nextCursor});
  final List<Shift> items;
  final String? nextCursor;
}

abstract class ShiftRepository {
  Future<ShiftPage> openShifts({
    required String department,
    String? cursor,
    int limit = 20,
  });
  Future<void> claim(String shiftId);
}
