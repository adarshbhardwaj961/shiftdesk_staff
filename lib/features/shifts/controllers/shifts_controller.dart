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
  final isClaiming = false.obs;
  final error = RxnString();
  final department = ''.obs;
  final DateTime? filterFrom = null;
  final DateTime? filterTo = null;
  String? _cursor;
  bool _hasMore = true;
  int _requestVersion = 0;

  List<String> get departments => const ['ICU', 'ER', 'General Ward', 'Theatre'];

  Future<void> loadFirstPage() async {
    final version = ++_requestVersion;
    isLoading.value = true;
    isLoadingMore.value = false;
    error.value = null;
    _cursor = null;
    _hasMore = true;
    shifts.clear();
    try {
      final page = await repository.openShifts(department: department.value.isEmpty ? null : department.value, limit: 20);
      if (version != _requestVersion) return;
      _appendUnique(page);
    } catch (e) {
      if (version == _requestVersion) error.value = _message(e);
    } finally {
      if (version == _requestVersion) isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !_hasMore || error.value != null) return;
    isLoadingMore.value = true;
    try {
      final page = await repository.openShifts(
        department: department.value.isEmpty ? null : department.value,
        cursor: _cursor,
        limit: 20,
      );
      _appendUnique(page);
    } catch (e) {
      error.value = _message(e);
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _appendUnique(ShiftPage page) {
    final known = shifts.map((s) => s.id).toSet();
    shifts.addAll(page.items.where((s) => !known.contains(s.id)));
    _cursor = page.nextCursor;
    _hasMore = _cursor != null;
    error.value = null;
  }

  Future<void> refresh() async => loadFirstPage();

  Future<void> setDepartment(String value) async {
    department.value = value;
    await loadFirstPage();
  }

  Future<void> loadMyShifts() async {
    try {
      final now = DateTime.now();
      myShifts.assignAll(await repository.myShifts(
        from: DateTime(now.year, now.month, now.day),
        to: DateTime(now.year + 1, now.month, now.day),
      ));
    } catch (e) {
      Get.snackbar('Unable to load your shifts', _message(e));
    }
  }

  ClaimCheck check(Shift shift) {
    final staff = Get.find<AuthController>().staff.value;
    if (staff == null) return const ClaimCheck.denied('Please select a staff member.');
    return checkClaim(staff: staff, shift: shift, myShifts: myShifts);
  }

  Future<bool> claim(Shift shift) async {
    if (isClaiming.value) return false;
    final result = check(shift);
    if (!result.canClaim) {
      Get.snackbar('Cannot claim shift', result.reason ?? 'This shift cannot be claimed.');
      return false;
    }
    isClaiming.value = true;
    try {
      await repository.claim(shift.id);
      await Future.wait([loadFirstPage(), loadMyShifts()]);
      return true;
    } catch (e) {
      Get.snackbar('Claim failed', _message(e));
      return false;
    } finally {
      isClaiming.value = false;
    }
  }

  Future<void> cancel(Shift shift) async {
    try {
      await repository.cancel(shift.id);
      await Future.wait([loadFirstPage(), loadMyShifts()]);
      Get.snackbar('Cancelled', 'Your shift has been cancelled.');
    } catch (e) {
      Get.snackbar('Unable to cancel', _message(e));
    }
  }

  String _message(Object error) => error is ApiException ? error.message : 'Something went wrong. Please try again.';
}
