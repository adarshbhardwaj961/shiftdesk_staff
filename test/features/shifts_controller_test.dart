import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shiftdesk_staff/core/errors/api_exception.dart';
import 'package:shiftdesk_staff/core/storage/session_storage.dart';
import 'package:shiftdesk_staff/domain/models/shift.dart';
import 'package:shiftdesk_staff/domain/models/shift_page.dart';
import 'package:shiftdesk_staff/domain/models/staff_profile.dart';
import 'package:shiftdesk_staff/domain/repositories/shift_repository.dart';
import 'package:shiftdesk_staff/features/auth/controllers/auth_controller.dart';
import 'package:shiftdesk_staff/features/shifts/controllers/shifts_controller.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
    Get.testMode = false;
  });

  test('deduplicates duplicate shift IDs within and across pages', () async {
    final repository = _FakeShiftRepository()
      ..openResponses.addAll([
        ShiftPage(items: [_shift('one')], nextCursor: 'page-2'),
        ShiftPage(
            items: [_shift('one'), _shift('two'), _shift('two')],
            nextCursor: 'page-3'),
        ShiftPage(items: [_shift('three')], nextCursor: null),
      ]);
    final controller = ShiftsController(repository);

    await controller.loadFirstPage();
    await controller.loadMore();
    await controller.loadMore();

    expect(controller.shifts.map((shift) => shift.id), ['one', 'two', 'three']);
    expect(repository.openRequests.map((request) => request.cursor),
        [null, 'page-2', 'page-3']);
  });

  test('changing department resets pagination and replaces old results',
      () async {
    final repository = _FakeShiftRepository()
      ..openResponses.addAll([
        ShiftPage(items: [_shift('icu')], nextCursor: 'icu-page-2'),
        ShiftPage(items: [_shift('er')], nextCursor: 'er-page-2'),
        ShiftPage(items: [_shift('er-2')], nextCursor: null),
      ]);
    final controller = ShiftsController(repository);

    await controller.loadFirstPage();
    await controller.setDepartment('ER');
    await controller.loadMore();

    expect(controller.shifts.map((shift) => shift.id), ['er', 'er-2']);
    expect(repository.openRequests.map((request) => request.department),
        [null, 'ER', 'ER']);
    expect(repository.openRequests.map((request) => request.cursor),
        [null, null, 'er-page-2']);
  });

  test('changing date range resets pagination and sends the inclusive date window',
      () async {
    final repository = _FakeShiftRepository()
      ..openResponses.addAll([
        ShiftPage(items: [_shift('all-date')], nextCursor: 'all-page-2'),
        ShiftPage(items: [_shift('filtered-date')], nextCursor: 'filtered-page-2'),
        ShiftPage(items: [_shift('filtered-date-2')], nextCursor: null),
      ]);
    final controller = ShiftsController(repository);
    final from = DateTime(2027, 1, 10, 14);
    final to = DateTime(2027, 1, 12, 18);

    await controller.loadFirstPage();
    await controller.setDateRange(from, to);
    await controller.loadMore();

    expect(controller.shifts.map((shift) => shift.id), ['filtered-date', 'filtered-date-2']);
    expect(repository.openRequests.map((request) => request.cursor), [null, null, 'filtered-page-2']);
    expect(repository.openRequests[1].from, DateTime(2027, 1, 10));
    expect(repository.openRequests[1].to, DateTime(2027, 1, 13).subtract(const Duration(microseconds: 1)));
    expect(repository.openRequests[2].from, repository.openRequests[1].from);
    expect(repository.openRequests[2].to, repository.openRequests[1].to);
  });

  test('ignores a stale page response after the department changes', () async {
    final stalePage = Completer<ShiftPage>();
    final repository = _FakeShiftRepository()
      ..openPage = (request) {
        if (request.department == null && request.cursor == null) {
          return Future.value(
            ShiftPage(items: [_shift('old-filter')], nextCursor: 'old-page-2'),
          );
        }
        if (request.cursor != null) return stalePage.future;
        return Future.value(
          ShiftPage(items: [_shift('new-filter')], nextCursor: null),
        );
      };
    final controller = ShiftsController(repository);

    await controller.loadFirstPage();
    final oldPageRequest = controller.loadMore();
    await controller.setDepartment('ER');
    stalePage.complete(
      ShiftPage(items: [_shift('stale')], nextCursor: null),
    );
    await oldPageRequest;

    expect(controller.shifts.map((shift) => shift.id), ['new-filter']);
  });

  test('503 page failure keeps existing rows and retries the same cursor',
      () async {
    final repository = _FakeShiftRepository()
      ..openResponses.addAll([
        ShiftPage(items: [_shift('one')], nextCursor: 'page-2'),
        const ApiException(503, 'Network unavailable.'),
        ShiftPage(items: [_shift('two')], nextCursor: null),
      ]);
    final controller = ShiftsController(repository);

    await controller.loadFirstPage();
    await controller.loadMore();
    expect(controller.shifts.map((shift) => shift.id), ['one']);
    expect(controller.error.value, 'Network unavailable.');
    expect(controller.isLoadMoreError.value, isTrue);

    await controller.retryLoadMore();

    expect(controller.shifts.map((shift) => shift.id), ['one', 'two']);
    expect(controller.error.value, isNull);
    expect(repository.openRequests.map((request) => request.cursor),
        [null, 'page-2', 'page-2']);
  });

  test('failed refresh retains the rows already on screen', () async {
    final repository = _FakeShiftRepository()
      ..openResponses.addAll([
        ShiftPage(items: [_shift('one')], nextCursor: null),
        const ApiException(503, 'Network unavailable.'),
      ]);
    final controller = ShiftsController(repository);

    await controller.loadFirstPage();
    await controller.refresh();

    expect(controller.shifts.map((shift) => shift.id), ['one']);
    expect(controller.error.value, 'Network unavailable.');
    expect(controller.isLoadMoreError.value, isFalse);
  });

  test('my shifts loading exposes retryable API errors', () async {
    final repository = _FakeShiftRepository()
      ..myShiftResponses.addAll([
        const ApiException(503, 'Network unavailable.'),
        [_shift('booked')],
      ]);
    final controller = ShiftsController(repository);

    await controller.loadMyShifts();
    expect(controller.isLoadingMyShifts.value, isFalse);
    expect(controller.myShiftsError.value, 'Network unavailable.');

    await controller.loadMyShifts();
    expect(controller.myShifts.map((shift) => shift.id), ['booked']);
    expect(controller.myShiftsError.value, isNull);
  });

  test('my shifts loading state ends after the request completes', () async {
    final response = Completer<List<Shift>>();
    final repository = _FakeShiftRepository()
      ..myShiftsRequest = () => response.future;
    final controller = ShiftsController(repository);

    final loading = controller.loadMyShifts();
    expect(controller.isLoadingMyShifts.value, isTrue);
    response.complete([_shift('booked')]);
    await loading;

    expect(controller.isLoadingMyShifts.value, isFalse);
    expect(controller.myShifts, hasLength(1));
  });

  testWidgets('409 claim conflict refreshes open and booked shifts',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox.shrink()));
    final shift = _shift('conflict');
    final repository = _FakeShiftRepository()
      ..openResponses.addAll([
        ShiftPage(items: [shift], nextCursor: null),
        const ShiftPage(items: [], nextCursor: null),
      ])
      ..claimError = const ApiException(409, 'This shift was just filled.');
    final controller = ShiftsController(repository);
    final licenceExpiry = DateTime.utc(2028, 12, 31);
    final authController = AuthController(repository, SessionStorage())
      ..staff.value = StaffProfile(
        id: 'nurse',
        name: 'Nurse',
        role: StaffRole.nurse,
        active: true,
        licenceExpiry: licenceExpiry,
      );
    Get.put<AuthController>(authController);

    await controller.loadFirstPage();
    final claimed = await controller.claim(shift);

    expect(claimed, isFalse);
    expect(repository.openRequests, hasLength(2));
    expect(controller.shifts, isEmpty);
    expect(shift.filled, shift.slots);
    expect(controller.isClaiming.value, isFalse);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  test('does not update controller state after disposal during a request',
      () async {
    final response = Completer<ShiftPage>();
    final repository = _FakeShiftRepository()
      ..openPage = (_) => response.future;
    final controller = ShiftsController(repository);

    final load = controller.loadFirstPage();
    controller.onClose();
    response.complete(ShiftPage(items: [_shift('late')], nextCursor: null));
    await load;

    expect(controller.shifts, isEmpty);
  });
}

