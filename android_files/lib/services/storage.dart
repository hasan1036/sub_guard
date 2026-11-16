import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment.dart';
import '../models/subscription.dart';

/// Everything is stored on the phone only. No account, no server, no bank link.
class Storage {
  static const _subsKey = 'subscriptions_v1';
  static const _paymentsKey = 'payments_v1';
  static const _currencyKey = 'default_currency';
  static const _remindKey = 'default_remind_days';
  static const _premiumKey = 'is_premium';
  static const _askedPermissionKey = 'asked_notification_permission';
  static const _setupDoneKey = 'reminder_setup_done';
  static const _reminderMinuteKey = 'reminder_minute_of_day';
  static const _onboardingKey = 'onboarding_seen';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// One damaged entry is skipped instead of stopping the app from opening.
  static List<T> _parseEach<T>(
      List<Map<String, dynamic>> raw, T Function(Map<String, dynamic>) parse) {
    final out = <T>[];
    for (final j in raw) {
      try {
        out.add(parse(j));
      } catch (_) {}
    }
    return out;
  }

  List<Subscription> loadSubscriptions() =>
      _parseEach(_readList(_subsKey), Subscription.fromJson);

  Future<void> saveSubscriptions(List<Subscription> subs) =>
      _prefs.setString(_subsKey, jsonEncode(subs.map((s) => s.toJson()).toList()));

  List<Payment> loadPayments() =>
      _parseEach(_readList(_paymentsKey), Payment.fromJson);

  Future<void> savePayments(List<Payment> payments) => _prefs.setString(
      _paymentsKey, jsonEncode(payments.map((p) => p.toJson()).toList()));

  String get defaultCurrency => _prefs.getString(_currencyKey) ?? 'USD';
  Future<void> setDefaultCurrency(String v) => _prefs.setString(_currencyKey, v);

  int get defaultRemindDays => _prefs.getInt(_remindKey) ?? 1;
  Future<void> setDefaultRemindDays(int v) => _prefs.setInt(_remindKey, v);

  bool get isPremium => _prefs.getBool(_premiumKey) ?? false;
  Future<void> setPremium(bool v) => _prefs.setBool(_premiumKey, v);

  bool get askedPermission => _prefs.getBool(_askedPermissionKey) ?? false;
  Future<void> setAskedPermission() => _prefs.setBool(_askedPermissionKey, true);

  /// Time of day for reminders, in minutes after midnight (default 9:00 AM).
  int get reminderMinuteOfDay => _prefs.getInt(_reminderMinuteKey) ?? 9 * 60;
  Future<void> setReminderMinuteOfDay(int v) => _prefs.setInt(_reminderMinuteKey, v);

  bool get onboardingSeen => _prefs.getBool(_onboardingKey) ?? false;
  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingKey, true);

  bool get reminderSetupDone => _prefs.getBool(_setupDoneKey) ?? false;
  Future<void> setReminderSetupDone() => _prefs.setBool(_setupDoneKey, true);

  Future<void> clearAll() async {
    await _prefs.remove(_subsKey);
    await _prefs.remove(_paymentsKey);
  }
}
