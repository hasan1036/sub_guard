import 'package:flutter/material.dart';

import '../services/device_setup.dart';
import '../services/notifications.dart';
import '../state/app_state.dart';
import '../widgets/ui.dart';
import 'shell_screen.dart';

/// Guided, one-tap-per-step setup so reminders really arrive.
/// Opens by itself after the first subscription is added, and from
/// the banner on Home until it is finished.
class ReminderSetupScreen extends StatefulWidget {
  const ReminderSetupScreen({super.key, this.firstRun = false});

  /// true when shown right after the welcome pages, before the app itself:
  /// finishing (or skipping) then opens Home instead of going back.
  final bool firstRun;

  /// True when nothing needs the user: every setting reminders depend on is
  /// already allowed. Then setup is skipped and the user goes straight on.
  /// (Auto-start can't be read on any phone, so phones that have it always
  /// show setup.)
  static Future<bool> everythingAllowed() async {
    final device = DeviceSetup.instance;
    final notify = NotificationService.instance;
    await device.load();
    if (!await notify.notificationsEnabled()) return false;
    if (!await notify.canUseExact()) return false;
    if (device.needsBackgroundSetup && device.hasAutostart) return false;
    if (device.needsBackgroundSetup && !await device.isBatteryUnrestricted()) {
      return false;
    }
    return true;
  }

  @override
  State<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends State<ReminderSetupScreen>
    with WidgetsBindingObserver {
  final _device = DeviceSetup.instance;
  final _notify = NotificationService.instance;

  bool _loading = true;
  bool _notificationsOn = false;
  bool _exactOn = false;
  // The phone doesn't tell apps about these two settings,
  // so the user confirms them with one tap after opening the page.
  bool _autostartOpened = false;
  bool _autostartDone = false;
  bool _batteryOpened = false;
  bool _batteryDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the phone's settings: re-check what is now allowed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    await _device.load();
    final n = await _notify.notificationsEnabled();
    final e = await _notify.canUseExact();
    final b = await _device.isBatteryUnrestricted();
    if (!mounted) return;
    setState(() {
      _notificationsOn = n;
      _exactOn = e;
      // Ticks itself when Android reports it (stock Android, Samsung...).
      if (b) _batteryDone = true;
      _loading = false;
    });
  }

  bool get _needsBackground => _device.needsBackgroundSetup;

  bool get _needsAutostart => _needsBackground && _device.hasAutostart;

  bool get _allDone =>
      _notificationsOn &&
      _exactOn &&
      (!_needsAutostart || _autostartDone) &&
      (!_needsBackground || _batteryDone);

  Future<void> _fixNotifications() async {
    final on = await _notify.askNotifications();
    // Android stops showing the popup after a "Don't allow";
    // then the only way is the app's settings page.
    if (!on) await _device.openAppSettings();
    await _refresh();
  }

  Future<void> _fixExact() async {
    await _notify.requestExactPermission();
    await _refresh();
  }

  Future<void> _fixAutostart() async {
    setState(() => _autostartOpened = true);
    await _device.openBackgroundSettings();
  }

  Future<void> _fixBattery() async {
    setState(() => _batteryOpened = true);
    await _device.openAppSettings();
  }

  Future<void> _finish() async {
    final state = AppScope.read(context);
    final navigator = Navigator.of(context);
    await state.markReminderSetupDone();
    // Re-schedule in the best mode now that permissions changed.
    await state.refresh();
    _leave(navigator);
  }

