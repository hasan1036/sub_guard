import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'catalog_picker_screen.dart';
import 'paywall_screen.dart';
import 'reminder_setup_screen.dart';
import 'subscription_detail_screen.dart';

/// Opens "add subscription", or the Premium screen when the free limit is hit.
void openAddFlow(BuildContext context) {
  final state = AppScope.read(context);
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) =>
        state.canAddMore ? const CatalogPickerScreen() : const PaywallScreen(),
  ));
}

void openDetail(BuildContext context, Subscription s) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => SubscriptionDetailScreen(subscriptionId: s.id),
  ));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// 1 = Upcoming, 2 = History, 3 = Settings.
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final subs = state.subscriptions;
    final trials = state.trials;
    final next = state.upcomingCharges(30);
    final year = DateTime.now().year;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(state: state, onSettings: () => onOpenTab(3)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
            child: subs.isEmpty
                ? _EmptyState(onAdd: () => openAddFlow(context))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 18),
                      if (!state.reminderSetupDone) ...[
                        const _SetupBanner(),
                        const SizedBox(height: 14),
                      ],
                      // Next payment
                      SoftCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const IconBadge(Icons.calendar_month_rounded, size: 34),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text('Upcoming Payment',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w800)),
                                ),
                                InkWell(
                                  onTap: () => onOpenTab(1),
                                  child: Row(children: [
                                    Text('See All',
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w700)),
                                    Icon(Icons.arrow_forward,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary),
                                  ]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (next.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Nothing due in the next 30 days 🎉'),
                              )
                            else
                              _NextPaymentRow(charge: next.first),
                          ],
                        ),
                      ),
                      if (trials.isNotEmpty) ...[
                        const SectionHeader('Free Trials', icon: Icons.timer_rounded),
                        _SubList(subs: trials),
                      ],
                      SectionHeader('Your Subscriptions',
                          onSeeAll: () => onOpenTab(1)),
                      _SubList(subs: subs),
                      const SizedBox(height: 18),
                      // Yearly banner
                      GradientCard(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.savings_rounded,
                                  color: Color(0xFFFFB3D9), size: 34),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('You spend per year',
                                      style: TextStyle(color: Colors.white70)),
                                  Text(
                                    formatTotals(state.monthlyTotals
                                        .map((k, v) => MapEntry(k, v * 12))),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.trending_up_rounded,
                                color: Colors.white54, size: 40),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.event_available_rounded,
                              label: 'Due next 30 days',
                              value: formatTotals(state.upcomingTotals(30)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.receipt_long_rounded,
                              label: 'Spent in $year',
                              value: formatTotals(state.spentInYear(year)),
                            ),
                          ),
                        ],
                      ),
                      if (paymentsEnabled && !state.isPremium)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            '${subs.length} of $freeLimit free slots used',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.onSettings});
  final AppState state;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final totals = state.monthlyTotals;
    return Container(
      decoration: const BoxDecoration(
        gradient: Brand.gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.verified_user_rounded,
                        color: Brand.primary, size: 30),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appName,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                        Text('Smart Subscription Manager',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onSettings,
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Monthly Cost',
                              style: TextStyle(color: Colors.white70, fontSize: 15)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatTotals(totals),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.layers_rounded,
                                    color: Color(0xFF7CF2B5), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${state.subscriptions.length} active subscription${state.subscriptions.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _CalendarArt(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small decorative calendar + clock, drawn with icons.
class _CalendarArt extends StatelessWidget {
  const _CalendarArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 4,
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: Brand.primary, size: 42),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Brand.deep,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time_filled_rounded,
                  color: Colors.white, size: 30),
            ),
          ),
          const Positioned(
            right: 2,
            top: 0,
            child: Icon(Icons.notifications_active_rounded,
                color: Color(0xFFFFB86B), size: 22),
          ),
        ],
      ),
    );
  }
}

class _NextPaymentRow extends StatelessWidget {
  const _NextPaymentRow({required this.charge});
  final UpcomingCharge charge;

  @override
  Widget build(BuildContext context) {
    final s = charge.sub;
    final days = dateOnly(charge.date).difference(dateOnly(DateTime.now())).inDays;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => openDetail(context, s),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ServiceAvatar(name: s.name, color: s.colorValue, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${relativeDays(days)} · ${formatDate(charge.date)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Pill(formatMoney(s.price, s.currency), strong: true),
          ],
        ),
      ),
    );
  }
}

class _SubList extends StatelessWidget {
  const _SubList({required this.subs});
  final List<Subscription> subs;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < subs.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  indent: 74,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
            _SubRow(sub: subs[i]),
          ],
        ],
      ),
    );
  }
}

class _SubRow extends StatelessWidget {
  const _SubRow({required this.sub});
  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final soon = sub.daysUntilBilling() <= 3;
    return InkWell(
      onTap: () => openDetail(context, sub),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            ServiceAvatar(name: sub.name, color: sub.colorValue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(sub.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                      if (sub.isTrial) ...[
                        const SizedBox(width: 6),
                        const TrialTag(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sub.cycle.label} · Next: ${formatDate(sub.nextBillingDate)}',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: soon ? cs.error : cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 5),
                  DaysLeftChip(days: sub.daysUntilBilling(), trial: sub.isTrial),
                ],
              ),
            ),
            Text(formatMoney(sub.price, sub.currency),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon, size: 32),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: SoftCard(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            const IconBadge(Icons.shield_rounded, size: 72),
            const SizedBox(height: 18),
            const Text('Never pay for a subscription\nyou forgot about again',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              'Add your subscriptions and free trials. We remind you '
              'before every charge, so you can cancel in time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            GradientButton(
              label: 'Add your first subscription',
              icon: Icons.add_rounded,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown on Home until Reminder setup is finished.
class _SetupBanner extends StatelessWidget {
  const _SetupBanner();

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFE07000);
    return SoftCard(
      color: orange.withValues(alpha: 0.12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const ReminderSetupScreen())),
      child: const Row(
        children: [
          IconBadge(Icons.notifications_off_rounded, color: orange, size: 42),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reminders may be blocked',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text('Finish the 1-minute setup so they always arrive.',
                    style: TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: orange),
        ],
      ),
    );
  }
}
