import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftdesk_staff/app/app.dart';
import 'package:shiftdesk_staff/app/bindings/app_binding.dart';

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
}
