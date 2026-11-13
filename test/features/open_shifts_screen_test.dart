import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftdesk_staff/app/app.dart';
import 'package:shiftdesk_staff/app/bindings/app_binding.dart';
import 'package:shiftdesk_staff/core/storage/session_storage.dart';
import 'package:shiftdesk_staff/data/datasources/fake_shift_api.dart';
import 'package:shiftdesk_staff/data/repositories/shift_repository_impl.dart';
import 'package:shiftdesk_staff/domain/models/staff_profile.dart';
import 'package:shiftdesk_staff/features/auth/controllers/auth_controller.dart';
import 'package:shiftdesk_staff/features/shifts/controllers/shifts_controller.dart';
import 'package:shiftdesk_staff/features/shifts/presentation/open_shifts_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and resolves the initial route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await tester.pumpWidget(ShiftDeskApp(binding: AppBinding()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byType(MaterialApp), findsOneWidget);
    Get.reset();
    Get.testMode = false;
  });

  testWidgets('open shifts displays the filter controls and first page',
      (tester) async {
    Get.reset();
    Get.testMode = true;
    final api = FakeShiftApi(requestDelay: Duration.zero);
    final storage = SessionStorage();
    final repository = ShiftRepositoryImpl(api, storage);
    final auth = AuthController(repository, storage)
      ..staff.value = StaffProfile(
        id: 'staff-doctor',
        name: 'Alex Morgan',
        role: StaffRole.doctor,
        active: true,
        licenceExpiry: DateTime.utc(2028, 12, 31),
      );
    Get.put<AuthController>(auth);
    Get.put<ShiftsController>(ShiftsController(repository));

    await tester.pumpWidget(const GetMaterialApp(home: OpenShiftsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Open shifts'), findsOneWidget);
    expect(find.text('Any date'), findsOneWidget);
    expect(find.byType(Card), findsAtLeastNWidgets(1));

    Get.reset();
    Get.testMode = false;
  });
}
