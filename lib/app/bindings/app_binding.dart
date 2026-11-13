import 'package:get/get.dart';
import '../../core/storage/session_storage.dart';
import '../../data/datasources/fake_shift_api.dart';
import '../../data/repositories/shift_repository_impl.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/shifts/controllers/shifts_controller.dart';
import '../../features/developer/controllers/developer_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SessionStorage(), permanent: true);
    Get.put(FakeShiftApi(), permanent: true);
    Get.put<ShiftRepository>(
      ShiftRepositoryImpl(Get.find<FakeShiftApi>(), Get.find<SessionStorage>()),
      permanent: true,
    );
    Get.put(AuthController(Get.find<ShiftRepository>(), Get.find<SessionStorage>()), permanent: true);
    Get.put(ShiftsController(Get.find<ShiftRepository>()), permanent: true);
    Get.put(DeveloperController(Get.find<FakeShiftApi>()), permanent: true);
  }
}
