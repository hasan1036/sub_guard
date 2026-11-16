import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/ui.dart';
import 'reminder_setup_screen.dart';
import 'shell_screen.dart';

/// Shown once, the first time the app opens: what SubGuard does and why.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      title: 'Never pay for a subscription you forgot about again',
      text: 'Netflix, Spotify, ChatGPT, free trials… Keep every subscription '
          'in one place and see what they really cost you each month.',
      art: _Art.subscriptions,
    ),
    (
      title: 'Get reminded before every charge',
      text: 'SubGuard warns you days before you are charged, and before a '
          'free trial turns into a paid plan. Even when the app is closed.',
      art: _Art.reminder,
    ),
    (
      title: 'Cancel in one tap',
      text: 'Not using it anymore? Open the official cancel page instantly. '
          'No account, no bank link: your data stays on your phone.',
      art: _Art.cancel,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// After the welcome pages, set up reminders BEFORE anything else:
  /// some phones (Xiaomi, Oppo, Vivo...) block them until allowed.
  Future<void> _finish() async {
    final navigator = Navigator.of(context);
    final state = AppScope.read(context);
    await state.markOnboardingSeen();
    var ready = state.reminderSetupDone;
    if (!ready && await ReminderSetupScreen.everythingAllowed()) {
      // This phone already allows everything: no need to ask.
      await state.markReminderSetupDone();
      ready = true;
    }
    navigator.pushReplacement(MaterialPageRoute<void>(
      builder: (_) =>
          ready ? const ShellScreen() : const ReminderSetupScreen(firstRun: true),
    ));
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Brand.gradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: last ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: last ? null : _finish,
                    child: const Text('Skip',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: Center(child: _Illustration(p.art))),
                          Text(
                            p.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            p.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15.5,
                                height: 1.45),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // Next / Get started
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Brand.deep,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      last ? 'Get started' : 'Next',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Art { subscriptions, reminder, cancel }

/// Simple drawings made from the app's own parts, so the welcome pages
/// look exactly like what the user will get.
class _Illustration extends StatelessWidget {
  const _Illustration(this.art);
  final _Art art;

  @override
  Widget build(BuildContext context) {
    switch (art) {
      case _Art.subscriptions:
        return SizedBox(
          width: 260,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _glow(220),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: Brand.primary, size: 72),
              ),
              const Positioned(
                  left: 10,
                  top: 18,
                  child: ServiceAvatar(name: 'Netflix', color: 0xFFE50914, size: 58)),
              const Positioned(
                  right: 6,
                  top: 30,
                  child: ServiceAvatar(name: 'Spotify', color: 0xFF1DB954, size: 54)),
              const Positioned(
                  left: 22,
                  bottom: 12,
                  child: ServiceAvatar(name: 'ChatGPT', color: 0xFF10A37F, size: 52)),
              const Positioned(
                  right: 24,
                  bottom: 6,
                  child: ServiceAvatar(name: 'YouTube', color: 0xFFFF0000, size: 58)),
            ],
          ),
        );

      case _Art.reminder:
        return Stack(
          alignment: Alignment.center,
          children: [
            _glow(240),
            Container(
              width: 290,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, 10)),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: Brand.primary, size: 16),
                      SizedBox(width: 6),
                      Text('SubGuard · Upcoming payment',
                          style: TextStyle(
                              fontSize: 11.5, color: Color(0xFF6B6B80))),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔔 Netflix renews tomorrow',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Color(0xFF1B1B2F))),
                            SizedBox(height: 4),
                            Text('\$15.99 will be charged. Still using it?',
                                style: TextStyle(
                                    fontSize: 12.5, color: Color(0xFF4A4A5E))),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      ServiceAvatar(name: 'Netflix', color: 0xFFE50914, size: 40),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text('CANCEL NOW',
                          style: TextStyle(
                              color: Color(0xFFE0245E),
                              fontWeight: FontWeight.w900,
                              fontSize: 12)),
                      SizedBox(width: 18),
                      Text('VIEW DETAILS',
                          style: TextStyle(
                              color: Brand.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

      case _Art.cancel:
      default:
        return Stack(
          alignment: Alignment.center,
          children: [
            _glow(240),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 280,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF5A5F), Color(0xFFE0245E)]),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 20,
                          offset: Offset(0, 8)),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel_rounded, color: Colors.white, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cancel Netflix',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17)),
                            Text('Opens netflix.com, the official site',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Your data stays on your phone',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _glow(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.10),
        ),
      );
}
