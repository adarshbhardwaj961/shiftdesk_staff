import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _staffKey = 'selected_staff_id';

  Future<String?> readStaffId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_staffKey);
  }

  Future<void> saveStaffId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_staffKey, id);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_staffKey);
  }
}
