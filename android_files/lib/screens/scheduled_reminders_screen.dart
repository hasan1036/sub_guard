import 'package:flutter/material.dart';

import '../services/notifications.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';

/// Shows the reminders SubGuard has handed to the phone, and how many the
/// phone itself says are waiting. If those two numbers differ, the phone is
/// not keeping SubGuard's reminders.
class ScheduledRemindersScreen extends StatefulWidget {
  const ScheduledRemindersScreen({super.key});

  @override
  State<ScheduledRemindersScreen> createState() =>
      _ScheduledRemindersScreenState();
}

class _ScheduledRemindersScreenState extends State<ScheduledRemindersScreen> {
  bool _loading = true;
  int? _onPhone;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Schedule everything again, then ask the phone what it holds.
    await AppScope.read(context).refresh();
    final count = await NotificationService.instance.pendingCount();
    if (!mounted) return;
    setState(() {
      _onPhone = count;
      _loading = false;
    });
  }

  String _time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;
    final list = service.lastScheduled;
    final error = service.lastError;
    final text = Theme.of(context).textTheme;
    const green = Color(0xFF16A34A);
    const orange = Color(0xFFE07000);
    final ok = error == null && _onPhone != null && _onPhone! >= list.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled reminders'),
        actions: [
          IconButton(
            tooltip: 'Check again',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
              children: [
                SoftCard(
                  color: (ok ? green : orange).withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      IconBadge(
                          ok ? Icons.check_circle_rounded : Icons.warning_rounded,
                          color: ok ? green : orange,
                          size: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              list.isEmpty
                                  ? 'No reminders coming up'
                                  : ok
                                      ? '${list.length} reminders are ready'
                                      : 'Some reminders may not arrive',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Set by SubGuard: ${list.length}  ·  '
                              'Kept by your phone: ${_onPhone ?? '?'}',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  SoftCard(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.10),
                    child: SelectableText('Error: $error',
                        style: text.bodySmall),
                  ),
                ],
                const SectionHeader('Next reminders',
                    icon: Icons.schedule_rounded),
                if (list.isEmpty)
                  Text(
                    'Reminders appear here for subscriptions whose reminder '
                    'time is still ahead.',
                    style: text.bodyMedium,
                  ),
                for (final r in list.take(20))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SoftCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const IconBadge(Icons.notifications_rounded, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(r.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_time(r.at),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              Text(formatDayDate(r.at), style: text.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
