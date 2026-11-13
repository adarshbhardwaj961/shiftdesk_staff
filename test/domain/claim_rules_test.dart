import 'package:flutter_test/flutter_test.dart';
import 'package:shiftdesk_staff/domain/models/shift.dart';
import 'package:shiftdesk_staff/domain/models/staff_profile.dart';
import 'package:shiftdesk_staff/domain/rules/claim_rules.dart';

void main() {
  final nurse = StaffProfile(
    id: 'n1', name: 'Nurse', role: StaffRole.nurse, active: true,
    licenceExpiry: DateTime.utc(2027, 12, 31),
  );
  Shift makeShift({String id = 's1', int filled = 0, int slots = 2, int startHour = 8, int duration = 8}) {
    final start = DateTime.utc(2026, 11, 16, startHour);
    return Shift(id: id, department: 'ICU', requiredRole: StaffRole.nurse,
      start: start, end: start.add(Duration(hours: duration)), slots: slots, filled: filled);
  }

  test('allows matching active licensed staff with a free slot', () {
    expect(checkClaim(staff: nurse, shift: makeShift(), myShifts: []).canClaim, isTrue);
  });
  test('rejects role mismatch', () {
    expect(checkClaim(staff: nurse, shift: Shift(id: 's', department: 'ER', requiredRole: StaffRole.doctor,
      start: DateTime.utc(2026, 11, 16, 8), end: DateTime.utc(2026, 11, 16, 12), slots: 1, filled: 0), myShifts: []).reason,
      'This shift needs a different role.');
  });
  test('rejects inactive staff', () {
    final inactive = StaffProfile(id: 'x', name: 'X', role: StaffRole.nurse, active: false, licenceExpiry: DateTime.utc(2027));
    expect(checkClaim(staff: inactive, shift: makeShift(), myShifts: []).canClaim, isFalse);
  });
  test('rejects full shift', () {
    expect(checkClaim(staff: nurse, shift: makeShift(filled: 2), myShifts: []).canClaim, isFalse);
  });
  test('rejects a shift that has already started', () {
    final shift = makeShift();
    expect(
      checkClaim(
        staff: nurse,
        shift: shift,
        myShifts: [],
        now: shift.start.add(const Duration(seconds: 1)),
      ).reason,
      'This shift has already started.',
    );
  });
  test('rejects overlapping booking but allows back-to-back', () {
    final booked = makeShift(id: 'old', startHour: 8, duration: 4);
    final backToBack = makeShift(id: 'new', startHour: 12, duration: 4);
    expect(checkClaim(staff: nurse, shift: backToBack, myShifts: [booked]).canClaim, isTrue);
    final overlapping = makeShift(id: 'new2', startHour: 11, duration: 4);
    expect(checkClaim(staff: nurse, shift: overlapping, myShifts: [booked]).canClaim, isFalse);
  });
  test('rejects duplicate booking', () {
    final shift = makeShift();
    expect(checkClaim(staff: nurse, shift: shift, myShifts: [shift]).canClaim, isFalse);
  });
  test('rejects more than 48 weekly hours', () {
    final existing = makeShift(id: 'old', startHour: 0, duration: 44);
    final candidate = makeShift(id: 'new', startHour: 20, duration: 8);
    expect(checkClaim(staff: nurse, shift: candidate, myShifts: [existing]).canClaim, isFalse);
  });
}
