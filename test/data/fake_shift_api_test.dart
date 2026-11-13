import 'package:flutter_test/flutter_test.dart';
import 'package:shiftdesk_staff/core/errors/api_exception.dart';
import 'package:shiftdesk_staff/data/datasources/fake_shift_api.dart';
import 'package:shiftdesk_staff/domain/models/staff_profile.dart';

void main() {
  test('seeded open shifts do not share the same start time', () async {
    final api = FakeShiftApi(requestDelay: Duration.zero);
    final page = await api.openShifts(limit: 50);

    expect(page.items.map((shift) => shift.start).toSet(),
        hasLength(page.items.length));
  });

  test('cursor pagination returns each available shift once', () async {
    final api = FakeShiftApi(requestDelay: Duration.zero);
    final ids = <String>{};
    String? cursor;
    do {
      final page = await api.openShifts(cursor: cursor, limit: 37);
      for (final shift in page.items) {
        expect(ids.add(shift.id), isTrue);
      }
      cursor = page.nextCursor;
    } while (cursor != null);

    expect(ids.length, greaterThan(100));
  });

  test('cursor remains stable when a delivered shift is claimed', () async {
    final api = FakeShiftApi(requestDelay: Duration.zero);
    final firstPage = await api.openShifts(limit: 10);
    final claimable = firstPage.items.firstWhere(
      (shift) =>
          shift.requiredRole == StaffRole.doctor ||
          shift.requiredRole == StaffRole.nurse,
    );
    final staffId = claimable.requiredRole == StaffRole.doctor
        ? 'staff-doctor'
        : 'staff-nurse';
    await api.signInAs(staffId);
    final expectedNextPage =
        await api.openShifts(cursor: firstPage.nextCursor, limit: 10);

    await api.claim(claimable.id);
    final actualNextPage =
        await api.openShifts(cursor: firstPage.nextCursor, limit: 10);

    expect(
      actualNextPage.items.map((shift) => shift.id),
      expectedNextPage.items.map((shift) => shift.id),
    );
  });

  test('rejects a pagination cursor created for another filter', () async {
    final api = FakeShiftApi(requestDelay: Duration.zero);
    final page = await api.openShifts(limit: 1);

    expect(
      api.openShifts(department: 'ER', cursor: page.nextCursor, limit: 1),
      throwsA(isA<ApiException>()
          .having((error) => error.statusCode, 'statusCode', 400)),
    );
  });

  test('fake API enforces the shared claim rules', () async {
    final api = FakeShiftApi(requestDelay: Duration.zero);
    await api.signInAs('staff-nurse');

    await expectLater(
      api.claim('SHIFT-00003'),
      throwsA(isA<ApiException>()
          .having((error) => error.statusCode, 'statusCode', 422)
          .having((error) => error.message, 'message',
              'This shift needs a different role.')),
    );

    await api.signInAs('staff-tech');
    await expectLater(
      api.claim('SHIFT-00003'),
      throwsA(isA<ApiException>()
          .having((error) => error.statusCode, 'statusCode', 422)
          .having((error) => error.message, 'message',
              'Your account is deactivated.')),
    );
  });

  test('fake API rejects expired licences and full shifts', () async {
    final api = FakeShiftApi(requestDelay: Duration.zero);
    await api.signInAs('staff-nurse');

    await expectLater(
      api.claim('SHIFT-00152'),
      throwsA(isA<ApiException>()
          .having((error) => error.statusCode, 'statusCode', 422)
          .having((error) => error.message, 'message',
              'Your licence is not valid on this shift date.')),
    );

    await api.signInAs('staff-doctor');
    await expectLater(
      api.claim('SHIFT-00055'),
      throwsA(isA<ApiException>()
          .having((error) => error.statusCode, 'statusCode', 422)
          .having((error) => error.message, 'message',
              'This shift is already full.')),
    );
  });

  test('fake API rejects duplicate and overlapping bookings', () async {
    final api = FakeShiftApi(requestDelay: Duration.zero);
    await api.signInAs('staff-doctor');
    await api.claim('SHIFT-00004');

    await expectLater(
      api.claim('SHIFT-00004'),
      throwsA(isA<ApiException>()
          .having((error) => error.statusCode, 'statusCode', 422)
          .having((error) => error.message, 'message',
              'You have already claimed this shift.')),
    );
    await expectLater(
      api.claim('SHIFT-00094'),
      throwsA(isA<ApiException>()
          .having((error) => error.statusCode, 'statusCode', 422)
          .having((error) => error.message, 'message',
              'You already have a shift at this time.')),
    );
  });

  test('fake API rejects a claim before the shift start time', () async {
    final api = FakeShiftApi(
      requestDelay: Duration.zero,
      clock: () => DateTime.now().add(const Duration(days: 1)),
    );
    await api.signInAs('staff-nurse');

    await expectLater(
      api.claim('SHIFT-00001'),
      throwsA(isA<ApiException>()
          .having((error) => error.statusCode, 'statusCode', 422)
          .having((error) => error.message, 'message',
              'This shift has already started.')),
    );
  });
}