Shift _shift(String id) {
  final start = DateTime.utc(2027, 1, 10, 8);
  return Shift(
    id: id,
    department: 'ER',
    requiredRole: StaffRole.nurse,
    start: start,
    end: start.add(const Duration(hours: 8)),
    slots: 2,
    filled: 0,
  );
}

class _OpenRequest {
  const _OpenRequest({
    required this.department,
    required this.from,
    required this.to,
    required this.cursor,
  });
  final String? department;
  final DateTime? from;
  final DateTime? to;
  final String? cursor;
}

class _FakeShiftRepository implements ShiftRepository {
  final List<Object> openResponses = [];
  final List<Object> myShiftResponses = [];
  final List<_OpenRequest> openRequests = [];
  Future<ShiftPage> Function(_OpenRequest request)? openPage;
  Future<List<Shift>> Function()? myShiftsRequest;
  Object? claimError;

  @override
  Future<ShiftPage> openShifts({
    String? department,
    DateTime? from,
    DateTime? to,
    String? cursor,
    int limit = 20,
  }) async {
    final request = _OpenRequest(
      department: department,
      from: from,
      to: to,
      cursor: cursor,
    );
    openRequests.add(request);
    if (openPage != null) return openPage!(request);
    final response = openResponses.removeAt(0);
    if (response is Exception) throw response;
    return response as ShiftPage;
  }

  @override
  Future<void> claim(String shiftId) async {
    final error = claimError;
    if (error != null) throw error;
  }

  @override
  Future<void> cancel(String shiftId) async {}

  @override
  Future<StaffProfile?> currentStaff() async => null;

  @override
  Future<List<Shift>> myShifts(
      {required DateTime from, required DateTime to}) async {
    if (myShiftsRequest != null) return myShiftsRequest!();
    if (myShiftResponses.isEmpty) return [];
    final response = myShiftResponses.removeAt(0);
    if (response is Exception) throw response;
    return response as List<Shift>;
  }

  @override
  Future<List<StaffProfile>> listStaff() async => [];

  @override
  Future<void> signInAs(String staffId) async {}

  @override
  Future<void> signOut() async {}
}
