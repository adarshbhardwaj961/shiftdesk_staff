import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/routes/app_routes.dart';
import '../../../domain/models/staff_profile.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/shifts_controller.dart';

class OpenShiftsScreen extends StatefulWidget {
  const OpenShiftsScreen({super.key});
  @override
  State<OpenShiftsScreen> createState() => _OpenShiftsScreenState();
}

class _OpenShiftsScreenState extends State<OpenShiftsScreen> {
  final controller = Get.find<ShiftsController>();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.loadFirstPage();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 250) {
      controller.loadMore();
    }
  }

  Future<void> _selectDateRange() async {
    final today = DateTime.now();
    final currentFrom = controller.filterFrom.value ?? today;
    final currentTo = controller.filterTo.value ?? currentFrom.add(const Duration(days: 30));
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2, today.month, today.day),
      initialDateRange: DateTimeRange(start: currentFrom, end: currentTo),
    );
    if (!mounted || range == null) return;
    await controller.setDateRange(range.start, range.end);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staff = Get.find<AuthController>().staff;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open shifts'),
        actions: [
          IconButton(tooltip: 'My shifts', onPressed: () => Get.toNamed(AppRoutes.myShifts), icon: const Icon(Icons.event_available)),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'switch') {
                await Get.find<AuthController>().switchUser();
                Get.offAllNamed(AppRoutes.users);
              } else {
                Get.toNamed(AppRoutes.developer);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'switch', child: Text('Switch user')),
              PopupMenuItem(value: 'developer', child: Text('Developer settings')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() => Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text('Hello, ${staff.value?.name ?? 'Staff'}', style: Theme.of(context).textTheme.titleMedium)),
                DropdownButton<String>(
                  value: controller.department.value,
                  hint: const Text('All departments'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All departments')),
                    ...controller.departments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                  ],
                  onChanged: (value) => controller.setDepartment(value ?? ''),
                ),
              ]),
              Row(children: [
                TextButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    controller.filterFrom.value == null
                        ? 'Any date'
                        : '${DateFormat('d MMM').format(controller.filterFrom.value!)} – ${DateFormat('d MMM').format(controller.filterTo.value!)}',
                  ),
                ),
                if (controller.filterFrom.value != null)
                  TextButton(
                    onPressed: () => controller.setDateRange(null, null),
                    child: const Text('Clear'),
                  ),
              ]),
            ]),
          )),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.shifts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.error.value != null && controller.shifts.isEmpty) {
                return _ErrorView(message: controller.error.value!, onRetry: controller.loadFirstPage);
              }
              if (controller.shifts.isEmpty) return const Center(child: Text('No open shifts found.'));
              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.shifts.length + (controller.isLoadingMore.value ? 1 : 0) + (controller.error.value != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= controller.shifts.length) {
                      if (controller.error.value != null) {
                        return TextButton(
                          onPressed: controller.isLoadMoreError.value
                              ? controller.retryLoadMore
                              : controller.loadFirstPage,
                          child: Text(
                            '${controller.isLoadMoreError.value ? 'Could not load more' : 'Could not refresh shifts'}. '
                            'Retry: ${controller.error.value}',
                          ),
                        );
                      }
                      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                    }
                    final shift = controller.shifts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text('${shift.department} • ${shift.requiredRole.label}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${DateFormat('EEE d MMM').format(shift.start.toLocal())} · ${DateFormat('HH:mm').format(shift.start.toLocal())}–${DateFormat('HH:mm').format(shift.end.toLocal())}\n${shift.filled} / ${shift.slots} filled'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Get.toNamed(AppRoutes.detail, arguments: shift),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  ));
}
