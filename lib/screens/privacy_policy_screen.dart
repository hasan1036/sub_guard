import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/ui.dart';

/// The privacy policy, built into the app so it can be read offline.
/// Keep this text the same as the public web version.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = 'November 16, 2026';

  static const _sections = <({IconData icon, String title, String body})>[
    (
      icon: Icons.shield_rounded,
      title: 'The short version',
      body: 'SubGuard does not collect, sell or share any of your personal '
          'information. Everything you enter is stored only on your own '
          'phone, and we cannot see it. The app has no account system, no '
          'server, no bank connection, no ads and no tracking.',
    ),
    (
      icon: Icons.person_rounded,
      title: 'Who we are',
      body: 'SubGuard: Subscription Tracker is provided by Md Hasan Ali '
          '("we", "us"). This policy explains what information the app '
          'handles and where it is kept. It applies to the Android version '
          'of the app.',
    ),
    (
      icon: Icons.edit_note_rounded,
      title: 'Information you enter',
      body: 'The subscriptions you add are saved only on your device, in the '
          'app\'s private storage: service names, prices, currencies, billing '
          'cycles, renewal dates, free-trial status, categories, colors, '
          'notes and cancel links.\n\n'
          'SubGuard also keeps a payment history on your device. It is built '
          'from the billing dates you entered, not from your bank or card.\n\n'
          'Your settings (currency, reminder days and reminder time) are '
          'saved on your device too.\n\n'
          'None of this is sent to us or to anyone else.',
    ),
    (
      icon: Icons.backup_rounded,
      title: 'Device backups',
      body: 'If backup is turned on in your phone\'s settings, Android may '
          'include app data in your own device backup or when you move to a '
          'new phone. That backup is handled by Google under your Google '
          'account and Google\'s privacy terms. We have no access to it. You '
          'can manage backups in your phone\'s settings.',
    ),
    (
      icon: Icons.phone_android_rounded,
      title: 'Device information',
      body: 'SubGuard checks your phone\'s brand name (for example Xiaomi or '
          'Samsung) and whether reminder-related settings are allowed for '
          'SubGuard, on the device itself, only to show the right setup steps '
          'for reminders. This is never sent anywhere. SubGuard does not read '
          'your phone number, contacts, location, photos, camera, microphone, '
          'messages or any account details.',
    ),
    (
      icon: Icons.notifications_rounded,
      title: 'Notifications and permissions',
      body: 'Reminders are scheduled and shown by your phone\'s own system; '
          'nothing goes over the internet to deliver them.\n\n'
          '• Notifications: to show a reminder before a payment or a free '
          'trial ends.\n'
          '• Alarms & reminders: so reminders arrive at the time you chose.\n'
          '• Run at startup: to restore reminders after the phone restarts '
          'or the app is updated.\n\n'
          'SubGuard may open your phone\'s settings pages (for example '
          'battery or auto-start settings) so you can allow these yourself. '
          'It cannot change any setting without you. You can turn reminders '
          'off at any time in your phone\'s notification settings.',
    ),
    (
      icon: Icons.open_in_new_rounded,
      title: 'Links to other websites',
      body: 'When you tap Cancel, SubGuard opens the service\'s own website or '
          'app (for example netflix.com, claude.ai or your Google Play '
          'subscriptions page), or a web search for how to cancel it. '
          'SubGuard never sees your passwords or anything you do on those '
          'sites. Those websites have their own privacy policies.',
    ),
    (
      icon: Icons.block_rounded,
      title: 'Ads, analytics and tracking',
      body: 'This version of SubGuard contains no ads, no analytics, no '
          'tracking tools and no in-app purchases. We do not sell or share '
          'any information. The app works without an internet connection, '
          'except when you open a cancel link.',
    ),
    (
      icon: Icons.delete_outline_rounded,
      title: 'Deleting your information',
      body: 'Tap Settings → Delete all data to remove all your subscriptions '
          'and payment history at any time. Uninstalling the app also removes '
          'this information from your phone. Backups you made separately are '
          'managed in your phone\'s settings.',
    ),
    (
      icon: Icons.mail_outline_rounded,
      title: 'If you email us',
      body: 'If you contact us by email, we receive your email address and '
          'your message. We use them only to reply to you, and we do not '
          'share them.',
    ),
    (
      icon: Icons.child_care_rounded,
      title: 'Children',
      body: 'SubGuard is not directed at children under 13, and we do not '
          'knowingly collect any information from children.',
    ),
    (
      icon: Icons.update_rounded,
      title: 'Changes to this policy',
      body: 'If this policy changes, the new version will be shown here and on '
          'our website with a new "Last updated" date. If a future version '
          'adds features such as in-app purchases, this policy will be '
          'updated before those features are released.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
        children: [
          GradientCard(
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white, size: 38),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your data stays on your phone',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('Last updated: $_lastUpdated',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final s in _sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBadge(s.icon, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(s.body, style: text.bodyMedium?.copyWith(height: 1.45)),
                  ],
                ),
              ),
            ),
          SoftCard(
            child: Row(
              children: [
                const IconBadge(Icons.mail_rounded, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Developer: $developerName', style: text.bodyMedium),
                      SelectableText(supportEmail,
                          style: text.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700)),
                    ],
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
