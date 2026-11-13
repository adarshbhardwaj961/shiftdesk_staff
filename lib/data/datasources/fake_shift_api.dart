import 'dart:math';
import '../../core/errors/api_exception.dart';
import '../../domain/models/shift.dart';
import '../../domain/models/shift_page.dart';
import '../../domain/models/staff_profile.dart';
import '../../domain/rules/claim_rules.dart';

class FakeShiftApi {
  FakeShiftApi({this.requestDelay, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _seed();
  }

  final Duration? requestDelay;
  final DateTime Function() _clock;
  final Random _random = Random(42);
  final Map<String, StaffProfile> _staff = {};
  final List<Shift> _shifts = [];
  final Map<String, ({String queryKey, String shiftId})> _issuedCursors = {};
  final Map<String, Set<String>> _claims = {};
  int _nextCursorId = 0;
  String? _activeStaffId;
  bool flakyNetwork = false;
  bool busyHospital = false;

  Future<void> _delay() async {
    await Future.delayed(
      requestDelay ?? Duration(milliseconds: 300 + _random.nextInt(601)),
    );
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
      final slotInDay = i ~/ 90;
      final start = today.add(
        Duration(days: dayOffset, hours: 6, minutes: slotInDay * 15),
      );
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
    _shifts.sort((a, b) {
      final startComparison = a.start.compareTo(b.start);
      return startComparison != 0 ? startComparison : a.id.compareTo(b.id);
    });
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
    String? afterShiftId;
    if (cursor != null) {
      final issuedCursor = _issuedCursors[cursor];
      if (issuedCursor == null || issuedCursor.queryKey != key) {
        throw const ApiException(400, 'Invalid or expired pagination cursor.');
      }
      afterShiftId = issuedCursor.shiftId;
    }
    final filtered = _shifts.where((shift) {
      if (department != null && department.isNotEmpty && shift.department != department) return false;
      if (from != null && shift.end.isBefore(from.toUtc())) return false;
      if (to != null && shift.start.isAfter(to.toUtc())) return false;
      return true;
    }).toList();
    var startIndex = 0;
    if (afterShiftId != null) {
      final anchorIndex = filtered.indexWhere((shift) => shift.id == afterShiftId);
      if (anchorIndex < 0) {
        throw const ApiException(400, 'Invalid or expired pagination cursor.');
      }
      startIndex = anchorIndex + 1;
    }
    final now = _clock().toUtc();
    final available = filtered
        .skip(startIndex)
        .where((shift) =>
            shift.start.isAfter(now) &&
            shift.filled < shift.slots)
        .toList();
    final pageItems = available.take(safeLimit).map((shift) => shift.copy()).toList();
    String? next;
    if (available.length > safeLimit && pageItems.isNotEmpty) {
      next = 'cursor-${_nextCursorId++}';
      _issuedCursors[next] = (queryKey: key, shiftId: pageItems.last.id);
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
    final shift = _shifts[index];
    if (busyHospital && _random.nextInt(3) == 0) {
      shift.filled = shift.slots;
      throw const ApiException(409, 'This shift was just filled. Please choose another shift.');
    }
    final mine = await _myShiftsWithoutDelay();
    final check = checkClaim(staff: staff, shift: shift, myShifts: mine, now: _clock());
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
