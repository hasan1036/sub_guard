import 'dart:math';

enum BillingCycle { weekly, monthly, quarterly, yearly }

extension BillingCycleX on BillingCycle {
  String get label => switch (this) {
        BillingCycle.weekly => 'Weekly',
        BillingCycle.monthly => 'Monthly',
        BillingCycle.quarterly => 'Quarterly',
        BillingCycle.yearly => 'Yearly',
      };

  String get short => switch (this) {
        BillingCycle.weekly => '/wk',
        BillingCycle.monthly => '/mo',
        BillingCycle.quarterly => '/qtr',
        BillingCycle.yearly => '/yr',
      };
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime _addMonths(DateTime d, int months, int anchorDay) {
  final total = d.month - 1 + months;
  final year = d.year + total ~/ 12;
  final month = total % 12 + 1;
  final day = min(anchorDay, _daysInMonth(year, month));
  return DateTime(year, month, day);
}

/// Next billing date after [d]. [anchorDay] keeps e.g. the 31st from
/// drifting to the 28th forever after February.
DateTime advanceDate(DateTime d, BillingCycle cycle, int anchorDay) =>
    switch (cycle) {
      BillingCycle.weekly => DateTime(d.year, d.month, d.day + 7),
      BillingCycle.monthly => _addMonths(d, 1, anchorDay),
      BillingCycle.quarterly => _addMonths(d, 3, anchorDay),
      BillingCycle.yearly => _addMonths(d, 12, anchorDay),
    };

class Subscription {
  final String id;
  final String name;
  final double price;
  final String currency;
  final BillingCycle cycle;
  final DateTime nextBillingDate;
  final int anchorDay;
  final bool isTrial;
  final String category;
  final int colorValue;
  final String? cancelUrl;
  final String notes;
  final int remindDaysBefore;
  final DateTime createdAt;

  const Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.cycle,
    required this.nextBillingDate,
    required this.anchorDay,
    required this.isTrial,
    required this.category,
    required this.colorValue,
    required this.cancelUrl,
    required this.notes,
    required this.remindDaysBefore,
    required this.createdAt,
  });

  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';

  double get monthlyCost => switch (cycle) {
        BillingCycle.weekly => price * 52 / 12,
        BillingCycle.monthly => price,
        BillingCycle.quarterly => price / 3,
        BillingCycle.yearly => price / 12,
      };

  double get yearlyCost => monthlyCost * 12;

  int daysUntilBilling([DateTime? now]) =>
      dateOnly(nextBillingDate).difference(dateOnly(now ?? DateTime.now())).inDays;

  Subscription copyWith({DateTime? nextBillingDate, bool? isTrial}) =>
      Subscription(
        id: id,
        name: name,
        price: price,
        currency: currency,
        cycle: cycle,
        nextBillingDate: nextBillingDate ?? this.nextBillingDate,
        anchorDay: anchorDay,
        isTrial: isTrial ?? this.isTrial,
        category: category,
        colorValue: colorValue,
        cancelUrl: cancelUrl,
        notes: notes,
        remindDaysBefore: remindDaysBefore,
        createdAt: createdAt,
      );

  /// Billing dates that are already in the past. Each one is a charge that
  /// happened (a trial's end date is its first charge).
  List<DateTime> pastChargeDates([DateTime? now]) {
    final today = dateOnly(now ?? DateTime.now());
    final out = <DateTime>[];
    var next = dateOnly(nextBillingDate);
    while (next.isBefore(today) && out.length < 1000) {
      out.add(next);
      next = advanceDate(next, cycle, anchorDay);
    }
    return out;
  }

  /// Future charge dates from the next billing date up to [until] (inclusive).
  List<DateTime> chargesUntil(DateTime until) {
    final end = dateOnly(until);
    final out = <DateTime>[];
    var next = dateOnly(nextBillingDate);
    while (!next.isAfter(end) && out.length < 1000) {
      out.add(next);
      next = advanceDate(next, cycle, anchorDay);
    }
    return out;
  }

  /// Moves a past billing date forward to today or later.
  /// A trial whose end date has passed becomes a normal paid subscription.
  Subscription rolledForward([DateTime? now]) {
    final today = dateOnly(now ?? DateTime.now());
    var next = dateOnly(nextBillingDate);
    if (!next.isBefore(today)) return this;
    while (next.isBefore(today)) {
      next = advanceDate(next, cycle, anchorDay);
    }
    return copyWith(nextBillingDate: next, isTrial: false);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'currency': currency,
        'cycle': cycle.name,
        'nextBillingDate': nextBillingDate.toIso8601String(),
        'anchorDay': anchorDay,
        'isTrial': isTrial,
        'category': category,
        'colorValue': colorValue,
        'cancelUrl': cancelUrl,
        'notes': notes,
        'remindDaysBefore': remindDaysBefore,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Subscription.fromJson(Map<String, dynamic> j) {
    final next = DateTime.parse(j['nextBillingDate'] as String);
    return Subscription(
      id: j['id'] as String,
      name: j['name'] as String,
      price: (j['price'] as num).toDouble(),
      currency: j['currency'] as String? ?? 'USD',
      cycle: BillingCycle.values.firstWhere(
        (c) => c.name == j['cycle'],
        orElse: () => BillingCycle.monthly,
      ),
      nextBillingDate: next,
      anchorDay: j['anchorDay'] as int? ?? next.day,
      isTrial: j['isTrial'] as bool? ?? false,
      category: j['category'] as String? ?? 'Other',
      colorValue: j['colorValue'] as int? ?? 0xFF607D8B,
      cancelUrl: j['cancelUrl'] as String?,
      notes: j['notes'] as String? ?? '',
      remindDaysBefore: j['remindDaysBefore'] as int? ?? 1,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
