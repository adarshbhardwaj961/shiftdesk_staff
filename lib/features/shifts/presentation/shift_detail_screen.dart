import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/shift.dart';
import '../../../domain/models/staff_profile.dart';
import '../controllers/shifts_controller.dart';

class ShiftDetailScreen extends StatelessWidget {
  const ShiftDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shift = Get.arguments as Shift;
    final controller = Get.find<ShiftsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Shift details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final check = controller.check(shift);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shift.department, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Required role: ${shift.requiredRole.label}'),
            Text('Date: ${DateFormat('EEE, d MMM yyyy').format(shift.start.toLocal())}'),
            Text('Time: ${DateFormat('HH:mm').format(shift.start.toLocal())} – ${DateFormat('HH:mm').format(shift.end.toLocal())}'),
            Text('Slots: ${shift.filled} / ${shift.slots} filled'),
            const SizedBox(height: 24),
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(check.canClaim ? Icons.check_circle : Icons.info, color: check.canClaim ? Colors.green : Colors.orange),
                const SizedBox(width: 10),
                Expanded(child: Text(check.canClaim ? 'You are eligible to claim this shift.' : check.reason!)),
              ]),
            )),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: !check.canClaim || controller.isClaiming.value ? null : () async {
                  final success = await controller.claim(shift);
                  if (success && context.mounted) Get.back();
                },
                child: controller.isClaiming.value
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Claim shift'),
              )),
            ),
          ]);
        }),
      ),
    );
  }
}
