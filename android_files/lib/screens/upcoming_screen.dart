import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'add_edit_screen.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final charges = state.upcomingCharges(_days);

    // Group by date.
    final byDate = <DateTime, List<UpcomingCharge>>{};
    for (final c in charges) {
      byDate.putIfAbsent(c.date, () => []).add(c);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming payments')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 7, label: Text('7 days')),
              ButtonSegment(value: 30, label: Text('30 days')),
              ButtonSegment(value: 90, label: Text('90 days')),
              ButtonSegment(value: 365, label: Text('1 year')),
            ],
            selected: {_days},
            onSelectionChanged: (s) => setState(() => _days = s.first),
          ),
          const SizedBox(height: 16),
          GradientCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Due in the next $_days days',
                      style: text.bodyMedium
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    formatTotals(state.upcomingTotals(_days)),
                    style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text('${charges.length} payments',
                      style: text.bodySmall
                          ?.copyWith(color: Colors.white)),
                ],
              ),
          ),
          if (charges.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Nothing is due in this period.',
                  textAlign: TextAlign.center, style: text.bodyMedium),
            ),
          for (final entry in byDate.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Row(
                children: [
                  Text(formatDate(entry.key),
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(
                    relativeDays(dateOnly(entry.key)
                        .difference(dateOnly(DateTime.now()))
                        .inDays),
                    style: text.bodySmall?.copyWith(color: cs.primary),
                  ),
                ],
              ),
            ),
            for (final c in entry.value) _ChargeTile(charge: c),
          ],
        ],
      ),
    );
  }
}

class _ChargeTile extends StatelessWidget {
  const _ChargeTile({required this.charge});
  final UpcomingCharge charge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = charge.sub;
    final trialEnd = s.isTrial && charge.date == dateOnly(s.nextBillingDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        padding: EdgeInsets.zero,
        color: trialEnd ? const Color(0xFFFFE9D6) : null,
        child: ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => AddEditScreen(existing: s)),
          ),
          leading: ServiceAvatar(name: s.name, color: s.colorValue),
          title: Text(s.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(trialEnd
              ? 'Free trial ends: first charge'
              : '${s.cycle.label} · ${s.category}'),
          trailing: Text(formatMoney(s.price, s.currency),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
