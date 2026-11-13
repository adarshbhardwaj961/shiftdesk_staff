import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/developer_controller.dart';

class DeveloperSettingsScreen extends StatelessWidget {
  const DeveloperSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DeveloperController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Developer settings')),
      body: Obx(() => ListView(padding: const EdgeInsets.all(16), children: [
        SwitchListTile(
          title: const Text('Flaky network'),
          subtitle: const Text('About 1 in 5 API calls will fail with a 503 error.'),
          value: controller.flakyNetwork.value,
          onChanged: controller.setFlaky,
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Busy hospital'),
          subtitle: const Text('About 1 in 3 claim attempts may fail with a 409 conflict.'),
          value: controller.busyHospital.value,
          onChanged: controller.setBusy,
        ),
      ])),
    );
  }
}
