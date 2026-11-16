import 'package:flutter/material.dart';

import 'screens/shell_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/reminder_setup_screen.dart';
import 'screens/subscription_detail_screen.dart';
import 'services/device_setup.dart';
import 'services/notifications.dart';
import 'services/storage.dart';
import 'state/app_state.dart';
import 'utils/cancel.dart';
import 'widgets/ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await DeviceSetup.instance.load();
  final state = AppState(Storage());
  await state.load();
  runApp(SubGuardApp(state: state));
}

class SubGuardApp extends StatefulWidget {
  const SubGuardApp({super.key, required this.state});

  final AppState state;

  @override
  State<SubGuardApp> createState() => _SubGuardAppState();
}

class _SubGuardAppState extends State<SubGuardApp> {
  late final AppLifecycleListener _lifecycle;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Billing dates that passed while the app was closed go into History.
    _lifecycle = AppLifecycleListener(onResume: _onResume);

    // Tapping a reminder opens that subscription's page.
    NotificationService.instance.onOpenSubscription = _openSubscription;
    NotificationService.instance.onCancelSubscription = _cancelSubscription;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.handleLaunchFromNotification();
      // The phone may have closed the app during a test: check on start too.
      _checkTestReminder();
    });
  }

  Future<void> _onResume() async {
    await widget.state.refresh();
    await _checkTestReminder();
  }

  /// After "Send a test reminder": if the reminder never showed up, the phone
  /// is blocking SubGuard. Say so, and offer the setup that fixes it.
  Future<void> _checkTestReminder() async {
    final arrived = await NotificationService.instance.takeTestResult();
    final ctx = _navigatorKey.currentContext;
    if (arrived == null || ctx == null || !ctx.mounted) return;

    if (arrived) {
      ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(const SnackBar(
        content: Text('✅ Test reminder arrived. Your reminders work!'),
      ));
      return;
    }

    final fix = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        icon: const Icon(Icons.notifications_off_rounded,
            color: Color(0xFFE07000), size: 40),
        title: const Text('Did the test reminder arrive?'),
        content: const Text(
            'We could not see it on your phone. Some phones stop apps in the '
            'background and block reminders. The 1-minute setup fixes this.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('It arrived')),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Fix it now')),
        ],
      ),
    );
    if (fix == true) {
      _navigatorKey.currentState?.push(MaterialPageRoute<void>(
          builder: (_) => const ReminderSetupScreen()));
    }
  }

  /// "Cancel now" on a reminder: show the subscription in the app (so the
  /// user lands there when they come back) and open its cancel page.
  void _cancelSubscription(String id) {
    for (final s in widget.state.subscriptions) {
      if (s.id == id) {
        _openSubscription(id);
        openCancelPage(s);
        return;
      }
    }
  }

  void _openSubscription(String id) {
    final exists = widget.state.subscriptions.any((s) => s.id == id);
    if (!exists) return;
    _navigatorKey.currentState?.push(MaterialPageRoute<void>(
      builder: (_) => SubscriptionDetailScreen(subscriptionId: id),
    ));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  ThemeData _theme(Brightness b) {
    final light = b == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: Brand.primary,
      brightness: b,
      primary: light ? Brand.primary : null,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: light ? Brand.bgLight : null,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        // First launch: explain what the app does; afterwards straight in.
        home: widget.state.onboardingSeen
            ? const ShellScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}
