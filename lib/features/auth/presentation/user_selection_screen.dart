import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../domain/models/staff_profile.dart';
import '../controllers/auth_controller.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});
  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final auth = Get.find<AuthController>();
  @override
  void initState() {
    super.initState();
    auth.loadStaff();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose staff member')),
      body: Obx(() {
        if (auth.isLoading.value && auth.staffList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (auth.error.value != null && auth.staffList.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(auth.error.value!),
            ElevatedButton(onPressed: auth.loadStaff, child: const Text('Retry')),
          ]));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Select a profile to continue.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            for (final person in auth.staffList)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(person.name.substring(0, 1))),
                  title: Text(person.name),
                  subtitle: Text('${person.role.label} • ${person.active ? 'Active' : 'Deactivated'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: auth.isLoading.value ? null : () async {
                    final ok = await auth.selectStaff(person);
                    if (ok) Get.offAllNamed(AppRoutes.shifts);
                    else Get.snackbar('Unable to continue', auth.error.value ?? 'Please try again.');
                  },
                ),
              ),
          ],
        );
      }),
    );
  }
}
