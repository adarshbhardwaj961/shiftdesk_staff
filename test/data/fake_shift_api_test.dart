import 'package:flutter_test/flutter_test.dart';
import 'package:shiftdesk_staff/data/datasources/fake_shift_api.dart';

void main() {
  test('seeded open shifts do not share the same start time', () async {
    final api = FakeShiftApi();
    final page = await api.openShifts(limit: 50);

    expect(page.items.map((shift) => shift.start).toSet(),
        hasLength(page.items.length));
  });
}
