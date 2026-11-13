DateTime mondayOf(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day - (local.weekday - 1));
}

DateTime nextMonday(DateTime date) => mondayOf(date).add(const Duration(days: 7));

bool rangesOverlap(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
  return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
}
