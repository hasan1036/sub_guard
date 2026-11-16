import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/subscription.dart';
import '../utils/format.dart';

/// Notification buttons.
const _actionOpen = 'open_subscription';
const _actionCancel = 'cancel_now';

/// White shield silhouette in android/app/src/main/res/drawable/.
const _smallIcon = '@drawable/ic_stat_subguard';
const _brand = Color(0xFF6A3DF0);

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Set by the app: opens the detail page of a subscription by id.
  void Function(String subscriptionId)? onOpenSubscription;

  /// Set by the app: opens the service's own cancel page.
  void Function(String subscriptionId)? onCancelSubscription;

  // Plain style. Used for the test and as a fallback if the rich style fails
  // (for example when the custom icon file is missing).
  static const _plainAndroid = AndroidNotificationDetails(
    'billing_reminders',
    'Billing reminders',
    channelDescription: 'Reminders before a subscription charges you',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _plain = NotificationDetails(
    android: _plainAndroid,
    iOS: DarwinNotificationDetails(),
  );

  static const _brandedTest = NotificationDetails(
    android: AndroidNotificationDetails(
      'billing_reminders',
      'Billing reminders',
      channelDescription: 'Reminders before a subscription charges you',
      importance: Importance.high,
      priority: Priority.high,
      icon: _smallIcon,
      color: _brand,
      subText: 'Test',
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (r) =>
            _handleTap(r.payload, actionId: r.actionId),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  void _handleTap(String? payload, {String? actionId}) {
    if (payload == null || payload.isEmpty) return;
    if (actionId == _actionCancel) {
      onCancelSubscription?.call(payload);
    } else {
      onOpenSubscription?.call(payload);
    }
  }

  /// If the app was started by tapping a reminder, open that subscription.
  /// Call once after the first frame.
  Future<void> handleLaunchFromNotification() async {
    if (!_ready) return;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        final r = details!.notificationResponse;
        _handleTap(r?.payload, actionId: r?.actionId);
      }
    } catch (e) {
      debugPrint('Launch details failed: $e');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// True when the phone lets us fire reminders at an exact time.
  /// Xiaomi and some other brands delay "inexact" reminders a lot,
  /// so exact mode is much more reliable there.
  Future<bool> canUseExact() async {
    if (!_ready) return false;
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Whether SubGuard is allowed to show notifications at all.
  Future<bool> notificationsEnabled() async {
    if (!_ready) return false;
    try {
      return await _android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Asks for notification permission; returns whether it is now on.
  Future<bool> askNotifications() async {
    if (!_ready) return false;
    try {
      await _android?.requestNotificationsPermission();
    } catch (_) {}
    return notificationsEnabled();
  }

  /// Opens the phone's "Alarms & reminders" page for SubGuard.
  Future<bool> requestExactPermission() async {
    if (!_ready) return false;
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Exact alarm request failed: $e');
    }
    return canUseExact();
  }

  /// "Alarm clock" mode is the most reliable kind of reminder on Android:
  /// it is what alarm-clock apps use, and phones that kill background apps
  /// (Xiaomi, Oppo, Vivo...) still deliver it. Needs the exact-alarm
  /// permission; without it we fall back to the normal (best-effort) mode.
  Future<AndroidScheduleMode> _mode() async => await canUseExact()
      ? AndroidScheduleMode.alarmClock
      : AndroidScheduleMode.inexactAllowWhileIdle;

  static const _testDueKey = 'test_reminder_due_at';

  /// After a test, tells whether the "2/2" reminder really showed up.
  /// null = no finished test to report; true = it arrived; false = it did not
  /// (the phone blocked it). Each test is reported once.
  Future<bool?> takeTestResult() async {
    if (!_ready) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final due = DateTime.tryParse(prefs.getString(_testDueKey) ?? '');
      if (due == null) return null;
      // Give the phone a little extra time before judging.
      if (DateTime.now().isBefore(due.add(const Duration(seconds: 20)))) {
        return null;
      }
      await prefs.remove(_testDueKey);
      final active = await _android?.getActiveNotifications();
      if (active == null) return null;
      return active.any((n) => n.id == 9999);
    } catch (e) {
      debugPrint('Test check failed: $e');
      return null;
    }
  }

  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _android?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Rich reminder design
  // ---------------------------------------------------------------------------

  /// Draws the service's rounded-square letter icon as a PNG, used as the
  /// big picture on the right side of the notification.
  /// Icons already drawn, so each one is drawn only once per app run.
  final _avatarCache = <String, Uint8List?>{};

  Future<Uint8List?> _avatarPng(String name, int color) async {
    final key = '${_initial(name)}|$color';
    if (_avatarCache.containsKey(key)) return _avatarCache[key];
    final png = await _drawAvatar(name, color);
    _avatarCache[key] = png;
    return png;
  }

  Future<Uint8List?> _drawAvatar(String name, int color) async {
    try {
      const size = 72.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final c = Color(color);
      const rect = Rect.fromLTWH(0, 0, size, size);
      final paint = Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(size, size),
          [Color.lerp(c, Colors.white, 0.18)!, c],
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(size * 0.28)),
        paint,
      );
      final letter = _initial(name);
      final tp = TextPainter(
        text: TextSpan(
          text: letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: size * 0.52,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));
      final image =
          await recorder.endRecording().toImage(size.toInt(), size.toInt());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Avatar render failed: $e');
      return null;
    }
  }

  /// First letter, safe for emoji and accented names.
  static String _initial(String name) {
    final t = name.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  static String _esc(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  ({String title, String body, NotificationDetails details}) _content(
    Subscription s,
    DateTime chargeDate,
    bool trialEnd,
    Uint8List? avatar,
  ) {
    final amount = formatMoney(s.price, s.currency);
    final yearly = formatMoney(s.yearlyCost, s.currency);
    final day = formatDayDate(chargeDate);
    final when = s.remindDaysBefore == 0
        ? 'today'
        : s.remindDaysBefore == 1
            ? 'tomorrow'
            : 'in ${s.remindDaysBefore} days';
    final name = _esc(s.name);

    // Collapsed view (one line each).
    final title = trialEnd
        ? '⚠️ ${s.name} free trial ends $when'
        : '🔔 ${s.name} renews $when';
    final body = trialEnd
        ? '$amount will be charged on $day. Cancel now if you don\'t need it.'
        : '$amount will be charged on $day. Still using it?';

    // Expanded view (pull down on the notification).
    final bigTitle = trialEnd
        ? '⚠️ <b>$name</b> free trial ends $when'
        : '🔔 <b>$name</b> renews $when';
    final bigText = trialEnd
        ? 'Your free trial turns into a paid plan on <b>$day</b>.<br>'
            '💳 You will be charged <b>${_esc(amount)}</b>.<br>'
            '✂️ Not sure? Cancel today and pay nothing.'
        : '💳 <b>${_esc(amount)}</b> will be charged on <b>$day</b>.<br>'
            '📉 That is <b>${_esc(yearly)}</b> a year.<br>'
            '🤔 Not using it anymore? Cancel before the charge.';

    final android = AndroidNotificationDetails(
      'billing_reminders',
      'Billing reminders',
      channelDescription: 'Reminders before a subscription charges you',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      icon: _smallIcon,
      color: _brand,
      largeIcon: avatar == null ? null : ByteArrayAndroidBitmap(avatar),
      subText: trialEnd ? 'Free trial ending' : 'Upcoming payment',
      ticker: title,
      styleInformation: BigTextStyleInformation(
        bigText,
        htmlFormatBigText: true,
        contentTitle: bigTitle,
        htmlFormatContentTitle: true,
        summaryText: trialEnd ? 'Free trial ending' : 'Upcoming payment',
      ),
      actions: const [
        AndroidNotificationAction(
          _actionCancel,
          'Cancel now',
          showsUserInterface: true,
          cancelNotification: true,
          titleColor: Color(0xFFE0245E),
        ),
        AndroidNotificationAction(
          _actionOpen,
          'View details',
          showsUserInterface: true,
          cancelNotification: true,
          titleColor: _brand,
        ),
      ],
    );

    return (
      title: title,
      body: body,
      details: NotificationDetails(
        android: android,
        iOS: DarwinNotificationDetails(
          subtitle: trialEnd ? 'Free trial ending' : 'Upcoming payment',
        ),
      ),
    );
  }

  /// Schedules with the rich design; if that fails for any reason,
  /// falls back to the plain design so the reminder is never lost.
  Future<void> _scheduleSafe({
    required int id,
    required DateTime at,
    required AndroidScheduleMode mode,
    required String title,
    required String body,
    required NotificationDetails details,
    String? payload,
  }) async {
    // TZDateTime.from keeps the exact instant, so UTC is fine here.
    final when = tz.TZDateTime.from(at, tz.UTC);
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: mode,
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Rich reminder failed, using plain: $e');
      lastError = 'Rich style failed: $e';
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: _plain,
        androidScheduleMode: mode,
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  /// What the app handed to the phone last time (for the
  /// "Scheduled reminders" screen), and the last error, if any.
  List<({String title, DateTime at})> lastScheduled = [];
  String? lastError;

  /// How many reminders the phone itself says are waiting.
  Future<int?> pendingCount() async {
    if (!_ready) return null;
    try {
      return (await _plugin.pendingNotificationRequests()).length;
    } catch (_) {
      return null;
    }
  }

  /// iOS keeps at most 64 pending notifications per app; stay well under it.
  /// Reminders further ahead are added as time passes (every app open).
  static const _maxPending = 40;

  /// Only the nearest reminders carry the service's picture: pictures make
  /// each saved reminder much bigger, which slows the phone down.
  static const _withPicture = 5;

  /// What is scheduled right now: reminder id -> fingerprint of its content.
  static const _sigKey = 'scheduled_reminders_v2';

  Future<void> _queue = Future.value();

  /// Re-schedules are queued so two of them never overlap.
  ///
  /// [forceNearest]: re-hand this many of the nearest reminders to the phone
  /// even if they look unchanged. Used on app start, because a "Force stop"
  /// (or some phones' cleaners) silently wipes an app's alarms while the
  /// plugin's own list still shows them as waiting.
  Future<void> rescheduleAll(List<Subscription> subs,
      {int minuteOfDay = 9 * 60, int forceNearest = 0}) {
    final next = _queue
        .then((_) => _rescheduleNow(subs, minuteOfDay, forceNearest));
    _queue = next.catchError((_) {});
    return next;
  }

  /// Same reminder (same subscription, same charge date) always gets the
  /// same id, so unchanged reminders can be left alone.
  static int _stableId(String subId, DateTime chargeDate) {
    var h = 17;
    for (final c in '$subId|${chargeDate.toIso8601String()}'.codeUnits) {
      h = (h * 31 + c) & 0x3fffffff;
    }
    return 10000 + h % 1000000000; // never 9998/9999 (the test reminders)
  }

  /// Brings the phone's reminders in line with the subscriptions, touching
  /// ONLY what changed: new ones are added, removed ones cancelled,
  /// unchanged ones left as they are. When nothing changed, nothing is done.
  ///
  /// Reminders are handed to the OS (AlarmManager on Android,
  /// UNUserNotificationCenter on iOS), so they fire even when the app is
  /// closed. Several future billing cycles are scheduled per subscription.
  Future<void> _rescheduleNow(
      List<Subscription> subs, int minuteOfDay, int forceNearest) async {
    if (!_ready) {
      lastError = 'Notifications are not available.';
      return;
    }
    lastError = null;
    try {
      final mode = await _mode();
      final now = DateTime.now();
      final horizon = dateOnly(now).add(const Duration(days: 400));

      // 1. The plan: every reminder that should exist, nearest first.
      final plan = <({
        Subscription sub,
        DateTime chargeDate,
        DateTime remindAt,
        bool trialEnd
      })>[];
      for (final s in subs) {
        final dates = s.chargesUntil(horizon);
        for (var i = 0; i < dates.length; i++) {
          final d = dates[i];
          // The user's reminder time (default 9:00 AM), N days before the charge.
          final remindAt = DateTime(d.year, d.month, d.day - s.remindDaysBefore,
              minuteOfDay ~/ 60, minuteOfDay % 60);
          if (!remindAt.isAfter(now)) continue;
          plan.add((
            sub: s,
            chargeDate: d,
            remindAt: remindAt,
            trialEnd: s.isTrial && i == 0,
          ));
        }
      }
      plan.sort((a, b) => a.remindAt.compareTo(b.remindAt));
      final wanted = plan.take(_maxPending).toList();

      // 2. What the phone has now (our record + what Android really holds).
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sigKey);
      if (raw == null) {
        // First run of this version: clear reminders made the old way.
        await _plugin.cancelAll();
      }
      final had = <int, String>{};
      if (raw != null) {
        for (final part in raw.split('\n')) {
          final i = part.indexOf('=');
          if (i > 0) had[int.tryParse(part.substring(0, i)) ?? -1] = part.substring(i + 1);
        }
      }
      final onPhone = (await _plugin.pendingNotificationRequests())
          .map((r) => r.id)
          .toSet();

      // 3. Work out the differences.
      final now2 = <int, String>{};
      final scheduled = <({String title, DateTime at})>[];
      for (var i = 0; i < wanted.length; i++) {
        final p = wanted[i];
        final s = p.sub;
        final withPicture = i < _withPicture;
        final id = _stableId(s.id, p.chargeDate);
        final c = _content(s, p.chargeDate, p.trialEnd, null);
        final sig = [
          c.title, c.body, p.remindAt.millisecondsSinceEpoch, mode.name,
          withPicture, s.colorValue, s.name,
        ].join('|');
        now2[id] = sig;
        scheduled.add((title: c.title, at: p.remindAt));

        final unchanged =
            i >= forceNearest && had[id] == sig && onPhone.contains(id);
        if (unchanged) continue;

        final picture =
            withPicture ? await _avatarPng(s.name, s.colorValue) : null;
        final rich = withPicture
            ? _content(s, p.chargeDate, p.trialEnd, picture)
            : c;
        await _scheduleSafe(
          id: id,
          at: p.remindAt,
          mode: mode,
          title: rich.title,
          body: rich.body,
          details: rich.details,
          payload: s.id,
        );
      }

      // 4. Cancel reminders that are no longer wanted. Only ones still
      // WAITING: a reminder that already fired is not touched, otherwise
      // opening the app would wipe it from the notification shade unread.
      for (final id in onPhone) {
        if (id >= 10000 && !now2.containsKey(id)) {
          await _plugin.cancel(id: id);
        }
      }

      await prefs.setString(
          _sigKey, now2.entries.map((e) => '${e.key}=${e.value}').join('\n'));
      lastScheduled = scheduled;
    } catch (e) {
      debugPrint('Scheduling failed: $e');
      lastError = 'Scheduling failed: $e';
    }
  }

  /// Two-step test for real phones, returns a message for the user:
  /// 1. An instant notification: proves permission + display work.
  /// 2. A scheduled one in [seconds]: proves the OS delivers it with the
  ///    app closed. If 1 arrives but 2 doesn't, the phone is killing the app.
  Future<String> scheduleTest({int seconds = 120}) async {
    if (!_ready) return 'Notifications are not available on this device.';
    try {
      await requestPermission();

      final enabled = await _android?.areNotificationsEnabled();
      if (enabled == false) {
        return 'Notifications are OFF for SubGuard. Turn them on in '
            'phone Settings → Apps → SubGuard → Notifications.';
      }

      const t1 = '1/2 SubGuard test';
      final b1 =
          'Notifications are allowed. Now close the app. "2/2" arrives in 2 minutes.';
      try {
        await _plugin.show(
            id: 9998, title: t1, body: b1, notificationDetails: _brandedTest);
      } catch (_) {
        await _plugin.show(
            id: 9998, title: t1, body: b1, notificationDetails: _plain);
      }

      // A preview of the real reminder design, as if Netflix renewed tomorrow.
      final exact = await canUseExact();
      final mode = await _mode();
      final demo = Subscription(
        id: '',
        name: 'Netflix',
        price: 15.99,
        currency: 'USD',
        cycle: BillingCycle.monthly,
        nextBillingDate: DateTime.now().add(const Duration(days: 1)),
        anchorDay: 1,
        isTrial: false,
        category: 'Streaming',
        colorValue: 0xFFE50914,
        cancelUrl: null,
        notes: '',
        remindDaysBefore: 1,
        createdAt: DateTime.now(),
      );
      final c = _content(demo, demo.nextBillingDate, false,
          await _avatarPng(demo.name, demo.colorValue));
      await _scheduleSafe(
        id: 9999,
        at: DateTime.now().add(Duration(seconds: seconds)),
        mode: mode,
        title: '✅ 2/2 ${c.title}',
        body: c.body,
        details: c.details,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_testDueKey,
          DateTime.now().add(Duration(seconds: seconds)).toIso8601String());

      final pending = await _plugin.pendingNotificationRequests();
      return 'Scheduled (${pending.length} waiting, '
          '${exact ? 'ALARM' : 'NORMAL'} mode). '
          'You should see "1/2" now. Close the app; "2/2" comes in 2 minutes.';
    } catch (e) {
      debugPrint('Test notification failed: $e');
      return 'Test failed: $e';
    }
  }
}
