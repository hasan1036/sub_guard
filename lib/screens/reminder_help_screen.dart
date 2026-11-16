import 'package:flutter/material.dart';

import '../services/notifications.dart';
import '../widgets/ui.dart';

/// Step-by-step fixes for phones that block background reminders.
/// Steps were checked on a Xiaomi (HyperOS/MIUI) phone; other brands use
/// similar menus but the names can differ slightly between versions.
class ReminderHelpScreen extends StatelessWidget {
  const ReminderHelpScreen({super.key});

  static const _brands = <({String name, int color, List<String> steps})>[
    (
      name: 'Xiaomi · Redmi · POCO',
      color: 0xFFFF6900,
      steps: [
        'Settings → Apps → Manage apps → SubGuard',
        'Turn ON "Autostart" (or Settings → Apps → Permissions → Background autostart)',
        'Battery saver → choose "No restrictions"',
        'Notifications → turn everything ON',
        'In Recent apps, press and hold SubGuard → tap the 🔒 lock',
      ],
    ),
    (
      name: 'Samsung',
      color: 0xFF1428A0,
      steps: [
        'Settings → Apps → SubGuard → Battery → choose "Unrestricted"',
        'Settings → Battery → Background usage limits → make sure SubGuard is NOT in "Sleeping apps" or "Deep sleeping apps"',
        'Settings → Apps → SubGuard → Notifications → turn ON',
      ],
    ),
    (
      name: 'Oppo · Realme · OnePlus',
      color: 0xFF1BA784,
      steps: [
        'Settings → Apps → App management → SubGuard',
        'Battery usage → turn ON "Allow background activity" and "Allow auto launch"',
        'Notifications → turn ON',
        'In Recent apps, tap ⋮ on SubGuard → Lock',
      ],
    ),
    (
      name: 'Vivo · iQOO',
      color: 0xFF415FFF,
      steps: [
        'Settings → Battery → Background power consumption management → SubGuard → "Allow"',
        'Settings → Apps → SubGuard → Autostart → ON',
        'Settings → Apps → SubGuard → Notifications → ON',
      ],
    ),
    (
      name: 'Huawei · Honor',
      color: 0xFFC7000B,
      steps: [
        'Settings → Battery → App launch → SubGuard',
        'Turn OFF "Manage automatically", then turn ON all three switches',
        'Settings → Apps → SubGuard → Notifications → ON',
      ],
    ),
    (
      name: 'Walton · Symphony · Pixel · Motorola · Nokia · others',
      color: 0xFF4285F4,
      steps: [
        'Settings → Apps → SubGuard → Notifications → ON',
        'Settings → Apps → SubGuard → App battery usage → "Unrestricted"',
        'Settings → Apps → SubGuard → Alarms & reminders → ON',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders not arriving?')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
        children: [
          GradientCard(
            child: Row(
              children: [
                const Icon(Icons.battery_alert_rounded,
                    color: Colors.white, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Some phones stop apps in the background to save battery, '
                    'which can block reminders. Follow the steps for your phone '
                    'once, and reminders will arrive on time.',
                    style: text.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Step 1 · Everyone', icon: Icons.looks_one_rounded),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const IconBadge(Icons.alarm_on_rounded, size: 40),
              title: const Text('Allow precise reminders',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Turn on "Alarms & reminders" for SubGuard'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok =
                    await NotificationService.instance.requestExactPermission();
                messenger.showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Precise reminders are ON ✅'
                      : 'Still off. Turn on "Alarms & reminders" for SubGuard.'),
                ));
              },
            ),
          ),
          const SectionHeader('Step 2 · Your phone brand',
              icon: Icons.looks_two_rounded),
          for (final b in _brands)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  // Removes the default divider lines of ExpansionTile.
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(),
                    leading: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Color(b.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(b.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    children: [
                      for (var i = 0; i < b.steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Text('${i + 1}',
                                    style: TextStyle(
                                        color: cs.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(b.steps[i],
                                      style: text.bodyMedium)),
                            ],
                          ),
                        ),
                      Text('Menu names can differ a little between versions.',
                          style: text.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          const SectionHeader('Step 3 · Check it works',
              icon: Icons.looks_3_rounded),
          GradientButton(
            label: 'Send a test reminder',
            icon: Icons.send_rounded,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final msg = await NotificationService.instance.scheduleTest();
              messenger.showSnackBar(SnackBar(
                content: Text(msg),
                duration: const Duration(seconds: 6),
              ));
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Close the app after tapping. If "2/2" arrives in about 2 minutes, you are all set.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
