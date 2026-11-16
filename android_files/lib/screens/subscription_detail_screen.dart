import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../state/app_state.dart';
import '../utils/cancel.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'add_edit_screen.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  final String subscriptionId;

  Subscription? _find(AppState state) {
    for (final s in state.subscriptions) {
      if (s.id == subscriptionId) return s;
    }
    return null;
  }

  void _edit(BuildContext context, Subscription s) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AddEditScreen(existing: s),
    ));
  }

  Future<void> _delete(BuildContext context, Subscription s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${s.name}?'),
        content: const Text(
            'This only removes it from SubGuard. Remember to cancel it with the company too.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final state = AppScope.read(context);
    Navigator.of(context).pop();
    await state.delete(s.id);
  }

  Future<void> _cancel(BuildContext context, Subscription s) async {
    final ok = await openCancelPage(s);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the cancel page')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = _find(state);
    if (s == null) {
      // Removed (e.g. from the edit screen): leave this page.
      // Close THIS page only, never whatever happens to be on top of it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final route = ModalRoute.of(context);
        if (route == null || !route.isActive) return;
        if (route.isCurrent) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).removeRoute(route);
        }
      });
      return const Scaffold();
    }

    final cs = Theme.of(context).colorScheme;
    final days = s.daysUntilBilling();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: Brand.gradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    top: 40,
                    child: Icon(Icons.play_arrow_rounded,
                        size: 150, color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _edit(context, s),
                            icon: const Icon(Icons.edit_rounded, color: Colors.white),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: ServiceAvatar(
                            name: s.name, color: s.colorValue, size: 92),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(s.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900)),
                          ),
                          if (s.isTrial) ...[
                            const SizedBox(width: 8),
                            const TrialTag(),
                          ],
                        ],
                      ),
                      Text(s.category,
                          style: const TextStyle(color: Colors.white70, fontSize: 15)),
                      const SizedBox(height: 26),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.calendar_month_rounded,
                        label: s.isTrial ? 'Trial ends' : 'Next Payment',
                        value: formatDate(s.nextBillingDate),
                        trailing: DaysLeftChip(days: days, trial: s.isTrial),
                      ),
                      const Divider(height: 1),
                      _InfoRow(
                        icon: Icons.attach_money_rounded,
                        label: 'Price',
                        trailing: Text(
                          '${formatMoney(s.price, s.currency)} / ${s.cycle.label}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      const Divider(height: 1),
                      _InfoRow(
                        icon: Icons.autorenew_rounded,
                        label: 'Monthly cost',
                        trailing: Text(
                          formatMoney(s.monthlyCost, s.currency),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _CancelButton(sub: s, onTap: () => _cancel(context, s)),
                const SizedBox(height: 14),
                GradientCard(
                  padding: const EdgeInsets.all(0),
                  radius: 22,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    onTap: () => _edit(context, s),
                    leading: const Icon(Icons.notifications_active_rounded,
                        color: Colors.white, size: 30),
                    title: const Text('Reminder Settings',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      s.remindDaysBefore == 0
                          ? 'Get notified on the day of renewal.'
                          : 'Get notified ${s.remindDaysBefore} day${s.remindDaysBefore == 1 ? '' : 's'} before renewal.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                  ),
                ),
                const SectionHeader('Actions'),
                SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _ActionRow(
                        icon: Icons.edit_rounded,
                        label: 'Edit Subscription',
                        onTap: () => _edit(context, s),
                      ),
                      const Divider(height: 1, indent: 60),
                      _ActionRow(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete Subscription',
                        color: cs.error,
                        onTap: () => _delete(context, s),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SoftCard(
                  child: Row(
                    children: [
                      const IconBadge(Icons.bar_chart_rounded, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cancel it and save',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${formatMoney(s.yearlyCost, s.currency)} per year!',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.notes.isNotEmpty) ...[
                  const SectionHeader('Notes'),
                  SoftCard(child: Text(s.notes)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconBadge(icon, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: value == null
                        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)
                        : Theme.of(context).textTheme.bodySmall),
                if (value != null)
                  Text(value!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      title: Text(label,
          style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

/// Big red button: opens the service's own cancel page (app or website).
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.sub, required this.onTap});

  final Subscription sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final target = cancelTarget(sub);
    final host = cancelHost(sub);
    final button = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5A5F), Color(0xFFE0245E)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x44E0245E), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.white, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cancel ${sub.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                      Text(
                        target.isDirect
                            ? 'Opens $host, the official site'
                            : 'Searches the web for how to cancel ${sub.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );

    if (!target.isDirect) return button;

    // Trust note: the user may see the service's own sign-in page next.
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 14, color: muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'SubGuard never sees your password.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
