import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/notifications.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'paywall_screen.dart';
import 'privacy_policy_screen.dart';
import 'reminder_help_screen.dart';
import 'reminder_setup_screen.dart';
import 'scheduled_reminders_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _remindOptions = {
    0: 'On the day',
    1: '1 day before',
    2: '2 days before',
    3: '3 days before',
    7: '1 week before',
  };

  Future<void> _pickCurrency(BuildContext context, AppState state) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in {...currencies, state.defaultCurrency})
              ListTile(
                title: Text(c, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: c == state.defaultCurrency
                    ? Icon(Icons.check_rounded,
                        color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await state.setDefaultCurrency(picked);
  }

  Future<void> _pickReminder(BuildContext context, AppState state) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in _remindOptions.entries)
              ListTile(
                title: Text(e.value,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: e.key == state.defaultRemindDays
                    ? Icon(Icons.check_rounded,
                        color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, e.key),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await state.setDefaultRemindDays(picked);
  }

  Future<void> _pickTime(BuildContext context, AppState state) async {
    final m = state.reminderMinuteOfDay;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
      helpText: 'Reminders arrive at',
    );
    if (picked == null) return;
    await state.setReminderMinuteOfDay(picked.hour * 60 + picked.minute);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Reminders will arrive at ${picked.format(context)}'),
    ));
  }

  Future<void> _deleteAll(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
            'All subscriptions and payment history will be removed from this phone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await state.deleteAll();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.verified_user_rounded,
                          color: Brand.primary, size: 32),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Settings',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900)),
                          Text('Make SubGuard work your way',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (paymentsEnabled) ...[
                  const SizedBox(height: 18),
                  GradientCard(
                    padding: EdgeInsets.zero,
                    radius: 22,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const PaywallScreen()),
                      ),
                      leading: const Icon(Icons.workspace_premium_rounded,
                          color: Color(0xFFFFD36B), size: 34),
                      title: Text(
                          state.isPremium ? 'Premium active' : 'Go Premium',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17)),
                      subtitle: Text(
                          state.isPremium
                              ? 'Thank you for supporting $appName'
                              : 'Unlimited subscriptions and more',
                          style: const TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                    ),
                  ),
                ],

                const SectionHeader('Preferences', icon: Icons.tune_rounded),
                SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.payments_rounded,
                        title: 'Default currency',
                        value: state.defaultCurrency,
                        onTap: () => _pickCurrency(context, state),
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.schedule_rounded,
                        title: 'Reminder time',
                        value: TimeOfDay(
                                hour: state.reminderMinuteOfDay ~/ 60,
                                minute: state.reminderMinuteOfDay % 60)
                            .format(context),
                        onTap: () => _pickTime(context, state),
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.notifications_rounded,
                        title: 'Default reminder',
                        value: _remindOptions[state.defaultRemindDays] ?? '',
                        onTap: () => _pickReminder(context, state),
                      ),
                    ],
                  ),
                ),

                const SectionHeader('Reminders',
                    icon: Icons.notifications_active_rounded),
                SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.verified_rounded,
                        title: 'Reminder setup',
                        subtitle: state.reminderSetupDone
                            ? 'Done. Run it again anytime'
                            : 'Not finished: reminders may be blocked',
                        highlight: !state.reminderSetupDone,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const ReminderSetupScreen()),
                        ),
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.event_note_rounded,
                        title: 'Scheduled reminders',
                        subtitle: 'See exactly when the next ones arrive',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const ScheduledRemindersScreen()),
                        ),
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.send_rounded,
                        title: 'Send a test reminder',
                        subtitle: 'Arrives in 2 minutes. Close the app meanwhile',
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final msg =
                              await NotificationService.instance.scheduleTest();
                          messenger.showSnackBar(SnackBar(
                            content: Text(msg),
                            duration: const Duration(seconds: 6),
                          ));
                        },
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.alarm_on_rounded,
                        title: 'Allow precise reminders',
                        subtitle: 'Reminders arrive exactly on time',
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final appState = AppScope.read(context);
                          final ok = await NotificationService.instance
                              .requestExactPermission();
                          // Re-schedule all reminders in the new mode.
                          await appState.refresh();
                          messenger.showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'Precise reminders are ON.'
                                : 'Still off. Turn on "Alarms & reminders" for SubGuard, then come back.'),
                          ));
                        },
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.help_rounded,
                        title: 'Reminders not arriving?',
                        subtitle: 'Fix it in 1 minute (Xiaomi, Samsung, Oppo…)',
                        highlight: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const ReminderHelpScreen()),
                        ),
                      ),
                    ],
                  ),
                ),

                const SectionHeader('Privacy & data', icon: Icons.lock_rounded),
                SoftCard(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.10),
                  child: Row(
                    children: [
                      const IconBadge(Icons.shield_rounded,
                          color: Color(0xFF16A34A), size: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your data stays on your phone',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(
                              'No account, no bank connection. Nothing is sent to any server.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _Row(
                    icon: Icons.policy_rounded,
                    title: 'Privacy policy',
                    subtitle: 'What SubGuard does (and never does) with your data',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const PrivacyPolicyScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _Row(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete all data',
                    color: cs.error,
                    onTap: () => _deleteAll(context, state),
                  ),
                ),

                // Only in debug builds: never visible to real users.
                if (kDebugMode && paymentsEnabled) ...[
                  const SectionHeader('Developer', icon: Icons.bug_report_rounded),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SwitchListTile(
                      title: const Text('Simulate Premium'),
                      value: state.isPremium,
                      onChanged: state.setPremium,
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                Column(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: Brand.primary, size: 28),
                    const SizedBox(height: 6),
                    const Text('$appName v$appVersion',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('Never pay for a subscription you forgot about again.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text('Made by $developerName · $supportEmail',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 70,
        endIndent: 16,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    this.color,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Color? color;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final badgeColor =
        color ?? (highlight ? const Color(0xFFE07000) : cs.primary);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconBadge(icon, color: badgeColor, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: color)),
                  if (subtitle != null)
                    Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (value != null) ...[
              Text(value!,
                  style: TextStyle(
                      color: cs.primary, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right_rounded,
                color: color ?? cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
