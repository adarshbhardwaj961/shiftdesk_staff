import '../models/shift.dart';
import '../models/shift_page.dart';
import '../models/staff_profile.dart';

abstract class ShiftRepository {
  Future<List<StaffProfile>> listStaff();
  Future<void> signInAs(String staffId);
  Future<StaffProfile?> currentStaff();
  Future<ShiftPage> openShifts({String? department, DateTime? from, DateTime? to, String? cursor, int limit = 20});
  Future<List<Shift>> myShifts({required DateTime from, required DateTime to});
  Future<void> claim(String shiftId);
  Future<void> cancel(String shiftId);
  Future<void> signOut();
}
