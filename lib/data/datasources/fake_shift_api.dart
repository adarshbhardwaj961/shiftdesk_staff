import 'dart:math';
import '../../core/errors/api_exception.dart';
import '../../domain/models/shift.dart';
import '../../domain/models/shift_page.dart';
import '../../domain/models/staff_profile.dart';
import '../../domain/rules/claim_rules.dart';

class FakeShiftApi {
  FakeShiftApi() {
    _seed();
  }

  final Random _random = Random(42);
  final Map<String, StaffProfile> _staff = {};
  final List<Shift> _shifts = [];
  final Map<String, String> _issuedCursors = {};
  final Map<String, Set<String>> _claims = {};
  String? _activeStaffId;
  bool flakyNetwork = false;
  bool busyHospital = false;

  Future<void> _delay() async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(601)));
    if (flakyNetwork && _random.nextInt(5) == 0) {
      throw const ApiException(503, 'Network is temporarily unavailable. Please retry.');
    }
  }

  void _seed() {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    _staff.addAll({
      'staff-doctor': StaffProfile(id: 'staff-doctor', name: 'Alex Morgan', role: StaffRole.doctor, active: true, licenceExpiry: DateTime.utc(now.year + 2, 12, 31)),
      'staff-nurse': StaffProfile(id: 'staff-nurse', name: 'Sam Taylor', role: StaffRole.nurse, active: true, licenceExpiry: DateTime.utc(now.year, now.month + 1, 20)),
      'staff-tech': StaffProfile(id: 'staff-tech', name: 'Jamie Lee', role: StaffRole.technician, active: false, licenceExpiry: DateTime.utc(now.year + 2, 12, 31)),
    });
    const departments = ['ICU', 'ER', 'General Ward', 'Theatre'];
    const roles = StaffRole.values;
    for (var i = 0; i < 5000; i++) {
      final dayOffset = i % 90;
      final hour = 6 + (i * 7) % 16;
      final start = today.add(Duration(days: dayOffset, hours: hour));
      final duration = 4 + (i % 5);
      final slots = 2 + (i % 4);
      _shifts.add(Shift(
        id: 'SHIFT-${(i + 1).toString().padLeft(5, '0')}',
        department: departments[i % departments.length],
        requiredRole: roles[i % roles.length],
        start: start,
        end: start.add(Duration(hours: duration)),
        slots: slots,
        filled: i % (slots + 1),
      ));
    }
    _shifts.sort((a, b) => a.start.compareTo(b.start));
  }

  Future<List<StaffProfile>> listStaff() async {
    await _delay();
    return _staff.values.toList(growable: false);
  }

  Future<void> signInAs(String staffId) async {
    await _delay();
    if (!_staff.containsKey(staffId)) throw const ApiException(404, 'Staff member not found.');
    _activeStaffId = staffId;
  }

  Future<StaffProfile> me() async {
    await _delay();
    final staff = _staff[_activeStaffId];
    if (staff == null) throw const ApiException(401, 'Please choose a staff member.');
    return staff;
  }

  Future<ShiftPage> openShifts({String? department, DateTime? from, DateTime? to, String? cursor, int limit = 20}) async {
    await _delay();
    if (limit < 1) throw const ApiException(400, 'Page size must be greater than zero.');
    final safeLimit = min(limit, 50);
    final key = '${department ?? ''}|${from?.toIso8601String() ?? ''}|${to?.toIso8601String() ?? ''}';
    var offset = 0;
    if (cursor != null) {
      final issuedKey = _issuedCursors[cursor];
      if (issuedKey == null || !issuedKey.startsWith('$key|')) {
        throw const ApiException(400, 'Invalid or expired pagination cursor.');
      }
      offset = int.tryParse(issuedKey.substring(key.length + 1)) ?? 0;
    }
    final filtered = _shifts.where((s) {
      if (s.filled >= s.slots) return false;
      if (department != null && department.isNotEmpty && s.department != department) return false;
      if (from != null && s.end.isBefore(from.toUtc())) return false;
      if (to != null && s.start.isAfter(to.toUtc())) return false;
      return true;
    }).toList();
    final pageItems = filtered.skip(offset).take(safeLimit).map((s) => s.copy()).toList();
    final nextOffset = offset + pageItems.length;
    String? next;
    if (nextOffset < filtered.length) {
      next = 'cursor-${key.hashCode}-$nextOffset';
      _issuedCursors[next] = '$key|$nextOffset';
    }
    return ShiftPage(items: pageItems, nextCursor: next);
  }

  Future<List<Shift>> myShifts({required DateTime from, required DateTime to}) async {
    await _delay();
    final id = _activeStaffId;
    if (id == null) throw const ApiException(401, 'Please choose a staff member.');
    final ids = _claims[id] ?? <String>{};
    return _shifts.where((s) => ids.contains(s.id) && s.start.isBefore(to.toUtc()) && s.end.isAfter(from.toUtc())).map((s) => s.copy()).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<void> claim(String shiftId) async {
    await _delay();
    final staff = _staff[_activeStaffId];
    if (staff == null) throw const ApiException(401, 'Please choose a staff member.');
    final index = _shifts.indexWhere((s) => s.id == shiftId);
    if (index < 0) throw const ApiException(404, 'Shift not found.');
    if (busyHospital && _random.nextInt(3) == 0) {
      throw const ApiException(409, 'This shift was just filled. Please choose another shift.');
    }
    final shift = _shifts[index];
    final mine = await _myShiftsWithoutDelay();
    final check = checkClaim(staff: staff, shift: shift, myShifts: mine);
    if (!check.canClaim) throw ApiException(422, check.reason!);
    shift.filled++;
    (_claims[_activeStaffId!] ??= <String>{}).add(shiftId);
  }

  Future<List<Shift>> _myShiftsWithoutDelay() async {
    final ids = _claims[_activeStaffId] ?? <String>{};
    return _shifts.where((s) => ids.contains(s.id)).map((s) => s.copy()).toList();
  }

  Future<void> cancel(String shiftId) async {
    await _delay();
    final id = _activeStaffId;
    if (id == null) throw const ApiException(401, 'Please choose a staff member.');
    final claims = _claims[id] ?? <String>{};
    if (!claims.remove(shiftId)) throw const ApiException(404, 'Your booking was not found.');
    final index = _shifts.indexWhere((s) => s.id == shiftId);
    if (index >= 0 && _shifts[index].filled > 0) _shifts[index].filled--;
  }

  void setFlakyNetwork(bool value) => flakyNetwork = value;
  void setBusyHospital(bool value) => busyHospital = value;
}
