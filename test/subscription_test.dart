import 'package:flutter_test/flutter_test.dart';
import 'package:subguard/models/subscription.dart';
import 'package:subguard/utils/format.dart';

Subscription _sub(DateTime next, BillingCycle cycle,
        {double price = 12, bool trial = false}) =>
    Subscription(
      id: 'x', name: 'Test', price: price, currency: 'USD', cycle: cycle,
      nextBillingDate: next, anchorDay: next.day, isTrial: trial,
      category: 'Other', colorValue: 0, cancelUrl: null, notes: '',
      remindDaysBefore: 1, createdAt: DateTime(2026),
    );

void main() {
  test('monthly keeps the 31st when the month allows it', () {
    final feb = advanceDate(DateTime(2027, 1, 31), BillingCycle.monthly, 31);
    expect(feb, DateTime(2027, 2, 28));
    final mar = advanceDate(feb, BillingCycle.monthly, 31);
    expect(mar, DateTime(2027, 3, 31));
  });

  test('yearly handles leap day', () {
    expect(advanceDate(DateTime(2028, 2, 29), BillingCycle.yearly, 29),
        DateTime(2029, 2, 28));
  });

  test('monthly cost conversion', () {
    expect(_sub(DateTime(2027), BillingCycle.yearly, price: 120).monthlyCost, 10);
    expect(_sub(DateTime(2027), BillingCycle.quarterly, price: 30).monthlyCost, 10);
  });

  test('roll forward moves past dates and ends trials', () {
    final s = _sub(DateTime(2026, 10, 5), BillingCycle.monthly, trial: true)
        .rolledForward(DateTime(2026, 11, 13));
    expect(s.nextBillingDate, DateTime(2026, 12, 5));
    expect(s.isTrial, false);
  });

  test('past charge dates become history', () {
    final dates = _sub(DateTime(2026, 9, 10), BillingCycle.monthly)
        .pastChargeDates(DateTime(2026, 11, 13));
    expect(dates, [
      DateTime(2026, 9, 10),
      DateTime(2026, 10, 10),
      DateTime(2026, 11, 10),
    ]);
  });

  test('weekly charges repeat inside the upcoming window', () {
    final dates = _sub(DateTime(2026, 11, 14), BillingCycle.weekly)
        .chargesUntil(DateTime(2026, 12, 13));
    expect(dates.length, 5);
    expect(dates.last, DateTime(2026, 12, 12));
  });

  test('future dates are untouched', () {
    final s = _sub(DateTime(2026, 12, 1), BillingCycle.monthly, trial: true)
        .rolledForward(DateTime(2026, 11, 13));
    expect(s.nextBillingDate, DateTime(2026, 12, 1));
    expect(s.isTrial, true);
  });

  test('prices typed in different ways are read correctly', () {
    expect(parsePrice('9.99'), 9.99);
    expect(parsePrice('9,99'), 9.99);
    expect(parsePrice('1,200'), 1200);
    expect(parsePrice('1,299.50'), 1299.5);
    expect(parsePrice('1.299,50'), 1299.5);
    expect(parsePrice('1 200'), 1200);
    expect(parsePrice(''), null);
    expect(parsePrice('abc'), null);
    expect(parsePrice('-5'), null);
    expect(parsePrice('1e400'), null);
  });

  test('cancel links are completed or rejected', () {
    expect(webLink('netflix.com/cancel').toString(), 'https://netflix.com/cancel');
    expect(webLink('https://claude.ai/settings/billing')!.host, 'claude.ai');
    expect(webLink('hello'), null);
    expect(webLink('my link.com'), null);
  });
}
