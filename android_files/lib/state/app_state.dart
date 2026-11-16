import 'package:flutter/widgets.dart';

import '../models/payment.dart';
import '../models/subscription.dart';
import '../services/notifications.dart';
import '../services/storage.dart';

const appName = 'SubGuard';
const appVersion = '1.0.0';

/// Developer contact, shown in Settings and the privacy policy.
const developerName = 'Md Hasan Ali';
const supportEmail = 'bdhasan009@gmail.com';
const freeLimit = 5;

/// Launch switch. false = everything is free (first Play Store version):
/// no 5-subscription limit, no Premium screens.
/// Set to true after RevenueCat payments are connected.
const paymentsEnabled = false;

/// One future charge: which subscription and on what date.
typedef UpcomingCharge = ({Subscription sub, DateTime date});

class AppState extends ChangeNotifier {
  AppState(this._storage);

  final Storage _storage;
  List<Subscription> _subs = [];
  List<Payment> _payments = [];

  List<Subscription> get subscriptions {
    final list = [..._subs];
    list.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    return list;
  }

  /// Newest first.
  List<Payment> get payments {
    final list = [..._payments];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  String get defaultCurrency => _storage.defaultCurrency;
  int get defaultRemindDays => _storage.defaultRemindDays;
  bool get isPremium => _storage.isPremium;
  bool get onboardingSeen => _storage.onboardingSeen;

  Future<void> markOnboardingSeen() async {
    await _storage.setOnboardingSeen();
    notifyListeners();
  }

  bool get reminderSetupDone => _storage.reminderSetupDone;

  int get reminderMinuteOfDay => _storage.reminderMinuteOfDay;

  /// Changes when reminders arrive and re-schedules all of them.
  Future<void> setReminderMinuteOfDay(int minute) async {
    await _storage.setReminderMinuteOfDay(minute);
    await _persist();
  }

  Future<void> markReminderSetupDone() async {
    await _storage.setReminderSetupDone();
    notifyListeners();
  }

  bool get canAddMore =>
      !paymentsEnabled || isPremium || _subs.length < freeLimit;

  Future<void> load() async {
    await _storage.init();
    _payments = _storage.loadPayments();
    _subs = _storage.loadSubscriptions().map(_rollAndRecord).toList();
    // App start: re-hand the nearest reminders to the phone in case it
    // wiped them (Force stop, phone cleaner apps).
    _forceNearest = 10;
    await _persist();
  }

  /// Called when the app comes back to the foreground, so dates that passed
  /// while the app was in the background become history.
  ///
  /// Also used where the caller needs the reminders to be fully scheduled
  /// before going on (Scheduled reminders screen, Reminder setup).
  Future<void> refresh() async {
    _subs = _subs.map(_rollAndRecord).toList();
    await _persist();
    await remindersReady;
  }

  /// Logs every passed billing date as a payment, then moves the
  /// subscription to its next future date.
  Subscription _rollAndRecord(Subscription s) {
    final dates = s.pastChargeDates();
    if (dates.isEmpty) return s;
    for (final d in dates) {
      final exists = _payments
          .any((p) => p.subscriptionId == s.id && dateOnly(p.date) == d);
      if (exists) continue;
      _payments.add(Payment(
        id: Subscription.newId(),
        subscriptionId: s.id,
        name: s.name,
        amount: s.price,
        currency: s.currency,
        date: d,
        colorValue: s.colorValue,
      ));
    }
    return s.rolledForward();
  }

  /// Saves to the phone and updates the screen right away. Reminders are
  /// re-scheduled in the background, so saving never makes the app wait,
  /// however many subscriptions there are.
  Future<void> _persist() async {
    await _storage.saveSubscriptions(_subs);
    await _storage.savePayments(_payments);
    notifyListeners();
    _scheduleReminders();
  }

  int _forceNearest = 0;
  bool _scheduling = false;
  bool _scheduleAgain = false;
  Future<void> _scheduleRun = Future.value();

  /// Completes when the latest reminder update has finished.
  Future<void> get remindersReady => _scheduleRun;

  /// Runs one reminder update at a time. If more changes arrive while one is
  /// running, they are merged into ONE more update afterwards (not one each).
  void _scheduleReminders() {
    if (_scheduling) {
      _scheduleAgain = true;
      return;
    }
    _scheduling = true;
    _scheduleRun = () async {
      try {
        do {
          _scheduleAgain = false;
          final force = _forceNearest;
          _forceNearest = 0;
          await NotificationService.instance.rescheduleAll(
            List.of(_subs),
            minuteOfDay: _storage.reminderMinuteOfDay,
            forceNearest: force,
          );
        } while (_scheduleAgain);
      } finally {
        _scheduling = false;
      }
    }();
  }

  Future<void> upsert(Subscription s) async {
    final rolled = _rollAndRecord(s);
    final i = _subs.indexWhere((e) => e.id == rolled.id);
    if (i >= 0) {
      _subs[i] = rolled;
    } else {
      _subs.add(rolled);
    }
    if (!_storage.askedPermission) {
      await _storage.setAskedPermission();
      await NotificationService.instance.requestPermission();
    }
    await _persist();
  }

  Future<void> delete(String id) async {
    _subs.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> deletePayment(String id) async {
    _payments.removeWhere((p) => p.id == id);
    // Notify right away so a swiped-away row leaves the list immediately.
    notifyListeners();
    await _persist();
  }

  Future<void> restorePayment(Payment p) async {
    _payments.add(p);
    await _persist();
  }

  Future<void> deleteAll() async {
    _subs = [];
    _payments = [];
    await _storage.clearAll();
    await _persist();
  }

  Future<void> setDefaultCurrency(String c) async {
    await _storage.setDefaultCurrency(c);
    notifyListeners();
  }

  Future<void> setDefaultRemindDays(int d) async {
    await _storage.setDefaultRemindDays(d);
    notifyListeners();
  }

  // TODO: replace with RevenueCat purchase status.
  Future<void> setPremium(bool v) async {
    await _storage.setPremium(v);
    notifyListeners();
  }

  /// Totals grouped by currency (no exchange rates yet).
  Map<String, double> get monthlyTotals {
    final m = <String, double>{};
    for (final s in _subs) {
      m[s.currency] = (m[s.currency] ?? 0) + s.monthlyCost;
    }
    return m;
  }

  List<Subscription> get trials => subscriptions.where((s) => s.isTrial).toList();

  List<Subscription> upcoming(int days) => subscriptions
      .where((s) => !s.isTrial && s.daysUntilBilling() <= days)
      .toList();

  /// Every charge in the next [days] days, including repeats
  /// (a weekly subscription shows up 4 times in 30 days).
  List<UpcomingCharge> upcomingCharges(int days) {
    final until = dateOnly(DateTime.now()).add(Duration(days: days));
    final out = <UpcomingCharge>[
      for (final s in _subs)
        for (final d in s.chargesUntil(until)) (sub: s, date: d),
    ];
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  Map<String, double> upcomingTotals(int days) {
    final m = <String, double>{};
    for (final c in upcomingCharges(days)) {
      m[c.sub.currency] = (m[c.sub.currency] ?? 0) + c.sub.price;
    }
    return m;
  }

  Map<String, double> spentInYear(int year) {
    final m = <String, double>{};
    for (final p in _payments.where((p) => p.date.year == year)) {
      m[p.currency] = (m[p.currency] ?? 0) + p.amount;
    }
    return m;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  /// Rebuilds the caller when the state changes.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// For callbacks (button presses): no rebuild subscription.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
