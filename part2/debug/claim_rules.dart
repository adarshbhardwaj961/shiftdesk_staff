// Fixed reference implementation for Part 2.
// Keep the original model imports/adapt names to the supplied repository models.
import '../models/shift.dart';
import '../models/staff.dart';

class ClaimCheck {
  const ClaimCheck.ok() : allowed = true, reason = null;
  const ClaimCheck.no(this.reason) : allowed = false;
  final bool allowed;
  final String? reason;
}

const maxWeeklyHours = 48;

double hoursOf(Shift s) => s.end.difference(s.start).inMinutes / 60.0;

ClaimCheck checkClaim(Staff staff, Shift shift, List<Shift> myShifts) {
  if (staff.role != shift.requiredRole) return const ClaimCheck.no('This shift needs a different role');
  if (!staff.active) return const ClaimCheck.no('Your account is deactivated');
  if (staff.licenceExpiry.isBefore(shift.start)) return const ClaimCheck.no('Your licence is not valid on this shift date');
  if (shift.filled >= shift.slots) return const ClaimCheck.no('This shift is full');
  if (myShifts.any((s) => s.id == shift.id)) return const ClaimCheck.no('You have already claimed this shift');

  for (final s in myShifts) {
    // Half-open intervals: touching endpoints are back-to-back, not overlapping.
    if (s.start.isBefore(shift.end) && shift.start.isBefore(s.end)) {
      return const ClaimCheck.no('You already have a shift at this time');
    }
  }

  final weekStart = DateTime(shift.start.year, shift.start.month, shift.start.day)
      .subtract(Duration(days: shift.start.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));
  var weekHours = 0.0;
  for (final s in [...myShifts, shift]) {
    final start = s.start.isAfter(weekStart) ? s.start : weekStart;
    final end = s.end.isBefore(weekEnd) ? s.end : weekEnd;
    if (end.isAfter(start)) weekHours += end.difference(start).inMinutes / 60.0;
  }
  if (weekHours > maxWeeklyHours) return const ClaimCheck.no('This would take you over 48 hours this week');
  return const ClaimCheck.ok();
}
