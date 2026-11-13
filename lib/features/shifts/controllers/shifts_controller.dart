import 'package:get/get.dart';
import '../../../core/errors/api_exception.dart';
import '../../../domain/models/claim_check.dart';
import '../../../domain/models/shift.dart';
import '../../../domain/models/shift_page.dart';
import '../../../domain/rules/claim_rules.dart';
import '../../../domain/repositories/shift_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class ShiftsController extends GetxController {
  ShiftsController(this.repository);
  final ShiftRepository repository;
  final shifts = <Shift>[].obs;
  final myShifts = <Shift>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isLoadingMyShifts = false.obs;
  final isClaiming = false.obs;
  final error = RxnString();
  final myShiftsError = RxnString();
  final isLoadMoreError = false.obs;
  final department = ''.obs;
  final filterFrom = Rxn<DateTime>();
  final filterTo = Rxn<DateTime>();
  String? _cursor;
  bool _hasMore = true;
  int _requestVersion = 0;
  int _myShiftsRequestVersion = 0;
  final Set<String> _loadedShiftIds = {};
  bool _disposed = false;

  List<String> get departments => const ['ICU', 'ER', 'General Ward', 'Theatre'];

  Future<void> loadFirstPage({bool clearExisting = false}) async {
    if (_disposed) return;
    final version = ++_requestVersion;
    isLoading.value = true;
    isLoadingMore.value = false;
    error.value = null;
    isLoadMoreError.value = false;
    _cursor = null;
    _hasMore = true;
    if (clearExisting) {
      shifts.clear();
      _loadedShiftIds.clear();
    }
    try {
      final page = await repository.openShifts(
        department: department.value.isEmpty ? null : department.value,
        from: filterFrom.value,
        to: _inclusiveFilterEnd(filterTo.value),
        limit: 20,
      );
      if (!_isCurrentRequest(version)) return;
      _replaceUnique(page);
    } catch (e) {
      if (_isCurrentRequest(version)) error.value = _message(e);
    } finally {
      if (_isCurrentRequest(version)) isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_disposed || isLoading.value || isLoadingMore.value || !_hasMore || error.value != null) return;
    final version = _requestVersion;
    final cursor = _cursor;
    if (cursor == null) return;
    isLoadingMore.value = true;
    isLoadMoreError.value = false;
    try {
      final page = await repository.openShifts(
        department: department.value.isEmpty ? null : department.value,
        from: filterFrom.value,
        to: _inclusiveFilterEnd(filterTo.value),
        cursor: cursor,
        limit: 20,
      );
      if (!_isCurrentRequest(version)) return;
      _appendUnique(page);
    } catch (e) {
      if (_isCurrentRequest(version)) {
        error.value = _message(e);
        isLoadMoreError.value = true;
      }
    } finally {
      if (_isCurrentRequest(version)) isLoadingMore.value = false;
    }
  }

  Future<void> retryLoadMore() async {
    if (_disposed || !isLoadMoreError.value) return;
    error.value = null;
    isLoadMoreError.value = false;
    await loadMore();
  }

  void _replaceUnique(ShiftPage page) {
    shifts.assignAll(_uniqueItems(page.items));
    _loadedShiftIds
      ..clear()
      ..addAll(shifts.map((shift) => shift.id));
    _updatePagination(page);
    error.value = null;
    isLoadMoreError.value = false;
  }

  void _appendUnique(ShiftPage page) {
    for (final shift in page.items) {
      if (_loadedShiftIds.add(shift.id)) shifts.add(shift);
    }
    _updatePagination(page);
    error.value = null;
    isLoadMoreError.value = false;
  }

  List<Shift> _uniqueItems(Iterable<Shift> items) {
    final ids = <String>{};
    return items.where((shift) => ids.add(shift.id)).toList();
  }

  void _updatePagination(ShiftPage page) {
    _cursor = page.nextCursor;
    _hasMore = _cursor != null;
  }

  @override
  Future<void> refresh() async => loadFirstPage();

  Future<void> setDepartment(String value) async {
    if (_disposed || department.value == value) return;
    department.value = value;
    await loadFirstPage(clearExisting: true);
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    if (_disposed) return;
    final normalizedFrom = from == null ? null : DateTime(from.year, from.month, from.day);
    final normalizedTo = to == null ? null : DateTime(to.year, to.month, to.day);
    if (filterFrom.value == normalizedFrom && filterTo.value == normalizedTo) return;
    filterFrom.value = normalizedFrom;
    filterTo.value = normalizedTo;
    await loadFirstPage(clearExisting: true);
  }

  DateTime? _inclusiveFilterEnd(DateTime? date) => date == null
      ? null
      : DateTime(date.year, date.month, date.day + 1).subtract(const Duration(microseconds: 1));

  Future<void> loadMyShifts() async {
    if (_disposed) return;
    final version = ++_myShiftsRequestVersion;
    isLoadingMyShifts.value = true;
    myShiftsError.value = null;
    try {
      final now = DateTime.now();
      final result = await repository.myShifts(
        from: DateTime(now.year, now.month, now.day),
        to: DateTime(now.year + 1, now.month, now.day),
      );
      if (_isCurrentMyShiftsRequest(version)) myShifts.assignAll(result);
    } catch (e) {
      if (_isCurrentMyShiftsRequest(version)) myShiftsError.value = _message(e);
    } finally {
      if (_isCurrentMyShiftsRequest(version)) isLoadingMyShifts.value = false;
    }
  }

  ClaimCheck check(Shift shift) {
    final staff = Get.find<AuthController>().staff.value;
    if (staff == null) return const ClaimCheck.denied('Please select a staff member.');
    return checkClaim(staff: staff, shift: shift, myShifts: myShifts);
  }

  Future<bool> claim(Shift shift) async {
    if (_disposed || isClaiming.value) return false;
    final result = check(shift);
    if (!result.canClaim) {
      Get.snackbar('Cannot claim shift', result.reason ?? 'This shift cannot be claimed.');
      return false;
    }
    isClaiming.value = true;
    try {
      await repository.claim(shift.id);
      if (_disposed) return false;
      await Future.wait([loadFirstPage(), loadMyShifts()]);
      return true;
    } catch (e) {
      if (!_disposed && e is ApiException && e.statusCode == 409) {
        shift.filled = shift.slots;
        await Future.wait([loadFirstPage(), loadMyShifts()]);
      }
      if (!_disposed) Get.snackbar('Claim failed', _message(e));
      return false;
    } finally {
      if (!_disposed) isClaiming.value = false;
    }
  }

  Future<void> cancel(Shift shift) async {
    if (_disposed) return;
    try {
      await repository.cancel(shift.id);
      if (_disposed) return;
      await Future.wait([loadFirstPage(), loadMyShifts()]);
      if (!_disposed) Get.snackbar('Cancelled', 'Your shift has been cancelled.');
    } catch (e) {
      if (!_disposed) Get.snackbar('Unable to cancel', _message(e));
    }
  }

  bool _isCurrentRequest(int version) => !_disposed && version == _requestVersion;

  bool _isCurrentMyShiftsRequest(int version) =>
      !_disposed && version == _myShiftsRequestVersion;

  String _message(Object error) => error is ApiException ? error.message : 'Something went wrong. Please try again.';

  @override
  void onClose() {
    _disposed = true;
    _requestVersion++;
    _myShiftsRequestVersion++;
    super.onClose();
  }
}
