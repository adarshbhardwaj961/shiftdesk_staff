import '../../core/storage/session_storage.dart';
import '../../domain/models/shift.dart';
import '../../domain/models/shift_page.dart';
import '../../domain/models/staff_profile.dart';
import '../../domain/repositories/shift_repository.dart';
import '../datasources/fake_shift_api.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  ShiftRepositoryImpl(this.api, this.storage);
  final FakeShiftApi api;
  final SessionStorage storage;

  @override
  Future<List<StaffProfile>> listStaff() => api.listStaff();

  @override
  Future<void> signInAs(String staffId) async {
    await api.signInAs(staffId);
    await storage.saveStaffId(staffId);
  }

  @override
  Future<StaffProfile?> currentStaff() async {
    try {
      return await api.me();
    } catch (_) {
      final id = await storage.readStaffId();
      if (id == null) return null;
      await api.signInAs(id);
      return api.me();
    }
  }

  @override
  Future<ShiftPage> openShifts({String? department, DateTime? from, DateTime? to, String? cursor, int limit = 20}) =>
      api.openShifts(department: department, from: from, to: to, cursor: cursor, limit: limit);

  @override
  Future<List<Shift>> myShifts({required DateTime from, required DateTime to}) =>
      api.myShifts(from: from, to: to);

  @override
  Future<void> claim(String shiftId) => api.claim(shiftId);

  @override
  Future<void> cancel(String shiftId) => api.cancel(shiftId);

  @override
  Future<void> signOut() async {
    await storage.clear();
  }
}
