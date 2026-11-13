import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/models/shift.dart';
import '../../../domain/models/staff_profile.dart';
import '../controllers/shifts_controller.dart';

class MyShiftsScreen extends StatefulWidget {
  const MyShiftsScreen({super.key});
  @override
  State<MyShiftsScreen> createState() => _MyShiftsScreenState();
}

class _MyShiftsScreenState extends State<MyShiftsScreen> {
  final controller = Get.find<ShiftsController>();
  @override
  void initState() {
    super.initState();
    controller.loadMyShifts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My shifts')),
      body: Obx(() {
        if (controller.isLoadingMyShifts.value && controller.myShifts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.myShiftsError.value != null && controller.myShifts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(controller.myShiftsError.value!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: controller.loadMyShifts, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }
        if (controller.myShifts.isEmpty) return const Center(child: Text('You have no upcoming shifts.'));
        final grouped = <DateTime, List<Shift>>{};
        for (final shift in controller.myShifts) {
          grouped.putIfAbsent(mondayOf(shift.start), () => []).add(shift);
        }
        final weeks = grouped.keys.toList()..sort();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (controller.myShiftsError.value != null)
              TextButton(
                onPressed: controller.loadMyShifts,
                child: Text('Could not refresh your shifts. Retry: ${controller.myShiftsError.value}'),
              ),
            for (final week in weeks) ...[
              Text('Week of ${DateFormat('d MMM').format(week)}', style: Theme.of(context).textTheme.titleMedium),
              Text('${grouped[week]!.fold<double>(0, (sum, s) => sum + s.end.difference(s.start).inMinutes / 60)} booked hours', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              for (final shift in grouped[week]!)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text('${shift.department} • ${shift.requiredRole.label}'),
                    subtitle: Text('${DateFormat('EEE d MMM, HH:mm').format(shift.start.toLocal())} – ${DateFormat('HH:mm').format(shift.end.toLocal())}'),
                    trailing: TextButton(onPressed: () => controller.cancel(shift), child: const Text('Cancel')),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ],
        );
      }),
    );
  }
}