  void _leave(NavigatorState navigator) {
    if (widget.firstRun) {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ShellScreen()),
      );
    } else {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    var step = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder setup'),
        // First run: there is nothing to go back to.
        automaticallyImplyLeading: !widget.firstRun,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
              children: [
                GradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: Colors.white, size: 36),
                      const SizedBox(height: 10),
                      Text(
                          widget.firstRun
                              ? 'One last step: allow reminders'
                              : 'Make sure reminders reach you',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        _device.isKnownStrict
                            ? '${_device.brandLabel} phones block reminders '
                                'unless you allow SubGuard. It takes 1 minute.'
                            : _needsBackground
                                ? 'Phones can delay reminders to save battery. '
                                    'Allow SubGuard once and every reminder '
                                    'arrives on time. It takes 1 minute.'
                                : 'Allow these once, and every reminder will arrive on time.',
                        style: text.bodyMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _StepCard(
                  number: ++step,
                  icon: Icons.notifications_rounded,
                  title: 'Allow notifications',
                  description: 'Tap Allow on the popup.',
                  done: _notificationsOn,
                  buttonLabel: 'Allow',
                  onFix: _fixNotifications,
                ),
                _StepCard(
                  number: ++step,
                  icon: Icons.alarm_on_rounded,
                  title: 'Allow precise reminders',
                  description: 'Turn on the switch, then come back.',
                  illustration: const _MockSwitch(
                      screen: 'Alarms & reminders',
                      label: 'Allow setting alarms and reminders'),
                  done: _exactOn,
                  buttonLabel: 'Open',
                  onFix: _fixExact,
                ),
                if (_needsAutostart)
                  _StepCard(
                    number: ++step,
                    icon: Icons.power_settings_new_rounded,
                    title: 'Turn on ${_device.autostartLabel}',
                    description: 'One switch, then come back.',
                    illustration: _MockSwitch(
                        screen: _device.autostartLabel, label: 'SubGuard'),
                    done: _autostartDone,
                    buttonLabel: 'Open',
                    onFix: _fixAutostart,
                    confirmLabel: _autostartOpened && !_autostartDone
                        ? 'Done'
                        : null,
                    onConfirm: () => setState(() => _autostartDone = true),
                  ),
                if (_needsBackground)
                  _StepCard(
                    number: ++step,
                    icon: Icons.battery_charging_full_rounded,
                    title: 'Remove battery limits',
                    description:
                        'Tap ${_device.batteryMenu}, choose "${_device.batteryChoice}", then come back.',
                    illustration: _MockChoice(
                        screen: _device.batteryMenu,
                        choice: _device.batteryChoice),
                    done: _batteryDone,
                    buttonLabel: 'Open',
                    onFix: _fixBattery,
                    confirmLabel:
                        _batteryOpened && !_batteryDone ? 'Done' : null,
                    onConfirm: () => setState(() => _batteryDone = true),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final msg = await _notify.scheduleTest();
                    messenger.showSnackBar(SnackBar(
                      content: Text(msg),
                      duration: const Duration(seconds: 6),
                    ));
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send a test reminder'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  label: _allDone ? 'All set!' : 'Done',
                  icon: _allDone ? Icons.check_circle_rounded : Icons.check_rounded,
                  onPressed: _finish,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => _leave(Navigator.of(context)),
                    child: const Text('Skip for now'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.done,
    required this.buttonLabel,
    required this.onFix,
    this.illustration,
    this.confirmLabel,
    this.onConfirm,
  });

  final int number;
  final IconData icon;
  final String title;
  final String description;
  final Widget? illustration;
  final bool done;
  final String buttonLabel;
  final VoidCallback onFix;
  final String? confirmLabel;
  final VoidCallback? onConfirm;

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        color: done ? _green.withValues(alpha: 0.10) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(done ? Icons.check_rounded : icon,
                    color: done ? _green : cs.primary, size: 42),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step $number',
                          style: text.labelSmall?.copyWith(
                              color: done ? _green : cs.primary,
                              fontWeight: FontWeight.w800)),
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15.5)),
                    ],
                  ),
                ),
                if (done)
                  const Text('Done ✅',
                      style: TextStyle(
                          color: _green, fontWeight: FontWeight.w800))
                else
                  FilledButton(
                    onPressed: onFix,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(buttonLabel),
                  ),
              ],
            ),
            if (!done) ...[
              const SizedBox(height: 10),
              Text(description, style: text.bodyMedium),
              if (illustration != null) ...[
                const SizedBox(height: 10),
                illustration!,
              ],
              if (confirmLabel != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onFix,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open again'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onConfirm,
                        style: FilledButton.styleFrom(backgroundColor: _green),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(confirmLabel!),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// A small drawing of the phone's settings screen, so people know exactly
/// which switch to look for. Not the real screen: a simple picture of it.
class _MockScreen extends StatelessWidget {
  const _MockScreen({required this.screen, required this.child});
  final String screen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_back_rounded, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(screen,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          gradient: Brand.gradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.verified_user_rounded,
            color: Colors.white, size: 17),
      );
}

/// "Find this row, turn this switch on" picture.
class _MockSwitch extends StatelessWidget {
  const _MockSwitch({required this.screen, required this.label});
  final String screen;
  final String label;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);
    return _MockScreen(
      screen: screen,
      child: Row(
        children: [
          const _AppIcon(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const _Pointer(),
          const SizedBox(width: 6),
          // Switch drawn in the ON position.
          Container(
            width: 42,
            height: 24,
            padding: const EdgeInsets.all(3),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Pick this option" picture.
class _MockChoice extends StatelessWidget {
  const _MockChoice({required this.screen, required this.choice});
  final String screen;
  final String choice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const green = Color(0xFF16A34A);
    Widget option(String text, bool picked) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                picked
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: picked ? green : cs.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                      fontWeight: picked ? FontWeight.w800 : FontWeight.w500,
                      color: picked ? null : cs.onSurfaceVariant,
                    )),
              ),
              if (picked) const _Pointer(),
            ],
          ),
        );
    return _MockScreen(
      screen: 'SubGuard  ›  $screen',
      child: Column(
        children: [
          option(choice, true),
          option('Battery saver (recommended)', false),
          option('Restrict background apps', false),
        ],
      ),
    );
  }
}

/// Orange "tap here" pointer.
class _Pointer extends StatelessWidget {
  const _Pointer();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8A00),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('THIS',
            style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900)),
      );
}
