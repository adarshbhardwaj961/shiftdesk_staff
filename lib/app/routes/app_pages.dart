import 'package:get/get.dart';
import '../../features/auth/presentation/user_selection_screen.dart';
import '../../features/shifts/presentation/open_shifts_screen.dart';
import '../../features/shifts/presentation/shift_detail_screen.dart';
import '../../features/shifts/presentation/my_shifts_screen.dart';
import '../../features/developer/presentation/developer_settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.users, page: () => const UserSelectionScreen()),
    GetPage(name: AppRoutes.shifts, page: () => const OpenShiftsScreen()),
    GetPage(name: AppRoutes.detail, page: () => const ShiftDetailScreen()),
    GetPage(name: AppRoutes.myShifts, page: () => const MyShiftsScreen()),
    GetPage(name: AppRoutes.developer, page: () => const DeveloperSettingsScreen()),
  ];
}
