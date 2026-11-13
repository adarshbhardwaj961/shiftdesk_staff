import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/bindings/app_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ShiftDeskApp(binding: AppBinding()));
}
