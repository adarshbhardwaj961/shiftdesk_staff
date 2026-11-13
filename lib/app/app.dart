import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/app_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class ShiftDeskApp extends StatelessWidget {
  const ShiftDeskApp({super.key, required this.binding});
  final AppBinding binding;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ShiftDesk Staff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4169E1)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
        ),
      ),
      initialBinding: binding,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
