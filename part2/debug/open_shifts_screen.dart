// Fixed reference implementation for Part 2. Adapt imports/model names to supplied repo.
import 'package:flutter/material.dart';

import '../data/shift_repository.dart';
import '../models/shift.dart';
// import '../../data/shift_repository.dart';
// import '../../models/shift.dart';

class OpenShiftsScreen extends StatefulWidget {
  const OpenShiftsScreen({super.key, required this.repo, required this.department});
  final ShiftRepository repo;
  final String department;

  @override
  State<OpenShiftsScreen> createState() => _OpenShiftsScreenState();
}

class _OpenShiftsScreenState extends State<OpenShiftsScreen> {
  final ScrollController scroll = ScrollController();
  final List<Shift> shifts = [];
  String? cursor;
  String? error;
  bool loading = false;
  bool hasMore = true;
  bool disposed = false;
  bool claiming = false;
  final Set<String> ids = {};

  @override
  void initState() {
    super.initState();
    scroll.addListener(_onScroll);
    loadMore(reset: true);
  }

  void _onScroll() {
    if (!scroll.hasClients || loading || !hasMore || error != null) return;
    if (scroll.position.pixels >= scroll.position.maxScrollExtent - 200) loadMore();
  }

  Future<void> loadMore({bool reset = false}) async {
    if (loading || (!hasMore && !reset)) return;
    if (reset) {
      cursor = null;
      hasMore = true;
      ids.clear();
      shifts.clear();
      error = null;
    }
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final page = await widget.repo.openShifts(department: widget.department, cursor: cursor, limit: 20);
      if (!mounted) return;
      setState(() {
        for (final item in page.items) {
          if (ids.add(item.id)) shifts.add(item);
        }
        cursor = page.nextCursor;
        hasMore = cursor != null;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> claim(Shift shift) async {
    if (claiming) return;
    setState(() => claiming = true);
    try {
      await widget.repo.claim(shift.id);
      if (!mounted) return;
      setState(() => shift.filled++);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => claiming = false);
    }
  }

  @override
  void dispose() {
    scroll.removeListener(_onScroll);
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => loadMore(reset: true),
    child: ListView.builder(
      controller: scroll,
      itemCount: shifts.length + (loading ? 1 : 0) + (error != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= shifts.length) {
          if (error != null) return ListTile(title: Text(error!), trailing: TextButton(onPressed: loadMore, child: const Text('Retry')));
          return const Center(child: CircularProgressIndicator());
        }
        final shift = shifts[index];
        return ListTile(
          title: Text('${shift.department} · ${shift.requiredRole}'),
          subtitle: Text('${shift.start.toLocal()} – ${shift.end.toLocal()}'),
          trailing: shift.filled < shift.slots
              ? ElevatedButton(onPressed: claiming ? null : () => claim(shift), child: const Text('Claim'))
              : const Text('Full'),
        );
      },
    ),
  );
}
