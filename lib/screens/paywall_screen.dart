import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/ui.dart';

/// Premium screen. Purchases are not wired yet.
/// Next step: add the `purchases_flutter` (RevenueCat) package and call
/// Purchases.purchasePackage(...) from the buttons below.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _yearly = true;

  void _buy() {
    // TODO: RevenueCat purchase. Until then, tell the tester.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Payments are coming soon. Use the developer switch in Settings to test Premium.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    const features = [
      (Icons.all_inclusive, 'Unlimited subscriptions', 'Free plan is limited to $freeLimit'),
      (Icons.timer_outlined, 'Free-trial guard', 'Never get charged for a trial you forgot'),
      (Icons.trending_up, 'Price-increase alerts', 'Coming soon'),
      (Icons.document_scanner_outlined, 'Scan receipts with AI', 'Coming soon'),
      (Icons.family_restroom, 'Family sharing', 'Coming soon'),
    ];

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Icon(Icons.workspace_premium, size: 64, color: cs.primary),
          const SizedBox(height: 12),
          Text('$appName Premium',
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            state.isPremium
                ? 'Premium is active on this device.'
                : 'Most people find at least one subscription they forgot. '
                    'Premium usually pays for itself in the first month.',
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
          const SizedBox(height: 24),
          for (final f in features)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(f.$1, color: cs.primary),
              title: Text(f.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(f.$3),
            ),
          const SizedBox(height: 16),
          if (!state.isPremium) ...[
            _PlanCard(
              selected: _yearly,
              title: 'Yearly',
              price: '\$34.99 / year',
              note: 'Just \$2.92 a month · save 40%',
              onTap: () => setState(() => _yearly = true),
            ),
            const SizedBox(height: 12),
            _PlanCard(
              selected: !_yearly,
              title: 'Monthly',
              price: '\$4.99 / month',
              note: 'Cancel anytime',
              onTap: () => setState(() => _yearly = false),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Start 7-day free trial',
              icon: Icons.workspace_premium_rounded,
              onPressed: _buy,
            ),
            const SizedBox(height: 8),
            Text(
              'You will be reminded before the trial ends. Of course.',
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.selected,
    required this.title,
    required this.price,
    required this.note,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String price;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? cs.primary : cs.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(note, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
