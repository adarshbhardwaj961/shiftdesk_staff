import '../models/claim_check.dart';
import '../models/shift.dart';
import '../models/staff_profile.dart';
import '../../core/utils/date_utils.dart';

const int maxWeeklyHours = 48;

double hoursOf(Shift shift) => shift.end.difference(shift.start).inMinutes / 60.0;

/// Pure Dart business rules. Used by both detail UI and the fake API.
ClaimCheck checkClaim({
  required StaffProfile staff,
  required Shift shift,
  required List<Shift> myShifts,
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();

  if (staff.role != shift.requiredRole) {
    return const ClaimCheck.denied('This shift needs a different role.');
  }
  if (!staff.active) {
    return const ClaimCheck.denied('Your account is deactivated.');
  }
  if (staff.licenceExpiry.isBefore(shift.start.toLocal())) {
    return const ClaimCheck.denied('Your licence is not valid on this shift date.');
  }
  if (shift.filled >= shift.slots) {
    return const ClaimCheck.denied('This shift is already full.');
  }
  if (myShifts.any((item) => item.id == shift.id)) {
    return const ClaimCheck.denied('You have already claimed this shift.');
  }
  for (final booked in myShifts) {
    if (rangesOverlap(booked.start, booked.end, shift.start, shift.end)) {
      return const ClaimCheck.denied('You already have a shift at this time.');
    }
  }

  final weekStart = mondayOf(shift.start);
  final weekEnd = nextMonday(weekStart);
  var weeklyHours = 0.0;
  for (final booked in myShifts) {
    // Count the portion of each booking that falls within this Monday-Sunday week.
    final overlapStart = booked.start.isAfter(weekStart.toUtc()) ? booked.start : weekStart.toUtc();
    final overlapEnd = booked.end.isBefore(weekEnd.toUtc()) ? booked.end : weekEnd.toUtc();
    if (overlapEnd.isAfter(overlapStart)) {
      weeklyHours += overlapEnd.difference(overlapStart).inMinutes / 60.0;
    }
  }
  final newStart = shift.start.isAfter(weekStart.toUtc()) ? shift.start : weekStart.toUtc();
  final newEnd = shift.end.isBefore(weekEnd.toUtc()) ? shift.end : weekEnd.toUtc();
  if (newEnd.isAfter(newStart)) {
    weeklyHours += newEnd.difference(newStart).inMinutes / 60.0;
  }
  if (weeklyHours > maxWeeklyHours) {
    return const ClaimCheck.denied('This would take you over 48 hours in this week.');
  }
  return const ClaimCheck.allowed();
}
