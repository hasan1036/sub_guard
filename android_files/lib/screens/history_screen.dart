import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final payments = state.payments;
    final year = DateTime.now().year;

    // Group by month (newest first, because payments are already sorted).
    final byMonth = <DateTime, List<Payment>>{};
    for (final p in payments) {
      byMonth.putIfAbsent(DateTime(p.date.year, p.date.month), () => []).add(p);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payment history')),
      body: payments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: cs.primary),
                    const SizedBox(height: 16),
                    Text('No payments yet',
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'Every time a billing date passes, the payment is '
                      'added here automatically.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
              children: [
                GradientCard(
            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spent in $year',
                            style: text.bodyMedium
                                ?.copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          formatTotals(state.spentInYear(year)),
                          style: text.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ],
                    ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Swipe a payment away if you were not actually charged.',
                  style: text.bodySmall,
                ),
                for (final entry in byMonth.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(formatMonthYear(entry.key),
                              style: text.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        Text(_monthTotal(entry.value),
                            style: text.titleSmall?.copyWith(color: cs.primary)),
                      ],
                    ),
                  ),
                  for (final p in entry.value) _PaymentTile(payment: p),
                ],
              ],
            ),
    );
  }

  String _monthTotal(List<Payment> list) {
    final m = <String, double>{};
    for (final p in list) {
      m[p.currency] = (m[p.currency] ?? 0) + p.amount;
    }
    return formatTotals(m);
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = payment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(p.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: cs.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_outline, color: cs.onError),
        ),
        onDismissed: (_) {
          final state = AppScope.read(context);
          final messenger = ScaffoldMessenger.of(context);
          state.deletePayment(p.id);
          messenger.showSnackBar(SnackBar(
            content: Text('${p.name} payment removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => state.restorePayment(p),
            ),
          ));
        },
        child: SoftCard(
          padding: EdgeInsets.zero,
          color: null,
          child: ListTile(
            leading: ServiceAvatar(name: p.name, color: p.colorValue),
            title: Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(formatDate(p.date)),
            trailing: Text(formatMoney(p.amount, p.currency),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
