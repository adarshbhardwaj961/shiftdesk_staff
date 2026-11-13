import 'package:get/get.dart';
import '../../../core/storage/session_storage.dart';
import '../../../domain/models/staff_profile.dart';
import '../../../domain/repositories/shift_repository.dart';

class AuthController extends GetxController {
  AuthController(this.repository, this.storage);
  final ShiftRepository repository;
  final SessionStorage storage;

  final staff = Rxn<StaffProfile>();
  final staffList = <StaffProfile>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  Future<bool> restoreSession() async {
    try {
      final id = await storage.readStaffId();
      if (id == null) return false;
      await repository.signInAs(id);
      staff.value = await repository.currentStaff();
      return staff.value != null;
    } catch (_) {
      await storage.clear();
      return false;
    }
  }

  Future<void> loadStaff() async {
    isLoading.value = true;
    error.value = null;
    try {
      staffList.assignAll(await repository.listStaff());
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> selectStaff(StaffProfile selected) async {
    isLoading.value = true;
    error.value = null;
    try {
      await repository.signInAs(selected.id);
      staff.value = selected;
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> switchUser() async {
    staff.value = null;
    await repository.signOut();
  }
}
