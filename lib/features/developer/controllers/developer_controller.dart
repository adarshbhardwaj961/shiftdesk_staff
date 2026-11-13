import 'package:get/get.dart';
import '../../../data/datasources/fake_shift_api.dart';

class DeveloperController extends GetxController {
  DeveloperController(this.api);
  final FakeShiftApi api;
  final flakyNetwork = false.obs;
  final busyHospital = false.obs;

  void setFlaky(bool value) {
    flakyNetwork.value = value;
    api.setFlakyNetwork(value);
  }

  void setBusy(bool value) {
    busyHospital.value = value;
    api.setBusyHospital(value);
  }
}
